\# Azure resource setup



Create a shell script (bash) that will use the Azure CLI to create the following Azure resources with described configuration:



\* A resource group named "photo-album-resources". All subsequent resources should be placed in this resource group.

\* Create an Azure Container Apps environment with System Assigned MI enabled

\* Set up ACR and configure properly the local credential for image push

\* configure to allow image pulling from the ACA MI

\* Provision Azure SQL Server and configure the MI login

\* configure to allow login with the ACA MI

\* Provision a storage account

\* configure to allow the ACA MI with Contributor role and  Storage Blob Data Contributor role



The shell script should use the default azure subscription that the CLI is setup for.

