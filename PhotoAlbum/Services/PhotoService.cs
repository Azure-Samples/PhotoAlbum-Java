using Microsoft.EntityFrameworkCore;
using PhotoAlbum.Data;
using PhotoAlbum.Models;
using SixLabors.ImageSharp;
using Azure.Storage.Blobs;
using Azure.Identity;

namespace PhotoAlbum.Services;

/// <summary>
/// Service for photo operations including upload, retrieval, and deletion using Azure Blob Storage
/// </summary>
public class PhotoService : IPhotoService
{
    private readonly PhotoAlbumContext _context;
    private readonly IConfiguration _configuration;
    private readonly ILogger<PhotoService> _logger;
    private readonly BlobServiceClient _blobServiceClient;
    private readonly string _containerName;
    private readonly long _maxFileSizeBytes;
    private readonly string[] _allowedMimeTypes;

    public PhotoService(
        PhotoAlbumContext context,
        IConfiguration configuration,
        ILogger<PhotoService> logger)
    {
        _context = context;
        _configuration = configuration;
        _logger = logger;

        // Initialize Azure Blob Storage client
        var endpoint = _configuration["AzureStorageBlob:Endpoint"];
        if (string.IsNullOrEmpty(endpoint))
        {
            throw new InvalidOperationException("AzureStorageBlob:Endpoint configuration is required");
        }

        _blobServiceClient = new BlobServiceClient(
            new Uri(endpoint),
            new DefaultAzureCredential());

        _containerName = _configuration["AzureStorageBlob:ContainerName"] ?? "photos";
        _maxFileSizeBytes = _configuration.GetValue<long>("FileUpload:MaxFileSizeBytes", 10485760);
        _allowedMimeTypes = _configuration.GetSection("FileUpload:AllowedMimeTypes").Get<string[]>()
            ?? new[] { "image/jpeg", "image/png", "image/gif", "image/webp" };
    }

    /// <summary>
    /// Get all photos ordered by upload date (newest first)
    /// </summary>
    public async Task<List<Photo>> GetAllPhotosAsync()
    {
        try
        {
            return await _context.Photos
                .OrderByDescending(p => p.UploadedAt)
                .ToListAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving photos from database");
            throw;
        }
    }

    /// <summary>
    /// Get a specific photo by ID
    /// </summary>
    public async Task<Photo?> GetPhotoByIdAsync(int id)
    {
        try
        {
            return await _context.Photos.FindAsync(id);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving photo with ID {PhotoId}", id);
            throw;
        }
    }

    /// <summary>
    /// Upload a photo file to Azure Blob Storage
    /// </summary>
    public async Task<UploadResult> UploadPhotoAsync(IFormFile file)
    {
        var result = new UploadResult
        {
            FileName = file.FileName
        };

        try
        {
            // Validate file type
            if (!_allowedMimeTypes.Contains(file.ContentType.ToLowerInvariant()))
            {
                result.Success = false;
                result.ErrorMessage = $"File type not supported. Please upload JPEG, PNG, GIF, or WebP images.";
                _logger.LogWarning("Upload rejected: Invalid file type {ContentType} for {FileName}",
                    file.ContentType, file.FileName);
                return result;
            }

            // Validate file size
            if (file.Length > _maxFileSizeBytes)
            {
                result.Success = false;
                result.ErrorMessage = $"File size exceeds {_maxFileSizeBytes / 1024 / 1024}MB limit.";
                _logger.LogWarning("Upload rejected: File size {FileSize} exceeds limit for {FileName}",
                    file.Length, file.FileName);
                return result;
            }

            // Validate file length
            if (file.Length <= 0)
            {
                result.Success = false;
                result.ErrorMessage = "File is empty.";
                return result;
            }

            // Generate unique blob name
            var extension = Path.GetExtension(file.FileName);
            var blobName = $"{Guid.NewGuid()}{extension}";

            // Extract image dimensions using ImageSharp
            int? width = null;
            int? height = null;
            try
            {
                using var imageStream = file.OpenReadStream();
                using var image = await Image.LoadAsync(imageStream);
                width = image.Width;
                height = image.Height;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Could not extract image dimensions for {FileName}", file.FileName);
                // Continue without dimensions - not critical
            }

            // Upload to Azure Blob Storage
            try
            {
                var containerClient = _blobServiceClient.GetBlobContainerClient(_containerName);
                
                // Ensure container exists
                await containerClient.CreateIfNotExistsAsync();

                var blobClient = containerClient.GetBlobClient(blobName);

                // Upload file content
                using var uploadStream = file.OpenReadStream();
                var uploadOptions = new Azure.Storage.Blobs.Models.BlobUploadOptions
                {
                    HttpHeaders = new Azure.Storage.Blobs.Models.BlobHttpHeaders
                    {
                        ContentType = file.ContentType
                    }
                };

                await blobClient.UploadAsync(uploadStream, uploadOptions);

                _logger.LogInformation("Successfully uploaded blob {BlobName} to container {ContainerName}",
                    blobName, _containerName);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading file {FileName} to Azure Blob Storage", file.FileName);
                result.Success = false;
                result.ErrorMessage = "Error saving file. Please try again.";
                return result;
            }

            // Create photo entity
            var photo = new Photo
            {
                OriginalFileName = file.FileName,
                StoredFileName = blobName,
                FilePath = $"/{_containerName}/{blobName}",
                FileSize = file.Length,
                MimeType = file.ContentType,
                UploadedAt = DateTime.UtcNow,
                Width = width,
                Height = height
            };

            // Save to database
            try
            {
                await _context.Photos.AddAsync(photo);
                await _context.SaveChangesAsync();

                result.Success = true;
                result.PhotoId = photo.Id;

                _logger.LogInformation("Successfully uploaded photo {FileName} with ID {PhotoId}",
                    file.FileName, photo.Id);
            }
            catch (Exception ex)
            {
                // Rollback: Delete blob if database save fails
                try
                {
                    var containerClient = _blobServiceClient.GetBlobContainerClient(_containerName);
                    var blobClient = containerClient.GetBlobClient(blobName);
                    await blobClient.DeleteIfExistsAsync();
                }
                catch (Exception deleteEx)
                {
                    _logger.LogError(deleteEx, "Error deleting blob {BlobName} during rollback", blobName);
                }

                _logger.LogError(ex, "Error saving photo metadata to database for {FileName}", file.FileName);
                result.Success = false;
                result.ErrorMessage = "Error saving photo information. Please try again.";
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error during photo upload for {FileName}", file.FileName);
            result.Success = false;
            result.ErrorMessage = "An unexpected error occurred. Please try again.";
        }

        return result;
    }

    /// <summary>
    /// Delete a photo by ID from Azure Blob Storage
    /// </summary>
    public async Task<bool> DeletePhotoAsync(int id)
    {
        try
        {
            var photo = await _context.Photos.FindAsync(id);
            if (photo == null)
            {
                _logger.LogWarning("Photo with ID {PhotoId} not found for deletion", id);
                return false;
            }

            // Delete blob from Azure Storage
            try
            {
                var containerClient = _blobServiceClient.GetBlobContainerClient(_containerName);
                var blobClient = containerClient.GetBlobClient(photo.StoredFileName);
                await blobClient.DeleteIfExistsAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting blob {BlobName} for photo ID {PhotoId}", photo.StoredFileName, id);
                // Continue with database deletion even if blob deletion fails
            }

            // Delete from database
            _context.Photos.Remove(photo);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Successfully deleted photo ID {PhotoId}", id);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting photo with ID {PhotoId}", id);
            throw;
        }
    }
}
