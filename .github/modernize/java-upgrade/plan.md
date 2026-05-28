# Upgrade Plan: PhotoAlbum-Java (001-upgrade-spring-boot-3)

- **Generated**: 2025-07-14
- **HEAD Branch**: modernize
- **HEAD Commit ID**: c8768e1

## Available Tools

**JDKs**
- JDK 25.0.2: C:\Users\rujche\Work\Softwares\jdk-25.0.2+10 (system JDK — used for all steps; supports `--release 21` target)
- JDK 8: not available (baseline will be skipped)

**Build Tools**
- Maven 3.9.10: C:\Users\rujche\Work\Softwares\apache-maven-3.9.10

## Guidelines

> Note: This upgrade runs in fully autonomous mode. No user confirmation is required.

- Upgrade Spring Boot from 2.7.18 to latest 3.x release
- Upgrade Java source/target from 8 to 21
- Migrate all javax.* imports to jakarta.* equivalents
- Update Dockerfile base image from eclipse-temurin:8 to eclipse-temurin:21
- Ensure project builds and all tests pass

## Options

- Working branch: modernize (pre-existing branch used)
- Run tests before and after the upgrade: true

## Upgrade Goals

1. Spring Boot: 2.7.18 → 3.5.x (latest 3.x)
2. Java: 8 → 21
3. Spring Framework: 5.x → 6.x (derived from Spring Boot 3.x)
4. Jakarta EE: javax.* → jakarta.* namespace migration

## Technology Stack

| Technology/Dependency     | Current  | Min Compatible | Why Incompatible                                           |
| ------------------------- | -------- | -------------- | ---------------------------------------------------------- |
| Java                      | 8        | 21             | User requested; Spring Boot 3.x requires Java 17+          |
| Spring Boot               | 2.7.18   | 3.5.x          | User requested; EOL                                        |
| Spring Framework          | 5.3.x    | 6.1.x          | Derived from Spring Boot 3.x                               |
| jakarta.persistence (JPA) | javax.*  | jakarta.*      | Spring Boot 3.x uses Jakarta EE 10 (jakarta.* namespace)  |
| jakarta.validation        | javax.*  | jakarta.*      | Spring Boot 3.x uses Jakarta EE 10                        |
| ojdbc8                    | managed  | same           | Compatible with Java 21, no change needed                  |
| h2                        | managed  | 2.x            | Spring Boot 3.x manages H2 2.x                            |
| Maven                     | 3.9.10   | 3.9+           | Already compatible                                         |

## Derived Upgrades

- **Spring Framework 6.x**: Required by Spring Boot 3.x (auto-managed by parent BOM)
- **Hibernate 6.x**: Required by Spring Boot 3.x/Data JPA 3.x (auto-managed by BOM)
- **Jakarta EE 10 namespace**: Spring Boot 3.x / Hibernate 6.x require `jakarta.*` instead of `javax.*`
- **Java 21**: Spring Boot 3.x requires minimum Java 17; upgrading to 21 as requested

## Impact Analysis

### Dependency Changes

| File    | Dependency                     | Current | Action  | Target | Reason                                      |
| ------- | ------------------------------ | ------- | ------- | ------ | ------------------------------------------- |
| pom.xml | spring-boot-starter-parent     | 2.7.18  | upgrade | 3.5.3  | User requested; EOL                         |
| pom.xml | java.version                   | 1.8     | upgrade | 21     | User requested                              |
| pom.xml | maven.compiler.source          | 8       | upgrade | 21     | User requested                              |
| pom.xml | maven.compiler.target          | 8       | upgrade | 21     | User requested                              |

### Source Code Changes

| File                      | Location        | Current                   | Required Change                        | Reason                             |
| ------------------------- | --------------- | ------------------------- | -------------------------------------- | ---------------------------------- |
| model/Photo.java          | import line 3   | `import javax.persistence.*` | Replace with `import jakarta.persistence.*` | Jakarta EE 10 namespace        |
| model/Photo.java          | import line 4-7 | `import javax.validation.constraints.*` | Replace with `import jakarta.validation.constraints.*` | Jakarta EE 10 namespace |

### Configuration Changes

| File                           | Property/Setting                         | Current                              | Required Change                              | Reason                        |
| ------------------------------ | ---------------------------------------- | ------------------------------------ | -------------------------------------------- | ----------------------------- |
| application-test.properties    | spring.jpa.database-platform             | org.hibernate.dialect.H2Dialect      | No change needed (still valid in Hibernate 6) | —                            |

### CI/CD Changes

| File       | Location       | Current                         | Required Change                           |
| ---------- | -------------- | ------------------------------- | ----------------------------------------- |
| Dockerfile | FROM line 2    | maven:3.9.6-eclipse-temurin-8   | maven:3.9.6-eclipse-temurin-21            |
| Dockerfile | FROM line 17   | eclipse-temurin:8-jre           | eclipse-temurin:21-jre                    |

### Risks & Warnings

- **Hibernate 6 @Lob behavior change**: In Hibernate 6 (used by Spring Boot 3.x), `@Lob byte[]` maps to BLOB — this is unchanged behavior for Oracle but the DDL generation may differ. Since the test uses `create-drop` with H2, this may be transparent.
- **Oracle-specific native queries in PhotoRepository**: These queries use ROWNUM, NVL, and Oracle analytical functions. They will fail at runtime against H2, but the context-load test doesn't call them, so the test should pass.
- **ojdbc8 with Java 21**: ojdbc8 is designed for Java 8 but is certified to work with Java 21. Spring Boot 3.x BOM includes a compatible ojdbc version (ojdbc11 is newer but ojdbc8 continues to work).

## Upgrade Steps

- Step 1: Setup Environment
  - **Rationale**: Verify available JDKs and build tools
  - **Changes to Make**: None — JDK 25 is available and supports `--release 21` target
  - **Verification**: `java -version`, Expected: JDK available

- Step 2: Setup Baseline
  - **Rationale**: The original JDK 8 is not available, baseline will be skipped
  - **Changes to Make**: None
  - **Verification**: Skipped (JDK 8 not available)

- Step 3: Upgrade Spring Boot 3.x + Migrate javax → jakarta
  - **Rationale**: Core upgrade — update parent BOM, Java version properties, and migrate Jakarta EE namespace
  - **Changes to Make**:
    - pom.xml: Spring Boot 2.7.18 → 3.5.3, java.version 1.8 → 21, compiler source/target 8 → 21
    - Photo.java: javax.persistence.* → jakarta.persistence.*, javax.validation.* → jakarta.validation.*
    - Dockerfile: update base images to eclipse-temurin:21
  - **Verification**: `mvn clean test-compile -q`, JDK 25 (with --release 21 target), Expected: Compilation SUCCESS

- Step 4: Final Validation
  - **Rationale**: Ensure all tests pass and upgrade goals are met
  - **Changes to Make**: Fix any test failures discovered
  - **Verification**: `mvn clean test`, JDK 25, Expected: All tests pass
