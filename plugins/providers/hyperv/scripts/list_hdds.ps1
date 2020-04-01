#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

try {
    $VM = Hyper-V\Get-VM -Id $VmId
    Hyper-V\Get-VMHardDiskDrive -VMName $VM
} catch {
    Write-ErrorMessage "Failed to retrieve all disk info from ${VM}: ${PSItem}"
    exit 1
}
