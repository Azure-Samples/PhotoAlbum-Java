# Modernization Summary: Oracle to PostgreSQL Migration

**Task ID**: 002-transform-oracle-to-postgresql  
**Skill**: migration-oracle-to-postgresql  
**Status**: Completed

## Overview

Migrated the PhotoAlbum application database layer from Oracle Database to Azure Database for PostgreSQL. All Oracle-specific code, configuration, and SQL syntax have been fully removed and replaced with PostgreSQL equivalents. Managed identity (passwordless) authentication is configured for Azure deployments.

## Changes Made

### 1. `pom.xml`
- Removed Oracle JDBC driver dependency (`com.oracle.database.jdbc:ojdbc8`)
- Added PostgreSQL JDBC driver (`org.postgresql:postgresql`)
- Added `spring-cloud-azure-dependencies` BOM (version 5.22.0, compatible with Spring Boot 3.x)
- Added `com.azure.spring:spring-cloud-azure-starter-jdbc-postgresql` for Azure managed identity support
- Updated project description from "Oracle DB" to "PostgreSQL"

### 2. `src/main/resources/application.properties`
- Replaced Oracle datasource URL with Azure Database for PostgreSQL URL using environment variables
- Replaced `oracle.jdbc.OracleDriver` with PostgreSQL driver (managed by Spring auto-configuration)
- Replaced `OracleDialect` with `PostgreSQLDialect`
- Removed hardcoded Oracle credentials; configured passwordless authentication using Azure Managed Identity
- Added detailed comments for:
  - Managed identity configuration
  - Service principal authentication alternative
  - Azure sovereign cloud deployment guidance

### 3. `src/main/resources/application-docker.properties`
- Replaced Oracle datasource URL with local PostgreSQL container URL (`jdbc:postgresql://postgres-db:5432/photoalbum`)
- Replaced Oracle driver class with `org.postgresql.Driver`
- Replaced `OracleDialect` with `PostgreSQLDialect`
- Updated comment from "Oracle DB" to "local PostgreSQL container"

### 4. `docker-compose.yml`
- Removed Oracle Database service (`gvenzl/oracle-free:latest`) and `oracle-init` volume mount
- Added PostgreSQL 16 service (`postgres:16`) with:
  - Database/user/password environment variables
  - Persistent volume `postgres_data`
  - Health check using `pg_isready`
  - Faster startup (30s start period vs 180s for Oracle)
- Updated application service datasource environment variables to PostgreSQL JDBC URL
- Replaced `oracle_data` volume with `postgres_data`

### 5. `src/main/java/com/photoalbum/model/Photo.java`
- Removed Oracle-specific `columnDefinition = "NUMBER(19,0)"` from `fileSize` field (Hibernate uses BIGINT for `Long` by default in PostgreSQL)
- Removed Oracle-specific `columnDefinition = "TIMESTAMP DEFAULT SYSTIMESTAMP"` from `uploadedAt` field
- Updated Javadoc comment from "stored directly in Oracle database" to "stored in the database"

### 6. `src/main/java/com/photoalbum/repository/PhotoRepository.java`
- Converted all native SQL queries from Oracle to PostgreSQL syntax:
  - **`findAllOrderByUploadedAtDesc`**: Converted identifiers from uppercase to lowercase
  - **`findPhotosUploadedBefore`**: Replaced Oracle `ROWNUM`-based top-N with PostgreSQL `LIMIT 10`
  - **`findPhotosUploadedAfter`**: Replaced Oracle `NVL()` with PostgreSQL `COALESCE()`; converted identifiers to lowercase
  - **`findPhotosByUploadMonth`**: Kept `TO_CHAR()` (supported in PostgreSQL); converted identifiers to lowercase; updated method Javadoc to remove "Oracle specific" label
  - **`findPhotosWithPagination`**: Replaced Oracle dual-ROWNUM pagination with PostgreSQL `ROW_NUMBER() OVER (ORDER BY ...)` window function subquery; converted identifiers to lowercase
  - **`findPhotosWithStatistics`**: Converted window functions `RANK()` and `SUM()` identifiers to lowercase (window functions are natively supported in PostgreSQL); updated Javadoc to remove "Oracle specific" label

## SQL Conversions Reference

| Oracle Pattern | PostgreSQL Equivalent |
|---|---|
| `ROWNUM <= N` (top-N) | `LIMIT N` |
| Nested `ROWNUM` pagination | `ROW_NUMBER() OVER (...)` subquery |
| `NVL(expr, default)` | `COALESCE(expr, default)` |
| `TIMESTAMP DEFAULT SYSTIMESTAMP` | Standard `TIMESTAMP` (default via application) |
| `NUMBER(19,0)` column type | `BIGINT` (Hibernate default for `Long`) |
| Uppercase identifiers (e.g., `FROM PHOTOS`) | Lowercase identifiers (e.g., `FROM photos`) |

## Build & Test Results

- ✅ `mvn clean package -DskipTests` — BUILD SUCCESS
- ✅ `mvn test` — Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
- ✅ Consistency check — No Critical or Major issues found
