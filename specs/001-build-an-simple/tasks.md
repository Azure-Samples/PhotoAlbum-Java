# Tasks: Photo Storage Application

**Input**: Design documents from `/specs/001-build-an-simple/`
**Prerequisites**: plan.md, research.md, data-model.md, contracts/, quickstart.md

---

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- File paths are absolute from repository root
- Tests MUST be written and MUST fail before implementation

---

## Phase 3.1: Project Setup & Infrastructure

### Foundation Tasks

- [ ] **T001** Create solution and project structure
  - Create `PhotoAlbum.sln` at repository root
  - Create `PhotoAlbum/PhotoAlbum.csproj` (ASP.NET Core Web App)
  - Create `PhotoAlbum.Tests/PhotoAlbum.Tests.csproj` (xUnit test project)
  - Add project references: Tests → PhotoAlbum
  - **Files**: `PhotoAlbum.sln`, `PhotoAlbum/PhotoAlbum.csproj`, `PhotoAlbum.Tests/PhotoAlbum.Tests.csproj`
  - **Time**: M (30 min)

- [ ] **T002** Configure NuGet packages and dependencies
  - PhotoAlbum project: Add `Microsoft.EntityFrameworkCore.SqlServer`, `Microsoft.EntityFrameworkCore.Tools`, `SixLabors.ImageSharp`
  - PhotoAlbum.Tests project: Add `xUnit`, `xUnit.runner.visualstudio`, `Microsoft.AspNetCore.Mvc.Testing`, `Microsoft.EntityFrameworkCore.InMemory`
  - Verify .NET 8 SDK target framework in both projects
  - **Files**: `PhotoAlbum/PhotoAlbum.csproj`, `PhotoAlbum.Tests/PhotoAlbum.Tests.csproj`
  - **Depends on**: T001
  - **Time**: S (15 min)

- [ ] **T003** [P] Create directory structure and initial files
  - Create folders: `PhotoAlbum/Pages/`, `PhotoAlbum/Pages/Shared/`, `PhotoAlbum/Models/`, `PhotoAlbum/Data/`, `PhotoAlbum/Services/`, `PhotoAlbum/wwwroot/css/`, `PhotoAlbum/wwwroot/js/`, `PhotoAlbum/wwwroot/uploads/`
  - Create folders: `PhotoAlbum.Tests/Unit/Services/`, `PhotoAlbum.Tests/Integration/Pages/`
  - Create `.gitignore` with standard .NET entries plus `wwwroot/uploads/*` (but keep folder)
  - **Files**: Multiple directory creation
  - **Depends on**: T001
  - **Time**: S (10 min)

- [ ] **T004** [P] Configure application settings
  - Create `PhotoAlbum/appsettings.json` with LocalDB connection string, file upload limits (10MB), allowed file types
  - Create `PhotoAlbum/appsettings.Development.json` with debug settings
  - **Files**: `PhotoAlbum/appsettings.json`, `PhotoAlbum/appsettings.Development.json`
  - **Depends on**: T001
  - **Time**: S (10 min)

---

## Phase 3.2: Data Models & Database Setup

### Core Entity Tasks (Can run in parallel)

- [ ] **T005** [P] Create Photo entity model
  - Implement `PhotoAlbum/Models/Photo.cs` per data-model.md specification
  - Properties: Id, OriginalFileName, StoredFileName, FilePath, FileSize, MimeType, UploadedAt, Width, Height
  - Data annotations for validation: Required, MaxLength, Range
  - **Files**: `PhotoAlbum/Models/Photo.cs`
  - **Depends on**: T001
  - **Time**: S (15 min)

- [ ] **T006** [P] Create UploadResult value object
  - Implement `PhotoAlbum/Models/UploadResult.cs` per data-model.md
  - Properties: Success, PhotoId, FileName, ErrorMessage
  - **Files**: `PhotoAlbum/Models/UploadResult.cs`
  - **Depends on**: T001
  - **Time**: S (10 min)

- [ ] **T007** [P] Create PhotoAlbumContext DbContext
  - Implement `PhotoAlbum/Data/PhotoAlbumContext.cs`
  - DbSet<Photo> Photos
  - Configure entity with Fluent API: index on UploadedAt DESC
  - Override OnModelCreating for entity configuration
  - **Files**: `PhotoAlbum/Data/PhotoAlbumContext.cs`
  - **Depends on**: T005
  - **Time**: S (15 min)

