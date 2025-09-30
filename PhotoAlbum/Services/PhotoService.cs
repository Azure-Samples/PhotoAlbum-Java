using Microsoft.EntityFrameworkCore;
using PhotoAlbum.Data;
using PhotoAlbum.Models;
using SixLabors.ImageSharp;

namespace PhotoAlbum.Services;

/// <summary>
/// Service for photo operations including upload, retrieval, and deletion
/// </summary>
public class PhotoService : IPhotoService
{
    private readonly PhotoAlbumContext _context;
    private readonly IConfiguration _configuration;
    private readonly ILogger<PhotoService> _logger;
    private readonly string _uploadPath;
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

        _uploadPath = _configuration["FileUpload:UploadPath"] ?? "wwwroot/uploads";
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
    /// Upload a photo file
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

            // Generate unique filename
            var extension = Path.GetExtension(file.FileName);
            var storedFileName = $"{Guid.NewGuid()}{extension}";
            var relativePath = $"/uploads/{storedFileName}";

            // Ensure upload directory exists
            if (!Directory.Exists(_uploadPath))
            {
                Directory.CreateDirectory(_uploadPath);
            }

            var fullPath = Path.Combine(_uploadPath, storedFileName);

            // Extract image dimensions using ImageSharp
            int? width = null;
            int? height = null;
            try
            {
                using var image = await Image.LoadAsync(file.OpenReadStream());
                width = image.Width;
                height = image.Height;

                // Reset stream position for file saving
                file.OpenReadStream().Position = 0;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Could not extract image dimensions for {FileName}", file.FileName);
                // Continue without dimensions - not critical
            }

            // Save file to disk
            try
            {
                using var stream = new FileStream(fullPath, FileMode.Create);
                await file.CopyToAsync(stream);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error saving file {FileName} to {FullPath}", file.FileName, fullPath);
                result.Success = false;
                result.ErrorMessage = "Error saving file. Please try again.";
                return result;
            }

            // Create photo entity
            var photo = new Photo
            {
                OriginalFileName = file.FileName,
                StoredFileName = storedFileName,
                FilePath = relativePath,
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
                // Rollback: Delete file if database save fails
                try
                {
                    if (File.Exists(fullPath))
                    {
                        File.Delete(fullPath);
                    }
                }
                catch (Exception deleteEx)
                {
                    _logger.LogError(deleteEx, "Error deleting file {FullPath} during rollback", fullPath);
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
    /// Delete a photo by ID
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

            // Delete file from disk
            var fullPath = Path.Combine(_uploadPath, photo.StoredFileName);
            try
            {
                if (File.Exists(fullPath))
                {
                    File.Delete(fullPath);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting file {FullPath} for photo ID {PhotoId}", fullPath, id);
                // Continue with database deletion even if file deletion fails
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
