---
Module Name: Group-Policy-Backup
Module Guid: 4ce32930-8476-4748-9011-fa152e80fdf6
Help Version: 1.3
Locale: en-US
---
# Group-Policy-Backup Module
## Description
A collection of PowerShell scripts needed to fully backup and document a enterprise Group Policy environment.
## Group-Policy-Backup Cmdlets
### [Check-GPPermissions](Docs/Check-GPPermissions.md)
Script to report GPOs in a domain that do not have accessible ACLs applied.
### [Get-GPLinks](Docs/Get-GPLinks.md)
Script to provide either a TXT or CSV report of linking relationships between OUs and GPOs.
### [Run-GPOBackup](Docs/Run-GPOBackup.md)
All-in-one GPO Backup Script. It leverages external modules/functions to create a robust backup of Group Policies in a domain.
