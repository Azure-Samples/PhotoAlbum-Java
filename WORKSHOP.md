# Photo Album Application - Migration Workshop

This document serves as a comprehensive workshop guide that will walk you through the process of migrating a Java application to Azure using GitHub Copilot app modernization. The workshop covers assessment, database migration from Oracle to PostgreSQL, containerization, and deployment to Azure.

**What the Migration Process Will Do:**
The migration will transform your application from using Oracle Database to a modern Azure-native solution. This includes migrating from Oracle Database to Azure Database for PostgreSQL Flexible Server with managed identity authentication, containerizing the application, and deploying it to Azure with proper monitoring and health checks.

## Table of Contents

- [Overview](#overview)
- [Current Architecture](#current-architecture)
- [Prerequisites](#prerequisites)
- [Workshop Steps](#workshop-steps)
  - [Step 1: Assess Your Java Application](#step-1-assess-your-java-application)
  - [Step 2: Migrate from Oracle to PostgreSQL](#step-2-migrate-from-oracle-to-postgresql)
  - [Step 3: Containerize the Application](#step-3-containerize-the-application)
  - [Step 4: Deploy to Azure](#step-4-deploy-to-azure)
- [Clean Up](#clean-up)
- [Troubleshooting](#troubleshooting)

## Overview

The Photo Album application is a Spring Boot web application that allows users to:
- Upload photos via drag-and-drop or file selection
- View photos in a responsive gallery
- View photo details with metadata
- Navigate between photos
- Delete photos

**Original State (Before Migration):**
* Oracle Database 21c Express Edition for photo storage
* Photos stored as BLOBs in Oracle Database
* Password-based authentication
* Running in Docker containers locally

**After Migration:**
* Azure Database for PostgreSQL Flexible Server
* Managed Identity passwordless authentication
* Containerized application
* Deployed to Azure Container Apps

**Time Estimates:**
The complete workshop takes approximately **1.5 hours** to complete. Here's the breakdown for each major step:
- **Assess Your Java Application**: ~5 minutes
- **Migrate from Oracle to PostgreSQL**: ~30 minutes
- **Containerize the Application**: ~15 minutes
- **Deploy to Azure**: ~40 minutes

## Current Architecture

### Technology Stack

- **Framework**: Spring Boot 3.5.0
- **Java Version**: 21
- **Database**: Oracle Database 21c Express Edition (to be migrated to PostgreSQL)
- **Templating**: Thymeleaf
- **Build Tool**: Maven
- **Frontend**: Bootstrap 5.3.0, Vanilla JavaScript
- **Storage**: Database BLOBs for photo data

### Database Schema

The application uses the following database structure:

#### PHOTOS Table
- `ID` (VARCHAR(36), Primary Key, UUID Generated)
- `ORIGINAL_FILE_NAME` (VARCHAR(255), Not Null)
- `FILE_SIZE` (NUMBER/BIGINT, Not Null)
- `MIME_TYPE` (VARCHAR(50), Not Null)
- `UPLOADED_AT` (TIMESTAMP, Not Null)
- `WIDTH` (NUMBER/INTEGER, Nullable)
- `HEIGHT` (NUMBER/INTEGER, Nullable)
- `PHOTO_DATA` (BLOB/BYTEA, Not Null)

## Prerequisites

Before starting this workshop, ensure you have:

### Required Software

- **Operating System**: Windows, macOS, or Linux
- **Java Development Kit (JDK)**: JDK 21 or higher
  - Download from [Microsoft OpenJDK](https://learn.microsoft.com/java/openjdk/download)
- **Maven**: 3.8.0 or higher
  - Download from [Apache Maven](https://maven.apache.org/download.cgi)
- **Docker Desktop**: Latest version
  - Download from [Docker](https://docs.docker.com/desktop/)
- **Git**: For version control
  - Download from [Git](https://git-scm.com/)

### IDE and Extensions

- **Visual Studio Code**: Version 1.101 or later
  - Download from [Visual Studio Code](https://code.visualstudio.com/)
- **GitHub Copilot**: Must be enabled in your GitHub account
  - [GitHub Copilot subscription](https://github.com/features/copilot) (Pro, Pro+, Business, or Enterprise)
- **VS Code Extensions** (Required):
  1. **GitHub Copilot** extension
     - Install from [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot)
     - Sign in to your GitHub account within VS Code
  2. **GitHub Copilot app modernization** extension
     - Install from [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=vscjava.migrate-java-to-azure)
     - Restart VS Code after installation

### Azure Requirements

- **Azure Account**: Active Azure subscription
  - [Create a free account](https://azure.microsoft.com/free/) if you don't have one
- **Azure CLI**: Latest version
  - Download from [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)

### Configuration

- Ensure `chat.extensionTools.enabled` is set to `true` in VS Code settings
- If using Gradle, only Gradle wrapper version 5+ is supported
- Access to public Maven Central repository for Maven-based projects

### Optional (for testing locally)

- **Oracle Database 21c XE** or **PostgreSQL** (if you want to test locally before Azure deployment)

## Workshop Steps

### Step 1: Assess Your Java Application

The first step is to assess the Photo Album application to identify migration opportunities and potential issues.

#### 1.1 Open the Project

1. Clone or open the Photo Album project in Visual Studio Code:

```bash
git clone <your-repository-url>
cd PhotoAlbum-Java
code .
```

> **📸 Screenshot Needed**: Screenshot of VS Code with the PhotoAlbum-Java project opened

#### 1.2 Install GitHub Copilot App Modernization Extension

1. Open the Extensions view in VS Code (`Ctrl+Shift+X` or `Cmd+Shift+X` on macOS)
2. Search for `GitHub Copilot app modernization`
3. Click **Install**
4. Restart VS Code if prompted

> **📸 Screenshot Needed**: Screenshot of the GitHub Copilot app modernization extension installation page

#### 1.3 Run Assessment

1. In the Activity sidebar, open the **GitHub Copilot app modernization** extension pane
2. In the **QUICKSTART** section, click **Start Assessment** to trigger the app assessment

> **📸 Screenshot Needed**: Screenshot showing the GitHub Copilot app modernization extension pane with the "Start Assessment" button

3. The Copilot Chat panel will open in **Agent Mode**
4. The agent will analyze your code and identify:
   - Database technology (Oracle Database)
   - Migration opportunities to Azure services
   - Code quality issues
   - Security vulnerabilities
   - Framework and runtime compatibility

> **📸 Screenshot Needed**: Screenshot of Copilot Chat panel showing the assessment in progress

5. Wait for the assessment to complete. This step could take **3-5 minutes**
6. Upon completion, an **Assessment Report** tab opens automatically

> **📸 Screenshot Needed**: Screenshot of the Assessment Report showing Oracle Database migration opportunity

#### 1.4 Review Assessment Report

The Assessment Report provides:

- **Overview**: Summary of detected technologies and frameworks
- **Issues**: Categorized list of migration opportunities
  - **Database Migration**: Oracle Database → Azure Database for PostgreSQL
  - **Security**: Current password-based authentication
  - **Cloud Readiness**: Recommendations for Azure deployment
- **Recommended Solutions**: Predefined migration tasks for each issue

Look for the following in your report:

1. **Database Migration (Oracle Database)**
   - Detected: Oracle Database 21c
   - Recommendation: Migrate to Azure Database for PostgreSQL Flexible Server
   - Action: **Run Task** button available

> **📸 Screenshot Needed**: Screenshot highlighting the "Database Migration" section with the "Run Task" button

2. **Authentication**
   - Current: Password-based authentication
   - Recommendation: Migrate to Managed Identity (passwordless)

3. **Containerization**
   - Recommendation: Containerize for cloud deployment

### Step 2: Migrate from Oracle to PostgreSQL

Now that you've assessed the application, let's begin the database migration from Oracle to Azure Database for PostgreSQL.

> **Note**: If you want to skip the assessment step, ensure you're on a branch where Oracle is still being used. The migration will handle the transition to PostgreSQL.

#### 2.1 Start Migration Task

1. In the **Assessment Report**, locate the **Database Migration (Oracle Database)** issue
2. Click the **Run Task** button next to **Migrate to Azure Database for PostgreSQL (Spring)**

> **📸 Screenshot Needed**: Screenshot showing clicking the "Run Task" button for PostgreSQL migration

3. The Copilot Chat panel opens in **Agent Mode** with a pre-populated migration prompt

#### 2.2 Review Migration Plan

1. The Copilot Agent will analyze the project and generate a **migration plan**
2. The plan includes:
   - **Session ID**: Unique identifier for this migration session
   - **Target Branch**: New Git branch for migration changes (e.g., `migration/oracle-to-postgresql-<timestamp>`)
   - **Files to Change**: List of files that will be modified
   - **Migration Guidelines**: Steps from the knowledge base
   - **Build Environment**: JDK and Maven configuration

3. Review the plan carefully. The plan will be saved to `.appmod/.migration/plan.md`

> **📸 Screenshot Needed**: Screenshot of the migration plan.md file showing the migration strategy

4. The agent will pause and ask you to review the plan
5. Type **"Continue"** in the chat to proceed with the migration

#### 2.3 Version Control Setup

The agent will automatically:

1. Check the Git repository status
2. Handle any uncommitted changes (based on your extension settings)
3. Create a new branch for the migration (e.g., `migration/oracle-to-postgresql-20250310-143022`)
4. Update the progress tracking file

> **📸 Screenshot Needed**: Screenshot showing the new Git branch created in VS Code

#### 2.4 Code Migration

The agent will now perform automatic code changes:

1. **Update Dependencies** (`pom.xml`):
   - Remove Oracle JDBC driver dependency
   - Add PostgreSQL JDBC driver
   - Add Azure Identity Extensions for managed identity support

2. **Update Configuration** (`application.properties`):
   - Change JDBC URL from Oracle format to PostgreSQL format
   - Update JPA dialect from Oracle to PostgreSQL
   - Add Azure passwordless connection support

3. **Update Entity Classes**:
   - Replace Oracle-specific data types (e.g., `VARCHAR2` → `VARCHAR`)
   - Update BLOB handling for PostgreSQL (`BLOB` → `BYTEA`)
   - Fix any Oracle-specific SQL or annotations

4. **Update Test Configuration** (`application-test.properties`):
   - Update test database configuration

> **📸 Screenshot Needed**: Screenshot showing file changes in VS Code's Source Control view

The agent will:
- Click **Allow** for any tool call permission requests
- Automatically commit changes with descriptive commit messages
- Update progress in `.appmod/.migration/progress.md`

#### 2.5 Validation and Fix Loop

After code migration, the agent automatically runs a **validation and fix iteration loop**:

##### Stage 1: Build Validation

1. The agent uses Maven to build the project
2. If build errors occur:
   - Agent analyzes each error
   - Implements fixes automatically
   - Commits fixes with descriptive messages
   - Rebuilds the project
3. This loop continues until the build succeeds or reaches maximum 10 attempts

> **📸 Screenshot Needed**: Screenshot of build validation progress in Copilot Chat

##### Stage 2: CVE Validation

1. Agent scans all dependencies for known vulnerabilities
2. If CVEs are detected:
   - Agent recommends updated dependency versions
   - Applies fixes automatically
   - Commits the CVE fixes
3. Proceeds to next stage

##### Stage 3: Consistency Validation

1. Agent analyzes Git diffs to identify functional changes
2. Categorizes issues by severity:
   - **Critical**: Must be fixed (e.g., behavior changes)
   - **Major**: Should be fixed (e.g., missing validations)
   - **Minor**: Documented but not auto-fixed
3. Automatically fixes critical and major issues
4. Documents minor issues for manual review

> **📸 Screenshot Needed**: Screenshot showing consistency validation results

##### Stage 4: Test Validation

1. Agent runs unit tests using Maven
2. If test failures occur:
   - Agent identifies integration tests vs unit tests
   - Skips integration tests that require external resources
   - Fixes unit test failures automatically
   - Re-runs tests to verify fixes
3. Continues until all unit tests pass or reaches maximum 10 attempts

##### Stage 5: Completeness Validation

1. Agent searches the entire codebase for any remaining Oracle references
2. Checks:
   - Configuration files
   - Documentation
   - Comments
   - Unused code
3. Fixes any missed migration items
4. Commits completeness fixes

> **📸 Screenshot Needed**: Screenshot of completeness validation discovering missed Oracle references

##### Stage 6: Final Build Validation

1. Agent performs a final build to ensure all fixes work together
2. If successful, proceeds to summary generation
3. If any issues remain, agent attempts up to 5 more fix rounds

#### 2.6 Review Migration Summary

1. After all validation stages complete, the agent generates a **summary.md** file
2. The summary includes:
   - Migration session details
   - Files modified
   - Build status
   - Test status
   - CVE fixes applied
   - Consistency issues resolved
   - Completeness validation results
   - Git commit history

> **📸 Screenshot Needed**: Screenshot of the summary.md file showing successful migration

3. Review the summary to understand all changes made
4. Click **Keep** in the Copilot Chat to apply all changes

#### 2.7 Test Locally (Optional)

If you want to test the migrated application locally before deploying to Azure:

1. Start a local PostgreSQL database:

```bash
docker run --name postgres-test -e POSTGRES_USER=photoalbum \
  -e POSTGRES_PASSWORD=photoalbum -e POSTGRES_DB=photoalbum \
  -p 5432:5432 -d postgres:latest
```

2. Build and run the application:

```bash
mvn clean package
java -jar target/photo-album-1.0.0.jar
```

3. Open your browser to `http://localhost:8080`
4. Test photo upload, viewing, and deletion functionality

### Step 3: Containerize the Application

Now that you've successfully migrated to PostgreSQL, the next step is to prepare the application for cloud deployment by containerizing it.

> **Note**: If you encountered issues in Step 2, you can checkout a branch where migration is complete and proceed from here.

#### 3.1 Start Containerization Task

1. In the Activity sidebar, open the **GitHub Copilot app modernization** extension pane
2. In the **TASKS** section, expand **Common Tasks** > **Containerize Tasks**
3. Click the **Run** button for **Containerize Application**

> **📸 Screenshot Needed**: Screenshot showing the Containerize Tasks section with the Run button

4. The Copilot Chat panel opens with a pre-populated containerization prompt

#### 3.2 Review Containerization Plan

1. The agent analyzes the workspace and creates a **containerization-plan.copilotmd**
2. The plan includes:
   - **Container Strategy**: Multi-stage Docker build for smaller images
   - **Base Image**: Eclipse Temurin JRE (lightweight Java runtime)
   - **Exposed Ports**: Port 8080 for the web application
   - **Health Checks**: Spring Boot Actuator endpoints
   - **Build Steps**: Maven build, Docker image creation

> **📸 Screenshot Needed**: Screenshot of the containerization plan showing the Docker strategy

3. Click **Continue** or **Allow** when prompted to proceed

#### 3.3 Dockerfile Generation

The agent will:

1. Create a `Dockerfile` in the project root
2. Use a multi-stage build:
   - **Stage 1**: Maven build stage
   - **Stage 2**: Lightweight runtime stage with JRE

Example Dockerfile structure:

```dockerfile
# Stage 1: Build stage
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Runtime stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

> **📸 Screenshot Needed**: Screenshot of the generated Dockerfile

3. The agent may also create:
   - `.dockerignore` file (to exclude unnecessary files from Docker context)
   - Docker Compose file for local testing (optional)

#### 3.4 Build Docker Image

The agent will automatically:

1. Build the Docker image:

```bash
docker build -t photoalbum-java:latest .
```

2. If build errors occur, the agent will:
   - Analyze the error
   - Fix the Dockerfile or configuration
   - Rebuild the image

> **📸 Screenshot Needed**: Screenshot showing successful Docker image build

3. Verify the image is created:

```bash
docker images | grep photoalbum-java
```

#### 3.5 Test Container Locally (Optional)

Before deploying to Azure, you can test the container locally:

1. Run the container:

```bash
docker run -p 8080:8080 \
  -e POSTGRES_USER=photoalbum \
  -e POSTGRES_PASSWORD=photoalbum \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://host.docker.internal:5432/photoalbum \
  photoalbum-java:latest
```

2. Access the application at `http://localhost:8080`
3. Verify all functionality works in the containerized environment

#### 3.6 Review and Keep Changes

1. The agent commits the containerization changes
2. Review the proposed code changes in VS Code
3. Click **Keep** to apply the Dockerfile and related files

> **📸 Screenshot Needed**: Screenshot of Git commits showing containerization changes

### Step 4: Deploy to Azure

At this point, you have successfully migrated the application to PostgreSQL and containerized it. Now, you can deploy it to Azure.

#### 4.1 Prerequisites for Azure Deployment

Ensure you have:

- Azure CLI installed and logged in:

```bash
az login
az account set --subscription <your-subscription-id>
```

- Docker CLI logged in to Azure Container Registry (will be set up by the agent)

#### 4.2 Start Deployment Task

1. In the Activity sidebar, open the **GitHub Copilot app modernization** extension pane
2. In the **TASKS** section, expand **Common Tasks** > **Deployment Tasks**
3. Click the **Run** button for **Provision Infrastructure and Deploy to Azure**

> **📸 Screenshot Needed**: Screenshot showing the Deployment Tasks section

4. A pre-populated prompt appears in the Copilot Chat panel
5. **Optional**: Edit the prompt to specify:
   - **Hosting Service**: Azure Container Apps (default) or Azure Kubernetes Service (AKS)
   - **Resource Naming**: Custom resource group or naming convention

Example prompt modification for AKS:

```
Deploy this Spring Boot application to Azure. 
Hosting service: AKS
```

> **📸 Screenshot Needed**: Screenshot of the deployment prompt in Copilot Chat

6. Press Enter or click **Continue** to proceed

#### 4.3 Review Deployment Plan

The agent creates a comprehensive deployment plan in **plan.copilotmd**:

1. **Azure Resources Architecture**:
   - Azure Container Registry (ACR) for Docker images
   - Azure Database for PostgreSQL Flexible Server
   - Azure Container Apps (or AKS)
   - Managed Identity for passwordless authentication
   - Virtual Network for secure communication

2. **Resource Configuration**:
   - Resource Group
   - Location/Region
   - SKU and pricing tiers
   - Network configuration
   - Security settings

3. **Execution Steps**:
   - Create resource group
   - Provision PostgreSQL server
   - Create container registry
   - Build and push Docker image
   - Configure managed identity
   - Deploy application
   - Configure health probes

> **📸 Screenshot Needed**: Screenshot showing the deployment plan architecture diagram (if generated)

4. Review the plan carefully
5. Click **Keep** to save the plan
6. Type **"Execute the plan"** in the Copilot Chat to start deployment

#### 4.4 Azure Resource Provisioning

The agent will:

1. **Create Resource Group**:

```bash
az group create --name photoalbum-rg --location eastus
```

2. **Create Azure Container Registry**:

```bash
az acr create --resource-group photoalbum-rg \
  --name photoalbumacr --sku Basic
```

3. **Create Azure PostgreSQL Flexible Server**:

```bash
az postgres flexible-server create \
  --resource-group photoalbum-rg \
  --name photoalbum-postgres \
  --location eastus \
  --admin-user azureuser \
  --admin-password <generated-password> \
  --sku-name Standard_B1ms \
  --version 16
```

4. **Create Database**:

```bash
az postgres flexible-server db create \
  --resource-group photoalbum-rg \
  --server-name photoalbum-postgres \
  --database-name photoalbum
```

5. **Configure Firewall Rules**:

```bash
az postgres flexible-server firewall-rule create \
  --resource-group photoalbum-rg \
  --name photoalbum-postgres \
  --rule-name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

> **📸 Screenshot Needed**: Screenshot showing Azure resources being created in Copilot Chat

6. Click **Allow** or **Continue** when the agent requests permission to run these commands

#### 4.5 Build and Push Docker Image

The agent will:

1. **Login to ACR**:

```bash
az acr login --name photoalbumacr
```

2. **Tag the image**:

```bash
docker tag photoalbum-java:latest photoalbumacr.azurecr.io/photoalbum-java:latest
```

3. **Push to ACR**:

```bash
docker push photoalbumacr.azurecr.io/photoalbum-java:latest
```

> **📸 Screenshot Needed**: Screenshot showing Docker image push progress

#### 4.6 Create Managed Identity

The agent will:

1. **Create User-Assigned Managed Identity**:

```bash
az identity create \
  --resource-group photoalbum-rg \
  --name photoalbum-identity
```

2. **Assign Roles**:
   - **AcrPull** role for pulling images from ACR
   - **PostgreSQL contributor** role for database access

3. **Configure PostgreSQL for Azure AD Authentication**:

```bash
az postgres flexible-server ad-admin create \
  --resource-group photoalbum-rg \
  --server-name photoalbum-postgres \
  --object-id <identity-object-id> \
  --display-name photoalbum-identity
```

#### 4.7 Deploy to Azure Container Apps

The agent will:

1. **Create Container Apps Environment**:

```bash
az containerapp env create \
  --name photoalbum-env \
  --resource-group photoalbum-rg \
  --location eastus
```

2. **Deploy the Application**:

```bash
az containerapp create \
  --name photoalbum-app \
  --resource-group photoalbum-rg \
  --environment photoalbum-env \
  --image photoalbumacr.azurecr.io/photoalbum-java:latest \
  --registry-server photoalbumacr.azurecr.io \
  --registry-identity <managed-identity-id> \
  --target-port 8080 \
  --ingress external \
  --env-vars \
    SPRING_DATASOURCE_URL=jdbc:postgresql://photoalbum-postgres.postgres.database.azure.com:5432/photoalbum?sslmode=require \
    AZURE_PASSWORDLESS_ENABLED=true \
    SPRING_DATASOURCE_USERNAME=photoalbum-identity \
  --user-assigned <managed-identity-id>
```

3. **Configure Health Probes**:
   - Liveness probe: `/actuator/health/liveness`
   - Readiness probe: `/actuator/health/readiness`

> **📸 Screenshot Needed**: Screenshot of Container App deployment progress

4. The agent will display the application URL once deployment is complete

#### 4.8 Verify Deployment

1. The agent provides the public URL for your application:

```
https://photoalbum-app.<random-id>.eastus.azurecontainerapps.io
```

2. Open the URL in your browser
3. Test the application:
   - Upload photos
   - View gallery
   - View photo details
   - Delete photos

> **📸 Screenshot Needed**: Screenshot of the deployed application running in Azure

4. Verify the database connection:
   - Azure AD authentication is being used (passwordless)
   - Data persists across application restarts

#### 4.9 Monitor Application

The agent may set up:

1. **Application Insights** for application monitoring
2. **Log Analytics** for container logs
3. **Metrics** for performance monitoring

Access logs:

```bash
az containerapp logs show \
  --name photoalbum-app \
  --resource-group photoalbum-rg \
  --follow
```

> **📸 Screenshot Needed**: Screenshot showing application logs in Azure Portal

#### 4.10 Review Deployment Summary

The agent generates a deployment summary in **progress.copilotmd**:

- ✅ Resource group created
- ✅ Azure Container Registry provisioned
- ✅ Azure PostgreSQL Flexible Server created
- ✅ Database configured
- ✅ Managed Identity created and configured
- ✅ Docker image built and pushed
- ✅ Container App deployed
- ✅ Health probes configured
- ✅ Application accessible

Click **Keep** to save all deployment scripts and configurations.

## Clean Up

After completing the workshop, clean up Azure resources to avoid charges:

### Option 1: Delete Resource Group (Recommended)

This deletes all resources in one command:

```bash
az group delete --name photoalbum-rg --yes --no-wait
```

### Option 2: Delete Individual Resources

If you want to keep some resources:

1. **Delete Container App**:

```bash
az containerapp delete \
  --name photoalbum-app \
  --resource-group photoalbum-rg \
  --yes
```

2. **Delete Container Apps Environment**:

```bash
az containerapp env delete \
  --name photoalbum-env \
  --resource-group photoalbum-rg \
  --yes
```

3. **Delete PostgreSQL Server**:

```bash
az postgres flexible-server delete \
  --resource-group photoalbum-rg \
  --name photoalbum-postgres \
  --yes
```

4. **Delete Container Registry**:

```bash
az acr delete \
  --name photoalbumacr \
  --resource-group photoalbum-rg \
  --yes
```

5. **Delete Managed Identity**:

```bash
az identity delete \
  --name photoalbum-identity \
  --resource-group photoalbum-rg
```

## Troubleshooting

### Assessment Issues

**Problem**: Assessment Report not generating

**Solution**:
- Ensure GitHub Copilot app modernization extension is installed and activated
- Check that you're signed in to GitHub Copilot
- Verify `chat.extensionTools.enabled` is `true` in VS Code settings
- Reload VS Code window (`Ctrl+Shift+P` → "Reload Window")

---

**Problem**: "No migration opportunities found"

**Solution**:
- Check that you're on the `main` branch (Oracle version)
- Ensure `pom.xml` contains Oracle JDBC dependency
- Verify `application.properties` has Oracle JDBC URL

### Migration Issues

**Problem**: Build fails after migration

**Solution**:
- Review error messages in Copilot Chat
- Allow the agent to attempt automatic fixes (up to 10 rounds)
- If still failing, check:
  - JDK version (should be 21)
  - Maven version (3.8+)
  - Internet connection for dependency downloads

---

**Problem**: Tests fail after migration

**Solution**:
- Agent should automatically skip integration tests
- For unit test failures, agent will attempt fixes
- If manual intervention needed:
  - Check test database configuration in `application-test.properties`
  - Ensure H2 database dependency is present for tests
  - Review test data compatibility with PostgreSQL

---

**Problem**: Uncommitted changes conflict

**Solution**:
- Before starting migration, commit or stash your changes:

```bash
git stash
```

- Or configure the extension setting for handling uncommitted changes

### Containerization Issues

**Problem**: Docker build fails

**Solution**:
- Ensure Docker Desktop is running
- Check that Maven build succeeds first: `mvn clean package`
- Review Dockerfile for syntax errors
- Agent will attempt automatic fixes

---

**Problem**: Container won't start

**Solution**:
- Check container logs:

```bash
docker logs <container-id>
```

- Verify environment variables are set correctly
- Ensure database is reachable from container

### Deployment Issues

**Problem**: Azure CLI not authenticated

**Solution**:

```bash
az login
az account set --subscription <subscription-id>
```

---

**Problem**: Insufficient permissions in Azure

**Solution**:
- Ensure your Azure account has **Contributor** or **Owner** role
- Check subscription permissions:

```bash
az role assignment list --assignee <your-email>
```

---

**Problem**: PostgreSQL connection fails from Container App

**Solution**:
- Verify firewall rules allow Azure services
- Check managed identity has correct permissions:

```bash
az postgres flexible-server ad-admin list \
  --resource-group photoalbum-rg \
  --server-name photoalbum-postgres
```

- Ensure environment variables are configured correctly

---

**Problem**: Container App deployment timeout

**Solution**:
- Check container logs in Azure Portal
- Verify health probe endpoints are responding:
  - `/actuator/health/liveness`
  - `/actuator/health/readiness`
- Ensure application starts within the timeout period (default: 240 seconds)
- Check application logs for startup errors

---

**Problem**: "Error pulling image from ACR"

**Solution**:
- Verify managed identity has **AcrPull** role:

```bash
az role assignment list --assignee <identity-principal-id>
```

- Ensure ACR login server is correct in Container App configuration
- Check that image was pushed successfully to ACR:

```bash
az acr repository list --name photoalbumacr
```

### Application Issues

**Problem**: Application returns 500 errors

**Solution**:
- Check application logs:

```bash
az containerapp logs show \
  --name photoalbum-app \
  --resource-group photoalbum-rg
```

- Verify database schema was created (check Hibernate DDL auto setting)
- Ensure managed identity authentication is working

---

**Problem**: Photos upload but don't display

**Solution**:
- Check BLOB/BYTEA column type in PostgreSQL
- Verify file size limits in application properties
- Review browser console for JavaScript errors

## Additional Resources

- [Spring Boot Documentation](https://spring.boot.io/docs)
- [Azure Database for PostgreSQL](https://learn.microsoft.com/azure/postgresql/)
- [Azure Container Apps](https://learn.microsoft.com/azure/container-apps/)
- [Managed Identity](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/)
- [GitHub Copilot for Java](https://docs.github.com/copilot)
- [Docker Documentation](https://docs.docker.com/)

## Contributing

When contributing to this project:

- Follow Spring Boot best practices
- Maintain database compatibility
- Ensure UI/UX consistency
- Test both local and Azure deployment scenarios
- Update documentation for any architectural changes
- Add appropriate tests for new features

## License

This project is provided as-is for educational and demonstration purposes.

---

**Congratulations!** 🎉

You have successfully completed the Photo Album Application Migration Workshop. You've learned how to:

- ✅ Assess a Java application for cloud readiness
- ✅ Migrate from Oracle Database to Azure Database for PostgreSQL
- ✅ Implement passwordless authentication with Managed Identity
- ✅ Containerize a Spring Boot application
- ✅ Deploy to Azure Container Apps
- ✅ Monitor and troubleshoot cloud applications

These skills are transferable to migrating and modernizing other Java applications to Azure!
