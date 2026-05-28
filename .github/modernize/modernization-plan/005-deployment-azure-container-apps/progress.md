# Deployment Progress: 005-deployment-azure-container-apps

## Status

- [x] Containerization complete (Dockerfile found at `./Dockerfile`, port 8080, Java 21)
- [x] Env Setup for AzCLI (subscription: 6c933f90-8115-4392-90f2-7077c9fa5dbd, serviceconnector-passwordless extension installed)
- [x] Bicep IaC files generated (infra/main.bicep, infra/modules/resources.bicep — both validated with az bicep build)
- [x] Provisioning (all 10 Azure resources provisioned — RG, ACR, Container App Env, Container App, PostgreSQL v17, Managed Identity, Log Analytics, DB, Firewall Rule, AcrPull Role Assignment)
- [x] Service Connector created (photoalbum_pg_connection — Managed Identity → PostgreSQL via Spring Boot)
- [x] Docker image built and pushed to ACR: azacra7gtzdzjcrgy2.azurecr.io/photo-album:latest
- [x] Container App updated with photo-album image
- [x] Env vars patched via ARM REST API (POSTGRESQL_SERVER, POSTGRESQL_PORT, POSTGRESQL_DATABASE, MANAGED_IDENTITY_NAME, SPRING_PROFILES_ACTIVE=docker, SPRING_CLOUD_AZURE_CREDENTIAL_CLIENT_ID)
- [x] Deployment Validated — Spring Boot started, Managed Identity authenticated to PostgreSQL 17.9, Hibernate tables created, Tomcat on port 8080
- [x] Summarize Result

- [ ] Check Azure Resources Existence
- [ ] Deployment (build + push image, deploy to Container App)
- [ ] Deployment Validation
- [ ] Summarize Result
