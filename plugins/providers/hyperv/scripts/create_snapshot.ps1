#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$VmId,
    [string]$SnapName
)

$ErrorActionPreference = "Stop"

try {
    $VM = Hyper-V\Get-VM -Id $VmId
    $ChkPnt = $VM.CheckpointType
    if($ChkPnt -eq "Disabled") {
        Hyper-V\Set-VM -VM $VM -CheckpointType "Standard"
    }
    Hyper-V\Checkpoint-VM $VM -SnapshotName $SnapName
    if($ChkPnt -eq "Disabled") {
        Hyper-V\Set-VM -VM $VM -CheckpointType "Disabled"
    }
} catch {
    Write-ErrorMessage "Failed to create snapshot: ${PSItem}"
    exit 1
}
