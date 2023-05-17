# Define script root for PowerShell 2.0
$ScriptRoot = Split-Path $script:MyInvocation.MyCommand.Path

# Run the upstream bootstrap script with passthrough arguments
& "${ScriptRoot}\bootstrap_salt_upstream.ps1" @args
