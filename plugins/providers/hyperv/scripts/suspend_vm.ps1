Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

$VM = Get-VM -Id $VmId -ErrorAction "Stop"
Suspend-VM $VM
