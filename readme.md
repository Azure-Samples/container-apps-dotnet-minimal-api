# .NET Minimal API boilerplate hosted in Azure Container Apps

This is a boilerplate template for a simple .NET Minimal API application hosted in Azure Container Apps.

This template will deploy the .NET application as a Docker container to Azure Container Registry. Then, the template will deploy an Azure Container Apps resource using the same Docker container.

All interconnected services in this template uses Microsoft Entra authentication with a managed identity. The deployer of the template is automatically granted [`AcrPush`](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/containers#acrpush) role in Azure role-based access control to the Azure Container Registry resource.
