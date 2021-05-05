#Script to automate a routine backup of Group Policy. Paul B. 4-2-2020

# Location where GroupPolicy backups will be stored
$backupFolder = "\\sscwin.ads.ssc.wisc.edu\dfsroot\project\SSCC Staff\DISASTER\GroupPolicy"

# Variable for today's date
[String]$date = Get-Date -Format "MM-dd-yyyy"

# Retention period indicated as # of days to keep backups (function requires negative days to subtract from current date)
[int]$retentionThreshold = -15

# Begin Transcript
Start-Transcript -Verbose -Path "$backupFolder\$date\backup.log"

# Make folders for new backup
New-Item -ItemType Directory -Path $backupFolder -Name $date -Force
New-Item -ItemType Directory -Path "$backupFolder\$date" -Name "Policies" -Force

# Export Group Policies
Backup-GPO -Domain "ads.ssc.wisc.edu" -All -Path "$backupFolder\$date\Policies" -Verbose -Comment "Automated Backup - $date"

# Copy Policy Definitions from Central Store
Copy-Item -Path "\\sscwinnt\SYSVOL\ads.ssc.wisc.edu\Policies\PolicyDefinitions" -Destination "$backupFolder\$date\Policies" -Recurse -Verbose

# Copy additional directories
Copy-Item -Path "\\sscwinnt\SYSVOL\ads.ssc.wisc.edu\scripts" -Destination "$backupFolder\$date\" -Recurse -Verbose
Copy-Item -Path "\\sscwinnt\SYSVOL\ads.ssc.wisc.edu\StarterGPOs"-Destination "$backupFolder\$date\" -Recurse -Verbose

# Stop transcript
Stop-Transcript

# Run GP Link Report
Start-Process powershell.exe -ArgumentList "-NoProfile -File `"$PSScriptRoot\GP_Links_2.ps1`" `"$backupFolder\$date`"" -Wait

# Create archieve and compress
Compress-Archive -Path "$backupFolder\$date\*" -DestinationPath "$backupFolder\$date.zip"
Start-Sleep -Seconds 5

# Compare file hashes
$backups = Get-ChildItem -Path $backupFolder -Filter '*.zip' | Sort-Object -Property LastWriteTime -Descending

$currentZip = Get-FileHash -Path $backups[0].FullName -Algorithm MD5
$recentZip = Get-FileHash -Path $backups[1].FullName -Algorithm MD5

# If backup does not contain deltas, delete the backup
if($currentZip.Hash -eq $recentZip.Hash){
    Get-Item $backups[0].FullName | Remove-Item -Recurse -Force
}

# Remove the working directory
Write-Host "Remove Working Folder" -ForegroundColor Yellow
Remove-Item -Recurse -Path "$backupFolder\$date" -Force

# Perform cleanup of older backups if the directory has more than 10 archives 
if ((Get-ChildItem $backupFolder | Measure-Object).Count -gt 10) {
   
    # Delete backups older than the specified retention period, however keep a minimum of 5 recent backups.
    Get-ChildItem $backupFolder | Sort-Object -Property LastWriteTime -Descending | Select-Object -Skip 5 | Where-Object {$_.LastWriteTime -lt $((Get-Date).AddDays([int]$retentionThreshold))} | Remove-Item -Recurse -Force

}