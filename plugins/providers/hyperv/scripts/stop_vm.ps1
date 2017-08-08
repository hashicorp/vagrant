Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

# Shuts down virtual machine regardless of any unsaved application data
$VM = Hyper-V\Get-VM -Id $VmId -ErrorAction "Stop"
Hyper-V\Stop-VM $VM -Force
