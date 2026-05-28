# Modernization Assessment Summary

**Target Azure Services**: Azure App Service, Azure Kubernetes Service, Azure Container Apps

## Overall Statistics

**Total Applications**: 1

**Name: photo-album**
- Mandatory: 3 issues
- Potential: 5 issues
- Optional: 1 issues

> **Severity Levels Explained:**
> - **Mandatory**: The issue has to be resolved for the migration to be successful.
> - **Potential**: This issue may be blocking in some situations but not in others. These issues should be reviewed to determine whether a change is required or not.
> - **Optional**: The issue discovered is real issue fixing which could improve the app after migration, however it is not blocking.

## Applications Profile

### Name: photo-album
- **JDK Version**: 1.8
- **Frameworks**: Spring Boot, Spring
- **Languages**: Java, JavaScript
- **Build Tools**: Maven

**Key Findings**:
- **Mandatory Issues (11 locations)**:
  - <!--ruleid=spring-framework-version-01000-->Spring Framework Version Has Reached the End of OSS Support (3 locations found)
  - <!--ruleid=azure-java-version-01000-->Java Version Has Reached the End of Support (1 location found)
  - <!--ruleid=spring-boot-to-azure-spring-boot-version-01000-->Spring Boot Version Has Reached the End of OSS Support (7 locations found)
- **Potential Issues (14 locations)**:
  - <!--ruleid=azure-database-microsoft-oracle-07000-->Oracle database found (6 locations found)
  - <!--ruleid=azure-password-01000-->Password found in configuration file (3 locations found)
  - <!--ruleid=spring-boot-to-azure-port-01000-->Server port configuration found (2 locations found)
  - <!--ruleid=spring-boot-to-azure-restricted-config-01000-->Restricted configurations found (2 locations found)
  - <!--ruleid=jakarta-database-00002-->Detects usage of Jakarta Persistence (JPA) APIs (1 location found)
- **Optional Issues (2 locations)**:
  - <!--ruleid=azure-java-version-02000-->Java Version is not the latest LTS (2 locations found)

## Next Steps

For comprehensive migration guidance and best practices, visit:
- [GitHub Copilot modernization](https://aka.ms/ghcp-appmod)

Have questions or suggestions? [Share your feedback](https://aka.ms/ghcp-appmod/feedback)
