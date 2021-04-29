//scope
targetScope = 'resourceGroup'

var randomstring = toLower(replace(uniqueString(subscription().id, resourceGroup().id), '-', ''))
param ipaddress string
var synapseName = 'synapse${randomstring}'
param sqlAdministratorLogin string
param sqlAdministratorLoginPassword string
var blobName = 'storage${randomstring}'
param storageAccountType string
param sqlpoolName string
param bigDataPoolName string
param nodeSize string
param sparkPoolMinNodeCount int
param sparkPoolMaxNodeCount int
param defaultDataLakeStorageFilesystemName string
param collation string
param userObjectId string
var location = resourceGroup().location


//Storage account for deployment scripts
module synapsedeploy 'synapse-workspace.bicep' = {
  name: 'synapsed'
  params: {
    synapseName: synapseName
    location: location
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorLoginPassword
    blobName: blobName
    storageAccountType: storageAccountType
    sqlpoolName: sqlpoolName
    bigDataPoolName: bigDataPoolName
    nodeSize: nodeSize
    sparkPoolMinNodeCount: sparkPoolMinNodeCount
    sparkPoolMaxNodeCount: sparkPoolMaxNodeCount
    defaultDataLakeStorageFilesystemName: defaultDataLakeStorageFilesystemName
    collation: collation
    startIpaddress: ipaddress
    endIpAddress: ipaddress
    userObjectId: userObjectId
  }
}