- [ ] **T008** Create initial EF Core migration
  - Run `dotnet ef migrations add InitialCreate` in PhotoAlbum project
  - Verify migration creates Photos table with correct schema
  - **Files**: `PhotoAlbum/Data/Migrations/*_InitialCreate.cs`
  - **Depends on**: T007
  - **Time**: S (10 min)

- [ ] **T009** [P] Create IPhotoService interface
  - Define interface in `PhotoAlbum/Services/IPhotoService.cs`
  - Methods: `Task<List<Photo>> GetAllPhotosAsync()`, `Task<UploadResult> UploadPhotoAsync(IFormFile file)`, `Task<bool> DeletePhotoAsync(int id)`
  - **Files**: `PhotoAlbum/Services/IPhotoService.cs`
  - **Depends on**: T005, T006
  - **Time**: S (10 min)

---

## Phase 3.3: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE IMPLEMENTATION

**CRITICAL: These tests MUST be written and MUST FAIL before implementing services/pages**

### Unit Test Tasks (Can run in parallel)

- [ ] **T010** [P] Write PhotoService unit tests
  - Create `PhotoAlbum.Tests/Unit/Services/PhotoServiceTests.cs`
  - Test scenarios:
    - `UploadPhotoAsync_WithValidImage_ReturnsSuccess()` ❌ MUST FAIL
    - `UploadPhotoAsync_WithInvalidMimeType_ReturnsError()` ❌ MUST FAIL
    - `UploadPhotoAsync_WithOversizedFile_ReturnsError()` ❌ MUST FAIL
    - `UploadPhotoAsync_CreatesFileInUploadsDirectory()` ❌ MUST FAIL
    - `UploadPhotoAsync_SavesMetadataToDatabase()` ❌ MUST FAIL
    - `GetAllPhotosAsync_ReturnsPhotosOrderedByDate()` ❌ MUST FAIL
    - `DeletePhotoAsync_RemovesFileAndDatabaseRecord()` ❌ MUST FAIL
  - Use in-memory database and temp directories for testing
  - **Files**: `PhotoAlbum.Tests/Unit/Services/PhotoServiceTests.cs`
  - **Depends on**: T005, T006, T007, T009
  - **Time**: M (30 min)

### Integration Test Tasks (Can run in parallel)

- [ ] **T011** [P] Write GET gallery integration tests
  - Create `PhotoAlbum.Tests/Integration/Pages/IndexPageGetTests.cs`
  - Test scenarios from contracts/get-gallery.md:
    - `GetIndex_WithNoPhotos_ReturnsEmptyGallery()` ❌ MUST FAIL
    - `GetIndex_WithPhotos_ReturnsGalleryWithPhotos()` ❌ MUST FAIL
    - `GetIndex_WithManyPhotos_ReturnsPhotosInChronologicalOrder()` ❌ MUST FAIL
  - Use `WebApplicationFactory<Program>` with in-memory database
  - **Files**: `PhotoAlbum.Tests/Integration/Pages/IndexPageGetTests.cs`
  - **Depends on**: T002, T005, T007
  - **Time**: M (30 min)

- [ ] **T012** [P] Write POST upload integration tests
  - Create `PhotoAlbum.Tests/Integration/Pages/IndexPageUploadTests.cs`
  - Test scenarios from contracts/upload-photos.md:
    - `PostUpload_WithValidImage_ReturnsSuccessAndCreatesPhoto()` ❌ MUST FAIL
    - `PostUpload_WithMultipleImages_UploadsAllSuccessfully()` ❌ MUST FAIL
    - `PostUpload_WithInvalidFileType_ReturnsBadRequest()` ❌ MUST FAIL
    - `PostUpload_WithOversizedFile_ReturnsBadRequest()` ❌ MUST FAIL
    - `PostUpload_WithMixedValidInvalid_ReturnsPartialSuccess()` ❌ MUST FAIL
    - `PostUpload_WithNoFiles_ReturnsBadRequest()` ❌ MUST FAIL
    - `PostUpload_CreatesFileInUploadsDirectory()` ❌ MUST FAIL
  - Create mock IFormFile instances for testing
  - **Files**: `PhotoAlbum.Tests/Integration/Pages/IndexPageUploadTests.cs`
  - **Depends on**: T002, T005, T006, T007
  - **Time**: L (1 hour)

### Test Verification Gate

