function ContentsReplace
{
    param
    (
        $taregetFileName,
        [System.Collections.Generic.Dictionary[String, String]]$targetReplaceDic
    )
    $path = $pwd.Path
    $path = $path + '\' + ${taregetFileName}
    Write-Host $path
    $contents = Get-Content -Path $path -Raw -Encoding utf8
    foreach ($item in $targetReplaceDic.GetEnumerator()) 
    {
        $contents = $contents.Replace($item.Key, $item.Value)
    }
    $path = $pwd.Path
    $path = $path + '\' + "after_${taregetFileName}"
    Write-Host $path
    [void](Set-Content -Value $contents -Encoding utf8 -Path $path)
    return $true
}


# set variables
set-variable -name TENANT_ID "xxxxxxxxxxxxxxxx" -option constant
set-variable -name SUBSCRIPTOIN_GUID "xxxxxxxxxxxxxxxxx" -option constant
set-variable -name BICEP_FILE "main.bicep" -option constant
set-variable -name CONTAINER_NAME "dl2" -option constant
set-variable -name SAMPLE_SOURCE "https://miscstrage.blob.core.windows.net/box/sample.zip?sv=2020-04-08&st=2021-07-29T22%3A21%3A54Z&se=2022-06-30T14%3A59%3A00Z&sr=b&sp=r&sig=TzZxkOsM2BmLH1ImbFy%2FWdWvTNOvU6MDpgEtubEAQ4w%3D"

$parameterFile = "azuredeploy.parameters.dev.json"
$resourceGroupName = "rgxxxx"
$location = "japaneast"


# install required packages
Install-Module -Name Az.Synapse


# initialize envirionment
Connect-AzAccount -Tenant ${TENANT_ID} -Subscription ${SUBSCRIPTOIN_GUID}

New-AzResourceGroup -Name ${resourceGroupName} -Location ${location} -Verbose

New-AzResourceGroupDeployment `
    -Name devenvironment `
    -ResourceGroupName ${resourceGroupName} `
    -TemplateFile ${BICEP_FILE} `
    -TemplateParameterFile ${parameterFile} `
    -Verbose

#1.作成されたストレージアカウントのSAS TOKEN を取得
$storage = Get-AzStorageAccount `
    -ResourceGroupName ${resourceGroupName}
    
$ctx = New-AzStorageContext `
    -StorageAccountName $storage.StorageAccountName `
    -UseConnectedAccount

$sas = New-AzStorageContainerSASToken -Context $ctx `
    -Name ${CONTAINER_NAME} `
    -Permission rw `
    -ExpiryTime (Get-Date).AddDays(1.0)

$sasurl = ${ctx}.BlobEndPoint + "dl2" + ${sas}
#2.使った sample.zip のダウンロード
invoke-webrequest -uri ${SAMPLE_SOURCE} -outfile sample.zip

#3. zip の解凍(コマンド)
#unzip -d sample sample.zip
Expand-Archive -LiteralPath .\sample.zip -DestinationPath sample

#4. 1で作成したsas token と共に、az copyで 作成されたストレージアカウントのコンテナdl2 へアップロード
azcopy copy "./sample" --recursive=true "${sasurl}" 

Remove-Item -Path sample.zip -Force
Remove-Item -Path .\sample\* -Recurse

#5.作成されたストレージアカウントのアカウントキーを取得
$saKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storage.StorageAccountName).Value[0]

#6-1. create_externa_table.sqlの<storage account name>を置換
$inputFilePath = "create_externa_table.sql"
$replaceStringsDic = [System.Collections.Generic.Dictionary[String, String]]::new()
$replaceStringsDic.Add("<storage account name>", $storage.StorageAccountName)
$replaceStringsDic.Add("<storage account key>", $saKey)
ContentsReplace -taregetFileName $inputFilePath -targetReplaceDic $replaceStringsDic

#7.Set-AzSynapseSqlScriptをつかって、リポジトリのSQLファイルを一式(*.sql)アップロード
$ws = Get-AzSynapseWorkspace -ResourceGroupName $resourceGroupName
Set-AzSynapseSqlScript　-WorkspaceName $ws.Name -Name "create_externa_table" -DefinitionFile ".\after_create_externa_table.sql"

#8. transform-csv.ipynbの_storage_account_をストレージアカウント名で置換
$linked_service = Get-AzSynapseLinkedService -WorkspaceName $ws.Name

$inputFilePath = "transform-csv.ipynb"
$replaceStringsDic = [System.Collections.Generic.Dictionary[String, String]]::new()
$replaceStringsDic.Add("_storage_account_", $storage.StorageAccountName)
$replaceStringsDic.Add("_linked_service_name_", $linked_service.Name[0])
ContentsReplace -taregetFileName $inputFilePath -targetReplaceDic $replaceStringsDic

#9.Set-AzSynapseNotebookをつかって、リポジトリのipynbファイルを一式(*.ipynb)アップロード
Set-AzSynapseNotebook -WorkspaceName $ws.Name -Name "transform-csv" -DefinitionFile ".\after_transform-csv.ipynb"

#10.ctasのアップロード
Set-AzSynapseSqlScript　-WorkspaceName $ws.Name -Name "ctas" -DefinitionFile ".\ctas.sql"
