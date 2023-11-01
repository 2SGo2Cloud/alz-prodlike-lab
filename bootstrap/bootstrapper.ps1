Function Replace-Placeholders {
  [CmdletBinding()]
  Param (
  [string]$ConfigPath,
  [hashtable]$Replacements
  ) 
  Write-Verbose "Starting to process $ConfigPath"
  (Get-Content -Path $ConfigPath) | ForEach-Object { 
    $EachLine = $_
      $Replacements.GetEnumerator() | ForEach-Object {
          if ($EachLine -match $_.Key)
          {
              Write-Verbose "Changing $EachLine to $($_.Value)" 
              $EachLine = $EachLine -replace $($_.Key), $($_.Value)
              Write-Verbose "Line is now $EachLine"
          }
    }
    $EachLine
  } | Out-File $ConfigPath
  Write-Verbose "Completed processing for $ConfigPath"
}

Function Get-UniqueString {
  Param(
  [string]$seed,
  [int]$length=13
  )
  $hashArray = (new-object System.Security.Cryptography.SHA512Managed).ComputeHash($seed.ToCharArray())
  -join ($hashArray[1..$length] | ForEach-Object { [char]($_ % 26 + [byte][char]'a') })
}

################################
# Set variables used throughout
################################
$prefix = ""
$random = Get-UniqueString -seed $prefix -length 4
$terraformStates = @{
  "ResourceGroupName" = "$prefix-tfstates-$random"
  "StorageAccountName" = "$($prefix)tfstates$random"
  "SubscriptionId" = "##tfstates-subscription-id##"
  "TenantId" = "##tenant-id##"
}

$identitiesResourceGroupName = "$prefix-tfidentities-$random"
$rootManagementGroupId = "/providers/Microsoft.Management/managementgroups/##root-management-group-id##"
$repoOwner = "##github-org##"
$defaultMgmtGroup = "/providers/Microsoft.Management/managementgroups/##decommissioned-management-group-id##"

$tiers = @("core;$prefix-tier-1", "management;$prefix-tier-2", "connectivity;$prefix-tier-3", "identity;$prefix-tier-4", "shared;$prefix-shared";"lz-vending;$prefix-lz-vending")

if (Test-Path -Path "subscription-ids.json") {
  $subscriptions = Get-Content "subscription-ids.json" | ConvertFrom-Json
}

if ($prefix -eq "" -or $prefix.Length -lt 2 -or $prefix.Length -gt 4) {
  throw("Please create an alphanumeric prefix with 2-4 characters.")
}

try {
  $tiersContext = Set-AzContext -Subscription $terraformStates["SubscriptionId"]
  $tiersContextAz = $(az account set --subscription $terraformStates["SubscriptionId"])
}
catch {
  Write-Host "Error changing to core config subscription."
}

$hierarchySettings = $(az account management-group hierarchy-settings list --name $terraformStates["TenantId"] | ConvertFrom-Json)

if ($hierarchySettings.value) {
  $hierarchySettings = $(az account management-group hierarchy-settings update --name $terraformStates["TenantId"] --default-management-group $rootManagementGroupId)
} else {
  $hierarchySettings = $(az account management-group hierarchy-settings create --name $terraformStates["TenantId"] --default-management-group $rootManagementGroupId)
}

###################################
# Create Resource Groups for state
###################################
$output = $(az group create -n $terraformStates["ResourceGroupName"] -l "norwayeast")
$output = $(az group create -n $identitiesResourceGroupName -l "norwayeast")

###################################
# Create Storage Account for state
###################################
$storage = $(az storage account show -n $terraformStates["StorageAccountName"] -g $terraformStates["ResourceGroupName"])
if ($storage) {
  Write-Host "Storage account exists..." -ForegroundColor DarkGreen
} else {
  Write-Host "Creating storage account..." -ForegroundColor DarkGreen
  $output = $(az storage account create -n $terraformStates["StorageAccountName"] -g $terraformStates["ResourceGroupName"] -l norwayeast --sku Standard_RAGRS --allow-blob-public-access false)
}

