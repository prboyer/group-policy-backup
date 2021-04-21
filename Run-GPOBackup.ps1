function Run-GPOBackup {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if(-not (Test-Path $_)){
                New-Item -Type Directory -Path $(Split-Path $_ -Parent) -Name $(Split-Path $_ -Leaf)
            }
        })]
        [String]
        $BackupFolder,
        [Parameter()]
        [String]
        $Domain
    )
    #Requires -Module ActiveDirectory
    
    # Import required module
    Import-Module $PSScriptRoot\External\GPFunctions.psm1

    ## CONSTANT Variables ##
        # Path to the location of Backup_GPOs.ps1
        [String]$global:BACKUP_GPOS = "$PSScriptRoot\External\BackUp_GPOs.ps1"

        # Path to the location of Get-GPLinks.ps1
        [String]$global:GET_GPLINKS = "$PSScriptRoot\Get-GPLinks.ps1"

        # Variable for today's date
        [String]$global:DATE = Get-Date -Format FileDateTimeUniversal

        # Information variable
        [String]$INFO
    
    ##

    # Assign value to the $BackupDomain variable if none supplied at runtime
    [String]$global:BackupDomain;
    if($Domain -ne ""){
        $BackupDomain = $Domain;
    }else{
        $BackupDomain = $(Get-ADDomain).Forest
    }

    # Start GPO Backup Job (takes parameters in positional order only)
    Write-Information "Begin local background job: BackupJob - Executes BackUp_GPOS.ps1" -InformationVariable +INFO
    $BackupJob = Start-Job -Name "BackupJob" -FilePath $global:BACKUP_GPOS -ArgumentList $BackupDomain,$BackupFolder 
  

    # Start GPO Links Job
    Write-Information "Begin local background job: LinksJob - Executes Get-GPLinks.ps1" -InformationVariable +INFO   
    $LinksJob = Start-Job -Name "LinksJob" -ArgumentList $BackupFolder -ScriptBlock {
        # Import requried module
        . $using:GET_GPLINKS

        # Run the script
        Get-GPLinks -BothReport -Path "$args"
    } 

    # Wait for the backup jobs to finish, then zip up the files
    Wait-Job -Job $BackupJob,$LinksJob
    Compress-Archive -Path $BackupFolder -DestinationPath "$(Split-Path $BackupFolder -Parent)\$DATE.zip"

    # [System.IO.DirectoryInfo]$currentBackup = (Get-ChildItem $BackupFolder | Sort-Object -Descending -Property LastWriteTime)[0]


}
Run-GPOBackup -BackupFolder $PSScriptRoot\Job 