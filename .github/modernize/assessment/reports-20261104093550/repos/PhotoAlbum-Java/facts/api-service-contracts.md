# API & Service Communication Contracts

The application exposes five HTTP routes: server-rendered gallery/detail pages, a multipart upload endpoint with a JSON response, and an endpoint that serves photo bytes. Requests are handled synchronously within one application and synchronously persisted to the database; no inter-service API or asynchronous messaging was found.

## Service Catalog

| Service | Port | Category | Purpose |
|---|---:|---|---|
| Photo Album Java (`photo-album`) | 8080 | API Layer | Source-built Spring MVC and Thymeleaf web application providing the photo gallery, upload, detail, delete, and image-serving routes. |
| Oracle Database (`oracle-db`) | 1521 | Infrastructure | Third-party Oracle Free container storing photo metadata and image BLOBs; reached by the application over the Compose network. |

The Maven build contains one application module. Docker Compose defines the application and database containers; the database is an image-based dependency, not a source-built service.

## API Endpoints Inventory

| Service | Method | Path | Request Type | Response Type |
|---|---|---|---|---|
| Photo Album Java — `HomeController` | GET | `/` | No body; optional MVC `Model` populated by the controller | HTTP 200, rendered `index` HTML view with photo data; on retrieval error, renders the view with an empty list |
| Photo Album Java — `HomeController` | POST | `/upload` | Multipart form field `files` containing one or more uploaded files | JSON map containing `success`, `uploadedPhotos`, and `failedUploads`; HTTP 400 for no files, HTTP 200 for processed uploads, including partial failures; HTTP 401 when unauthenticated |
| Photo Album Java — `DetailController` | GET | `/detail/{id}` | Path parameter `id` | HTTP 200, rendered `detail` HTML view; redirects to `/` when the photo is absent or an error occurs |
| Photo Album Java — `DetailController` | POST | `/detail/{id}/delete` | Path parameter `id`; no body | Redirect to `/` with a flash success/error message; HTTP 401 when unauthenticated |
| Photo Album Java — `PhotoFileController` | GET | `/photo/{id}` | Path parameter `id` | HTTP 200 with image bytes and the stored media type; HTTP 404 if unavailable; HTTP 500 on an unexpected error |

No explicit API versioning scheme was found. The routes are implemented with Spring MVC controllers; `/upload` is the only route returning a JSON response rather than an HTML view or binary content.

## Management & Observability Endpoints

| Service | Endpoint | Custom Metrics (if any) |
|---|---|---|
| Photo Album Java | No Actuator, health, metrics, or management endpoint was found. | None found |
| Oracle Database | Container health check is configured in Docker Compose; no HTTP management endpoint is exposed by this application. | None found |

## DTOs & Contracts

- `Photo` is the mutable JPA entity and is also added to MVC models for the gallery and detail views. Its persistence structure is documented separately in `data-architecture.md`.
- `UploadResult` is a mutable service-layer result object used to communicate per-file upload success or failure to the controller; it is not directly serialized as the HTTP response.
- The upload response is assembled from Java `Map` instances rather than a dedicated response DTO. Each successful item contains photo metadata, and each failed item contains a filename and error message.
- No dedicated request DTO is defined; upload input is Spring's `MultipartFile` binding. The `id` values are path parameters.
- No immutable DTOs were found. JSON responses use Spring Boot/Jackson serialization, while gallery and detail responses use Thymeleaf templates.
- No OpenAPI/Swagger specification, protobuf schema, or GraphQL schema was found.

## Communication Patterns

- **Synchronous:** The browser calls the Spring MVC application over HTTP. Controllers call `PhotoService` directly; `PhotoServiceImpl` calls `PhotoRepository` via Spring Data JPA/JDBC to Oracle. Photo metadata and binary content are stored in the database.
- **Asynchronous:** No message broker, event-driven communication, or asynchronous service calls were found.
- **Resilience:** No retry, circuit-breaker, timeout, or bulkhead policy was found. Errors are handled locally in some controller/service paths (including upload result errors, redirects, and HTTP 404/500 responses); no downstream-service fallback policy exists.
- **Discovery and gateway:** There is no service registry, client-side load balancing, or API gateway. Compose's internal `oracle-db` hostname is used for database connectivity.
- **Startup dependency:** Compose starts the application after the Oracle container reports healthy. This affects whether the application can start and access the database; operational probe and wait details are maintained in `configuration-inventory.md`.
- **Security:** Spring Security configures stateless HTTP Basic authentication for `POST /upload` and `POST /detail/*/delete`; other routes are permitted anonymously. There is no application-level role check beyond requiring authentication on those state-changing routes. CSRF is disabled. No TLS/HTTPS configuration was found, so transport encryption is not configured in the application.

## Service Technology Matrix

| Service | Web | Data Access | Discovery | Gateway | Actuator | Cache | Metrics |
|---|---|---|---|---|---|---|---|
| Photo Album Java | Spring MVC, Thymeleaf | Spring Data JPA | None | None | None found | None found | None found |
| Oracle Database | None | Oracle Database | None | None | Compose health check only | N/A | None found |

## Service Communication Sequence

The upload path illustrates the main state-changing request flow. Authentication is enforced before the controller receives the request; successful uploads are saved through the local service/repository chain.

```mermaid
sequenceDiagram
    participant Client as "Browser"
    participant Security as "Spring Security"
    participant Controller as "HomeController"
    participant Service as "PhotoService"
    participant Repository as "PhotoRepository"
    participant DB as "Oracle Database"

    Client->>Security: POST /upload with multipart files and HTTP Basic
    alt Authenticated
        Security->>Controller: Forward upload request
        loop Each uploaded file
            Controller->>Service: uploadPhoto(file)
            Service->>Service: Check file type and size; read image metadata
            Service->>Repository: Save Photo and image bytes
            Repository->>DB: Synchronous database write
            DB-->>Repository: Persisted Photo
            Repository-->>Service: Photo with ID
            Service-->>Controller: UploadResult
            Controller->>Service: getPhotoById(photoId)
            Service->>Repository: findById(photoId)
            Repository->>DB: Synchronous database read
            DB-->>Repository: Photo
            Repository-->>Service: Optional Photo
            Service-->>Controller: Optional Photo
        end
        Controller-->>Client: 200 JSON with uploadedPhotos and failedUploads
    else Unauthenticated
        Security-->>Client: 401 Unauthorized
    end
```
