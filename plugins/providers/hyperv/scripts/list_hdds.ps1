#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

try {
    $VM = Hyper-V\Get-VM -Id $VmId
    $Disks = @(Hyper-V\Get-VMHardDiskDrive -VMName $VM.Name)
} catch {
    Write-ErrorMessage "Failed to retrieve all disk info from ${VM}: ${PSItem}"
    exit 1
}

$result = ConvertTo-json $Disks
Write-OutputMessage $result
