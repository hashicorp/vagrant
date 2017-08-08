Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId,
    [string]$SnapName
)

$VM = Hyper-V\Get-VM -Id $VmId -ErrorAction "Stop"
Hyper-V\Checkpoint-VM $VM -SnapshotName $SnapName 
