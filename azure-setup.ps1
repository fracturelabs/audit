#Requires -Version 5.1
#Requires -Modules AzureAD.Standard.Preview, Az.Resources

Param (
    [Parameter(Mandatory=$false,HelpMessage="The tenantId for your Azure subscription")][Alias("tenantId")][string]$tenantIdVal
)


#
# Sign in
#

if($tenantIdVal)
{
    Write-Output "Connecting to tenant: $tenantIdVal"
    Connect-AzureAD -TenantId $tenantIdVal

} else {
    Write-Output "Connecting to the default tenant"
    Connect-AzureAD

}

$connected = $?

if(!($connected))
{
    Write-Error "Could not connect to AzureAD"
    exit 1
}

Write-Output "Connected to tenantId: $(Get-AzureADCurrentSessionInfo | Select-Object -ExpandProperty TenantId)"


#
# Create the audit app
#

$appName = "FractureLabsAuditApp"

if($auditApp = Get-AzureADApplication -Filter "DisplayName eq '$AppName'" -Top 1)
{
    Write-Output "Found an existing app registration "

} else {
    Write-Output "Creating the app registration"
    $auditApp = New-AzureADApplication -DisplayName $appName

}



#
# Create the client secret
#

if(Get-AzureADApplicationPasswordCredential -ObjectId $auditApp.ObjectId)
{
    Write-Output "Found an existing client secret"

} else {
    Write-Output "Creating the client secret"
    $startDate = Get-Date
    $endDate = $startDate.AddMonths(3)
    $auditAppSecret = New-AzureADApplicationPasswordCredential -ObjectId $auditApp.ObjectId -CustomKeyIdentifier "FractureLabsAuditAppSecret" -StartDate $startDate -EndDate $endDate
    Write-Output "The app key is: $($auditAppSecret.Value)"

}



#
# Create a Service Principal for the app and provide Read access
#

if(Get-AzADServicePrincipal -ApplicationId $auditApp.AppId)
{
    Write-Output "Found an existing Service Principal"

} else {
    Write-Output "Creating the Service Principal"
    New-AzADServicePrincipal -ApplicationId $auditApp.AppId -Role Reader

}



#
# Invite Auditor guest account
#
$auditorEmail = "auditor@fracturelabs.com"

if(Get-AzureADUser -Filter "Mail eq '$auditorEmail'")
{
    Write-Output "Found an existing guest auditor account"
} else {
    Write-Output "Sending a guest invitation to $auditorEmail"
    New-AzureADMSInvitation -InvitedUserDisplayName "Fracture Labs Auditor" -InvitedUserEmailAddress $auditorEmail -InviteRedirectUrl https://portal.azure.com-SendInvitationMessage $true
}


Write-Output "The app key is: $($auditAppSecret.Value)"

Write-Output "You must do the following manually through the portal:"
Write-Output "  1. Assign the Global Reader role to $auditorEmail"
Write-Output "     > Subscription | IAM | Add Role Assignment"
Write-Output "  2. Assign API permissions to $appName"
Write-Output "     > App Registrations | $appName | API Permissions"
Write-Output "     > Azure Service Management - user_impersonation (Delegated)"
Write-Output "     > Microsoft Graph - Directory.ReadAll & User.Read (Delegated)"
