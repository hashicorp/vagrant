#Requires -Modules VagrantMessages

param (
    [parameter (Mandatory=$true)]
    [Guid] $VMID,
    [parameter (Mandatory=$true)]
    [string] $Type
)

$ErrorActionPreference = "Stop"

try {
    $VM = Hyper-V\Get-VM -Id $VMID
} catch {
    Write-ErrorMessage "Failed to locate VM: ${PSItem}"
    exit 1
}

try {
    Hyper-V\Set-VM -VM $VM -EnhancedSessionTransportType $Type
} catch {
    Write-ErrorMessage "Failed to assign EnhancedSessionTransportType to ${Type}: ${PSItem}"
    exit 1
}
