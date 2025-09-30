# PhotoAlbum

A simple photo storage and gallery application built with ASP.NET Core Razor Pages, Entity Framework Core, and Bootstrap.

## Features

- 📸 **Photo Upload**: Drag-and-drop or click to upload multiple photos
- 🖼️ **Gallery View**: Responsive grid layout for browsing uploaded photos
- 📊 **Metadata Display**: View file size, dimensions, and upload timestamp for each photo
- ✅ **Validation**: File type and size validation (JPEG, PNG, GIF, WebP; max 10MB)
- 🗄️ **Database Storage**: Photo metadata stored in SQL Server LocalDB
- 🎨 **Modern UI**: Clean, responsive design with Bootstrap 5

## Prerequisites

- [.NET 9.0 SDK](https://dotnet.microsoft.com/download/dotnet/9.0) or later
- SQL Server LocalDB (installed with Visual Studio or SQL Server Express)
- A modern web browser

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd PhotoAlbum
```

### 2. Restore Dependencies

```bash
dotnet restore
```

### 3. Apply Database Migrations

The application uses Entity Framework Core with SQL Server LocalDB. Migrations are applied automatically on first run, or you can apply them manually:

```bash
dotnet ef database update --project PhotoAlbum
```

### 4. Run the Application

```bash
cd PhotoAlbum
dotnet run
```

The application will be available at `http://localhost:5000` (or `https://localhost:5001` for HTTPS).

## Project Structure

```
PhotoAlbum/
├── PhotoAlbum/                 # Main web application
│   ├── Data/                   # Database context and migrations
│   ├── Models/                 # Domain models (Photo, UploadResult)
│   ├── Pages/                  # Razor Pages (Index, Error, etc.)
│   ├── Services/               # Business logic (PhotoService)
│   ├── wwwroot/                # Static files (CSS, JS, uploaded photos)
│   └── Program.cs              # Application startup
├── PhotoAlbum.Tests/           # Test project
│   ├── Unit/                   # Unit tests
│   └── Integration/            # Integration tests
└── PhotoAlbum.sln              # Solution file
```

## Configuration

Configuration is stored in `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=PhotoAlbumDb;..."
  },
  "PhotoUpload": {
    "MaxFileSizeBytes": 10485760,
    "AllowedMimeTypes": ["image/jpeg", "image/png", "image/gif", "image/webp"],
    "UploadPath": "wwwroot/uploads"
  }
}
```

### Configuration Options

- **MaxFileSizeBytes**: Maximum file size in bytes (default: 10MB)
- **AllowedMimeTypes**: Array of accepted MIME types
- **UploadPath**: Directory for storing uploaded files (relative to project root)

## Running Tests

The project includes both unit tests and integration tests.

### Run All Tests

```bash
dotnet test
```

### Run Unit Tests Only

```bash
dotnet test --filter Category=Unit
```

### Run Integration Tests Only

```bash
dotnet test --filter Category=Integration
```

## Development

### Technology Stack

- **Framework**: ASP.NET Core 9.0 (Razor Pages)
- **Database**: SQL Server LocalDB with Entity Framework Core 9.0
- **Testing**: xUnit with WebApplicationFactory
- **Image Processing**: SixLabors.ImageSharp 3.1.11
- **Frontend**: Bootstrap 5.3.0, Vanilla JavaScript

### Code Quality

The project follows standard C# coding conventions and includes:

- XML documentation on all public APIs
- Comprehensive unit test coverage
- Integration tests for page handlers
- Consistent formatting (enforced via `dotnet format`)

### Building for Release

```bash
dotnet build --configuration Release
```

### Publishing

```bash
dotnet publish --configuration Release --output ./publish
```

## Usage

1. **Upload Photos**:
   - Drag and drop one or more photos onto the upload zone
   - Or click "Browse" to select files from your computer
   - Supported formats: JPEG, PNG, GIF, WebP (max 10MB each)

2. **View Gallery**:
   - Uploaded photos appear in a responsive grid
   - Each card shows the photo thumbnail, filename, dimensions, file size, and upload date

3. **Delete Photos**:
   - Click the "Delete" button on any photo card to remove it from the gallery and database

## Troubleshooting

### Database Connection Issues

If you encounter database connection errors:

1. Verify SQL Server LocalDB is installed:
   ```bash
   sqllocaldb info
   ```

2. Create a new LocalDB instance if needed:
   ```bash
   sqllocaldb create MSSQLLocalDB
   sqllocaldb start MSSQLLocalDB
   ```

3. Update the connection string in `appsettings.json` if using a different instance.

### Upload Directory Permissions

Ensure the application has write permissions to the upload directory (`wwwroot/uploads`). The directory is created automatically on first upload if it doesn't exist.

## License

This project is provided as-is for educational and demonstration purposes.

## Contributing

Contributions are welcome! Please ensure:

- All tests pass (`dotnet test`)
- Code is properly formatted (`dotnet format`)
- XML documentation is added for public APIs
- New features include appropriate tests

## Support

For issues or questions, please open an issue in the repository.
