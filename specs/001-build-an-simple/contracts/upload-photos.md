# API Contract: Upload Photos

**Endpoint**: `POST /Upload`
**Handler**: `Pages/Index.cshtml.cs` → `OnPostUploadAsync()`
**Purpose**: Upload one or more photos via drag-and-drop or file picker

---

## Request

**Method**: POST
**Path**: `/Upload`
**Content-Type**: `multipart/form-data`

**Form Fields**:
- `files`: Array of uploaded files (1-10 files)

**Headers**:
- `Content-Type: multipart/form-data; boundary=...`
- `X-Requested-With: XMLHttpRequest` (AJAX request)

**File Validation** (client-side pre-check):
```javascript
// Each file must pass:
- type: 'image/jpeg', 'image/png', 'image/gif', or 'image/webp'
- size: <= 10MB (10,485,760 bytes)
```

**Authentication**: None (demo application)
**CSRF Protection**: `[ValidateAntiForgeryToken]` required

---

## Response

**Success (200 OK)**:

**Content-Type**: `application/json`

**Body**:
```json
{
  "success": true,
  "uploadedPhotos": [
    {
      "id": 1,
      "originalFileName": "vacation.jpg",
      "filePath": "/uploads/abc123-def456-ghi789.jpg",
      "uploadedAt": "2025-09-30T10:30:00Z",
      "fileSize": 2048576,
      "width": 1920,
      "height": 1080
    },
    {
      "id": 2,
      "originalFileName": "sunset.png",
      "filePath": "/uploads/xyz987-uvw654-rst321.png",
      "uploadedAt": "2025-09-30T10:30:01Z",
      "fileSize": 1536000,
      "width": 1600,
      "height": 900
    }
  ],
  "failedUploads": []
}
```

**Partial Success (200 OK)** - Some files failed:

```json
{
  "success": true,
  "uploadedPhotos": [
    {
      "id": 1,
      "originalFileName": "vacation.jpg",
      "filePath": "/uploads/abc123-def456-ghi789.jpg",
      "uploadedAt": "2025-09-30T10:30:00Z",
      "fileSize": 2048576,
      "width": 1920,
      "height": 1080
    }
  ],
  "failedUploads": [
    {
      "fileName": "document.pdf",
      "error": "File type not supported. Please upload JPEG, PNG, GIF, or WebP images."
    },
    {
      "fileName": "huge-image.jpg",
      "error": "File size exceeds 10MB limit."
    }
  ]
}
```

**Complete Failure (400 Bad Request)**:

```json
{
  "success": false,
  "uploadedPhotos": [],
  "failedUploads": [
    {
      "fileName": "document.pdf",
      "error": "File type not supported. Please upload JPEG, PNG, GIF, or WebP images."
    }
  ]
}
```

---

## Error Responses

**400 Bad Request**:
- No files provided
- All files failed validation
- File size exceeds limit
- Invalid file type

**413 Payload Too Large**:
- Total request size exceeds server limit (configured in `FormOptions`)

**500 Internal Server Error**:
- File system write error
- Database save error
- Image processing error

**Error Response Body**:
```json
{
  "success": false,
  "error": "Unable to save files. Please try again.",
  "details": [] // Array of specific errors per file
}
```

---

## Business Rules

1. **File Type Validation**:
   - Server validates MIME type from `IFormFile.ContentType`
   - Server validates file extension (`.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`)
   - Server attempts to load image with ImageSharp (detects fake extensions)

2. **File Size Validation**:
   - Maximum 10MB per file
   - Maximum 10 files per request
   - Total request size limited by ASP.NET Core configuration

3. **Atomic Operations**:
   - Each file processed independently
   - File written to disk before database record created
   - If database save fails, file is deleted (rollback)
   - Partial success allowed (some files succeed, others fail)

4. **Filename Generation**:
   - GUID-based: `Guid.NewGuid().ToString() + extension`
   - Example: `abc123-def456-ghi789.jpg`
   - No collisions possible

