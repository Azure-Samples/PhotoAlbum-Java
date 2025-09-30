
# Implementation Plan: Photo Storage Application

**Branch**: `001-build-an-simple` | **Date**: 2025-09-30 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-build-an-simple/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from file system structure or context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code or `AGENTS.md` for opencode).
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
A simple photo storage application allowing users to drag-and-drop upload photos and view them in a flat, single-level gallery. The application will be built as a .NET 8 ASP.NET Core Web App using Razor Pages for the UI, Bootstrap CSS for styling, vanilla JavaScript for drag-and-drop functionality, SQL Server LocalDB for metadata storage, and file system storage for image files.

## Technical Context
**Language/Version**: C# / .NET 8  
**Primary Dependencies**: ASP.NET Core 8.0, Entity Framework Core 8.0, Bootstrap 5.x  
**Storage**: SQL Server LocalDB (metadata), File system (image files under web app runtime path)  
**Testing**: xUnit, Playwright or Selenium (for integration tests)  
**Target Platform**: Windows/Linux/macOS web server  
**Project Type**: web (ASP.NET Core Web App with Razor Pages)  
**Performance Goals**: <2s page load, <200ms interaction response, handle concurrent uploads  
**Constraints**: Files stored locally, drag-and-drop browser support, responsive design  
**Scale/Scope**: Demo application, single-user or small team usage, hundreds of photos

**User-Provided Implementation Details**: 
- .NET 8 solution with single ASP.NET Core Web App (Razor Pages) project
- Bootstrap CSS for styling, vanilla JavaScript where possible
- Images uploaded and stored in file system directory under web app runtime path
- Image metadata stored in SQL Server LocalDB
- Solution file (.sln) at repository root
- Separate folder for .csproj file

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Simplicity (NON-NEGOTIABLE)
- ✅ Single ASP.NET Core project (no microservices)
- ✅ Flat photo organization (no complex hierarchy)
- ✅ Direct file system storage (no cloud abstraction layer)
- ✅ Bootstrap for UI (no custom CSS framework)
- ✅ Vanilla JavaScript (no heavy frontend framework)
- ✅ LocalDB (no complex database setup)
- ✅ Drag-and-drop as primary upload (single clear feature)

### Code Quality
- ✅ .NET project structure follows conventions
- ✅ Separate concerns: Pages, Models, Data Access
- ✅ Entity Framework for data access (no raw SQL)
- ✅ Plan includes unit and integration tests
- ✅ Error handling for file operations
- ✅ Input validation for file types and sizes

### User Experience Consistency
- ✅ Bootstrap provides consistent UI patterns
- ✅ Immediate visual feedback on upload
- ✅ Responsive design (Bootstrap built-in)
- ✅ Clear error messages for failed uploads
- ✅ <2s page load, <200ms interaction targets

**Status**: ✅ PASS - No violations, aligns with demo simplicity goals

## Project Structure

### Documentation (this feature)
```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
PhotoAlbum.sln           # Solution file at repository root

PhotoAlbum/              # ASP.NET Core Web App project folder
├── Pages/               # Razor Pages
│   ├── Index.cshtml     # Main gallery page
│   ├── Index.cshtml.cs  # Page model
│   ├── Upload.cshtml    # Upload page (if separate)
│   ├── Upload.cshtml.cs
│   └── Shared/          # Shared layout and partials
│       ├── _Layout.cshtml
│       └── _ValidationScriptsPartial.cshtml
├── Models/              # Domain models
│   └── Photo.cs         # Photo entity
├── Data/                # Database context and migrations
│   ├── PhotoAlbumContext.cs
│   └── Migrations/
├── Services/            # Business logic services
│   ├── IPhotoService.cs
│   └── PhotoService.cs
├── wwwroot/             # Static files
│   ├── css/
│   ├── js/
│   │   └── upload.js    # Drag-and-drop logic
│   ├── lib/             # Bootstrap, etc.
│   └── uploads/         # Uploaded photo storage
├── appsettings.json
├── appsettings.Development.json
├── Program.cs
└── PhotoAlbum.csproj

PhotoAlbum.Tests/        # Test project
├── Unit/
│   └── Services/
│       └── PhotoServiceTests.cs
├── Integration/
│   └── Pages/
│       └── IndexPageTests.cs
└── PhotoAlbum.Tests.csproj
```

