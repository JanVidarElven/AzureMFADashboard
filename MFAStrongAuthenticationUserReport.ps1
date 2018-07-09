# Connect to MSOnline PowerShell (Azure AD v1)
Connect-MsolService

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

# Write to Markdown file
"## MFA Authentication Methods`n" | Set-Content .\MFAReport.md -Force -Encoding UTF8
"### Registered`n" | Add-Content .\MFAReport.md -Encoding UTF8 
"The following methods has been registered by users:`n" | Add-Content .\MFAReport.md -Encoding UTF8 
"| Method | Count |"   | Add-Content .\MFAReport.md -Encoding UTF8 
"|:-----------|:-----------|"   | Add-Content .\MFAReport.md -Encoding UTF8 
"| Authentication Phone | " + [string]$authMethodsData.AuthPhoneRegistered + " |"  | Add-Content .\MFAReport.md -Encoding UTF8 
"| Phone App | " + [string]$authMethodsData.AuthPhoneAppRegistered + " |" | Add-Content .\MFAReport.md -Encoding UTF8 
"| Alternate Phone | " + [string]$authMethodsData.AlternatePhoneRegistered + " |" | Add-Content .\MFAReport.md -Encoding UTF8 
"| Office Phone | " + [string]$authMethodsData.OfficePhoneRegistered + " |" | Add-Content .\MFAReport.md -Encoding UTF8 
"" | Add-Content .\MFAReport.md -Encoding UTF8 
"### Default Method" | Add-Content .\MFAReport.md -Encoding UTF8 
"The following methods has been configured as default by users:" | Add-Content .\MFAReport.md -Encoding UTF8 
"" | Add-Content .\MFAReport.md -Encoding UTF8 
"| Method | Count |" | Add-Content .\MFAReport.md -Encoding UTF8 
"|:-----------|:-----------|" | Add-Content .\MFAReport.md -Encoding UTF8 
"| OneWay SMS | " + [string]$authMethodsData.OneWaySMSDefault + " |"   | Add-Content .\MFAReport.md -Encoding UTF8 
"| Phone App Notification | " + [string]$authMethodsData.PhoneAppNotificationDefault + " |" | Add-Content .\MFAReport.md -Encoding UTF8 
"| Phone App OTP | " + [string]$authMethodsData.PhoneAppOTPDefault + " |" | Add-Content .\MFAReport.md -Encoding UTF8 
"| TwoWay Voice Mobile | " + [string]$authMethodsData.TwoWayVoiceMobileDefault + " |" | Add-Content .\MFAReport.md -Encoding UTF8 
"| TwoWay Voice Office Phone | " + [string]$authMethodsData.TwoWayVoiceOfficeDefault + " |`n" | Add-Content .\MFAReport.md -Encoding UTF8 
"Last reported " + [string](Get-Date) | Add-Content .\MFAReport.md -Encoding UTF8 
"<img width='10' src='https://portal.azure.com/favicon.ico'/>" | Add-Content .\MFAReport.md

