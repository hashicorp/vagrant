#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

$ErrorActionPreference = "Stop"

try {
    $VM = Hyper-V\Get-VM -Id $VmId
    $Snapshots = @(Hyper-V\Get-VMSnapshot $VM | Select-Object Name)
} catch {
    Write-ErrorMessage "Failed to get snapshot list: ${PSItem}"
    exit 1
}

$result = ConvertTo-json $Snapshots
Write-OutputMessage $result
