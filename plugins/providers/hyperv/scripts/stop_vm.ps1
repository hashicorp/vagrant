Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

# Shuts down virtual machine regardless of any unsaved application data
$VM = Get-VM -Id $VmId -ErrorAction "Stop"
Stop-VM $VM -Force
