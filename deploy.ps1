Write-Host "hello world"
set-variable -name TENANT_ID "xxxxxxxxxxxxxxxxxx" -option constant
set-variable -name SUBSCRIPTOIN_GUID "xxxxxxxxxxxxxxxxxxxxx" -option constant
set-variable -name BICEP_FILE "main.bicep" -option constant
set-variable -name CONTAINER_NAME "dl2" -option constant
set-variable -name SAMPLE_SOURCE "https://miscstrage.blob.core.windows.net/box/sample.zip?sv=2020-04-08&st=2021-07-29T22%3A21%3A54Z&se=2022-06-30T14%3A59%3A00Z&sr=b&sp=r&sig=TzZxkOsM2BmLH1ImbFy%2FWdWvTNOvU6MDpgEtubEAQ4w%3D"

$parameterFile = "azuredeploy.parameters.dev.json"
$resourceGroupName = "rg20211105"
$location = "japaneast"

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
$filePath = ".\create_externa_table.sql"
$inputFile = (Get-Content $filePath -Encoding "UTF8") -as [string[]]
$contents = ""
foreach ($readLine in $inputFile) {
  $contents = $contents + $readLine
  $contents = $contents + "`n"
}

$contents = $contents.Replace('<storage account name>', $storage.StorageAccountName)

#6-2. create_externa_table.sqlの<storage account key>を置換
$contents = $contents.Replace('<storage account key>', $saKey)

#6-3. 6-1, 6-2の結果をcreate_externa_table.sqlとして、上書き
$outFilePath = ".\after_create_externa_table.sql"

$UTF8woBOM = New-Object "System.Text.UTF8Encoding" -ArgumentList @($false)
# あとは.NET FrameworkのIO処理を頑張って書く
[System.IO.File]::WriteAllLines((Join-Path $PWD $outFilePath), @($contents), $UTF8woBOM)


#7.Set-AzSynapseSqlScriptをつかって、リポジトリのSQLファイルを一式(*.sql)アップロード
Set-AzSynapseSqlScript

#8. transform-csv.ipynbの_storage_account_をストレージアカウント名で置換
