# Configuration & Externalized Settings Inventory

The project uses Spring properties, a Docker Compose environment, and a git-ignored `.env` file populated from an example for database and administrator credentials. It has separate Docker and test runtime profiles; no remote configuration service or secret manager is configured.

## Configuration Sources

| Source | Type | Path/Location | Notes |
|---|---|---|---|
| Spring application configuration | Properties | `src/main/resources/application.properties` | Base settings, including Oracle connection placeholders and application defaults. |
| Spring Docker profile configuration | Properties | `src/main/resources/application-docker.properties` | Overrides logging levels; also repeats several base settings. |
| Spring test profile configuration | Properties | `src/test/resources/application-test.properties` | H2 in-memory database, test-only credentials, and test upload path. |
| Docker Compose | YAML | `docker-compose.yml` | Sets container environment variables, port mappings, persistent volume, network, health check, and database dependency. |
| Docker image build/runtime | Dockerfile | `Dockerfile` | Maven/Java image versions, exposed port, and JVM options. |
| Local deployment environment | Environment file template | `.env.example` (copied to git-ignored `.env`) | Supplies Oracle administrator, application schema, and application administrator credentials. Actual `.env` values are not inventoried. |
| Oracle initialization | SQL/shell | `oracle-init/01-create-user.sql`, `oracle-init/create-user.sh`, `oracle-init/02-verify-user.sql`, `oracle-init/healthcheck.sql` | Initialization scripts; credential-bearing values are passed through environment variables rather than embedded in the SQL source. |
| Maven project configuration | XML | `pom.xml` | Declares Spring Boot parent, Java version, dependencies, and packaging plugin. |

No Spring Cloud Config repository, Azure/AWS configuration service, Vault, or dedicated secret store reference was found. GitHub Actions repository secrets are used by repository automation workflows, not by the application's runtime configuration.

## Build Profiles

| Profile | Activation | Purpose | Key Dependencies/Plugins |
|---|---|---|---|
| Default Maven build | Automatic; no Maven profiles are declared in `pom.xml` | Compiles and packages the executable application JAR. | Spring Boot Maven plugin; application dependencies are declared in the main dependency set. |
| Docker build | Docker build invocation; `Dockerfile` runs `mvn clean package -DskipTests` | Builds the application in a Maven builder image before copying the JAR into the runtime image. | `maven:3.9.6-eclipse-temurin-8`; no profile-specific dependencies. |

## Runtime Profiles

| Profile | Activation Method | Config Files | Key Overrides |
|---|---|---|---|
| Default | Spring default when no profile is active | `src/main/resources/application.properties` | Oracle connection defaults and base logging settings. |
| `docker` | `SPRING_PROFILES_ACTIVE=docker` in Compose | `application.properties`, `application-docker.properties` | Compose-provided Oracle URL/user/password; application log level `INFO`, web log level `WARN`, Hibernate SQL log level `DEBUG`. |
| `test` | `@ActiveProfiles("test")` on `PhotoAlbumApplicationTests` | `application.properties`, `src/test/resources/application-test.properties` | H2 in-memory database; test-only admin credentials and upload path; SQL display disabled. |

Spring combines the active profile with base configuration. Compose activates only `docker`; the test class activates only `test`. No profile-specific config for production or profile combinations was found.

## Properties Inventory

### Application

| Property Key | Default | Profiles | Source |
|---|---|---|---|
| `server.port` | `8080` | default, docker | `application.properties`; repeated in `application-docker.properties` |
| `server.servlet.encoding.charset` | `UTF-8` | default, docker | Base and Docker properties |
| `server.servlet.encoding.enabled` | `true` | default, docker | Base and Docker properties |
| `server.servlet.encoding.force` | `true` | default, docker | Base and Docker properties |
| `spring.servlet.multipart.max-file-size` | `10MB` | default, docker | Base and Docker properties |
| `spring.servlet.multipart.max-request-size` | `50MB` | default, docker | Base and Docker properties |
| `app.file-upload.max-file-size-bytes` | `10485760` (10 MiB) | default, docker, test | Base, Docker, and test properties; repeated in Docker properties |
| `app.file-upload.allowed-mime-types` | `image/jpeg,image/png,image/gif,image/webp` | default, docker, test | Base, Docker, and test properties; repeated in Docker properties |
| `app.file-upload.max-files-per-upload` | `10` | default, docker, test | Base, Docker, and test properties; repeated in Docker properties |
| `app.file-upload.upload-path` | Not set in base/Docker configuration | test | `application-test.properties`: `target/test-uploads` |
| `app.admin.username` | `admin` via `@Value` default; Compose can override with `APP_ADMIN_USERNAME` | default, docker | `SecurityConfig`; Compose variable defaults to `admin`; test profile sets `admin` |
| `app.admin.password` | Required in application configuration; no source-code default | default, docker | `SecurityConfig`; Compose requires `APP_ADMIN_PASSWORD`; test profile uses a test-only value |

### Database

