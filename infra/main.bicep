metadata description = 'Bicep template for deploying a GitHub App using Azure Container Apps and Azure Container Registry.'

targetScope = 'resourceGroup'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('(Optional) Principal identifier of the identity that is deploying the template.')
param azureDeploymentPrincipalId string = ''

var deploymentIdentityPrincipalId = !empty(azureDeploymentPrincipalId)
  ? azureDeploymentPrincipalId
  : deployer().objectId

var resourceToken = toLower(uniqueString(resourceGroup().id, environmentName, location))

var tags = {
  'azd-env-name': environmentName
  repo: 'https://github.com/azure-samples/container-apps-dotnet-minimal-api'
}

module managedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.1' = {
  name: 'user-assigned-identity'
  params: {
    name: 'identity-${resourceToken}'
    location: location
    tags: tags
  }
}

module containerRegistry 'br/public:avm/res/container-registry/registry:0.9.1' = {
  name: 'container-registry'
  params: {
    name: 'containerreg${resourceToken}'
    location: location
    tags: tags
    acrAdminUserEnabled: false
    anonymousPullEnabled: false
    publicNetworkAccess: 'Enabled'
    acrSku: 'Standard'
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionIdOrName: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
      }
      {
        principalId: deploymentIdentityPrincipalId
        roleDefinitionIdOrName: '8311e382-0749-4cb8-b61a-304f252e45ec' // AcrPush
      }
    ]
  }
}

module containerAppsEnvironment 'br/public:avm/res/app/managed-environment:0.11.0' = {
  name: 'container-apps-env'
  params: {
    name: 'env-${resourceToken}'
    location: location
    tags: tags
    publicNetworkAccess: 'Enabled'
    zoneRedundant: false
  }
}

module containerAppsInstance 'br/public:avm/res/app/container-app:0.16.0' = {
  name: 'container-apps-instance'
  params: {
    name: 'app-${resourceToken}'
    environmentResourceId: containerAppsEnvironment.outputs.resourceId
    location: location
    tags: union(tags, { 'azd-service-name': 'api' })
    ingressTargetPort: 8080
    ingressExternal: true
    scaleSettings: {
      maxReplicas: 1
      minReplicas: 1
    }
    managedIdentities: {
      userAssignedResourceIds: [
        managedIdentity.outputs.resourceId
      ]
    }
    registries: [
      {
        server: containerRegistry.outputs.loginServer
        identity: managedIdentity.outputs.resourceId
      }
    ]
    secrets: [
      {
        name: 'user-assigned-managed-identity-client-id'
        value: managedIdentity.outputs.clientId
      }
    ]
    containers: [
      {
        image: 'mcr.microsoft.com/dotnet/samples:aspnetapp-9.0'
        name: 'api'
        resources: {
          cpu: '0.25'
          memory: '.5Gi'
        }
        env: [
          {
            name: 'AZURE_CLIENT_ID'
            secretRef: 'user-assigned-managed-identity-client-id'
          }
        ]
      }
    ]
  }
}

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
