#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$VmId,
    [string]$ControllerType,
    [string]$ControllerNumber,
    [string]$ControllerLocation,
    [Parameter(Mandatory=$true)]
    [string]$DiskFilePath
)

try {
    $vm = Hyper-V\Get-VM -Id $VmId
    Hyper-V\Add-VMHardDiskDrive -VMName $vm -ControllerType $ControllerType -ControllerNumber $ControllerNumber -ControllerLocation $ControllerLocation -Path $DiskFilePath
} catch {
    Write-ErrorMessage "Failed to attach disk ${DiskFilePath} to VM ${vm}: ${PSItem}"
    exit 1
}
