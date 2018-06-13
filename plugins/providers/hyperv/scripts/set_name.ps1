#Requires -Modules VagrantMessages

param (
    [parameter (Mandatory=$true)]
    [Guid] $VMID,
    [parameter (Mandatory=$true)]
    [string] $VMName
)

$ErrorActionPreference = "Stop"

try {
    $VM = Hyper-V\Get-VM -Id $VMID
} catch {
    Write-ErrorMessage "Failed to locate VM: ${PSItem}"
    exit 1
}

try {
    Hyper-V\Set-VM -VM $VM -NewVMName $VMName
} catch {
    Write-ErrorMessage "Failed to assign new VM name ${VMName}: ${PSItem}"
    exit 1
}
