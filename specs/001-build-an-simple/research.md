# Research: Photo Storage Application

**Feature**: Photo Storage Application
**Date**: 2025-09-30
**Status**: Complete

---

## Research Tasks

### 1. File Format Support

**Decision**: Support JPEG, PNG, GIF, and WebP formats

**Rationale**:
- JPEG and PNG are the most common photo formats across all devices and cameras
- GIF support allows for animated images, which users may want to store
- WebP is increasingly common from modern devices and offers better compression
- HEIC excluded for simplicity (requires additional codec dependencies on Windows)

**Alternatives Considered**:
- All formats including HEIC, TIFF, BMP: Rejected due to added complexity and codec requirements
- JPEG/PNG only: Too restrictive for modern use cases
- All common web formats (JPEG, PNG, GIF, WebP, SVG): SVG excluded as it's not typically a "photo" format

**Implementation Notes**:
- Use MIME type validation: `image/jpeg`, `image/png`, `image/gif`, `image/webp`
- File extension validation: `.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`
- Server-side validation using `System.Drawing` or `SixLabors.ImageSharp` to verify file headers

---

### 2. ASP.NET Core Razor Pages Best Practices

**Decision**: Use Page Models with dependency injection, separate concerns, and async/await patterns

**Rationale**:
- Page Models provide clear separation between UI and logic
- Dependency injection enables testability and follows .NET conventions
- Async file operations prevent blocking during uploads
- Built-in model binding and validation reduce boilerplate

**Alternatives Considered**:
- MVC with Controllers: More complex than needed for this simple app
- Razor Pages with code-behind only: Less testable, harder to maintain
- Blazor: Overkill for simple drag-and-drop functionality

**Implementation Notes**:
- Use `IFormFile` for file uploads
- Implement `IPhotoService` interface for business logic
- Use `[ValidateAntiForgeryToken]` for POST handlers
- Leverage `TempData` for success/error messages across redirects

---

### 3. File Storage Strategy

**Decision**: Store files in `wwwroot/uploads/` with GUID-based filenames, retain original extensions

**Rationale**:
- `wwwroot/` allows direct static file serving without additional middleware
- GUID filenames prevent naming collisions and path traversal attacks
- Retaining extensions enables browser content-type detection
- Metadata (original filename, upload date) stored in database

**Alternatives Considered**:
- Original filenames: Security risk (path traversal, overwriting)
- Outside wwwroot: Requires custom file serving middleware
- Cloud storage (Azure Blob): Too complex for demo app
- Database storage: Poor performance for large files

**Implementation Notes**:
- Generate filename: `Guid.NewGuid().ToString() + extension`
- Create `wwwroot/uploads/` directory on startup if not exists
- Store relative path in database: `/uploads/{guid}.jpg`
- Configure `StaticFileOptions` for appropriate caching headers

---

### 4. Entity Framework Core with LocalDB

**Decision**: Use EF Core Code-First with LocalDB connection string, enable migrations

**Rationale**:
- Code-First allows version control of schema through migrations
- LocalDB is included with Visual Studio, no separate install needed
- EF Core provides LINQ queries and change tracking
- Simple connection string configuration

**Alternatives Considered**:
- Database-First: Less flexible for incremental development
- SQLite: Simpler but less representative of production scenarios
- SQL Server Express: Requires separate installation
- In-memory/JSON file: Not suitable for relational data

**Implementation Notes**:
- Connection string: `Server=(localdb)\\mssqllocaldb;Database=PhotoAlbumDb;Trusted_Connection=true;MultipleActiveResultSets=true`
- Enable automatic migrations in development: `context.Database.Migrate()` in `Program.cs`
- Use `DbContext` lifecycle: Scoped per request

---

### 5. Drag-and-Drop Implementation

**Decision**: Use HTML5 Drag and Drop API with vanilla JavaScript, progressive enhancement

**Rationale**:
- Native browser API, no library dependencies
- Widely supported across modern browsers
- Graceful fallback to file input for unsupported browsers
- Allows multiple file selection and drag-from-desktop

**Alternatives Considered**:
- Third-party library (Dropzone.js, FilePond): Unnecessary complexity
- Form-only upload: Less user-friendly, no drag-and-drop
- Fetch API upload: Still requires drag-and-drop event handling

**Implementation Notes**:
- Listen for `dragover`, `dragleave`, `drop` events on upload zone
- Prevent default behavior to enable drop
- Use `FormData` API to submit files via AJAX
- Show progress feedback during upload
- Display thumbnails on successful upload

