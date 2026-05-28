# Modernization Plan: PhotoAlbum-Java Azure Migration

**Project**: Photo Album

---

## Technical Framework

- **Language**: Java 1.8 (upgrading to Java 21)
- **Framework**: Spring Boot 2.7.18 (upgrading to Spring Boot 3.x)
- **Build Tool**: Maven
- **Database**: Oracle Database (migrating to Azure Database for PostgreSQL)
- **Key Dependencies**: Spring Data JPA, Spring Web, Thymeleaf, Oracle JDBC (ojdbc8)

---

## Overview

> This migration modernizes the Photo Album application from a legacy Java 8 / Spring Boot 2.x stack running against Oracle Database to a cloud-native Java 21 / Spring Boot 3.x application hosted on Azure Container Apps with Azure Database for PostgreSQL. The application currently uses hardcoded database credentials and Oracle-specific SQL/JPA configuration. The new architecture will:
>
> - Upgrade the runtime from Java 8 and Spring Boot 2.7.18 (both end-of-support) to Java 21 and Spring Boot 3.x, including the migration from `javax.*` to `jakarta.*` namespaces
> - Replace Oracle Database with Azure Database for PostgreSQL, enabling a fully managed, cloud-native relational database
> - Eliminate hardcoded database passwords by enabling passwordless authentication using Azure Managed Identity
> - Deploy the containerized application to Azure Container Apps for scalable, serverless cloud hosting
> - Scan and remediate known CVE vulnerabilities in project dependencies
>
> The migration follows a phased approach: upgrade first, then migrate services, then harden security, and finally deploy to Azure.

---

## Migration Impact Summary

| Application   | Original Service      | New Azure Service                  | Authentication    | Comments                                     |
|---------------|-----------------------|------------------------------------|-------------------|----------------------------------------------|
| Photo Album   | Oracle Database       | Azure Database for PostgreSQL      | Managed Identity  | Migrate schema, SQL syntax, and JDBC config  |
| Photo Album   | Hardcoded credentials | Azure Managed Identity (passwordless) | Managed Identity | Remove plaintext DB password from properties |

---

## Tasks

### Task 1 — Upgrade to Spring Boot 3.x / Java 21

Upgrade the application from Spring Boot 2.7.18 / Java 8 to Spring Boot 3.x / Java 21. This includes upgrading Spring Framework to 6.x and migrating all `javax.*` imports to `jakarta.*` namespaces as required by Jakarta EE.

### Task 2 — Migrate Oracle Database to Azure Database for PostgreSQL

Replace the Oracle JDBC driver and Oracle-specific SQL/JPA configuration with PostgreSQL equivalents. Migrate the data model and any Oracle-specific SQL syntax to PostgreSQL-compatible syntax.

### Task 3 — Enable Managed Identity for PostgreSQL

Remove the plaintext database password from configuration files and configure passwordless authentication to Azure Database for PostgreSQL using Azure Managed Identity via Spring Cloud Azure.

### Task 4 — Security / CVE Remediation

Scan all project dependencies for known CVEs and remediate identified vulnerabilities by upgrading to patched versions, ensuring the application builds and all tests pass after remediation.

### Task 5 — Deploy to Azure Container Apps

Containerize the application and deploy it to Azure Container Apps, updating the Dockerfile from Java 8 to Java 21 and configuring the application for cloud-native operation (environment-variable-driven port configuration, console logging).

---

## Open Questions & Questionnaire

- [x] Q: Which Spring Boot version should the upgrade target? → A: Spring Boot 3.x with Java 21 (widely adopted LTS upgrade path)
- [x] Q: Which Azure deployment target should be used? → A: Azure Container Apps
- [x] Q: Which Azure database service should Oracle be migrated to? → A: Azure Database for PostgreSQL
- [x] Q: Should the plan include environment/infrastructure provisioning? → A: No — focus on code migration and deployment only
- [x] Q: Should the plan include security/CVE remediation? → A: Yes — include security/CVE remediation (default)
- [x] Q: Should the plan include integration testing? → A: No — integration testing not requested
