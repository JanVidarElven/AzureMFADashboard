<#
.SYNOPSIS 
    This Azure Automation runbook connects to Azure AD with MSOnline Module and Connect-MSOLService. 
    It lists all users StrongAuthentication Methods to report on MFA and save to a Markdown document. 
    You have to import the MSOnline module from the Automation module gallery, if it's not already there.

.DESCRIPTION
    This Azure Automation runbook connects to Azure AD with MSOnline Module and Connect-MSOLService. 
    It lists all users StrongAuthentication Methods to report on MFA and save to a Markdown document. 
    You have to import the MSOnline module from the Automation module gallery, if it's not already there.

    It is required to set up a credential for authenticating to Azure AD in the Automation assets store.
    This credential is used to authenticate against Azure AD and list StrongAuthentication methods.
    This user must be at least be a member of User Administrator Role, and excluded for any Conditional
    Access policies requiring MFA or other controls.

.PARAMETER AzureADCredentialName
    Required. Default is AzureADCredential. Name of credential asset in the Automation service with access to Azure AD.

.EXAMPLE
    .\MFAStrongAuthenticationUserReport.ps1 -AzureADCredentialName 

    AUTHOR: Jan Vidar Elven [MVP]
    LASTEDIT: July 9th, 2018  
#>
Param(
    [Parameter(Mandatory=$false)]
    [String] $AzureADCredentialName = "AzureADCredential"
)

# Retrieve credential from Automation asset store and authenticate to Azure AD
$AzureADCredential = Get-AutomationPSCredential -Name $AzureADCredentialName

# Connect to MSOnline PowerShell (Azure AD v1)
Connect-MsolService -Credential $AzureADCredential

# Get MFA Methods Registered as Hash Table
$authMethodsRegistered = Get-MsolUser -All | Where-Object {$_.StrongAuthenticationMethods -ne $null} | Select-Object -Property UserPrincipalName -ExpandProperty StrongAuthenticationMethods `
 | Group-Object MethodType -AsHashTable -AsString

 # Get Default MFA Methods as Hash Table
$authMethodsDefault = Get-MsolUser -All | Where-Object {$_.StrongAuthenticationMethods -ne $null} | Select-Object -Property UserPrincipalName -ExpandProperty StrongAuthenticationMethods `
 | Where-Object {$_.IsDefault -eq $true} | Group-Object MethodType -AsHashTable -AsString

# Create a Custom Object for MFA Data
$authMethodsData = New-Object PSObject
$authMethodsData | Add-Member -MemberType NoteProperty -Name AuthPhoneRegistered -Value $authMethodsRegistered.TwoWayVoiceMobile.Count
$authMethodsData | Add-Member -MemberType NoteProperty -Name AuthPhoneAppRegistered -Value $authMethodsRegistered.PhoneAppOTP.Count
$authMethodsData | Add-Member -MemberType NoteProperty -Name OfficePhoneRegistered -Value $authMethodsRegistered.TwoWayVoiceOffice.Count
$authMethodsData | Add-Member -MemberType NoteProperty -Name AlternatePhoneRegistered -Value $authMethodsRegistered.TwoWayVoiceAlternateMobile.Count
$authMethodsData | Add-Member -MemberType NoteProperty -Name OneWaySMSDefault –Value $authMethodsDefault.OneWaySMS.Count
$authMethodsData | Add-Member -MemberType NoteProperty -Name PhoneAppNotificationDefault –Value $authMethodsDefault.PhoneAppNotification.Count
$authMethodsData | Add-Member -MemberType NoteProperty -Name PhoneAppOTPDefault –Value $authMethodsDefault.PhoneAppOTP.Count
$authMethodsData | Add-Member -MemberType NoteProperty -Name TwoWayVoiceMobileDefault –Value $authMethodsDefault.TwoWayVoiceMobile.Count
$authMethodsData | Add-Member -MemberType NoteProperty -Name TwoWayVoiceOfficeDefault –Value $authMethodsDefault.TwoWayVoiceOffice.Count

# Write to Markdown variable
$MFAReport = "## MFA Authentication Methods`n`n"
$MFAReport = $MFAReport + "### Registered`n"
$MFAReport = $MFAReport + "The following methods has been registered by users:`n`n"
$MFAReport = $MFAReport + "| Method | Count |`n"   
$MFAReport = $MFAReport + "|:-----------|:-----------|`n"   
$MFAReport = $MFAReport + "| Authentication Phone | " + [string]$authMethodsData.AuthPhoneRegistered + " |`n" 
$MFAReport = $MFAReport + "| Phone App | " + [string]$authMethodsData.AuthPhoneAppRegistered + " |`n" 
$MFAReport = $MFAReport + "| Alternate Phone | " + [string]$authMethodsData.AlternatePhoneRegistered + " |`n" 
$MFAReport = $MFAReport + "| Office Phone | " + [string]$authMethodsData.OfficePhoneRegistered + " |`n`n"
$MFAReport = $MFAReport + "### Default Method`n" 
$MFAReport = $MFAReport + "The following methods has been configured as default by users:`n`n" 
$MFAReport = $MFAReport + "| Method | Count |`n"  
$MFAReport = $MFAReport + "|:-----------|:-----------|`n" 
$MFAReport = $MFAReport + "| OneWay SMS | " + [string]$authMethodsData.OneWaySMSDefault + " |`n"   
$MFAReport = $MFAReport + "| Phone App Notification | " + [string]$authMethodsData.PhoneAppNotificationDefault + " |`n" 
$MFAReport = $MFAReport + "| Phone App OTP | " + [string]$authMethodsData.PhoneAppOTPDefault + " |`n" 
$MFAReport = $MFAReport + "| TwoWay Voice Mobile | " + [string]$authMethodsData.TwoWayVoiceMobileDefault + " |`n" 
$MFAReport = $MFAReport + "| TwoWay Voice Office Phone | " + [string]$authMethodsData.TwoWayVoiceOfficeDefault + " |`n" 
$MFAReport = $MFAReport + "Last reported " + [string](Get-Date).AddHours(2) + "`n" 
$MFAReport = $MFAReport + "<img width='10' src='https://portal.azure.com/favicon.ico'/>`n" 

# Next log in to Azure Subscription
$connectionName = "AzureRunAsConnection"
# Get the connection "AzureRunAsConnection "
$servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         

"Logging in to Azure..."
Add-AzureRmAccount `
    -ServicePrincipal `
    -TenantId $servicePrincipalConnection.TenantId `
    -ApplicationId $servicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 

# Getting variables for dashboard resource group to deploy to
$dashboardResourceGroup = Get-AutomationVariable -Name 'EMSDashboardResourceGroup'

# Getting variables for dashboard resource name (only use allowed characters for this) and title (friendly display name)
$dashboardName = Get-AutomationVariable -Name 'EMSDashboardName'
$dashboardTitle = Get-AutomationVariable -Name 'EMSDashboardTitle'

# Convert to JSON format without escaping
$MFAReportJson = $MFAReport | ConvertTo-Json | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
$MFAReportJson
# Remove unneeded special character
$MFAReportJson = $MFAReportJson -replace '"',''

# Deploy resource custom dashboard where deployment template is externally located in my github repository
New-AzureRmResourceGroupDeployment -Name MFADashboardDeployment -ResourceGroupName $dashboardResourceGroup `
  -TemplateUri https://raw.githubusercontent.com/skillriver/AzureMFADashboard/master/DeploymentTemplateMFAReport.json `
  -markdownMFAContent $MFAReportJson -dashboardName $dashboardName -dashboardTitle $dashboardTitle