$storageAccountId = $(az storage account show --name $terraformStates["StorageAccountName"] --query id -o tsv)

if ($storageAccountId) {
  $userId = $(az ad signed-in-user show --query id -o tsv)
  $upn = $(az ad signed-in-user show --query userPrincipalName -o tsv)
  $saRoleAssignment = $(az role assignment list --assignee $userId --scope $storageAccountId)
  if (($saRoleAssignment | ConvertFrom-Json).Count -gt 0) {
    Write-Host "$upn already has sufficient permissions on $($terraformStates["StorageAccountName"])..." -ForegroundColor DarkGreen
  } else {
    Write-Host "Granting $upn Storage Blob Data Owner on storage account $($terraformStates["StorageAccountName"])..." -ForegroundColor DarkGreen
    $output = $(az role assignment create --role "Storage Blob Data Owner" `
      --assignee-object-id $(az ad signed-in-user show --query id -o tsv) `
      --scope $storageAccountId --assignee-principal-type User)
  }
}

###################################
# Loop through all tiers
###################################

Foreach ($item in $tiers) {
  $name = $item.Split(";")[0]
  $tier = $item.Split(";")[1]
  $uaiName = "$prefix-$name-uai"

  if ($name -ne "shared") {

    Write-Host "Processing $name" -ForegroundColor DarkYellow

    $container = ""
    $uaiClientId = ""
    $federatedCredential = ""
    $roleAssignment = ""

    ###################################
    # Create storage account container
    ###################################
    $container = $(az storage container show --account-name $terraformStates["StorageAccountName"] --name $name --auth-mode login)
    if ($container) {
      Write-Host "- Container exists..." -ForegroundColor DarkGreen
    } else {
      Write-Host "- Creating state container..." -ForegroundColor DarkGreen
      $output = $(az storage container create -n $name --auth-mode login --account-name $terraformStates["StorageAccountName"])
    }
    
    ########################################
    # Create User-Assigned Managed Identity
    ########################################
    $uaiClientId = $(az identity show --name "$uaiName" --resource-group $identitiesResourceGroupName --query clientId -o tsv)
    if ($uaiClientId) {
      Write-Host "- Managed identity exists..." -ForegroundColor DarkGreen
    } else {
      Write-Host "- Creating managed identity..." -ForegroundColor DarkGreen
      $uaiClientId = $(az identity create --name "$uaiName" --resource-group $identitiesResourceGroupName --location norwayeast --query clientId -o tsv)
    }

    ###################################
    # Create UAI federated credentials
    ###################################
    $configs = @("oidc-main-branch-credential", "oidc-pull-request-credential")
    foreach ($config in $configs){
      if ($config -eq "oidc-main-branch-credential") {
        $subject = "repo:$($repoOwner)/$($tier):ref:refs/heads/main"
      }
      if ($config -eq "oidc-pull-request-credential") {
        $subject = "repo:$($repoOwner)/$($tier):pull_request"
      }
      $federatedCredential = $(az identity federated-credential show --identity-name "$uaiName" --name $config --resource-group $identitiesResourceGroupName --query name -o tsv)
      if ($federatedCredential) {
        Write-Host "- Federated credential exists..." -ForegroundColor DarkGreen
      } else {
        Write-Host "- Creating federated credential..." -ForegroundColor DarkGreen
        $output = $(az identity federated-credential create --identity-name "$uaiName" `
                                                            --name $config `
                                                            --resource-group $identitiesResourceGroupName `
                                                            --audiences @("api://AzureADTokenExchange") `
                                                            --issuer "https://token.actions.githubusercontent.com" `
                                                            --subject $subject)
      }
    }
    
    ####################################
    # Create UAI State Role Assignments
    ####################################
    $principalId = $(az identity show --name "$uaiName" --resource-group $identitiesResourceGroupName --query principalId -o tsv)
    $containerId = "$storageAccountId/blobServices/default/containers/$name"
    $roleAssignment = $(az role assignment list --assignee $principalId --scope $containerId | ConvertFrom-Json)

    if ($roleAssignment.Count -gt 0) {
      Write-Host "- Role assignment on state exists..." -ForegroundColor DarkGreen
    } else {
      Write-Host "- Creating identity role assignment on state..." -ForegroundColor DarkGreen
      $output = $(az role assignment create --assignee $principalId --role "Storage Blob Data Owner" --scope $containerId)
    }
    
    ##############################################
    # Create UAI Azure Resources Role Assignments
    ##############################################
    if ($subscriptions.$name.role_assignments) {
      foreach ($ra in $subscriptions.$name.role_assignments) {
        if ($ra.scope -eq "rootManagementGroup") {
          $scope = $rootManagementGroupId
        } elseif ($ra.scope -eq "coreSubscription") {
          $scope = "/subscriptions/$($subscriptions.core.subscription_id)"
        } elseif ($ra.scope -eq "managementSubscription") {
          $scope = "/subscriptions/$($subscriptions.management.subscription_id)"
        } elseif ($ra.scope -eq "connectivitySubscription") {
          $scope = "/subscriptions/$($subscriptions.connectivity.subscription_id)"
        } elseif ($ra.scope -eq "identitySubscription") {
          $scope = "/subscriptions/$($subscriptions.identity.subscription_id)"
        } else {
          $scope = $ra.scope
        }
        $role = $ra.role_definition_name

        $azureRoleAssignment = $(az role assignment list --assignee $principalId --scope $scope --role "$role" | ConvertFrom-Json)
        if ($azureRoleAssignment.Count -gt 0) {
          Write-Host "- $name already has $role on scope $scope..." -ForegroundColor DarkGreen
        } else {
          Write-Host "- Creating $role on scope $scope for $name..." -ForegroundColor DarkGreen
          $azureRoleAssignment = $(az role assignment create --assignee $principalId --role "$role" --scope $scope)
        }
      }
    }

    ###################################################
    # Replace placeholders in terraform backend config
    ###################################################
    $backendFile = "../../$tier/code/providers.tf"
    $repo_name = $tier
    $repo = "$repoOwner/$repo_name"

    if (!(Test-Path $backendFile)) {
      Write-Host "No providers file found for $name in $tier folder"
    } else {
      $Replacements = @{
        '##tfstate-resource-group-name##' = $terraformStates["ResourceGroupName"]
        '##tfstate-storage-account-name##' = $terraformStates["StorageAccountName"]
        '##tfstate-container-name##' = $name
        '##tfstate-subscription-id##' = $terraformStates["SubscriptionId"]
        '##tfstate-tenant-id##' = $terraformStates["TenantId"]
        '##uai-client-id##' = $uaiClientId
        '##subscription-id-management##' = $subscriptions.management.subscription_id
        '##subscription-id-connectivity##' = $subscriptions.connectivity.subscription_id
        '##subscription-id-identity##' = $subscriptions.identity.subscription_id
        '##subscription-id-security##' = $subscriptions.security.subscription_id
      }
      Replace-Placeholders -ConfigPath $backendFile -Replacements $Replacements
    }

    ###################################################
    # Create or update GitHub repository secrets
    ###################################################
    $output = $(gh secret set ARM_CLIENT_ID --app actions --body $uaiClientId --repo $repo)
    if ($output -like "*Set Actions secret*") {
      Write-Host "Created or updated secret ARM_CLIENT_ID for $repo..." -ForegroundColor DarkGreen
    } else {
      Write-Host "Possible issues setting repository secret. Please investigate." -ForegroundColor DarkYellow
      Write-Host "Response from gh client:" -ForegroundColor DarkYellow
      Write-Host $output -ForegroundColor DarkYellow
    }
  } else {
    $Replacements = @{
      '##subscription-id-management##' = $subscriptions.management.subscription_id
      '##subscription-id-connectivity##' = $subscriptions.connectivity.subscription_id
      '##subscription-id-identity##' = $subscriptions.identity.subscription_id
      '##subscription-id-security##' = $subscriptions.security.subscription_id
    }
    Replace-Placeholders -ConfigPath "../../$tier/code/shared_variables/variables.tf" -Replacements $Replacements
  }
}