5. **Metadata Extraction**:
   - Image dimensions extracted using ImageSharp
   - MIME type from `IFormFile.ContentType`
   - File size from `IFormFile.Length`
   - Upload timestamp set to `DateTime.UtcNow`

---

## Page Handler Signature

```csharp
public async Task<IActionResult> OnPostUploadAsync(List<IFormFile> files)
{
    if (files == null || files.Count == 0)
    {
        return BadRequest(new { success = false, error = "No files provided" });
    }

    var uploadedPhotos = new List<PhotoDto>();
    var failedUploads = new List<UploadError>();

    foreach (var file in files)
    {
        var result = await _photoService.UploadPhotoAsync(file);
        if (result.Success)
        {
            uploadedPhotos.Add(result.Photo);
        }
        else
        {
            failedUploads.Add(new UploadError
            {
                FileName = file.FileName,
                Error = result.ErrorMessage
            });
        }
    }

    return new JsonResult(new
    {
        success = uploadedPhotos.Any(),
        uploadedPhotos,
        failedUploads
    });
}
```

---

## Client-Side Implementation (JavaScript)

```javascript
// Drag-and-drop event handling
const dropZone = document.getElementById('drop-zone');

dropZone.addEventListener('drop', async (e) => {
    e.preventDefault();
    const files = Array.from(e.dataTransfer.files);

    // Client-side validation
    const validFiles = files.filter(file => {
        return file.type.match(/^image\/(jpeg|png|gif|webp)$/)
            && file.size <= 10485760;
    });

    if (validFiles.length === 0) {
        showError('No valid image files found');
        return;
    }

    // Create FormData
    const formData = new FormData();
    validFiles.forEach(file => formData.append('files', file));

    // Add anti-forgery token
    const token = document.querySelector('input[name="__RequestVerificationToken"]').value;

    // Upload
    const response = await fetch('/Upload', {
        method: 'POST',
        body: formData,
        headers: {
            'X-Requested-With': 'XMLHttpRequest',
            'RequestVerificationToken': token
        }
    });

    const result = await response.json();

    if (result.success) {
        displayPhotos(result.uploadedPhotos);
    }

    if (result.failedUploads.length > 0) {
        showWarnings(result.failedUploads);
    }
});
```

---

## Performance

- **Expected Upload Time**: < 3 seconds for 5 photos @ 2MB each
- **File Processing**: Sequential (prevent resource contention)
- **Progress Feedback**: Client shows loading indicator
- **Async I/O**: Prevents thread blocking

---

## Example Flow

```
1. User drags 3 image files onto drop zone
2. JavaScript validates file types and sizes
3. JavaScript creates FormData with files
4. JavaScript POSTs to /Upload with anti-forgery token
5. Server validates each file (type, size, content)
6. Server saves valid files to wwwroot/uploads/
7. Server extracts image dimensions
8. Server creates Photo entities in database
9. Server commits transaction
10. Server returns JSON with success/failures
11. JavaScript displays new photos in gallery
12. JavaScript shows error messages for failed uploads
```

---

## Contract Tests

**Test File**: `PhotoAlbum.Tests/Integration/Pages/UploadPageTests.cs`

**Scenarios**:
1. `PostUpload_WithValidImage_ReturnsSuccessAndCreatesPhoto()`
2. `PostUpload_WithMultipleImages_UploadsAllSuccessfully()`
3. `PostUpload_WithInvalidFileType_ReturnsBadRequest()`
4. `PostUpload_WithOversizedFile_ReturnsBadRequest()`
5. `PostUpload_WithMixedValidInvalid_ReturnsPartialSuccess()`
6. `PostUpload_WithNoFiles_ReturnsBadRequest()`
7. `PostUpload_WithCorruptedImage_ReturnsError()`
8. `PostUpload_CreatesFileInUploadsDirectory()`
9. `PostUpload_RollbacksOnDatabaseError()`

---

**Status**: ✅ Contract defined, ready for test generation