| Property Key | Default | Profiles | Source |
|---|---|---|---|
| `spring.datasource.url` | `jdbc:oracle:thin:@oracle-db:1521/FREEPDB1`, overridden by `SPRING_DATASOURCE_URL` | default, docker | Base and Docker properties; Compose supplies the container hostname URL |
| `spring.datasource.username` | `photoalbum`, overridden by `SPRING_DATASOURCE_USERNAME` | default, docker | Base and Docker properties; Compose uses `APP_USER` (default `photoalbum`) |
| `spring.datasource.password` | Required from `SPRING_DATASOURCE_PASSWORD` | default, docker | Base and Docker properties; Compose maps `APP_USER_PASSWORD` to the Spring variable |
| `spring.datasource.driver-class-name` | `oracle.jdbc.OracleDriver` | default, docker | Base and Docker properties |
| `spring.jpa.database-platform` | `org.hibernate.dialect.OracleDialect` | default, docker | Base and Docker properties |
| `spring.jpa.hibernate.ddl-auto` | `create` | default, docker | Base and Docker properties |
| `spring.jpa.show-sql` | `true` | default, docker | Base and Docker properties |
| `spring.jpa.properties.hibernate.format_sql` | `true` | default, docker | Base and Docker properties |
| `spring.datasource.url` | `jdbc:h2:mem:testdb` | test | `application-test.properties` |
| `spring.datasource.driver-class-name` | `org.h2.Driver` | test | `application-test.properties` |
| `spring.datasource.username` | `sa` | test | `application-test.properties` |
| `spring.datasource.password` | Empty | test | `application-test.properties` |
| `spring.jpa.database-platform` | `org.hibernate.dialect.H2Dialect` | test | `application-test.properties` |
| `spring.jpa.hibernate.ddl-auto` | `create-drop` | test | `application-test.properties` |
| `spring.jpa.show-sql` | `false` | test | `application-test.properties` |

### Logging

| Property Key | Default | Profiles | Source |
|---|---|---|---|
| `logging.level.com.photoalbum` | `DEBUG` | default, test; `INFO` in docker | Base, test, and Docker properties |
| `logging.level.org.springframework.web` | `DEBUG` | default; `WARN` in docker | Base and Docker properties |
| `logging.level.org.hibernate.SQL` | Not set in base; `DEBUG` in docker | docker | `application-docker.properties` |

## Startup Parameters & Resource Requirements

| Service | JVM/Runtime Options | Memory | Instance Count |
|---|---|---|---|
| `photoalbum-java-app` | `JAVA_OPTS="-Xmx512m -Xms256m"`; Compose sets `SPRING_PROFILES_ACTIVE=docker` and database/admin environment overrides | JVM heap initial 256 MiB, maximum 512 MiB; container memory limit not specified | One Compose service/container declared; scaling not configured |
| `oracle-db` | Oracle container environment variables; no JVM options specified | Not specified | One Compose service/container declared; scaling not configured |

No CPU allocation, container memory limit, or cloud resource sizing configuration was found.

## Startup Dependency Chain

1. `oracle-db` starts first; Compose health check runs `healthcheck.sh` every 30 seconds, with a 10-second timeout, 15 retries, and a 180-second start period.
2. `photoalbum-java-app` waits for `oracle-db` to be healthy through Compose `depends_on: condition: service_healthy`; it then starts with the `docker` Spring profile.

No application-container health check or explicit Spring database connection retry/startup timeout was found.

## Secrets & Sensitive Configuration

| Secret Reference | Type | Storage (masked) |
|---|---|---|
| `ORACLE_PASSWORD` | Oracle administrator password | Local git-ignored `.env`, passed to Oracle container; `[MASKED]` |
| `APP_USER_PASSWORD` | Application database schema password | Local git-ignored `.env`, passed to Oracle and mapped to `SPRING_DATASOURCE_PASSWORD`; `[MASKED]` |
| `APP_ADMIN_PASSWORD` | Application administrator password | Local git-ignored `.env`, passed as an application environment variable; `[MASKED]` |
| `spring.datasource.password` / `SPRING_DATASOURCE_PASSWORD` | Spring datasource credential | Environment-variable reference; required, `[MASKED]` |
| Test `spring.datasource.password` | H2 test credential | Empty test-only value |
| Test `app.admin.password` | Test administrator credential | `application-test.properties`; test-only value, `[MASKED]` |

### Secrets Provisioning Workflow

Copy `.env.example` to `.env`, replace all placeholder values with strong unique credentials, and run Docker Compose. Compose requires `ORACLE_PASSWORD`, `APP_USER_PASSWORD`, and `APP_ADMIN_PASSWORD`; it forwards the Oracle administrator and schema credentials to the database container and maps the schema/admin credentials into the application container. `.env` is documented as git-ignored and must not be committed. No managed identity, service principal, RBAC setup, encrypted property mechanism, or external secret manager is configured. Test credentials are isolated in test resources.

## Feature Flags

No feature-flag framework, application feature toggle, conditional Spring configuration, or rollout flag was found.

| Flag Name | Default | Controlled By |
|---|---|---|
| None identified | N/A | N/A |

## Framework & Runtime Versions

| Component | Version | Source |
|---|---|---|
| Spring Boot | `2.7.18` | `pom.xml` parent |
| Java source/target | `8` | `pom.xml` |
| Maven | `3.9.6` in Docker build image | Dockerfile base image |
| Java build runtime | Eclipse Temurin 8 | `maven:3.9.6-eclipse-temurin-8` Docker image |
| Java application runtime | Eclipse Temurin 8 JRE | `eclipse-temurin:8-jre` Docker image |
| Oracle JDBC driver | `ojdbc8`; resolved version managed by Spring Boot dependency management | `pom.xml`; no explicit version declared |
| H2 | Version managed by Spring Boot dependency management | `pom.xml`, test scope |
| Commons IO | `2.11.0` | `pom.xml` |
| Oracle Database Free image | `latest` tag (version not pinned) | `docker-compose.yml` |
