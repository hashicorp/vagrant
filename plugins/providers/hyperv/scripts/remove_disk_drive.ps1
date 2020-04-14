#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$VmId,
    [Parameter(Mandatory=$true)]
    [string]$ControllerType,
    [Parameter(Mandatory=$true)]
    [string]$ControllerNumber,
    [Parameter(Mandatory=$true)]
    [string]$ControllerLocation
)

try {
    $VM = Hyper-V\Get-VM -Id $VmId

    Hyper-v\Remove-VMHardDiskDrive -VMName $VM.Name -ControllerType $ControllerType -ControllerNumber $ControllerNumber -ControllerLocation $ControllerLocation
} catch {
    Write-ErrorMessage "Failed to remove disk ${DiskFilePath} to VM ${VM}: ${PSItem}"
    exit 1
}
