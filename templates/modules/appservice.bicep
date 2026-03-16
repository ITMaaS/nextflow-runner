param location string
param tagVersion string
param nfRunnerAPIAppPlanName string
param nfRunnerAPIAppName string
param storageAccountName string
@secure()
param storagePassphrase string
@secure()
param storageSASToken string
param functionAppUrl string

@allowed([
  'nonprod'
  'prod'
])
param environmentType string

@secure()
param sqlConnection string

// Updated to modern App Service SKUs
var appServicePlanSkuName = (environmentType == 'prod') ? 'P2v3' : 'B1'
var appServicePlanTierName = (environmentType == 'prod') ? 'PremiumV3' : 'Basic'

var tagName = split(tagVersion, ':')[0]
var tagValue = split(tagVersion, ':')[1]

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: nfRunnerAPIAppPlanName
  location: location
  tags: {
    '${tagName}': tagValue
  }
  sku: {
    name: appServicePlanSkuName
    tier: appServicePlanTierName
  }
  kind: 'linux' // newer API version prefers lowercase
  properties: {
    reserved: true
  }
}

resource appServiceApp 'Microsoft.Web/sites@2023-12-01' = {
  name: nfRunnerAPIAppName
  location: location
  tags: {
    '${tagName}': tagValue
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      connectionStrings: [
        {
          name: 'DefaultConnection'
          connectionString: sqlConnection
          type: 'SQLAzure'
        }
      ]
      appSettings: [
        {
          name: 'AzureStorage__AZURE_STORAGE_ACCOUNTNAME'
          value: storageAccountName
        }
        {
          name: 'AzureStorage__AZURE_STORAGE_KEY'
          value: storagePassphrase
        }
        {
          name: 'AzureStorage__AZURE_STORAGE_SAS'
          value: storageSASToken
        }
        {
          name: 'OrchestratorClientOptions__WeblogUrl'
          value: '${functionAppUrl}/api/WeblogTracer'
        }
        {
          name: 'OrchestratorClientOptions__HttpStartUrl'
          value: '${functionAppUrl}/api/ContainerManager_HttpStart'
        }
      ]
    }
  }
}

output appServiceAppName string = appServiceApp.name
