# Quickstart: Photo Storage Application

**Purpose**: Verify the photo storage application works end-to-end  
**Time**: ~5 minutes  
**Prerequisites**: .NET 8 SDK, SQL Server LocalDB (included with Visual Studio)

---

## Setup

### 1. Restore Dependencies

```bash
cd PhotoAlbum
dotnet restore
```

**Expected Output**:
```
Restore completed in X ms for PhotoAlbum.csproj
```

### 2. Run Database Migrations

```bash
dotnet ef database update
```

**Expected Output**:
```
Build started...
Build succeeded.
Done.
```

**Verification**: Database `PhotoAlbumDb` created in LocalDB with `Photos` table

### 3. Create Upload Directory

```bash
# PowerShell
New-Item -ItemType Directory -Force -Path PhotoAlbum/wwwroot/uploads
```

**Expected Output**: Directory created (or already exists)

---

## Start Application

```bash
cd PhotoAlbum
dotnet run
```

**Expected Output**:
```
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://localhost:5000
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
```

**Application URL**: http://localhost:5000

---

## Acceptance Test Scenarios

### Scenario 1: View Empty Gallery

**Steps**:
1. Open browser to http://localhost:5000
2. Observe the page loads successfully

**Expected Results**:
- ✅ Page displays "No photos yet" message or empty gallery
- ✅ Upload zone is visible with drag-and-drop area
- ✅ Page loads in < 2 seconds
- ✅ No console errors in browser DevTools

**Validation**:
```sql
-- Database should be empty
SELECT COUNT(*) FROM Photos; 
-- Expected: 0
```

---

### Scenario 2: Upload Single Photo (Drag-and-Drop)

**Prerequisites**: Prepare a JPEG image file (e.g., `test-photo.jpg`, < 10MB)

**Steps**:
1. Navigate to http://localhost:5000
2. Drag `test-photo.jpg` from desktop/file explorer
3. Drop onto the upload zone
4. Wait for upload to complete

**Expected Results**:
- ✅ Upload zone highlights when file is dragged over it
- ✅ Loading indicator appears during upload
- ✅ Success message displays after upload
- ✅ Photo appears in gallery immediately
- ✅ Photo shows original filename
- ✅ Photo shows upload timestamp
- ✅ Upload completes in < 3 seconds
- ✅ No JavaScript errors in console

**Validation**:
```sql
-- Database should have 1 photo
SELECT OriginalFileName, StoredFileName, FileSize, MimeType, UploadedAt 
FROM Photos;
-- Expected: 1 row with correct metadata
```

```bash
# File should exist in uploads directory
ls PhotoAlbum/wwwroot/uploads/
# Expected: One .jpg file with GUID name
```

---

### Scenario 3: Upload Multiple Photos

**Prerequisites**: Prepare 3-5 image files (JPEG, PNG, GIF mix)

**Steps**:
1. Navigate to http://localhost:5000
2. Select all test images in file explorer
3. Drag and drop all files onto upload zone simultaneously
4. Wait for uploads to complete

**Expected Results**:
- ✅ All valid images upload successfully
- ✅ Each photo appears in gallery with correct metadata
- ✅ Photos appear in chronological order (newest first)
- ✅ Total upload time < 10 seconds for 5 photos
- ✅ No duplicate filenames in uploads directory

**Validation**:
```sql
-- Database should have all photos
SELECT COUNT(*) FROM Photos;
-- Expected: 6 (1 from previous test + 5 new)

-- Check order
SELECT OriginalFileName, UploadedAt 
FROM Photos 
ORDER BY UploadedAt DESC;
-- Expected: Newest uploads at top
```

---

### Scenario 4: Upload Invalid File Type

**Prerequisites**: Prepare a non-image file (e.g., `document.pdf` or `text.txt`)

**Steps**:
1. Navigate to http://localhost:5000
2. Drag `document.pdf` onto upload zone
3. Observe the error handling

**Expected Results**:
- ✅ Client-side validation rejects file before upload (ideal)
- OR ✅ Server returns error message: "File type not supported"
- ✅ Error message is user-friendly and clear
- ✅ No file created in uploads directory
- ✅ No database record created
- ✅ Gallery remains unchanged

**Validation**:
```sql
-- Photo count should not increase
SELECT COUNT(*) FROM Photos;
-- Expected: Still 6 from previous tests
```

---

### Scenario 5: Upload Oversized File

**Prerequisites**: Create or obtain an image file > 10MB

**Steps**:
1. Navigate to http://localhost:5000
2. Drag oversized image onto upload zone
3. Observe the error handling

**Expected Results**:
- ✅ Client-side validation shows error before upload (ideal)
- OR ✅ Server returns error: "File size exceeds 10MB limit"
- ✅ Error message includes file size information
- ✅ No partial file created in uploads directory
- ✅ No database record created

---

### Scenario 6: View Gallery After Uploads

**Steps**:
1. Navigate to http://localhost:5000
2. Observe the gallery display

