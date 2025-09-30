using PhotoAlbum.Models;

namespace PhotoAlbum.Services;

/// <summary>
/// Service interface for photo operations
/// </summary>
public interface IPhotoService
{
    /// <summary>
    /// Get all photos ordered by upload date (newest first)
    /// </summary>
    /// <returns>List of photos</returns>
    Task<List<Photo>> GetAllPhotosAsync();

    /// <summary>
    /// Upload a photo file
    /// </summary>
    /// <param name="file">The uploaded file</param>
    /// <returns>Upload result with success status and photo details or error message</returns>
    Task<UploadResult> UploadPhotoAsync(IFormFile file);

    /// <summary>
    /// Delete a photo by ID
    /// </summary>
    /// <param name="id">Photo ID</param>
    /// <returns>True if deleted successfully, false if not found</returns>
    Task<bool> DeletePhotoAsync(int id);
}
