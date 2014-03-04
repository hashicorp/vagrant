Param(
    [Parameter(Mandatory=$true)]
    [string]$vm_id
)

$VM = Get-VM -Id $vm_id -ErrorAction "Stop"
Suspend-VM $VM
