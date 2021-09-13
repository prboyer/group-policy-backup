function Get-GPOUnlinked {
<#
.SYNOPSIS
Script for evaluating unlinked GPOs

.DESCRIPTION
Get a list of all GPOs and then only select those that are unlinked. Join in information about the owner and description of the policy using calculated properties and the Get-GPO cmdlet. 
Then sort the results by their creation time and group them by owner. The final results are then written to a file.

.PARAMETER FilePath
The path to the file to write the results to.

.PARAMETER SendEmail
Switch parameter that tells the script to send the results in an email

.PARAMETER To
String array of email addresses 
    
.PARAMETER CC
String array of email addresses 
    
.PARAMETER BCC
String array of email addresses 

.EXAMPLE
Get-GPOUnlinked -FilePath C:\Temp\UnlinkedGPOs.txt

This will save the results to a file called UnlinkedGPOs.txt in the C:\Temp directory. The script will also return the results to standard out.

.EXAMPLE
Get-GPOUnlinked -SendEmail -To bbadger@wisc.edu 

This will email the results to bbadger@wisc.edu

.NOTES
    Author: Paul Boyer
    Date: 9-3-2021
#>
    param (
        [Parameter()]
        [String]
        $FilePath,
        [Parameter(ParameterSetName="Email")]
        [Switch]
        $SendEmail,
        [Parameter(ParameterSetName="Email", Mandatory=$true)]
        [String[]]
        $To,
        [Parameter(ParameterSetName="Email")]
        [String[]]
        $CC,
        [Parameter(ParameterSetName="Email")]
        [String[]]
        $BCC
    )
        
    #Requires -Module GroupPolicy
    #Requires -Version 5.1

    function private:Send-Email {
        <#
        .SYNOPSIS
        Script that generates and sends an Email message.
        
        .DESCRIPTION
        Due to the deprecation of Send-MailMessage cmdlet, this script leverages the .NET libraries to construct and email and send it to a user.
        
        .PARAMETER To
        String array of email addresses 
        
        .PARAMETER CC
        String array of email addresses 
        
        .PARAMETER BCC
        String array of email addresses 
        
        .PARAMETER Subject
        String for the subject line of the mail message
    
        .PARAMETER Attachments
        String array of paths to files to attach to the email
        
        .PARAMETER Body
        String to place into the body of the email
        
        .PARAMETER Unauthenticated
        Switch that indicates the SMTP server does not require credentials
        
        .PARAMETER HTML
        Switch that indicates that the -Body String is formatted in HTML
    
        .EXAMPLE
        Send-Email -To bbadger@wisc.edu -Subject "Tuition is Due" -Body "Your Tuition Bill is available online"
        
        .NOTES
            Author: Paul Boyer
            Date: 4-9-20201
    
        .LINK
        https://stackoverflow.com/questions/36355271/how-to-send-email-with-powershell
    
        .LINK
        https://docs.microsoft.com/en-us/dotnet/api/system.net.mail?view=net-5.0
    
        #>
        param (
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $To,
            [Parameter(Mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CC,
            [Parameter(Mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $BCC,
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [String]
            $Subject,
            [Parameter(Mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Attachments,
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [String]
            $Body,
            [Parameter()]
            [switch]
            $Unauthenticated,
            [Parameter()]
            [switch]
            $HTML
    
        )
        # Variables #
            # SMTP Server Configuration
            [String]$SMTP_SERVER = "smtp.ssc.wisc.edu"
            [Int]$SMTP_PORT = 587
            [String]$USERNAME = ""
            [String]$PASSWORD = ""
    
            # Sender Information
            [String]$SENDER_NAME = "SSCC"
            [String]$SENDER_EMAIL = "donotreply@ssc.wisc.edu"
            [String]$SENDER_REPLYTO = "helpdesk@ssc.wisc.edu"
    
        #########
        # Create new MailMessage Object
        [System.Net.Mail.MailMessage]$Message = [System.Net.Mail.MailMessage]::new();
    
        # Add sender information to the message
        [System.Net.Mail.MailAddress]$Sender = [System.Net.Mail.MailAddress]::new($SENDER_EMAIL, $SENDER_NAME);
        $Message.From = $Sender;
        $Message.Sender = $Sender;
        $Message.ReplyTo = $SENDER_REPLYTO;
    
        # Address the message
        $Message.To.Add($To)
        if($null -ne $CC){
            $Message.CC.Add($CC) 
        }
        
        if($null -ne $BCC){
            $Message.Bcc.Add($BCC)
        }
    
        # Compose the message
        $Message.Subject = $Subject
        $Message.Body = $Body
    
        # Set the body formatting mode to HTML if -HTML passed
        if ($HTML) {
            $Message.IsBodyHtml = $true;
        }
    
        # Handle Attachments
        if ($null -ne $Attachments) {
            foreach($a in $Attachments){
                $AttachmentObject = New-Object Net.Mail.Attachment($a);
                $Message.Attachments.Add($AttachmentObject);
            }
        }
    
        # Send the message
        [Net.Mail.SmtpClient]$Smtp = [Net.Mail.SmtpClient]::new()
        $Smtp.EnableSsl = $true;
        $Smtp.Port = $SMTP_PORT
        $Smtp.Host = $SMTP_SERVER
    
            # Create credentials
            if (-not $Unauthenticated) {
                [System.Net.NetworkCredential]$Credentials = [System.Net.NetworkCredential]::new()
                $Credentials.UserName = $USERNAME
                $Credentials.Password = $PASSWORD
                $Smtp.Credentials = $Credentials;
            }
        
        $Smtp.Send($Message);
    
        # Cleanup
        try{
            $AttachmentObject.Dispose();
        }catch [System.Management.Automation.RuntimeException] {
            if ($null -eq $Attachments) {
                Write-Warning -Message "No attachment object passed. Unable to dispose of null object."
            }else{
                Write-Warning -Message "Unable to dispose of attachment object."
            }
        }
    }
    

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
    
    # Only process if the -SendEmail parameter was specified
    if ($SendEmail) {
        # Set the $FilePath parameter
        $FilePath = "$PSScriptRoot\UnlikedGPOReport_$(Get-Date -Format FileDateTimeUniversal).txt"
        
        # Get a list of all GPOs and then only select those that are unlinked. Join in information about the owner and description of the policy using calculated properties and the Get-GPO cmdlet.
        # Then sort the results by their creation time and group them by owner. The final results are then written to a file.
        Get-GPUnlinked | Where-Object {!$_.Linked} | Select-Object DisplayName, @{Name="Owner";Expression={(Get-GPO -GUID $_.Name.Trim('{}').Trim()).Owner}}, @{Name="DateModified";Expression={$_.whenChanged}}, @{Name="DateCreated"; Expression={$_.whenCreated}}, @{Name="Description";Expression={(Get-GPO -GUID $_.Name.Trim('{}')).Description}} | Sort-Object DateCreated | Group-Object Owner | ForEach-Object{
                Tee-Object -InputObject $_.Name -File $FilePath -Append
                Tee-Object -InputObject $($_ | Select-Object -ExpandProperty Group | Format-Table -AutoSize | Out-String) -File $FilePath -Append
        }

        <# Prepare to send the email with the results #>
        # Create a string to store the email body message
        [string]$EmailBody = "Attached are the results of Get-GPOUnlinked.ps1; a report to gather all unlinked GPOs in the domain. The results are grouped by owner and sorted by creation time. The results can be found below or in the attached text file. Please do not reply to this message. It was systematically generated from $($env:COMPUTERNAME)."

        # Handle sending the email to the appropriate addresses based on how they are specifed (To, CC, BCC)
        if ($To -ne $null -and $CC -ne $null -and $BCC -ne $null) {
            private:Send-Email -To $To -CC $CC -BCC $BCC -Subject "Unlinked GPO Report - $(Get-Date -Format "d")" -Unauthenticated -Attachments $FilePath -Body $EmailBody 
        }elseif($To -ne $null -and $CC -ne $null){
            private:Send-Email -To $To -CC $CC -Subject "Unlinked GPO Report - $(Get-Date -Format "d")" -Unauthenticated -Attachments $FilePath -Body $EmailBody 
        }else{
            private:Send-Email -To $To -Subject "Unlinked GPO Report - $(Get-Date -Format "d")" -Unauthenticated -Attachments $FilePath -Body $EmailBody
        }
    
        # Cleanup by removing the file from $PSScriptRoot
        Remove-Item -Force -Path $FilePath

    }
    else{
    # Get a list of all GPOs and then only select those that are unlinked. Join in information about the owner and description of the policy using calculated properties and the Get-GPO cmdlet.
    # Then sort the results by their creation time and group them by owner. The final results are then written to a file.
        Get-GPUnlinked | Where-Object {!$_.Linked} | Select-Object DisplayName, @{Name="Owner";Expression={(Get-GPO -GUID $_.Name.Trim('{}').Trim()).Owner}}, @{Name="DateModified";Expression={$_.whenChanged}}, @{Name="DateCreated"; Expression={$_.whenCreated}}, @{Name="Description";Expression={(Get-GPO -GUID $_.Name.Trim('{}')).Description}} | Sort-Object DateCreated | Group-Object Owner | ForEach-Object{
            if ($FilePath -ne ""){
                Tee-Object -InputObject $_.Name -File $FilePath -Append
                Tee-Object -InputObject $($_ | Select-Object -ExpandProperty Group | Format-Table -AutoSize | Out-String) -File $FilePath -Append
            }
            else{
                $_.Name
                $_ | Select-Object -ExpandProperty Group | Format-Table -AutoSize
            }
        }
    }
}