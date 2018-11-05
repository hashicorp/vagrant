#Requires -Modules VagrantMessages

Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

$ErrorActionPreference = "Stop"

try{
    # Shuts down virtual machine regardless of any unsaved application data
    $VM = Hyper-V\Get-VM -Id $VmId
    Hyper-V\Stop-VM $VM -Force
} catch {
    Write-ErrorMessage "Failed to stop VM: ${PSItem}"
    exit 1
}
