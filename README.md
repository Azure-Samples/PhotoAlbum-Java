# Photo Album Application - Java Spring Boot with PostgreSQL

A photo gallery application built with Spring Boot and PostgreSQL Database, featuring drag-and-drop upload, responsive gallery view, and full-size photo details with navigation.

**Note**: This application has been successfully migrated from Oracle Database to PostgreSQL as part of an application modernization initiative.

## Features

- 📤 **Photo Upload**: Drag-and-drop or click to upload multiple photos
- 🖼️ **Gallery View**: Responsive grid layout for browsing uploaded photos  
- 🔍 **Photo Detail View**: Click any photo to view full-size with metadata and navigation
- 📊 **Metadata Display**: View file size, dimensions, aspect ratio, and upload timestamp
- ⬅️➡️ **Photo Navigation**: Previous/Next buttons to browse through photos
- ✅ **Validation**: File type and size validation (JPEG, PNG, GIF, WebP; max 10MB)
- 🗄️ **Database Storage**: Photo data stored as BLOBs in PostgreSQL Database
- 🗑️ **Delete Photos**: Remove photos from both gallery and detail views
- 🎨 **Modern UI**: Clean, responsive design with Bootstrap 5

## Technology Stack

- **Framework**: Spring Boot 2.7.18 (Java 8)
- **Database**: PostgreSQL 15
- **Templating**: Thymeleaf
- **Build Tool**: Maven
- **Frontend**: Bootstrap 5.3.0, Vanilla JavaScript
- **Containerization**: Docker & Docker Compose

## Prerequisites

- Docker Desktop installed and running
- Docker Compose (included with Docker Desktop)
- Minimum 2GB RAM available for PostgreSQL container

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Azure-Samples/PhotoAlbum-Java.git
   cd PhotoAlbum-Java
   git checkout migrated
   ```

2. **Start the application**:
   ```bash
   # Use docker-compose directly
   docker-compose up --build -d
   ```

   This will:
   - Start PostgreSQL 15 Database container
   - Build the Java Spring Boot application
   - Start the Photo Album application container
   - Automatically create the database schema using JPA/Hibernate

3. **Wait for services to start**:
   - PostgreSQL takes 1-2 minutes to initialize on first run
   - Application will start once PostgreSQL is healthy

4. **Access the application**:
   - Open your browser and navigate to: **http://localhost:8080**
   - The application should be running and ready to use

## Services

## PostgreSQL Database
- **Image**: `postgres:15`
- **Ports**: 
  - `5432` (database) - mapped to host port 5432
- **Database**: `postgres`
- **Schema**: `public`
- **Username/Password**: `photoalbum/photoalbum`

## Photo Album Java Application
- **Port**: `8080` (mapped to host port 8080)
- **Framework**: Spring Boot 2.7.18
- **Java Version**: 8
- **Database**: Connects to PostgreSQL container
- **Photo Storage**: All photos stored as BLOBs in database (no file system storage)
- **UUID System**: Each photo gets a globally unique identifier for cache-busting

## Database Setup

The application uses Spring Data JPA with Hibernate for automatic schema management:

1. **Automatic Schema Creation**: Hibernate automatically creates tables and indexes
2. **User Creation**: PostgreSQL init scripts create the `photoalbum` user
3. **No Manual Setup Required**: Everything is handled automatically

### Database Schema

The application creates the following table structure in PostgreSQL:

#### PHOTOS Table
- `ID` (VARCHAR(36), Primary Key, UUID Generated)
- `ORIGINAL_FILE_NAME` (VARCHAR(255), Not Null)
- `STORED_FILE_NAME` (VARCHAR(255), Not Null)
- `FILE_PATH` (VARCHAR(500), Nullable)
- `FILE_SIZE` (BIGINT, Not Null)
- `MIME_TYPE` (VARCHAR(50), Not Null)
- `UPLOADED_AT` (TIMESTAMP, Not Null, Default CURRENT_TIMESTAMP)
- `WIDTH` (INTEGER, Nullable)
- `HEIGHT` (INTEGER, Nullable)
- `PHOTO_DATA` (BYTEA, Not Null)

#### Indexes
- `IDX_PHOTOS_UPLOADED_AT` (Index on UPLOADED_AT for chronological queries)

#### UUID Generation
- **Java**: `UUID.randomUUID().toString()` generates unique identifiers
- **Benefits**: Eliminates browser caching issues, globally unique across databases
- **Format**: Standard UUID format (36 characters with hyphens)

## Storage Architecture

### Database BLOB Storage (Current Implementation)
- **Photos**: Stored as BLOB data directly in the database
- **Benefits**: 
  - No file system dependencies
  - ACID compliance for photo operations
  - Simplified backup and migration
  - Perfect for containerized deployments
- **Trade-offs**: Database size increases, but suitable for moderate photo volumes

## Development

### Running Locally (without Docker)

1. **Install PostgreSQL Database**
2. **Create database user**:
   ```sql
   CREATE USER photoalbum WITH PASSWORD 'photoalbum';
   CREATE DATABASE photoalbum OWNER photoalbum;
   GRANT ALL PRIVILEGES ON DATABASE photoalbum TO photoalbum;
   ```
3. **Update application.properties**:
   ```properties
   spring.datasource.url=jdbc:postgresql://localhost:5432/photoalbum
   spring.datasource.username=photoalbum
   spring.datasource.password=photoalbum
   spring.jpa.hibernate.ddl-auto=create
   ```
4. **Run the application**:
   ```bash
   mvn spring-boot:run
   ```

### Building from Source

```bash
# Build the JAR file
mvn clean package

