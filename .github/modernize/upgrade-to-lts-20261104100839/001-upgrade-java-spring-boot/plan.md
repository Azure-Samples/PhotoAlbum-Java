# Upgrade Plan: PhotoAlbum-Java (001-upgrade-java-spring-boot)

- **Generated**: 2026-11-04 11:15 +01:00
- **HEAD Branch**: N/A (version-control MCP operation unavailable)
- **HEAD Commit ID**: N/A (version-control MCP operation unavailable)

## Available Tools

**JDKs**
- JDK 8: not available locally (baseline may be attempted in Docker image `maven:3.9.6-eclipse-temurin-8`)
- JDK 25: use Docker image `maven:3.9.11-eclipse-temurin-25` (not installed locally)

**Build Tools**
- Docker CLI 29.8.1: available; Docker image supplies Maven 3.9.11
- Maven Wrapper: absent

## Guidelines
- Upgrade to Java 25, Spring Boot 4.x, Spring Framework 7.x, and use Jakarta APIs where required.
- Fully automatic execution; do not pause for approval.
> Note: You can add any specific guidelines or constraints for the upgrade process here if needed, bullet points are preferred.
- Version-control MCP is unavailable in this environment; source changes will remain uncommitted.

## Options

- Working branch: N/A (version-control MCP operation unavailable)
- Run tests before and after the upgrade: true

## Upgrade Goals
- Java 25
- Spring Boot 4.x (selected stable release 4.1.2)
- Spring Framework 7.x (managed by Spring Boot 4.1.2)
- Migrate Java EE APIs from `javax.*` to `jakarta.*` where applicable

## Technology Stack

| Technology/Dependency | Current | Min Compatible Version | Why Incompatible |
| --------------------- | ------- | ---------------------- | ---------------- |
| Java | 8 | 25 | User requested; Boot 4 requires Java 17+ |
| Spring Boot parent | 2.7.18 | 4.1.2 | User requested; Boot 4 aligns Jakarta EE and Spring Framework 7 |
| Spring Framework | 5.3.x (Boot-managed) | 7.x (Boot 4.1.2 managed) | Framework 7 is requested |
| `javax.persistence` / `javax.validation` | Java EE namespaces | `jakarta.persistence` / `jakarta.validation` | Boot 4/Hibernate 7 use Jakarta APIs |
| Spring Security config | legacy chained DSL | Security 7 lambda DSL | Legacy `authorizeRequests`/`antMatchers` APIs removed |
| Oracle JDBC `ojdbc8` | Boot-managed | `ojdbc11` | Java 11+ driver appropriate for Java 25 |
| Maven | not installed locally; no wrapper | 3.9.11 in Docker | Reproducible Java 25 build environment |
| Docker build/runtime base | Temurin 8 | Temurin 25 | Runtime/build image must match application target |
| Documentation | states Boot 2.7.18 / Java 8 | Boot 4.1.2 / Java 25 | Prevent stale usage guidance |

## Derived Upgrades
- Spring Boot 4.1.2 manages Spring Framework 7.x, Security 7, Jakarta EE APIs, and Hibernate 7; use its dependency management.
- Java 25 requires updating Maven compiler release and the container build/runtime images.
- Replace Oracle's Java 8 JDBC driver with the Java 11+ `ojdbc11` driver for the Java 25 target.
- Security configuration must move to the supported Security 7 lambda DSL while preserving stateless Basic authentication and the same endpoint authorization.

## Impact Analysis

### Dependency Changes

| File | Dependency | Current | Action | Target | Reason |
|------|------------|---------|--------|--------|--------|
| `pom.xml` | `spring-boot-starter-parent` | 2.7.18 | upgrade | 4.1.2 | User requested Boot 4.x; stable version verified in Maven Central metadata |
| `pom.xml` | `spring-boot-starter-web` | Boot 2-era starter | replace | `spring-boot-starter-webmvc` | Boot 4 modular web starter |
| `pom.xml` | `spring-boot-starter-webmvc-test` | absent | add | 4.1.2 managed | Boot 4 separates MVC test support; required for `MockMvc` integration tests |
| `pom.xml` | `java.version`, `maven.compiler.source`, `maven.compiler.target` | 1.8 / 8 / 8 | upgrade | 25 / release 25 | User target |
| `pom.xml` | `ojdbc8` | Boot-managed | replace | `ojdbc11` 23.26.3.0.0 | Java 25 runtime uses JDBC 11+ driver line; Boot 4.1.2 manages this coordinate |
| `pom.xml` | `commons-io` explicit 2.11.0 | 2.11.0 | upgrade | 2.22.0 | Update explicit old pin to the current stable release |

