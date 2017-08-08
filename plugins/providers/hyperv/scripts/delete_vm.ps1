Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

$VM = Hyper-V\Get-VM -Id $VmId -ErrorAction "Stop"
Hyper-V\Remove-VM $VM -Force