- [ ] **T013** Verify all tests fail as expected
  - Run `dotnet test` in PhotoAlbum.Tests project
  - Confirm all tests fail with appropriate errors (not compilation errors)
  - Document failure reasons (e.g., "PhotoService not implemented", "IndexModel not implemented")
  - **Action**: Run terminal command, verify output
  - **Depends on**: T010, T011, T012
  - **Time**: S (10 min)

---

## Phase 3.4: Service Layer Implementation

**ONLY proceed after T013 confirms tests are failing**

- [ ] **T014** Implement PhotoService
  - Create `PhotoAlbum/Services/PhotoService.cs` implementing `IPhotoService`
  - Implement `GetAllPhotosAsync()`: Query database ordered by UploadedAt DESC
  - Implement `UploadPhotoAsync()`:
    - Validate file type (JPEG, PNG, GIF, WebP) and size (≤10MB)
    - Generate GUID filename with original extension
    - Use ImageSharp to extract width/height
    - Save file to wwwroot/uploads/
    - Create Photo entity and save to database
    - Handle errors with rollback (delete file if DB save fails)
    - Return UploadResult
  - Implement `DeletePhotoAsync()`: Delete file and database record atomically
  - Inject `PhotoAlbumContext`, `IWebHostEnvironment`, `ILogger<PhotoService>`
  - **Files**: `PhotoAlbum/Services/PhotoService.cs`
  - **Depends on**: T009, T013
  - **Time**: L (1 hour)

- [ ] **T015** Configure dependency injection and middleware
  - Edit `PhotoAlbum/Program.cs`:
    - Register DbContext with LocalDB connection string
    - Register IPhotoService as scoped service
    - Configure static file serving with cache headers
    - Configure form options (10MB limit, 10 files max)
    - Run database migrations on startup (development only)
    - Ensure wwwroot/uploads/ directory exists on startup
  - **Files**: `PhotoAlbum/Program.cs`
  - **Depends on**: T007, T009, T014
  - **Time**: M (20 min)

- [ ] **T016** Run unit tests to verify PhotoService implementation
  - Run `dotnet test --filter "FullyQualifiedName~PhotoServiceTests"`
  - All PhotoService tests should now PASS ✅
  - Fix any failures before proceeding
  - **Action**: Run terminal command, verify output
  - **Depends on**: T014, T015
  - **Time**: S (10 min)

---

## Phase 3.5: Razor Pages & UI Implementation

### Layout and Shared Components

- [ ] **T017** [P] Create shared layout
  - Create `PhotoAlbum/Pages/Shared/_Layout.cshtml`
  - Bootstrap 5 structure with navbar, container, footer
  - Link to Bootstrap CSS (CDN or local), custom CSS, anti-forgery token script
  - **Files**: `PhotoAlbum/Pages/Shared/_Layout.cshtml`
  - **Depends on**: T003
  - **Time**: M (20 min)

- [ ] **T018** [P] Create _ViewImports and _ViewStart
  - Create `PhotoAlbum/Pages/_ViewImports.cshtml`: Import tag helpers, namespaces
  - Create `PhotoAlbum/Pages/_ViewStart.cshtml`: Set default layout
  - **Files**: `PhotoAlbum/Pages/_ViewImports.cshtml`, `PhotoAlbum/Pages/_ViewStart.cshtml`
  - **Depends on**: T017
  - **Time**: S (10 min)

### Index Page (Gallery & Upload)

- [ ] **T019** Implement Index Page Model (code-behind)
  - Create `PhotoAlbum/Pages/Index.cshtml.cs`
  - Implement IndexModel class inheriting from PageModel
  - Inject IPhotoService
  - Property: `public List<Photo> Photos { get; set; }`
  - Implement `OnGetAsync()`: Call `_photoService.GetAllPhotosAsync()`, populate Photos property
  - Implement `OnPostUploadAsync(List<IFormFile> files)` with `[ValidateAntiForgeryToken]`:
    - Validate files parameter (not null/empty)
    - Loop through files, call `_photoService.UploadPhotoAsync()` for each
    - Collect results into uploadedPhotos and failedUploads lists
    - Return JsonResult with success status and arrays
  - **Files**: `PhotoAlbum/Pages/Index.cshtml.cs`
  - **Depends on**: T009, T014, T015
  - **Time**: M (30 min)

