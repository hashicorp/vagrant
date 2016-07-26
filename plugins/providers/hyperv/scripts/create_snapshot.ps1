Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId,
    [string]$SnapName
)

$VM = Get-VM -Id $VmId -ErrorAction "Stop"
Checkpoint-VM $VM -SnapshotName $SnapName 
