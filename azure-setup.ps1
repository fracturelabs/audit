Param (
    [Parameter(Mandatory=$true,HelpMessage="The tenantId for your Azure subscription")][Alias("tenantId")][string]$tenantIdVal
)

Write-Output "The tenantId is $tenantIdVal"

# Sign in
Connect-AzureAD -TenantId $tenantIdVal

# Create the audit app
$appName = "FractureLabsAuditApp"
$auditApp = New-AzureADApplication -DisplayName $appName 

# Create the client secret
$startDate = Get-Date
$endDate = $startDate.AddMonths(3)
$auditAppSecret = New-AzureADApplicationPasswordCredential -ObjectId $auditApp.ObjectId -CustomKeyIdentifier "FractureLabsAuditAppSecret" -StartDate $startDate -EndDate $endDate
Write-Output "The app key is: $($auditAppSecret.Value)"

# Create a Service Principal for the app and provide Read access
New-AzADServicePrincipal -ApplicationId $auditApp.ApplicationId -Role Reader
