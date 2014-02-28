Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

$VM = Get-VM -Id $VmId -ErrorAction "Stop"
Remove-VM $VM -Force
