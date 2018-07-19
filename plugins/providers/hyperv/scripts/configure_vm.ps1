#Requires -Modules VagrantVM, VagrantMessages

param(
    [parameter (Mandatory=$true)]
    [Guid] $VMID,
    [parameter (Mandatory=$false)]
    [string] $SwitchID=$null,
    [parameter (Mandatory=$false)]
    [string] $Memory=$null,
    [parameter (Mandatory=$false)]
    [string] $MaxMemory=$null,
    [parameter (Mandatory=$false)]
    [string] $Processors=$null,
    [parameter (Mandatory=$false)]
    [string] $AutoStartAction=$null,
    [parameter (Mandatory=$false)]
    [string] $AutoStopAction=$null,
    [parameter (Mandatory=$false)]
    [switch] $VirtualizationExtensions,
    [parameter (Mandatory=$false)]
    [switch] $EnableCheckpoints,
    [parameter (Mandatory=$false)]
    [string] $DisksToCreate=$null
)

$ErrorActionPreference = "Stop"

try {
    $VM = Hyper-V\Get-VM -Id $VMID
} catch {
    Write-ErrorMessage "Failed to locate VM: ${PSItem}"
    exit 1
}

if($Processors) {
    try {
        Set-VagrantVMCPUS -VM $VM -CPUCount ($Processors -as [int])
    } catch {
        Write-ErrorMessage "Failed to configure CPUs: ${PSItem}"
        exit 1
    }
}

if($Memory -or $MaxMemory) {
    try {
        Set-VagrantVMMemory -VM $VM -Memory $Memory -MaxMemory $MaxMemory
    } catch {
        Write-ErrorMessage "Failed to configure memory: ${PSItem}"
        exit 1
    }
}

if($AutoStartAction -or $AutoStopAction) {
    try {
        Set-VagrantVMAutoActions -VM $VM -AutoStartAction $AutoStartAction -AutoStopAction $AutoStopAction
    } catch {
        Write-ErrorMessage "Failed to configure automatic actions: ${PSItem}"
        exit 1
    }
}

if($VirtualizationExtensions) {
    $virtex = $true
} else {
    $virtex = $false
}

try {
    Set-VagrantVMVirtExtensions -VM $VM -Enabled $virtex
} catch {
    Write-ErrorMessage "Failed to configure virtualization extensions: ${PSItem}"
    exit 1
}

if($SwitchID) {
    try {
        $SwitchName = Get-VagrantVMSwitch -NameOrID $SwitchID
        Set-VagrantVMSwitch -VM $VM -SwitchName $SwitchName
    } catch {
        Write-ErrorMessage "Failed to configure network adapter: ${PSItem}"
    }
}

if($EnableCheckpoints) {
    $checkpoints = "Standard"
    $CheckpointAction = "enable"
} else {
    $checkpoints = "Disabled"
    $CheckpointAction = "disable"
}

try {
    Hyper-V\Set-VM -VM $VM -CheckpointType $checkpoints
} catch {
    Write-ErrorMessage "Failed to ${CheckpointAction} checkpoints on VM: ${PSItem}"
    exit 1
}


#controller -  path (for existent)
#              path,
#              sizeMB, name (for new)
function AddDisks($vm, $controller) {
    #get controller    

    $contNumber = ($vm | Add-VMScsiController -PassThru).ControllerNumber
    foreach($disk in $controller) {
        #get vhd
        $vhd = $null
        if($disk.Path) {
            if (Test-Path -Path $disk.Path) {
                $vhd = Resolve-Path -Path $disk.Path
            }
        }
        else {
            $vhd = "$($disk.Name).vhdx"
            Add-Content "c:/ps_debug.log" -value "vhd: $vhd"
            if (!(Test-Path -Path $vhd)) {
                New-VHD -Path $vhd -SizeBytes ([UInt64]$disk.Size * 1MB) -Dynamic
            }
        }
        if (!(Test-Path -Path $vhd)) {
            Write-Error "There is error in virtual disk (VHD) configuration"
            break
        }

        $driveParam = @{
            ControllerNumber = $contNumber
            Path = $vhd
            ControllerType = "SCSI"
        }
        Add-Content "c:/ps_debug.log" -value "$vm | Add-VMHardDiskDrive @driveParam"
        Add-Content "c:/ps_debug.log" -value "vhd: $vhd"
        $vm | Add-VMHardDiskDrive @driveParam
    }
}

if ($DisksToCreate) {
    Add-Content "c:/ps_debug.log" -value "DisksToCreate: $DisksToCreate"
    $ParsedDisksToCreate = $DisksToCreate | ConvertFrom-Json
    Add-Content "c:/ps_debug.log" -value "ParsedDisksToCreate: $ParsedDisksToCreate"
    $ParsedDisksToCreate | ForEach-Object { AddDisks -vm $VM -controller $_ }
}