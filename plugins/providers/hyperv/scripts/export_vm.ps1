#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$VmId,
    [Parameter(Mandatory=$true)]
    [string]$Path
)

$ErrorActionPreference = "Stop"

try {
    $vm = Hyper-V\Get-VM -Id $VmId
    $vm | Hyper-V\Export-VM -Path $Path
} catch {
    Write-ErrorMessage "Failed to export VM: ${PSItem}"
    exit 1
}

# Prepare directory structure for box import
try {
    $name = $vm.Name
    Move-Item $Path/$name/* $Path
    Remove-Item -Path $Path/Snapshots -Force -Recurse
    Remove-Item -Path $Path/$name -Force
} catch {
    Write-ErrorMessage "Failed to format exported box: ${PSItem}"
    exit 1
}
