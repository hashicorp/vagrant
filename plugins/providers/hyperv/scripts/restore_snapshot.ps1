#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$VmId,
    [string]$SnapName
)

$ErrorActionPreference = "Stop"

try {
    $VM = Hyper-V\Get-VM -Id $VmId
    Hyper-V\Restore-VMSnapshot $VM -Name $SnapName -Confirm:$false
} catch {
    Write-ErrorMessage "Failed to restore snapshot: ${PSItem}"
    exit 1
}
