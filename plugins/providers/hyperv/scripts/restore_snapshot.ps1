Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId,
    [string]$SnapName
)

$VM = Get-VM -Id $VmId -ErrorAction "Stop"
Restore-VMSnapshot $VM -Name $SnapName -Confirm:$false
