namespace PhotoAlbum.Models;

/// <summary>
/// Transfer object for upload operation results
/// </summary>
public class UploadResult
{
    /// <summary>
    /// Indicates if upload succeeded
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// ID of created Photo entity (null on failure)
    /// </summary>
    public int? PhotoId { get; set; }

    /// <summary>
    /// Original filename
    /// </summary>
    public string FileName { get; set; } = string.Empty;

    /// <summary>
    /// User-friendly error message (null on success)
    /// </summary>
    public string? ErrorMessage { get; set; }
}
