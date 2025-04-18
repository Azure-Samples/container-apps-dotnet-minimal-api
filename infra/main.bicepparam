using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME', 'dev')
param location = readEnvironmentVariable('AZURE_LOCATION', 'eastus2')
param azureDeploymentPrincipalId = readEnvironmentVariable('AZURE_PRINCIPAL_ID', '')
