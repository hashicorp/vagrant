#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$VmId,
    [string]$SnapName
)

$ErrorActionPreference = "Stop"

try {
    $VM = Hyper-V\Get-VM -Id $VmId
    Hyper-V\Remove-VMSnapshot $VM -Name $SnapName
} catch {
    Write-ErrorMessage "Failed to delete snapshot: ${PSItem}"
}
