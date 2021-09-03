function Get-GPOUnlinked {
<#
.SYNOPSIS
Script for evaluating unlinked GPOs

.DESCRIPTION
Get a list of all GPOs and then only select those that are unlinked. Join in information about the owner and description of the policy using calculated properties and the Get-GPO cmdlet. 
Then sort the results by their creation time and group them by owner. The final results are then written to a file.

.PARAMETER FilePath
The path to the file to write the results to.

.EXAMPLE
Get-GPOUnlinked -FilePath C:\Temp\UnlinkedGPOs.txt

This will save the results to a file called UnlinkedGPOs.txt in the C:\Temp directory. The script will also return the results to standard out. 
.NOTES
    Author: Paul Boyer
    Date: 9-3-2021
#>
    param (
        [Parameter()]
        [String]
        $FilePath
    )
        
    #Requires -Module GroupPolicy
    #Requires -Version 5.1

    # Import module for determining GPO Links. Evaluate if the module is already loaded. Perform error handling if the module cannot be located
        try{
            if($(get-module | Where-Object {"GPFunctions" -in $_.name} | Measure-Object).Count -lt 1){
                Import-Module "$PSScriptRoot\External\GPFunctions.psm1" -ErrorAction Stop
            }
        }   catch [System.IO.FileNotFoundException]{

            # Terminate process of the script if the requisite module cannot be imported
            Write-Error "Unable to locate module 'GPFunctions.psm1'" -Category ObjectNotFound 
            Exit;
        }

    # Get a list of all GPOs and then only select those that are unlinked. Join in information about the owner and description of the policy using calculated properties and the Get-GPO cmdlet.
    # Then sort the results by their creation time and group them by owner. The final results are then written to a file.
    Get-GPUnlinked | Where-Object {!$_.Linked} | Select-Object DisplayName, @{Name="Owner";Expression={(Get-GPO -GUID $_.Name.Trim('{}').Trim()).Owner}}, @{Name="DateModified";Expression={$_.whenChanged}}, @{Name="DateCreated"; Expression={$_.whenCreated}}, @{Name="Description";Expression={(Get-GPO -GUID $_.Name.Trim('{}')).Description}} | Sort-Object DateCreated | Group-Object Owner | ForEach-Object{
        if ($FilePath -ne $null){
            Tee-Object -InputObject $_.Name -File $FilePath -Append
            Tee-Object -InputObject $($_ | Select-Object -ExpandProperty Group | Format-Table -AutoSize | Out-String) -File $FilePath -Append
        }
        else{
            $_.Name
            $_ | Select-Object -ExpandProperty Group | Format-Table -AutoSize
       }
    } 
}