using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using PhotoAlbum.Services;
using Azure.Storage.Blobs;
using Azure.Identity;

namespace PhotoAlbum.Pages;

/// <summary>
/// Page model for serving photo files from Azure Blob Storage
/// </summary>
public class PhotoFileModel : PageModel
{
    private readonly IPhotoService _photoService;
    private readonly ILogger<PhotoFileModel> _logger;
    private readonly IConfiguration _configuration;
    private readonly BlobServiceClient _blobServiceClient;
    private readonly string _containerName;

    /// <summary>
    /// Initializes a new instance of the PhotoFileModel class
    /// </summary>
    /// <param name="photoService">Service for photo operations</param>
    /// <param name="configuration">Configuration instance</param>
    /// <param name="logger">Logger instance</param>
    public PhotoFileModel(IPhotoService photoService, IConfiguration configuration, ILogger<PhotoFileModel> logger)
    {
        _photoService = photoService;
        _configuration = configuration;
        _logger = logger;

        // Initialize Azure Blob Storage client
        var endpoint = _configuration["AzureStorageBlob:Endpoint"];
        if (!string.IsNullOrEmpty(endpoint))
        {
            _blobServiceClient = new BlobServiceClient(
                new Uri(endpoint),
                new DefaultAzureCredential());
        }

        _containerName = _configuration["AzureStorageBlob:ContainerName"] ?? "photos";
    }

    /// <summary>
    /// Serves a photo file by ID from Azure Blob Storage
    /// </summary>
    /// <param name="id">The ID of the photo to serve</param>
    /// <returns>File result with the photo, or NotFound if photo doesn't exist</returns>
    public async Task<IActionResult> OnGetAsync(int? id)
    {
        if (id == null)
        {
            _logger.LogWarning("Photo file request with null ID");
            return NotFound();
        }

        if (_blobServiceClient == null)
        {
            _logger.LogError("Azure Blob Storage client not configured");
            return StatusCode(500);
        }

        try
        {
            var photo = await _photoService.GetPhotoByIdAsync(id.Value);

            if (photo == null)
            {
                _logger.LogWarning("Photo with ID {PhotoId} not found", id);
                return NotFound();
            }

            // Download blob content from Azure Storage
            try
            {
                var containerClient = _blobServiceClient.GetBlobContainerClient(_containerName);
                var blobClient = containerClient.GetBlobClient(photo.StoredFileName);

                // Check if blob exists
                var existsResponse = await blobClient.ExistsAsync();
                if (!existsResponse.Value)
                {
                    _logger.LogError("Blob {BlobName} not found for photo ID {PhotoId}", photo.StoredFileName, id);
                    return NotFound();
                }

                // Download blob content
                var downloadResponse = await blobClient.DownloadContentAsync();
                var fileBytes = downloadResponse.Value.Content.ToArray();

                _logger.LogDebug("Serving photo ID {PhotoId} ({FileName}, {FileSize} bytes) from blob {BlobName}",
                    id, photo.OriginalFileName, fileBytes.Length, photo.StoredFileName);

                // Return the file with appropriate content type and enable caching
                Response.Headers.CacheControl = "public,max-age=31536000"; // Cache for 1 year
                Response.Headers.ETag = $"\"{photo.Id}-{photo.UploadedAt.Ticks}\"";

                return File(fileBytes, photo.MimeType);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error downloading blob {BlobName} for photo ID {PhotoId}", photo.StoredFileName, id);
                return StatusCode(500);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error serving photo with ID {PhotoId}", id);
            return StatusCode(500);
        }
    }
}
