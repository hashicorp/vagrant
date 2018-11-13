#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

$ErrorActionPreference = "Stop"

try {
    $VM = Hyper-V\Get-VM -Id $VmId
    if((Get-Command Hyper-V\Set-VM).Parameters["AutomaticCheckpointsEnabled"] -ne $null) {
        Hyper-V\Set-VM -VM $VM -AutomaticCheckpointsEnabled $false -ErrorAction SilentlyContinue
    }
    Hyper-V\Remove-VM $VM -Force
} catch {
    Write-ErrorMessage "Failed to delete VM: ${PSItem}"
    exit 1
}
