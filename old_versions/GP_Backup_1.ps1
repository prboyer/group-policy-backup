#Script to automate a routine backup of Group Policy. Paul B. 4-2-2020

# Location where GroupPolicy backups will be stored
$backupFolder = "\\sscwin.ads.ssc.wisc.edu\dfsroot\project\SSCC Staff\DISASTER\GroupPolicy"

# Variable for today's date
[String]$date = Get-Date -Format "MM-dd-yyyy"

# Retention period indicated as # of days to keep backups (function requires negative days to subtract from current date)
[int]$retentionThreshold = -15

# Begin Transcript
Start-Transcript -Verbose -Path "$backupFolder\$date\backup.log"

# Delete backups older than the specified retention period.
Get-ChildItem $backupFolder | Where-Object {$_.LastWriteTime -lt $((Get-Date).AddDays([int]$retentionThreshold))} | Remove-Item -Recurse -Force

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
Start-Process powershell.exe -ArgumentList "-NoProfile -File `"$PSScriptRoot\GP_Links.ps1`" `"$backupFolder\$date`"" -NoNewWindow -Wait

# Create archieve and compress
Compress-Archive -Path "$backupFolder\$date\*" -DestinationPath "$backupFolder\$date.zip"
Start-Sleep -Seconds 5
Remove-Item -Recurse -Path "$backupFolder\$date" -Force

# SIG # Begin signature block
# MIIOgwYJKoZIhvcNAQcCoIIOdDCCDnACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUrFOo6la/aUlBEYyP29lUdlZT
# 23OgggvOMIIFvDCCA6SgAwIBAgITHgAAAAjRvX7DjspE9AAAAAAACDANBgkqhkiG
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
# IwYJKoZIhvcNAQkEMRYEFJrhLVVTaRInzQfX/Fnt8elYKLStMA0GCSqGSIb3DQEB
# AQUABIIBAHPCfCZQNNyxCxhrWc6iEwV0Trci1XQkPZ/uf3WJ6uXpMMY/zwl0nwnq
# Odw5WdlXRt8vGPRlO90RC1ZLlVX+apdlsJMxurDwRjDfIDFanvw7sWYiEblZIeNq
# 5zgsotkyNuZFdzyERSIO9tGob6F2NMWO4OP64uMEbYgWm/BiHjOKuKLKDnHqizVt
# bdWUC4LhwSVBV6e6Lmjarmo40zGa2SrpSFq30e0/qa0kx5CQ5+9Fay+O5zLFbI2h
# Qsia7467W5khg5ygSNCDdgqHK/+2uvyQGvM1+4ogPiWSwDe+qxcgkVA6U6GiVOa4
# i/JVhtlmYkZvThYavpZmOrckXSYFWWc=
# SIG # End signature block
