#Requires -Modules VagrantMessages

param (
    [parameter (Mandatory=$true)]
    [string]$VmId,
    [parameter (Mandatory=$true)]
    [string]$Mac
)

$ErrorActionPreference = "Stop"

try {
    $vm = Hyper-V\Get-VM -Id $VmId
    Hyper-V\Set-VMNetworkAdapter $vm -StaticMacAddress $Mac
} catch {
    Write-ErrorMessage "Failed to set VM MAC address: ${PSItem}"
    exit 1
}