### Source Code Changes

| File | Location | Current | Required Change | Reason |
|------|----------|---------|----------------|--------|
| `src/main/java/com/photoalbum/model/Photo.java` | imports | `javax.persistence.*`, `javax.validation.constraints.*` | Replace with `jakarta.persistence.*`, `jakarta.validation.constraints.*` | Jakarta migration |
| `src/main/java/com/photoalbum/service/impl/PhotoServiceImpl.java` | imports | `javax.imageio.*` | No change | `javax.imageio` is Java SE, not migrated Java EE |
| `src/main/java/com/photoalbum/config/SecurityConfig.java` | filter chain | chained `.csrf().disable()`, `authorizeRequests`, `antMatchers`, `.and()` | Use lambda DSL, `authorizeHttpRequests` and `requestMatchers` | Security 7 API compatibility; preserve endpoint rules and stateless Basic auth |
| `src/test/java/com/photoalbum/PhotoAlbumApplicationTests.java` | security behavior tests | context load only | Add MockMvc checks for authenticated mutation requests and public unmatched GET | Regression coverage for preserved access policy |

### Configuration Changes

No application property renames found in checked config files. JPA and servlet property namespaces are already Spring Boot names and remain applicable; validate at runtime via context test.

### CI/CD Changes

| File | Location | Current | Required Change |
|------|----------|---------|----------------|
| `Dockerfile` | build and runtime stages | Maven/Temurin 8 images | Use Maven 3.9.11 with Temurin 25 and Temurin 25 JRE |
| `README.md` | technology stack and application version references | Boot 2.7.18, Java 8 | Update to Boot 4.1.2 and Java 25 |

### Risks & Warnings
- **Boot 4 modular starter/dependency changes**: Starter artifacts and managed transitive versions may differ from Boot 2.7. **Mitigation**: compile/test in the Java 25 Maven container; use Boot-managed versions and make only compatibility-driven edits.
- **Security behavior**: DSL rewrite could alter authorization. **Mitigation**: preserve exact POST matchers, public read access, stateless sessions, HTTP Basic and CSRF setting; regression tests exercise the authorization behavior.
- **Oracle 11+ JDBC driver availability**: The Boot 4.1.2 BOM manages `ojdbc11`; resolved runtime version was verified as 23.26.3.0.0.
- Baseline verification ran in the Maven/Temurin 8 Docker image because the host has no local JDK 8 or Maven executable.
- CVE validation MCP tool is unavailable; inspect resolved dependencies and report that limitation rather than claiming a security scan.

## Upgrade Steps

- Step 1: Setup Environment
  - **Rationale**: Establish Docker-based Maven/JDK 25 build environment; local Java and Maven are absent.
  - **Changes to Make**: Pull/validate the Java 25 Maven image; no project files change.
  - **Verification**: `docker run --rm maven:3.9.11-eclipse-temurin-25 mvn -version`; expect Maven 3.9.11 and Java 25.
- Step 2: Setup Baseline
  - **Rationale**: Record pre-upgrade compilation/test status before edits.
  - **Changes to Make**: None.
  - **Verification**: In Docker, `mvn clean test-compile` then `mvn clean test` using Maven/Temurin 3.9.6/8; unavailable image/build means baseline skipped.
- Step 3: Upgrade Runtime, Dependencies, APIs, and Documentation
  - **Rationale**: Apply the coordinated Boot 4, Java 25, and Jakarta changes so the source remains compilable as a single step.
  - **Changes to Make**: Apply all Dependency, Source Code, Configuration, and CI/CD changes above.
  - **Verification**: `mvn clean test-compile -q` in Java 25 Docker container; expect all main and test code compiles.
- Step 4: Dependency and CVE Review
  - **Rationale**: Inspect final resolved direct/transitive dependency set after BOM migration.
  - **Changes to Make**: Fix any incompatible or vulnerable dependency versions identified; no dedicated CVE MCP scanner is exposed here.
  - **Verification**: `mvn dependency:tree` and `mvn clean test-compile -q`; report limitations of CVE scan.
- Step 5: Final Validation
  - **Rationale**: Demonstrate Java 25 compilation and full test pass.
  - **Changes to Make**: Resolve all compile/test failures.
  - **Verification**: `mvn clean test` (and packaging) in Java 25 container; all tests pass.