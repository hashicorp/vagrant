Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId,
    [string]$SnapName
)

$VM = Get-VM -Id $VmId -ErrorAction "Stop"
Remove-VMSnapshot $VM -Name $SnapName 
