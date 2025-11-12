# Kubernetes Manifests

This directory contains both template files and generated Kubernetes manifests for the Photo Album application.

## Template Files (Committed to Git)

- `deployment.template.yaml` - Template for the application deployment
- `secret.template.yaml` - Template for database secrets
- `namespace.yaml` - Namespace definition (static)
- `service.yaml` - Service definition (static)

## Generated Files (Not Committed to Git)

- `deployment.yaml` - Generated from `deployment.template.yaml` using `.env` values
- `secret.yaml` - Generated from `secret.template.yaml` using `.env` values

## How It Works

The `deploy-to-aks.ps1` script reads configuration from the `.env` file in the project root and generates the actual Kubernetes manifests from the template files by replacing placeholders like `{{ACR_NAME}}` with actual values.

### Template Placeholders

- `{{ACR_NAME}}` - Azure Container Registry name
- `{{POSTGRES_CONNECTION_STRING}}` - PostgreSQL connection string
- `{{POSTGRES_USER}}` - PostgreSQL username
- `{{POSTGRES_PASSWORD}}` - PostgreSQL password

## Usage

Run the deployment script which will automatically generate the manifests and deploy:

```powershell
.\deploy-to-aks.ps1
```

The script will:
1. Load configuration from `.env`
2. Generate `deployment.yaml` and `secret.yaml` from templates
3. Deploy all manifests to AKS