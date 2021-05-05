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
Start-Transcript -Path "$logDir\Link Report-$(Get-Date -Format FileDate).txt"

# Import Functions
Import-Module "$PSScriptRoot\GPFunctions.psm1"

# Report all OUs in domain
$domainName = (Get-ADDomain).Forest
Write-Host "`n"
Write-Host -ForegroundColor Yellow "Organizational Units in $domainName"
Write-Host $s.Substring(0,(("Organizational Units in $domainName").Length))
Get-ADOrganizationalUnit -Filter * | Select-Object DistinguishedName | Sort-Object -Property DistinguishedName | Format-Table

# Report all OUs in domain with linked GPOs
Write-Host -ForegroundColor Yellow "Organizational Units with Linked GPOS"
Write-Host $s.Substring(0,(("Organizational Units with Linked GPOS").Length))
$OUList = Get-ADOrganizationalUnit -Filter * | Where-Object {$_.LinkedGroupPolicyObjects.Count -gt 0}
$OUList | Select-Object DistinguishedName | Sort-Object -Property DistinguishedName | Format-Table

# Report GPOS linked to domain root
$domainRoot = (Get-ADDomain).DistinguishedName
Write-Host -ForegroundColor Yellow "$domainRoot"
Write-Host $s.Substring(0,("$domainRoot").Length)
Get-GpLink -Path $domainRoot | Select-Object DisplayName, LinkEnabled, Enforced, BlockInheritance,GUID | Format-Table -AutoSize

# Report GPOs linked to each OU
$OUList | ForEach-Object {Write-Host -ForegroundColor Yellow "$($_.DistinguishedName)" ; Write-Host $s.Substring(0,($_.DistinguishedName.Length));
Get-GPLink -Path $_.DistinguishedName | Select-Object DisplayName, LinkEnabled, Enforced, BlockInheritance,GUID | Format-Table -AutoSize}

#Mass Report that shows the one to many relationship of OUs and GPO Links
Write-Host "Correlation Table" -ForegroundColor Yellow
Write-Host $s.Substring(0,"Correleation Table".Length)

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

$reportArray | Format-Table -AutoSize

# Stop logging
Stop-Transcript


