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
"## MFA Authentication Methods" | Out-File .\MFAReport.md -Force -Encoding utf8
"" | Out-File .\MFAReport.md -Encoding utf8 -Append
"### Registered" | Out-File .\MFAReport.md -Encoding utf8 -Append
"The following methods has been registered by users:" | Out-File .\MFAReport.md -Encoding utf8 -Append
"" | Out-File .\MFAReport.md -Encoding utf8 -Append
"| Method | Count |"   | Out-File .\MFAReport.md -Encoding utf8 -Append
"|:-----------|:-----------|"   | Out-File .\MFAReport.md -Encoding utf8 -Append
"| Authentication Phone | " + [string]$authMethodsData.AuthPhoneRegistered + " |"  | Out-File .\MFAReport.md -Encoding utf8 -Append
"| Phone App | " + [string]$authMethodsData.AuthPhoneAppRegistered + " |" | Out-File .\MFAReport.md -Encoding utf8 -Append
"| Alternate Phone | " + [string]$authMethodsData.AlternatePhoneRegistered + " |" | Out-File .\MFAReport.md -Encoding utf8 -Append
"| Office Phone | " + [string]$authMethodsData.OfficePhoneRegistered + " |" | Out-File .\MFAReport.md -Encoding utf8 -Append
"" | Out-File .\MFAReport.md -Encoding utf8 -Append
"### Default Method" | Out-File .\MFAReport.md -Encoding utf8 -Append
"The following methods has been configured as default by users:" | Out-File .\MFAReport.md -Encoding utf8 -Append
"" | Out-File .\MFAReport.md -Encoding utf8 -Append
"| Method | Count |" | Out-File .\MFAReport.md -Encoding utf8 -Append
"|:-----------|:-----------|" | Out-File .\MFAReport.md -Encoding utf8 -Append
"| OneWay SMS | " + [string]$authMethodsData.OneWaySMSDefault + " |"   | Out-File .\MFAReport.md -Encoding utf8 -Append
"| Phone App Notification | " + [string]$authMethodsData.PhoneAppNotificationDefault + " |" | Out-File .\MFAReport.md -Encoding utf8 -Append
"| Phone App OTP | " + [string]$authMethodsData.PhoneAppOTPDefault + " |" | Out-File .\MFAReport.md -Encoding utf8 -Append
"| TwoWay Voice Mobile | " + [string]$authMethodsData.TwoWayVoiceMobileDefault + " |" | Out-File .\MFAReport.md -Encoding utf8 -Append
"| TwoWay Voice Office Phone | " + [string]$authMethodsData.TwoWayVoiceOfficeDefault + " |" | Out-File .\MFAReport.md -Encoding utf8 -Append
"" | Out-File .\MFAReport.md -Encoding utf8 -Append
"Last reported " + [string](Get-Date) | Out-File .\MFAReport.md -Encoding utf8 -Append
"<img width='10' src='https://portal.azure.com/favicon.ico'/>" | Out-File .\MFAReport.md -Encoding utf8 -Append