- [ ] **T020** Implement Index Razor view (HTML/UI)
  - Create `PhotoAlbum/Pages/Index.cshtml`
  - `@page` directive and `@model IndexModel`
  - Upload zone section:
    - Div with id="drop-zone" for drag-and-drop
    - Visible file input as fallback
    - Visual feedback areas (loading, success, errors)
  - Gallery section:
    - Bootstrap responsive grid (col-12 col-sm-6 col-md-4 col-lg-3)
    - Foreach loop over Model.Photos
    - Card components with image, filename, upload date, file size
    - Empty state message if no photos
  - Include anti-forgery token for AJAX
  - **Files**: `PhotoAlbum/Pages/Index.cshtml`
  - **Depends on**: T019
  - **Time**: M (30 min)

### JavaScript for Drag-and-Drop

- [ ] **T021** Implement drag-and-drop JavaScript
  - Create `PhotoAlbum/wwwroot/js/upload.js`
  - Get references to drop-zone, file-input, gallery elements
  - Event listeners:
    - `dragover`: Prevent default, add visual highlight class
    - `dragleave`: Remove highlight class
    - `drop`: Prevent default, get files from dataTransfer, call uploadFiles()
    - File input `change`: Get files, call uploadFiles()
  - `uploadFiles(files)` function:
    - Client-side validation (file type, size)
    - Create FormData, append files
    - Add anti-forgery token to request
    - Fetch POST to /Upload with FormData
    - Show loading indicator
    - Handle response: display new photos or errors
    - Update gallery dynamically
  - `displayPhotos(photos)` function: Create card HTML and append to gallery
  - `showErrors(errors)` function: Display error messages
  - **Files**: `PhotoAlbum/wwwroot/js/upload.js`
  - **Depends on**: T020
  - **Time**: M (30 min)

### Styling

- [ ] **T022** [P] Create custom CSS
  - Create `PhotoAlbum/wwwroot/css/site.css`
  - Styles for:
    - Drop zone (border, padding, hover/dragover states, transitions)
    - Upload feedback (loading spinner, success/error messages)
    - Photo gallery cards (consistent sizing, spacing, shadows)
    - Responsive adjustments
  - **Files**: `PhotoAlbum/wwwroot/css/site.css`
  - **Depends on**: T003
  - **Time**: M (20 min)

---

## Phase 3.6: Integration Test Verification

- [ ] **T023** Run all integration tests
  - Run `dotnet test --filter "FullyQualifiedName~Integration"`
  - All integration tests should now PASS ✅
  - Test scenarios:
    - Empty gallery display ✅
    - Photo display with data ✅
    - Valid upload ✅
    - Multiple uploads ✅
    - Invalid file type rejection ✅
    - Oversized file rejection ✅
    - Mixed valid/invalid uploads ✅
  - Fix any failures before proceeding
  - **Action**: Run terminal command, verify output
  - **Depends on**: T019, T020, T021
  - **Time**: S (15 min)

---

## Phase 3.7: Manual Testing & Validation

- [ ] **T024** Execute quickstart.md scenarios
  - Follow all 8 scenarios in quickstart.md:
    1. View empty gallery ✅
    2. Upload single photo (drag-and-drop) ✅
    3. Upload multiple photos ✅
    4. Upload invalid file type ✅
    5. Upload oversized file ✅
    6. View gallery after uploads ✅
    7. Browser refresh (persistence) ✅
    8. Responsive design testing ✅
  - Verify all expected results
  - Document any issues found
  - **Action**: Manual testing following quickstart.md
  - **Depends on**: T023
  - **Time**: M (30 min)

- [ ] **T025** Performance validation
  - Measure page load time (target: <2s)
  - Measure upload response time (target: <3s per photo)
  - Measure interaction response (target: <200ms)
  - Test with 10+ photos to ensure performance
  - Use browser DevTools Performance tab
  - **Action**: Manual performance testing
  - **Depends on**: T024
  - **Time**: S (15 min)

- [ ] **T026** Error handling verification
  - Test error scenarios:
    - Database connection failure (stop LocalDB)
    - File system write failure (remove write permissions)
    - Corrupt image upload
    - Network interruption during upload
  - Verify user-friendly error messages displayed
  - Verify no sensitive information leaked
  - Verify logging captures errors
  - **Action**: Manual error scenario testing
  - **Depends on**: T024
  - **Time**: M (20 min)

---

## Phase 3.8: Polish & Documentation

- [ ] **T027** [P] Add XML documentation comments
  - Add XML docs to all public interfaces and classes:
    - Photo.cs, UploadResult.cs
    - IPhotoService.cs, PhotoService.cs
    - IndexModel.cs
  - Include param and return descriptions
  - **Files**: Multiple .cs files
  - **Depends on**: T016, T023
  - **Time**: S (15 min)