# SIG # Begin signature block
# MIIOgwYJKoZIhvcNAQcCoIIOdDCCDnACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUh6NXZO4//AGPDAPkTHOXzjT8
# oPKgggvOMIIFvDCCA6SgAwIBAgITHgAAAAjRvX7DjspE9AAAAAAACDANBgkqhkiG
# 9w0BAQsFADB1MRMwEQYKCZImiZPyLGQBGRYDZWR1MRQwEgYKCZImiZPyLGQBGRYE
# d2lzYzETMBEGCgmSJomT8ixkARkWA3NzYzETMBEGCgmSJomT8ixkARkWA2FkczEe
# MBwGA1UEAxMVU1NDQ1Jvb3RDZXJ0QXV0aG9yaXR5MB4XDTE4MTIxMTIxMTY1NFoX
# DTIzMTIxMTIxMjY1NFowZzETMBEGCgmSJomT8ixkARkWA2VkdTEUMBIGCgmSJomT
# 8ixkARkWBHdpc2MxEzARBgoJkiaJk/IsZAEZFgNzc2MxEzARBgoJkiaJk/IsZAEZ
# FgNhZHMxEDAOBgNVBAMTB1NTQ0MgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
# ggEKAoIBAQC4x+jiZP66RVCKJEhDddCX5HmBV7gdtyul5zAdugwPaqiOkXT+xWBY
# 8HeFTCvNftAvrrYAJfl18VrbS95A/sjXWsinX3CHoXCE0Qs3yBFy7UQurFVHsLkz
# Tdq/5pRHJAtOcx0uUCwoAYUhhkG+blpSkXw6JgOQNI2XWN8vzlDTbQ8JCr/Wj+ex
# 2MNJpXrd/cBSc76kUvEhW+gAJJBCiTUWSYK5Cxe9vsQPACfcCDAE5SmuOyRpTFj4
# Nw0A4VjPAskUfpnOIxcllZL+sdbeBAZ1cAu7EY5CyKrHKC+iqMYv012aT4WJf5Ok
# VzWHodI1bO43GtRVyCWdIBF5t7TQME99AgMBAAGjggFRMIIBTTAQBgkrBgEEAYI3
# FQEEAwIBATAjBgkrBgEEAYI3FQIEFgQU5JUeo22fvT6ZWUeQUv5tNUECXggwHQYD
# VR0OBBYEFJucPDsOj4fHFNBuavgyLcmy5aiOMBkGCSsGAQQBgjcUAgQMHgoAUwB1
# AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaA
# FHu0uMuXGTAdHazdkc+XVIuSke/TMEcGA1UdHwRAMD4wPKA6oDiGNmh0dHA6Ly9j
# ZXJ0LnNzYy53aXNjLmVkdS9DRFAvU1NDQ1Jvb3RDZXJ0QXV0aG9yaXR5LmNybDBS
# BggrBgEFBQcBAQRGMEQwQgYIKwYBBQUHMAKGNmh0dHA6Ly9jZXJ0LnNzYy53aXNj
# LmVkdS9jZHAvU1NDQ1Jvb3RDZXJ0QXV0aG9yaXR5LmNydDANBgkqhkiG9w0BAQsF
# AAOCAgEALqjbBWFxNMELQtvxQYHmP4yln038iQjX3o8jJxvmC/5cZwCg7jw8asdf
# lRqYR8ZGFqzGRv040ECHhicjjVKnSxcNRuQCKR+Yoz83nAQXovhU/mtP/+3PKv9N
# l/9rMAP6LZ8t49fo/BsiKMTFmVc88KCc8yuKi2ie94GherAP02b5U52A3JLRgfFW
# tXISWGY2uS6nBvxw1MWw9+5xfUH+EROdrNIXLce+ypEzHTR7C1g2QllFP65nf6cB
# WUV6Tng2eCraZl23ieZcf+OX1GMFx83LK5NGsaUsZvH7oQTq456USsah/6gNrS3C
# hE6Ir30sL93bpNtr7szrsvf2a9AnqgF80ExU3k+WROGeFor1nRw3yp1GPRXa5U9M
# Z9+wYD/dyNd48riUIOTAgcjTcaHAxJVsYeSj8Lcqxh7acJ6W2e5TYi7tgQ6unCNF
# pgIJ9er2eefd12w9OJIJDdbicJbXoe6QreLeIQMwust9qkBlxb2oiTvBJj7tfLnd
# 9x0EIr+oh+opRW96wJRsxYCs6iro0N7bSiVYbMaXGEOSkGJsaCXyDy6580RmskrF
# zXAdLADHSdVjCKJ/trH4ArYxXRU3gA4wqlc0Pr950+wypoJsE7l4bKHMaf6v+AGO
# 7GH1lo3fjpCgK/m7qnsrVl+ylvfH0QeuDkal8DDp3SC+DkNbZNYwggYKMIIE8qAD
# AgECAhMZAAAvgi/AXXfejLtDAAEAAC+CMA0GCSqGSIb3DQEBCwUAMGcxEzARBgoJ
# kiaJk/IsZAEZFgNlZHUxFDASBgoJkiaJk/IsZAEZFgR3aXNjMRMwEQYKCZImiZPy
# LGQBGRYDc3NjMRMwEQYKCZImiZPyLGQBGRYDYWRzMRAwDgYDVQQDEwdTU0NDIENB
# MB4XDTIwMDQxNDE3MTMyMVoXDTIyMDQxNDE3MTMyMVowFTETMBEGA1UEAxMKUGF1
# bCBCb3llcjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANDaFi+f3bbp
# HoXchIz9lsOyFHdWjIwU25D38jaoNsLAvDxLRRhe/hJRAiplr7073atVUuyB3Jd4
# qckr24lfwuEN4mGtprgLhQaJY0L9cd7dxBwPQuwmw8PypNRPmJox1Zl9STvBlvYg
# OsXkWJU2N+/FyqFrPPkZ8dniWG0L9JqKXC3QrAPZLVm0KOBOCI09renm/N5oi0Bu
# dGUtsSUt+SY+0KA8KM0Y0cKRSUDcmJSeT/8tHQnd1urZ1I/yKD+F0GRXhl4J3Fay
# oNyFOGsxvulCkjqiscDgyB0o5gKGYM+LG+JXyKKWZRaSZl4DRoUGsMBZSzkmg1iO
# ckPph1v6N/0CAwEAAaOCAv8wggL7MD0GCSsGAQQBgjcVBwQwMC4GJisGAQQBgjcV
# CIXyvGaBt7Vqh9GbPoXpxRaC+Z5dLISosRqBpNpkAgFkAgEGMBMGA1UdJQQMMAoG
# CCsGAQUFBwMDMA4GA1UdDwEB/wQEAwIHgDAbBgkrBgEEAYI3FQoEDjAMMAoGCCsG
# AQUFBwMDMB0GA1UdDgQWBBQuCyWOqOdAepuTFboIU+V9Kf2KdjAfBgNVHSMEGDAW
# gBSbnDw7Do+HxxTQbmr4Mi3JsuWojjCCAQAGA1UdHwSB+DCB9TCB8qCB76CB7IaB
# vWxkYXA6Ly8vQ049U1NDQyUyMENBLENOPVNTQ0NTdWJDYSxDTj1DRFAsQ049UHVi
# bGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlv
# bixEQz1hZHMsREM9c3NjLERDPXdpc2MsREM9ZWR1P2NlcnRpZmljYXRlUmV2b2Nh
# dGlvbkxpc3Q/YmFzZT9vYmplY3RDbGFzcz1jUkxEaXN0cmlidXRpb25Qb2ludIYq
# aHR0cDovL2NlcnQuc3NjLndpc2MuZWR1L2NkcC9TU0NDJTIwQ0EuY3JsMIH+Bggr
# BgEFBQcBAQSB8TCB7jCBswYIKwYBBQUHMAKGgaZsZGFwOi8vL0NOPVNTQ0MlMjBD
# QSxDTj1BSUEsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMs
# Q049Q29uZmlndXJhdGlvbixEQz1hZHMsREM9c3NjLERDPXdpc2MsREM9ZWR1P2NB
# Q2VydGlmaWNhdGU/YmFzZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0aW9uQXV0aG9y
# aXR5MDYGCCsGAQUFBzAChipodHRwOi8vY2VydC5zc2Mud2lzYy5lZHUvY2RwL1NT
# Q0MlMjBDQS5jcnQwMwYDVR0RBCwwKqAoBgorBgEEAYI3FAIDoBoMGHBib3llcjJA
# YWRzLnNzYy53aXNjLmVkdTANBgkqhkiG9w0BAQsFAAOCAQEANIfgfRwgh1VYrItf
# ibq0yf/2B/2qk/aMG10mDO7qxdkLIAnyUI4WQKOq0F0f/buvQvDIjBT26znagwCO
# n6JoO9j3orgDxDJ5K9SQ3DGPuhMz6t90gSt6pk2WF9V0ELSd+yrMmHHOMgrMmQ7j
# Do2mrTpAEA9Es3Z3c8gv8GjckHAo4JZqJ0rAtogKhIsD4AfP2HAJaRH3q80YJ3vq
# zoGbF6MvHLSgop+fePvxnSWiM/9qaq+xeK5sWqV3G4G7nX6932yju8q/nzr3uaVN
# PfZ/0ACfZPu9lXoPhZctK2lkiqVj25WBewX8+s/YAeD/Opz1tok5pQ98PsNmdCt+
# kv7CtzGCAh8wggIbAgEBMH4wZzETMBEGCgmSJomT8ixkARkWA2VkdTEUMBIGCgmS
# JomT8ixkARkWBHdpc2MxEzARBgoJkiaJk/IsZAEZFgNzc2MxEzARBgoJkiaJk/Is
# ZAEZFgNhZHMxEDAOBgNVBAMTB1NTQ0MgQ0ECExkAAC+CL8Bdd96Mu0MAAQAAL4Iw
# CQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcN
# AQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUw
# IwYJKoZIhvcNAQkEMRYEFDgnVRMAivdUP2YQlvQ43SYrlPcMMA0GCSqGSIb3DQEB
# AQUABIIBAGEVV6M+VATQ63gI7TCs/6aI34snaaIYdQYKpRKD2hFnBp+kdi4Xo7JH
# cDwuqBfCIaxLepaZcKv5ngBCZwCTf0lIgmLqGLylzcSXYU0c98g3Abad+MdFu+zp
# aEfl8UYs749jbKM9OCDe0GH4tBTM1QDpKYezRhS8TEG4QcLA036/5Zc8kIKQreGT
# wXiDpjbKO1Kv9e1PXeCxyvODWLVF/X0cTaRGInB6QplcLAKHp3uIxSMeTJHYfvrP
# N3ybRvWtu40F/Bj85K6q1pB8O1B1ZXVW494cM8D+vHz/sZUf6RVs+ear1+oKjWUv
# FjqOygKnuYqzMTqeSoEzeyC0oubjl6M=
# SIG # End signature block
