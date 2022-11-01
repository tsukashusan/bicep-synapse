param synapseName string
param location string
param sqlAdministratorLogin string
@secure()
param sqlAdministratorLoginPassword string
param blobName string
param storageAccountType string
param sqlpoolName string
param bigDataPoolName string
param nodeSize string
param sparkPoolMinNodeCount int
param sparkPoolMaxNodeCount int
param defaultDataLakeStorageFilesystemName string
param collation string
param startIpaddress string
param endIpAddress string
param userObjectId string
param dataLakeUrlFormat string


var storageBlobDataContributorRoleID = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var storageRoleUniqueId = guid(resourceId('Microsoft.Storage/storageAccounts', synapseName), blobName)
var storageRoleUserUniqueId = guid(resourceId('Microsoft.Storage/storageAccounts', synapseName), userObjectId)
resource datalakegen2 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: blobName
  kind: 'StorageV2'
  location: location
  properties:{
    minimumTlsVersion: 'TLS1_2'
    isHnsEnabled: true
  }
  sku: {
    name: storageAccountType
  }
}

resource blob 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  name:  '${datalakegen2.name}/default'
}

resource containera 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name: '${datalakegen2.name}/default/${defaultDataLakeStorageFilesystemName}'
  properties: {
    publicAccess: 'None'
  }
  dependsOn:[
    blob
  ]
} 

resource synapse 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: synapseName
  location: location
  properties: {
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorLoginPassword
    defaultDataLakeStorage:{
      accountUrl: format(dataLakeUrlFormat, datalakegen2.name)
      filesystem: defaultDataLakeStorageFilesystemName
    }
  }
  identity:{
    type:'SystemAssigned'
  }
}

resource synapseroleassing 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: storageRoleUniqueId
  scope: datalakegen2
  properties:{
    principalId: synapse.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleID)
  }
}

resource userroleassing 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: storageRoleUserUniqueId
  scope: datalakegen2
  properties:{
    principalId: userObjectId
    principalType: 'User'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleID)
  }
}

resource manageid4Pipeline 'Microsoft.Synapse/workspaces/managedIdentitySqlControlSettings@2021-06-01' = {
  name: 'default'
  properties: {
    grantSqlControlToManagedIdentity: {
      desiredState:'Enabled'
    }
  }
  parent:synapse
}

resource sqlpool 'Microsoft.Synapse/workspaces/sqlPools@2021-06-01' = {
  name: sqlpoolName
  location: location
  parent: synapse
  sku:{
    name: 'DW100c'
  }
  properties:{
    collation: collation
    createMode: 'Default'
  }
}

resource sparkpool 'Microsoft.Synapse/workspaces/bigDataPools@2021-06-01' = {
  name: bigDataPoolName
  location: location
  parent: synapse
  properties:{
    nodeSize: nodeSize
    nodeSizeFamily: 'MemoryOptimized'
    autoScale:{
      enabled: true
      minNodeCount: sparkPoolMinNodeCount
      maxNodeCount: sparkPoolMaxNodeCount
    }
    autoPause:{
      enabled: true
      delayInMinutes: 15
    }
    sparkVersion: '3.2'
  }
}

resource allowazure4synapse 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  name: 'AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
  parent: synapse
}

resource symbolicname 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  name: 'AllowAccessPoint'
  properties: {
    endIpAddress: endIpAddress
    startIpAddress: startIpaddress
  }
  parent: synapse
}
