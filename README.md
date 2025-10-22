# Photo Album Application - Java Spring Boot with Oracle DB

A simple photo storage and gallery application built with Spring Boot and Oracle Database, featuring drag-and-drop upload, responsive gallery view, and full-size photo details with navigation.

## Features

- ?? **Photo Upload**: Drag-and-drop or click to upload multiple photos
- ??? **Gallery View**: Responsive grid layout for browsing uploaded photos  
- ?? **Photo Detail View**: Click any photo to view full-size with metadata and navigation
- ?? **Metadata Display**: View file size, dimensions, aspect ratio, and upload timestamp
- ???? **Photo Navigation**: Previous/Next buttons to browse through photos
- ? **Validation**: File type and size validation (JPEG, PNG, GIF, WebP; max 10MB)
- ??? **Oracle Database**: Photo metadata stored in Oracle Database
- ??? **Delete Photos**: Remove photos from both gallery and detail views
- ?? **Modern UI**: Clean, responsive design with Bootstrap 5

## Technology Stack

- **Framework**: Spring Boot 2.7.18 (Java 8)
- **Database**: Oracle Database 21c Express Edition
- **Templating**: Thymeleaf
- **Build Tool**: Maven
- **Frontend**: Bootstrap 5.3.0, Vanilla JavaScript
- **Containerization**: Docker & Docker Compose

## Prerequisites

- Docker Desktop installed and running
- Docker Compose (included with Docker Desktop)
- Minimum 4GB RAM available for Oracle DB container

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd PhotoAlbum
   ```

2. **Start the application**:
   ```bash
   # On Windows
   start.bat
   
   # On Unix/Linux/macOS
   ./start.sh
   
   # Or use docker-compose directly
   docker-compose up --build
   ```

   This will:
   - Start Oracle Database 21c Express Edition container
   - Build the Java Spring Boot application
   - Start the Photo Album application container
   - Automatically create the database schema using JPA/Hibernate

3. **Wait for services to start**:
   - Oracle DB takes 2-3 minutes to initialize on first run
   - Application will start once Oracle is healthy

4. **Access the application**:
   - Open your browser and navigate to: **http://localhost:8080**
   - The application should be running and ready to use

## Services

### Oracle Database
- **Image**: `container-registry.oracle.com/database/express:21.3.0-xe`
- **Ports**: 
  - `1521` (database) - mapped to host port 1521
  - `5500` (Enterprise Manager) - mapped to host port 5500
- **Database**: `XE` (Express Edition)
- **Schema**: `photoalbum`
- **Username/Password**: `photoalbum/photoalbum`

### Photo Album Java Application
- **Port**: `8080` (mapped to host port 8080)
- **Framework**: Spring Boot 2.7.18
- **Java Version**: 8
- **Database**: Connects to Oracle container

## Database Setup

The application uses Spring Data JPA with Hibernate for automatic schema management:

1. **Automatic Schema Creation**: Hibernate automatically creates tables and indexes
2. **User Creation**: Oracle init scripts create the `photoalbum` user
3. **No Manual Setup Required**: Everything is handled automatically

### Database Schema

The application creates the following table structure in Oracle:

#### PHOTOS Table
- `ID` (NUMBER, Primary Key, Sequence Generated)
- `ORIGINAL_FILE_NAME` (VARCHAR2(255), Not Null)
- `STORED_FILE_NAME` (VARCHAR2(255), Not Null)
- `FILE_PATH` (VARCHAR2(500), Not Null)
- `FILE_SIZE` (NUMBER, Not Null)
- `MIME_TYPE` (VARCHAR2(50), Not Null)
- `UPLOADED_AT` (TIMESTAMP, Not Null)
- `WIDTH` (NUMBER, Nullable)
- `HEIGHT` (NUMBER, Nullable)

#### Indexes
- `IDX_PHOTOS_UPLOADED_AT` (Index on UPLOADED_AT for chronological queries)

#### Sequences
- `PHOTO_SEQ` (Sequence for ID generation)

## File Storage

Uploaded photos are stored in the `uploads` directory, which is mapped to the host filesystem for persistence.

## Development

### Running Locally (without Docker)

1. **Install Oracle Database** (or use Oracle XE)
2. **Create database user**:
   ```sql
   CREATE USER photoalbum IDENTIFIED BY photoalbum;
   GRANT CONNECT, RESOURCE, DBA TO photoalbum;
   ```
3. **Update application.properties**:
   ```properties
   spring.datasource.url=jdbc:oracle:thin:@localhost:1521:XE
   spring.datasource.username=photoalbum
   spring.datasource.password=photoalbum
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

### Oracle Database Issues

1. **Oracle container won't start**:
   ```bash
   # Check container logs
   docker-compose logs oracle-db
   
   # Increase Docker memory allocation to at least 4GB
   ```

2. **Database connection errors**:
   ```bash
   # Verify Oracle is ready
   docker exec -it photoalbum-oracle sqlplus photoalbum/photoalbum@//localhost:1521/XE
   ```

3. **Permission errors**:
   ```bash
   # Check Oracle init scripts ran
   docker-compose logs oracle-db | grep "setup"
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

## Enterprise Manager (Optional)

Oracle Enterprise Manager is available at `http://localhost:5500/em` for database administration:
- **Username**: `system`
- **Password**: `photoalbum`
- **Container**: `XE`

## Performance Notes

- Oracle XE has limitations (max 2 CPU threads, 2GB RAM, 12GB storage)
- For production use, consider Oracle Standard/Enterprise Edition
- File upload performance is optimized with proper validation
- Database queries are optimized with proper indexing

## Project Structure

```
PhotoAlbum/
??? src/main/java/com/photoalbum/    # Java source code
?   ??? controller/                  # Spring MVC controllers
?   ??? model/                       # JPA entities
?   ??? repository/                  # Data access layer
?   ??? service/                     # Business logic
?   ??? config/                      # Configuration classes
??? src/main/resources/              # Application resources
?   ??? templates/                   # Thymeleaf templates
?   ??? static/                      # Static web assets (CSS, JS)
?   ??? application.properties       # Configuration
??? oracle-init/                     # Oracle DB initialization scripts
??? uploads/                         # Photo file storage
??? docker-compose.yml               # Docker services definition
??? Dockerfile                       # Application container build
??? pom.xml                          # Maven dependencies
??? README.md                        # This file
```

## Contributing

When contributing to this project:

- Follow Spring Boot best practices
- Maintain Oracle compatibility
- Ensure UI/UX consistency
- Add appropriate tests
- Update documentation

## License

This project is provided as-is for educational and demonstration purposes.