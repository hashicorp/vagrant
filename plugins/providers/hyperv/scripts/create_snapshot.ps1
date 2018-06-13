#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$VmId,
    [string]$SnapName
)

$ErrorActionPreference = "Stop"

try {
    $VM = Hyper-V\Get-VM -Id $VmId
    Hyper-V\Checkpoint-VM $VM -SnapshotName $SnapName
} catch {
    Write-Error-Message "Failed to create snapshot: ${PSItem}"
    exit 1
}
