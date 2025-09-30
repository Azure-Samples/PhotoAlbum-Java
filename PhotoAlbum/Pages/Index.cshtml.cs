using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using PhotoAlbum.Models;
using PhotoAlbum.Services;

namespace PhotoAlbum.Pages;

/// <summary>
/// Page model for the main photo gallery page with upload functionality
/// </summary>
public class IndexModel : PageModel
{
    private readonly IPhotoService _photoService;
    private readonly ILogger<IndexModel> _logger;

    /// <summary>
    /// Initializes a new instance of the IndexModel
    /// </summary>
    /// <param name="photoService">Service for photo operations</param>
    /// <param name="logger">Logger for diagnostics</param>
    public IndexModel(IPhotoService photoService, ILogger<IndexModel> logger)
    {
        _photoService = photoService;
        _logger = logger;
    }

    /// <summary>
    /// List of photos to display in the gallery
    /// </summary>
    public List<Photo> Photos { get; set; } = new();

    /// <summary>
    /// Handler for GET requests - loads all photos for display
    /// </summary>
    public async Task OnGetAsync()
    {
        try
        {
            Photos = await _photoService.GetAllPhotosAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading photos");
            Photos = new List<Photo>();
        }
    }

    /// <summary>
    /// Handler for POST requests - uploads one or more photo files
    /// </summary>
    /// <param name="files">Collection of files to upload</param>
    /// <returns>JSON result with upload status and details</returns>
    public async Task<IActionResult> OnPostUploadAsync(List<IFormFile> files)
    {
        if (files == null || files.Count == 0)
        {
            return BadRequest(new { success = false, error = "No files provided" });
        }

        var uploadedPhotos = new List<object>();
        var failedUploads = new List<object>();

        foreach (var file in files)
        {
            var result = await _photoService.UploadPhotoAsync(file);

            if (result.Success)
            {
                var photo = await _photoService.GetAllPhotosAsync();
                var uploadedPhoto = photo.FirstOrDefault(p => p.Id == result.PhotoId);

                if (uploadedPhoto != null)
                {
                    uploadedPhotos.Add(new
                    {
                        id = uploadedPhoto.Id,
                        originalFileName = uploadedPhoto.OriginalFileName,
                        filePath = uploadedPhoto.FilePath,
                        uploadedAt = uploadedPhoto.UploadedAt,
                        fileSize = uploadedPhoto.FileSize,
                        width = uploadedPhoto.Width,
                        height = uploadedPhoto.Height
                    });
                }
            }
            else
            {
                failedUploads.Add(new
                {
                    fileName = result.FileName,
                    error = result.ErrorMessage
                });
            }
        }

        return new JsonResult(new
        {
            success = uploadedPhotos.Count > 0,
            uploadedPhotos,
            failedUploads
        });
    }
}
