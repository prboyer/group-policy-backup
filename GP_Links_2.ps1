# Powershell script that reports what OUs in the domain have what GPOs linked to them. Intended for use with Group Policy backup as exported policies do not retain the link information.
# Paul B - 4-23-2020

# Destination of the report file. $Args[0] should be the output file path. If null or inaccessible, then save at script root
if ($args[0] -eq $null) {
    $logDir = $PSScriptRoot
}elseif(Test-Path $args[0]){
    $logDir = $args[0]
}else{
    $logDir = $PSScriptRoot
}

# Formatting
$s = "*************************************************************************************************************************************"

# Start logging 
New-Item -Path "$logDir\Link Report-$(Get-Date -Format 'yyyyMMdd').txt" -ItemType File
$file = Get-Item -Path "$logDir\Link Report-$(Get-Date -Format 'yyyyMMdd').txt"

# Import Functions
Import-Module "$PSScriptRoot\GPFunctions.psm1"

# Report all OUs in domain
$domainName = (Get-ADDomain).Forest
Write-Output "`n"
Write-Output "Organizational Units in $domainName" >> $file
Write-Output $s.Substring(0,(("Organizational Units in $domainName").Length)) >> $file
Get-ADOrganizationalUnit -Filter * | Select-Object DistinguishedName | Sort-Object -Property DistinguishedName | Format-Table >> $file

# Report all OUs in domain with linked GPOs
Write-Output "Organizational Units with Linked GPOS" >> $file
Write-Output $s.Substring(0,(("Organizational Units with Linked GPOS").Length)) >> $file
$OUList = Get-ADOrganizationalUnit -Filter * | Where-Object {$_.LinkedGroupPolicyObjects.Count -gt 0}
$OUList | Select-Object DistinguishedName | Sort-Object -Property DistinguishedName | Format-Table >> $file

# Report GPOS linked to domain root
$domainRoot = (Get-ADDomain).DistinguishedName
Write-Output "$domainRoot" >> $file
Write-Output $s.Substring(0,("$domainRoot").Length) >> $file
Get-GpLink -Path $domainRoot | Select-Object DisplayName, LinkEnabled, Enforced, BlockInheritance,GUID | Format-Table -AutoSize >> $file

# Report GPOs linked to each OU
$OUList | ForEach-Object {Write-Output "$($_.DistinguishedName)" >> $file; Write-Output $s.Substring(0,($_.DistinguishedName.Length)) >> $file;
Get-GPLink -Path $_.DistinguishedName | Select-Object DisplayName, LinkEnabled, Enforced, BlockInheritance,GUID | Format-Table -AutoSize >> $file}

#Mass Report that shows the one to many relationship of OUs and GPO Links
Write-Output "Correlation Table" >> $file
Write-Output $s.Substring(0,"Correleation Table".Length) >> $file

$reportArray = @();

$OUList += $domainRoot

foreach ($item in $OUList) {
    if($item.DistinguishedName -eq $domainRoot.DistinguishedName){
        $links = Get-ADDomain | select -ExpandProperty linkedgrouppolicyobjects | ForEach-Object {$_.Substring($_.IndexOf('{'),38)} 
        $links | ForEach-Object {$r = "" | Select-Object OU_Name, Linked_GUIDS; $r.OU_Name = (Get-ADDomain).DistinguishedName; $r.Linked_GUIDS = $_ ; $reportArray += $r;}
    }else{
        $links = Get-ADOrganizationalUnit -SearchBase $item.DistinguishedName -Filter * | select -ExpandProperty linkedgrouppolicyobjects | ForEach-Object {$_.Substring($_.IndexOf('{'),38)} 
        $links | ForEach-Object {$r = "" | Select-Object OU_Name, Linked_GUIDS; $r.OU_Name = $item.DistinguishedName; $r.Linked_GUIDS = $_ ; $reportArray += $r;}
    }
}

$reportArray | Format-Table -AutoSize >> $file