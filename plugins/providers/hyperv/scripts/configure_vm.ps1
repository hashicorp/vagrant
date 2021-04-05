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
    [switch] $EnableAutomaticCheckpoints,
    [parameter (Mandatory=$false)]
    [switch] $EnableTrustedPlatformModule,
    [parameter (Mandatory=$false)]
    [string] $KeyProtector
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
        exit 1
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
    if((Get-Command Hyper-V\Set-VM).Parameters["CheckpointType"] -eq $null) {
        if($CheckpointAction -eq "enable") {
            Write-ErrorMessage "CheckpointType is not available. Cannot enable checkpoints."
            exit 1
        }
    } else {
        Hyper-V\Set-VM -VM $VM -CheckpointType $checkpoints
    }
} catch {
    Write-ErrorMessage "Failed to ${CheckpointAction} checkpoints on VM: ${PSItem}"
    exit 1
}

if($EnableAutomaticCheckpoints) {
    $autochecks = 1
    $AutoAction = "enabled"
} else {
    $autochecks = 0
    $AutoAction = "disable"
}

try {
    if((Get-Command Hyper-V\Set-VM).Parameters["AutomaticCheckpointsEnabled"] -eq $null) {
        if($autochecks -eq 1) {
            Write-ErrorMessage "AutomaticCheckpointsEnabled is not available"
            exit 1
        }
    } else {
        Hyper-V\Set-VM -VM $VM -AutomaticCheckpointsEnabled $autochecks
    }
} catch {
    Write-ErrorMessage "Failed to ${AutoAction} automatic checkpoints on VM: ${PSItem}"
    exit 1
}

if($EnableTrustedPlatformModule) {
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem

    if($osInfo.BuildNumber -lt 14393) {
        $lineOne = "Failed to enable Trusted Platform Module: the version of Windows your machine is running needs to be run in Isolated User Mode"
        $lineTwo = "To activate Isolated User Mode, open Windows PowerShell as an administrator, and run the following commands:"
        $lineThree = "Enable-WindowsOptionalFeature -Feature IsolatedUserMode -Online"
        $lineFour = "New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard -Force"
        $lineFive = "New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard -Name EnableVirtualizationBasedSecurity -Value 1 -PropertyType DWord -Force"
        Write-ErrorMessage "$lineOne`n$lineTwo`n$lineThree`n$lineFour`n$lineFive"
        exit 1
    }

    if($KeyProtector) {
        try {
            $encoder = [system.Text.Encoding]::UTF8
            $rawKP = $encoder.getBytes($KeyProtector)
            Set-VMKeyProtector -VM $VM -KeyProtector $rawKP
        } catch {
            Write-ErrorMessage "Failed to set key protector for VM: ${PSItem}"
            exit 1
        }
    } else {
        try {
            Set-VMKeyProtector -VM $VM -NewLocalKeyProtector
        } catch {
            Write-ErrorMessage "Failed to generate new key protector for VM: ${PSItem}"
            exit 1
        }
    }

    try {
        Hyper-V\Enable-VMTPM -VM $VM
    } catch {
        Write-ErrorMessage "Failed to enable Trusted Platform Module on VM: ${PSItem}"
        exit 1
    }
} else {
    try {
        Hyper-V\Disable-VMTPM -VM $VM
    } catch {
        Write-ErrorMessage "Failed to disable Trusted Platform Module on VM: ${PSItem}"
        exit 1
    }
}
