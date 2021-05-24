# Powershell supports only TLS 1.0 by default. Add support for TLS 1.2 and TLS 1.3
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls12,Tls13'

# Define script root for PowerShell 2.0
$ScriptRoot = Split-Path $script:MyInvocation.MyCommand.Path

# Download the upstream bootstrap script
(New-Object System.Net.WebClient).DownloadFile('https://winbootstrap.saltproject.io', "${ScriptRoot}\bootstrap_salt_upstream.ps1")

# Run the upstream bootstrap script with passthrough arguments
& "${ScriptRoot}\bootstrap_salt_upstream.ps1" @args
