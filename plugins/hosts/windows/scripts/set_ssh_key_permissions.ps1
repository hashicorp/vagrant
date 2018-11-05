#Requires -Modules VagrantSSH

param(
    [Parameter(Mandatory=$true)]
    [string] $KeyPath,
    [Parameter(Mandatory=$false)]
    [string] $Principal=$null
)

$ErrorActionPreference = "Stop"

try {
    Set-SSHKeyPermissions -SSHKeyPath $KeyPath -Principal $Principal
} catch {
    Write-Error "Failed to set permissions on key: ${PSItem}"
    exit 1
}
