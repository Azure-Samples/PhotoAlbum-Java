# Data Model: Photo Storage Application

**Feature**: Photo Storage Application  
**Date**: 2025-09-30  
**Source**: Feature spec entities + research decisions

---

## Entities

### Photo

**Purpose**: Represents an uploaded photo with metadata for display and management

**Fields**:

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| Id | int | Primary Key, Identity | Unique identifier |
| OriginalFileName | string | Required, MaxLength(255) | Original filename as uploaded by user |
| StoredFileName | string | Required, MaxLength(255) | GUID-based filename with extension (e.g., `abc123.jpg`) |
| FilePath | string | Required, MaxLength(500) | Relative path from wwwroot (e.g., `/uploads/abc123.jpg`) |
| FileSize | long | Required, > 0 | File size in bytes |
| MimeType | string | Required, MaxLength(50) | MIME type (e.g., `image/jpeg`, `image/png`) |
| UploadedAt | DateTime | Required | UTC timestamp of upload |
| Width | int? | Optional | Image width in pixels (populated after upload) |
| Height | int? | Optional | Image height in pixels (populated after upload) |

**Relationships**:
- None (flat structure as per requirements)

**Validation Rules**:
- `OriginalFileName`: Must not contain path traversal characters (`..`, `/`, `\`)
- `FileSize`: Must be ≤ 10MB (10,485,760 bytes)
- `MimeType`: Must be one of: `image/jpeg`, `image/png`, `image/gif`, `image/webp`
- `FilePath`: Must start with `/uploads/` and end with valid image extension
- `UploadedAt`: Automatically set to `DateTime.UtcNow` on creation

**Indexes**:
- Clustered index on `Id` (default)
- Non-clustered index on `UploadedAt DESC` for chronological listing

**Business Rules**:
- Soft delete not required (physical delete when user removes photo)
- File system and database must remain synchronized (atomic operations)
- Thumbnails generated on-demand from stored file (no separate thumbnail entity)

---

## Value Objects

### UploadResult

**Purpose**: Transfer object for upload operation results

**Fields**:

| Field | Type | Description |
|-------|------|-------------|
| Success | bool | Indicates if upload succeeded |
| PhotoId | int? | ID of created Photo entity (null on failure) |
| FileName | string | Original filename |
| ErrorMessage | string? | User-friendly error message (null on success) |

**Usage**: Returned from `PhotoService.UploadPhotoAsync()` to page handlers

---

## Database Schema (EF Core Code-First)

```sql
CREATE TABLE Photos (
    Id INT PRIMARY KEY IDENTITY(1,1),
    OriginalFileName NVARCHAR(255) NOT NULL,
    StoredFileName NVARCHAR(255) NOT NULL,
    FilePath NVARCHAR(500) NOT NULL,
    FileSize BIGINT NOT NULL,
    MimeType NVARCHAR(50) NOT NULL,
    UploadedAt DATETIME2 NOT NULL,
    Width INT NULL,
    Height INT NULL
);

CREATE INDEX IX_Photos_UploadedAt ON Photos(UploadedAt DESC);
```

**Migration Notes**:
- Initial migration creates `Photos` table
- Future migrations should preserve existing photo records
- No seed data required (empty on first run)

---

## Entity Lifecycle

### Photo Creation (Upload Flow)

```
1. User drops file(s) on upload zone
2. Client sends file via AJAX POST to /Upload
3. Server validates file (type, size, content)
4. Server generates GUID filename, saves to wwwroot/uploads/
5. Server extracts image dimensions using ImageSharp
6. Server creates Photo entity with metadata
7. EF Core saves to database
8. Transaction commits (file + database atomic)
9. Server returns UploadResult with success/error
10. Client displays new photo or error message
```

**Error Rollback**:
- If database save fails → delete physical file
- If file save fails → don't create database record
- Use try-catch-finally pattern to ensure cleanup

### Photo Display (Gallery Flow)

```
1. User navigates to Index page
2. Server queries all Photos ordered by UploadedAt DESC
3. Server passes Photo list to Razor view
4. View renders Bootstrap grid with photo cards
5. Each card shows:
   - Thumbnail (img src="{FilePath}")
   - Original filename
   - Upload date
   - File size (formatted)
6. Images served directly from wwwroot/uploads/
```

### Photo Deletion (Future Feature)

```
1. User clicks delete button on photo card
2. Client sends DELETE request to /Photo/{id}
3. Server loads Photo entity by ID
4. Server deletes physical file from wwwroot/uploads/
5. Server deletes Photo entity from database
6. Transaction commits
7. Server returns success/error
8. Client removes photo from gallery
```

---

## State Transitions

Photos have no state machine (no draft, pending, published states). They are either:
- **Uploading** (transient, client-side only)
- **Stored** (persisted in DB and filesystem)
- **Deleted** (removed from both DB and filesystem)

---

## Performance Considerations

1. **Gallery Loading**:
   - Fetch all photos with single query: `context.Photos.OrderByDescending(p => p.UploadedAt).ToListAsync()`
   - For large collections (>100 photos), implement pagination (future enhancement)
   - Browser caches images after first load

2. **Image Serving**:
   - Static file middleware serves files from wwwroot/
   - Set cache headers for 1 day: `Cache-Control: public, max-age=86400`
   - Consider CDN for production (out of scope for demo)

3. **Upload Performance**:
   - Async file I/O prevents thread blocking
   - Process files sequentially to avoid resource contention
   - Validate file type before reading entire file

---

## Validation Summary

| Validation | Layer | Implementation |
|------------|-------|----------------|
| File type (MIME) | Client + Server | JavaScript `File.type` check + server `IFormFile.ContentType` |
| File size | Client + Server | JavaScript `File.size` check + server `IFormFile.Length` |
| File extension | Server | Path.GetExtension() whitelist |
| Image header | Server | ImageSharp load attempt (throws if invalid) |
| Filename safety | Server | Regex to block path traversal |
| Duplicate prevention | None | GUID filenames prevent collisions |

---

**Status**: ✅ Data model complete, ready for contract generation
