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
    $VM = Hyper-V\Get-VM -Id $VmId
    #Hyper-V\Add-VMHardDiskDrive -VMName $vm -ControllerType $ControllerType -ControllerNumber $ControllerNumber -ControllerLocation $ControllerLocation -Path $DiskFilePath
    # Add logic to support missing params. Below is the simple case for attaching a disk
    Hyper-V\Add-VMHardDiskDrive -VMName $VM.Name -Path $DiskFilePath
} catch {
    Write-ErrorMessage "Failed to attach disk ${DiskFilePath} to VM ${VM}: ${PSItem}"
    exit 1
}