# Run the JAR file
java -jar target/photo-album-1.0.0.jar
```

## Troubleshooting

### PostgreSQL Database Issues

1. **PostgreSQL container won't start**:
   ```bash
   # Check container logs
   docker-compose logs postgres-db
   
   # Ensure Docker has enough memory allocated
   ```

2. **Database connection errors**:
   ```bash
   # Verify PostgreSQL is ready
   docker exec -it photoalbum-postgres psql -U photoalbum -d postgres
   ```

3. **Permission errors**:
   ```bash
   # Check PostgreSQL init scripts ran
   docker-compose logs postgres-db | grep "setup"
   ```

### Application Issues

1. **View application logs**:
   ```bash
   docker-compose logs photoalbum-java-app
   ```

2. **Rebuild application**:
   ```bash
   docker-compose up --build
   ```

3. **Reset database (nuclear option)**:
   ```bash
   docker-compose down -v
   docker-compose up --build
   ```

## Stopping the Application

```bash
# Stop services
docker-compose down

# Stop and remove all data (including database)
docker-compose down -v
```

## Database Administration (Optional)

PostgreSQL database can be accessed directly for administration:
- **Host**: `localhost`
- **Port**: `5432`
- **Database**: `postgres`
- **Username**: `photoalbum`
- **Password**: `photoalbum`

## Performance Notes

- PostgreSQL is highly scalable and performant
- BLOB storage in database impacts performance at scale
- Suitable for development and production deployments

## Project Structure

```
PhotoAlbum/
├── src/                             # Java source code
├── postgres-init/                   # PostgreSQL initialization scripts
├── docker-compose.yml               # PostgreSQL + Application services
├── Dockerfile                       # Application container build
├── pom.xml                          # Maven dependencies and build config
└── README.md                        # Project documentation
```

## Contributing

When contributing to this project:

- Follow Spring Boot best practices
- Maintain database compatibility
- Ensure UI/UX consistency
- Test both local Docker and Azure deployment scenarios
- Update documentation for any architectural changes
- Preserve UUID system integrity
- Add appropriate tests for new features

## License

This project is provided as-is for educational and demonstration purposes.