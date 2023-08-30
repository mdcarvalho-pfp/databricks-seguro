#Script para implantação dos recursos no Azure

#Preencha as variáveis abaixo com os nomes escolhidos

$resourcetemplate = "template1"
$resourcegroup = "rg-databricks-secure-access-pattern"
$storageaccount = "sadatabricks0001abcdefgh"
$serviceprincipal = "app-databricks-secure-access-pattern"

#Configuração do ambiente operacional do Powershell

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
Connect-AzAccount

#Criação do grupo de recursos

New-AzResourceGroup -Name $resourcegroup -location brazilsouth

#Criação da conta de armazenamento

New-AzStorageAccount -ResourceGroupName $resourcegroup `
    -Name $storageaccount `
    -Location "brazilsouth" `
    -SkuName "Standard_LRS" `
    -Kind "StorageV2" `
    -EnableHttpsTrafficOnly $true `
    -AccessTier "Hot" `
    -AllowBlobPublicAccess $false `
    -EnableHierarchicalNamespace $true `
    -MinimumTlsVersion "TLS1_2" `
    -Tag @{KeyName=$storageaccount}

#CRIAÇÃO DOS BLOB CONTAINERS

# Obtenha a chave de acesso da conta de armazenamento

$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourcegroup -Name $storageaccount).Value[0]

# Crie o contexto da conta de armazenamento
$storageContext = New-AzStorageContext -StorageAccountName $storageaccount -StorageAccountKey $storageAccountKey

# Crie o blob container
New-AzStorageContainer -Name "bronze" -Context $storageContext
New-AzStorageContainer -Name "silver" -Context $storageContext
New-AzStorageContainer -Name "gold" -Context $storageContext

#Implantação do template para criação dos recursos

New-AzResourceGroupDeployment -Name $resourcetemplate -ResourceGroupName $resourcegroup -TemplateFile .\template.json

#Criação do Service Principal app-secure-access-pattern-databricks

$sp = New-AzADServicePrincipal -DisplayName $serviceprincipal
$dataLake = Get-AzResource -Name $storageaccount -ResourceType "Microsoft.Storage/storageAccounts"
New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Storage Blob Data Contributor" -Scope $dataLake.Id