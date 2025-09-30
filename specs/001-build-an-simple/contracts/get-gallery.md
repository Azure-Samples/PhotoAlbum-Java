# API Contract: Get Photo Gallery

**Endpoint**: `GET /`  
**Handler**: `Pages/Index.cshtml.cs` → `OnGetAsync()`  
**Purpose**: Retrieve all photos for display in gallery

---

## Request

**Method**: GET  
**Path**: `/`  
**Query Parameters**: None (pagination not implemented in v1)  
**Headers**: 
- `Accept: text/html`

**Authentication**: None (demo application)

---

## Response

**Success (200 OK)**:

**Content-Type**: `text/html`

**Razor Model Binding**:
```csharp
public class IndexModel : PageModel
{
    public List<Photo> Photos { get; set; }
    
    public async Task OnGetAsync()
    {
        Photos = await _photoService.GetAllPhotosAsync();
    }
}
```

**View Data**:
- `Photos`: List of Photo entities ordered by `UploadedAt DESC`

**HTML Structure** (simplified):
```html
<div class="container">
    <div class="row">
        @foreach (var photo in Model.Photos)
        {
            <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                <div class="card mb-4">
                    <img src="@photo.FilePath" class="card-img-top" alt="@photo.OriginalFileName">
                    <div class="card-body">
                        <p class="card-text">@photo.OriginalFileName</p>
                        <small>@photo.UploadedAt.ToLocalTime()</small>
                    </div>
                </div>
            </div>
        }
    </div>
</div>
```

**Empty State** (no photos):
```html
<div class="alert alert-info">
    No photos yet. Upload your first photo to get started!
</div>
```

---

## Error Responses

**500 Internal Server Error**:
- Database connection failure
- File system read error

**Error Page**: ASP.NET Core error handler redirects to `/Error`

---

## Business Rules

1. Photos ordered by upload date (newest first)
2. All photos displayed (no filtering)
3. Page cached for 60 seconds (output cache)
4. Images lazy-loaded by browser

---

## Performance

- **Expected Load Time**: < 1 second for up to 100 photos
- **Database Query**: Single query with `ToListAsync()`
- **Rendering**: Server-side (Razor Pages)

---

## Example Flow

```
1. User navigates to http://localhost:5000/
2. Browser sends GET / request
3. Server executes IndexModel.OnGetAsync()
4. PhotoService.GetAllPhotosAsync() queries database
5. Server renders Index.cshtml with photo data
6. Browser receives HTML
7. Browser loads images from /uploads/ paths
8. User sees photo gallery
```

---

## Contract Tests

**Test File**: `PhotoAlbum.Tests/Integration/Pages/IndexPageTests.cs`

**Scenarios**:
1. `GetIndex_WithNoPhotos_ReturnsEmptyGallery()`
2. `GetIndex_WithPhotos_ReturnsGalleryWithPhotos()`
3. `GetIndex_WithManyPhotos_ReturnsPhotosInChronologicalOrder()`
4. `GetIndex_ImagePaths_AreValidAndAccessible()`

---

**Status**: ✅ Contract defined, ready for test generation
