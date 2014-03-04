Param(
    [Parameter(Mandatory=$true)]
    [string]$vm_id
)

$VM = Get-VM -Id $vm_id -ErrorAction "Stop"
Remove-VM $VM -Force