**Structure Decision**: Web application structure (Option 2 simplified). Using ASP.NET Core conventions with Razor Pages in a single project. Solution file at root, project in `PhotoAlbum/` subfolder. Tests in separate `PhotoAlbum.Tests/` project. File storage within `wwwroot/uploads/` for direct web access.

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:
   ```
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Generate contract tests** from contracts:
   - One test file per endpoint
   - Assert request/response schemas
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps

5. **Update agent file incrementally** (O(1) operation):
   - Run `.specify/scripts/powershell/update-agent-context.ps1 -AgentType copilot`
     **IMPORTANT**: Execute it exactly as specified above. Do not add or remove any arguments.
   - If exists: Add only NEW tech from current plan
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:

1. **Foundation Tasks** (Infrastructure):
   - Create solution and project structure (.sln, .csproj)
   - Configure NuGet packages (EF Core, ImageSharp, Bootstrap)
   - Set up database context and connection string
   - Configure static file serving and upload directory

2. **Model & Data Layer Tasks**:
   - Create Photo entity from data-model.md [P]
   - Create PhotoAlbumContext (DbContext) [P]
   - Create UploadResult value object [P]
   - Generate initial EF Core migration
   - Create IPhotoService interface

3. **Service Layer Tasks** (TDD):
   - Write unit tests for PhotoService (validation, file operations) [P]
   - Implement PhotoService (upload, retrieval, deletion)
   - Wire up dependency injection in Program.cs

4. **Contract Test Tasks**:
   - Create integration test infrastructure (WebApplicationFactory)
   - Write GET / gallery tests from contracts/get-gallery.md [P]
   - Write POST /Upload tests from contracts/upload-photos.md [P]

5. **UI Implementation Tasks**:
   - Create Shared layout with Bootstrap (_Layout.cshtml)
   - Implement Index.cshtml Razor Page (gallery view)
   - Implement Index.cshtml.cs Page Model (OnGetAsync, OnPostUploadAsync)
   - Create upload.js (drag-and-drop, AJAX upload, progress feedback)
   - Add CSS for upload zone styling

6. **Validation & Polish Tasks**:
   - Run all tests and verify they pass
   - Execute quickstart.md scenarios manually
   - Performance testing (page load, upload timing)
   - Error handling verification
   - Accessibility review (WCAG 2.1 AA)

**Ordering Strategy**:
- **Phase 1: Foundation** → Tasks 1-4 (sequential, foundational)
- **Phase 2: Models & Services** → Tasks 5-10 (parallel where marked [P])
- **Phase 3: Tests** → Tasks 11-13 (parallel, should fail initially)
- **Phase 4: UI** → Tasks 14-18 (sequential, depends on services)
- **Phase 5: Validation** → Tasks 19-23 (sequential, final checks)

**TDD Order**: 
- Tests written before implementations (e.g., Task 11-13 before Task 14-18)
- Models before services before UI
- Each task makes one or more tests pass

**Parallelization**: 
- Mark independent tasks with [P] for concurrent execution
- Example: Photo.cs, PhotoAlbumContext.cs, IPhotoService.cs can be created in parallel

**Estimated Output**: 
- ~25-30 numbered, ordered tasks in tasks.md
- Each task includes:
  - Number and title
  - Description and acceptance criteria
  - Dependencies (blocked by which tasks)
  - Estimated time (S/M/L: Small=15min, Medium=30min, Large=1hr)
  - Test verification (which tests should pass after completion)
  - Files to create/modify

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented (none - all principles upheld)

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*