- [ ] **T028** [P] Code cleanup and refactoring
  - Remove any TODO comments
  - Remove unused using statements
  - Ensure consistent code formatting (run `dotnet format`)
  - Check for code duplication
  - Verify all magic numbers are constants
  - **Files**: Multiple files
  - **Depends on**: T027
  - **Time**: S (15 min)

- [ ] **T029** [P] Update README.md
  - Create or update `README.md` in repository root
  - Include:
    - Project description
    - Prerequisites (.NET 8 SDK, LocalDB)
    - Setup instructions (restore, migrate, run)
    - Features list
    - Technology stack
    - Link to quickstart.md for testing
  - **Files**: `README.md`
  - **Depends on**: T001
  - **Time**: S (15 min)

- [ ] **T030** Final full test suite run
  - Run `dotnet test` (all tests)
  - Verify 100% test pass rate ✅
  - Run `dotnet build --configuration Release`
  - Verify no warnings or errors
  - **Action**: Run terminal commands
  - **Depends on**: T027, T028, T029
  - **Time**: S (10 min)

---

## Dependencies Summary

```
T001 → T002, T003, T004, T005, T006
T002 → T011, T012
T005 → T007, T009, T010, T011, T012
T006 → T009, T010, T012
T007 → T008, T010, T011, T012
T008 → (database ready)
T009 → T010, T014, T015, T019

T010, T011, T012 → T013 (test verification gate)
T013 → T014 (implementation can begin)

T014 → T015, T016, T019
T015 → T016, T019
T016 → T027 (unit tests passing)

T003 → T017, T022
T017 → T018
T009, T014, T015 → T019
T019 → T020, T023
T020 → T021, T023
T021, T019 → T023 (integration tests)

T023 → T024 (manual testing)
T024 → T025, T026
T027, T028, T029 → T030 (final verification)
```

---

## Parallel Execution Examples

### Phase 1: Initial Setup (After T001)
```bash
# Can run in parallel:
Task T003: Create directory structure
Task T004: Configure application settings
```

### Phase 2: Models (After T001)
```bash
# Can run in parallel:
Task T005: Create Photo entity
Task T006: Create UploadResult value object
```

### Phase 3: Tests (After T009)
```bash
# Can run in parallel - CRITICAL: All must fail before T014:
Task T010: Write PhotoService unit tests
Task T011: Write GET gallery integration tests
Task T012: Write POST upload integration tests
```

### Phase 4: UI Components (After T003)
```bash
# Can run in parallel:
Task T017: Create shared layout
Task T022: Create custom CSS
```

### Phase 5: Polish (After T023)
```bash
# Can run in parallel:
Task T027: Add XML documentation
Task T028: Code cleanup and refactoring
Task T029: Update README
```

---

## Task Count: 30 tasks
**Estimated Total Time**: ~12-14 hours

## Phases Breakdown:
- **Phase 3.1 (Setup)**: T001-T004 (~65 min)
- **Phase 3.2 (Data Models)**: T005-T009 (~60 min)
- **Phase 3.3 (Tests - TDD)**: T010-T013 (~2h 20min) ⚠️ MUST FAIL
- **Phase 3.4 (Services)**: T014-T016 (~1h 30min)
- **Phase 3.5 (UI)**: T017-T022 (~2h 20min)
- **Phase 3.6 (Integration Tests)**: T023 (~15 min)
- **Phase 3.7 (Manual Testing)**: T024-T026 (~1h 5min)
- **Phase 3.8 (Polish)**: T027-T030 (~55 min)

---

## Validation Checklist

- [x] All contracts have corresponding tests (T011: GET gallery, T012: POST upload)
- [x] All entities have model tasks (T005: Photo entity, T006: UploadResult)
- [x] All tests come before implementation (T010-T013 before T014-T022)
- [x] Parallel tasks are truly independent (marked [P], different files)
- [x] Each task specifies exact file path
- [x] No [P] task modifies same file as another [P] task
- [x] TDD workflow enforced (test verification gate at T013)
- [x] Integration tests verify contracts (T011, T012)
- [x] Manual testing validates quickstart scenarios (T024)
- [x] Performance and error handling validated (T025, T026)

---

**Status**: ✅ Tasks ready for execution - Follow TDD workflow strictly
