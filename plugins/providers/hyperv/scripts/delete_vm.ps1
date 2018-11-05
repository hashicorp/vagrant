#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

$ErrorActionPreference = "Stop"

try {
    $VM = Hyper-V\Get-VM -Id $VmId
    Hyper-V\Remove-VM $VM -Force
} catch {
    Write-ErrorMessage "Failed to delete VM: ${PSItem}"
    exit 1
}