**Expected Results**:
- ✅ All uploaded photos visible in gallery
- ✅ Photos displayed in responsive grid (4 columns on desktop, fewer on mobile)
- ✅ Each photo card shows:
  - Thumbnail image
  - Original filename
  - Upload date/time
  - File size (formatted, e.g., "2.5 MB")
- ✅ Page loads in < 2 seconds
- ✅ Images load progressively (lazy loading)
- ✅ No broken image links

---

### Scenario 7: Browser Refresh (Persistence)

**Steps**:
1. With photos in gallery, refresh browser (F5 or Cmd+R)
2. Observe page reloads

**Expected Results**:
- ✅ All photos remain visible after refresh
- ✅ Photo order preserved (chronological)
- ✅ No data loss
- ✅ Page loads in < 2 seconds

**Validation**:
```sql
-- Verify data persisted
SELECT COUNT(*) FROM Photos;
-- Expected: Same count as before refresh
```

---

### Scenario 8: Responsive Design

**Steps**:
1. Open gallery with uploaded photos
2. Resize browser window to mobile width (e.g., 375px)
3. Resize to tablet width (e.g., 768px)
4. Resize to desktop width (e.g., 1920px)

**Expected Results**:
- ✅ Mobile (< 576px): 1 photo per row
- ✅ Tablet (576px - 992px): 2-3 photos per row
- ✅ Desktop (> 992px): 4 photos per row
- ✅ Upload zone remains accessible on all sizes
- ✅ No horizontal scrolling
- ✅ No overlapping elements

---

## Performance Validation

Run the application with performance monitoring:

```bash
dotnet run --configuration Release
```

**Metrics to Verify**:

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Page load time | < 2s | Browser DevTools Network tab |
| Upload response time (1 photo) | < 3s | Network tab, POST /Upload timing |
| Upload response time (5 photos) | < 10s | Network tab, POST /Upload timing |
| Interaction response | < 200ms | Click → visual feedback delay |
| Memory usage | < 100MB | Task Manager / Activity Monitor |
| Database query time | < 50ms | EF Core logging (debug mode) |

---

## Automated Test Execution

Run the test suite to verify functionality:

```bash
cd PhotoAlbum.Tests
dotnet test --verbosity normal
```

**Expected Output**:
```
Test run for PhotoAlbum.Tests.dll
Total tests: X
Passed: X
Failed: 0
Skipped: 0
Time: Y seconds
```

**Key Tests**:
- ✅ `GetIndex_WithNoPhotos_ReturnsEmptyGallery`
- ✅ `GetIndex_WithPhotos_ReturnsGalleryWithPhotos`
- ✅ `PostUpload_WithValidImage_ReturnsSuccessAndCreatesPhoto`
- ✅ `PostUpload_WithMultipleImages_UploadsAllSuccessfully`
- ✅ `PostUpload_WithInvalidFileType_ReturnsBadRequest`
- ✅ `PostUpload_WithOversizedFile_ReturnsBadRequest`
- ✅ `PhotoService_UploadPhoto_CreatesFileAndDatabaseRecord`

---

## Cleanup

### Reset Database

```bash
dotnet ef database drop --force
dotnet ef database update
```

### Clear Uploads Directory

```bash
# PowerShell
Remove-Item PhotoAlbum/wwwroot/uploads/* -Force
```

---

## Troubleshooting

### Issue: "No connection string found"

**Solution**: Verify `appsettings.json` contains:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=PhotoAlbumDb;Trusted_Connection=true;MultipleActiveResultSets=true"
  }
}
```

### Issue: "Database does not exist"

**Solution**: Run migrations:
```bash
dotnet ef database update
```

### Issue: "Access denied to uploads directory"

**Solution**: Ensure directory has write permissions:
```bash
# PowerShell
icacls PhotoAlbum/wwwroot/uploads /grant Everyone:F
```

### Issue: "Port 5000 already in use"

**Solution**: Kill the process or change port in `Program.cs`:
```csharp
builder.WebHost.UseUrls("http://localhost:5001");
```

---

## Success Criteria Summary

✅ **Functional Requirements**:
- FR-001: Drag-and-drop upload working
- FR-002: JPEG, PNG, GIF, WebP supported
- FR-003: Flat gallery view displaying all photos
- FR-004: Visual feedback during upload
- FR-005: Photos persist after refresh
- FR-006: Responsive grid layout
- FR-007: Multiple file upload working
- FR-008: File type validation working
- FR-009: Clear error messages shown
- FR-010: Progress indication during upload

✅ **Non-Functional Requirements**:
- Page load < 2 seconds
- Upload response < 3 seconds per photo
- Responsive design (mobile/tablet/desktop)
- No console errors
- Database persistence working
- File system storage working

✅ **Code Quality**:
- All tests passing
- No build warnings
- Clean separation of concerns
- Error handling implemented
- Logging configured

---

**Status**: ✅ Quickstart complete, ready for implementation validation