**Code Pattern**:
```javascript
dropZone.addEventListener('drop', (e) => {
    e.preventDefault();
    const files = e.dataTransfer.files;
    const formData = new FormData();
    for (let file of files) {
        formData.append('files', file);
    }
    fetch('/Upload', { method: 'POST', body: formData })
        .then(response => response.json())
        .then(data => displayPhotos(data));
});
```

---

### 6. Bootstrap Layout and Responsive Design

**Decision**: Use Bootstrap 5.x grid system with card components for photo gallery

**Rationale**:
- Bootstrap provides responsive grid out of the box
- Card components work well for image thumbnails with metadata
- No custom CSS framework needed (aligns with Simplicity principle)
- Consistent with modern web design patterns

**Alternatives Considered**:
- Custom CSS Grid: More work, no accessibility benefits
- Bootstrap 4: Older version, less modern
- Tailwind CSS: Requires build step, more complex setup
- Material Design: Doesn't fit photo gallery aesthetic

**Implementation Notes**:
- Use responsive columns: `col-12 col-sm-6 col-md-4 col-lg-3` for gallery
- Card component with `card-img-top` for thumbnails
- Navbar for header/branding
- Form components for upload area
- Utility classes for spacing and alignment

---

### 7. File Size and Upload Limits

**Decision**: Limit individual files to 10MB, allow up to 10 files per batch upload

**Rationale**:
- 10MB accommodates high-quality phone photos (typically 2-8MB)
- Prevents abuse and server resource exhaustion
- 10 files per batch balances usability and performance
- Configurable via `appsettings.json`

**Alternatives Considered**:
- Unlimited: Security and performance risk
- 5MB: Too restrictive for modern cameras
- 50MB per file: Encourages storing raw/uncompressed images

**Implementation Notes**:
- Configure in `Program.cs`: `builder.Services.Configure<FormOptions>(...)`
- Client-side validation in JavaScript before upload
- Server-side validation in page handler
- Return clear error messages for oversized files

---

### 8. Error Handling Strategy

**Decision**: Use try-catch with logging, return user-friendly error messages, maintain atomic operations

**Rationale**:
- File I/O and database operations can fail unpredictably
- Users need clear feedback without technical details
- Logging enables debugging production issues
- Atomic operations prevent partial state (orphaned files or database records)

**Alternatives Considered**:
- Generic error pages: Poor user experience
- Exception propagation: Exposes internal details
- Silent failures: Users don't know what went wrong

**Implementation Notes**:
- Use `ILogger<T>` for structured logging
- Wrap file operations in try-catch, delete file if DB save fails
- Return `JsonResult` with error details for AJAX requests
- Log full exception details but show sanitized messages to users

---

### 9. Testing Strategy

**Decision**: Unit tests for PhotoService, integration tests for Razor Pages with in-memory database

**Rationale**:
- PhotoService contains core business logic (file operations, validation)
- Integration tests verify page handlers and database interactions
- In-memory database enables fast, isolated tests
- Follows TDD principles from constitution

**Alternatives Considered**:
- UI tests with Selenium/Playwright only: Slow, brittle
- No tests: Violates Code Quality principle
- Unit tests only: Doesn't catch integration issues

**Implementation Notes**:
- Use xUnit as test framework (ASP.NET Core default)
- Mock `IFormFile` for unit tests
- Use `WebApplicationFactory<Program>` for integration tests
- In-memory database: `UseInMemoryDatabase("TestDb")`
- Test file operations with temp directories

---

## Outstanding Questions

None - All technical context clarified:
- ✅ File formats: JPEG, PNG, GIF, WebP
- ✅ Storage approach: File system + LocalDB
- ✅ Upload limits: 10MB per file, 10 files per batch
- ✅ Testing: xUnit with integration tests
- ✅ Framework: .NET 8, ASP.NET Core, Razor Pages

---

## Technology Stack Summary

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| Runtime | .NET | 8.0 | Application platform |
| Web Framework | ASP.NET Core | 8.0 | Web application |
| UI Pattern | Razor Pages | 8.0 | Server-side rendering |
| CSS Framework | Bootstrap | 5.3 | Responsive UI |
| Database | SQL Server LocalDB | 2022 | Metadata storage |
| ORM | Entity Framework Core | 8.0 | Data access |
| Testing | xUnit | 2.6+ | Unit/integration tests |
| Image Processing | SixLabors.ImageSharp | 3.1+ | Image validation/thumbnails |

---

**Status**: ✅ All research complete, ready for Phase 1 design
