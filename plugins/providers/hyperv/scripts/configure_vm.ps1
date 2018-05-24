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
    [switch] $EnableCheckpoints
)

$ErrorActionPreference = "Stop"

try {
    $VM = Hyper-V\Get-VM -Id $VMID
} catch {
    Write-Error-Message "Failed to locate VM: ${PSItem}"
    exit 1
}

if($Processors) {
    try {
        Set-VagrantVMCPUS -VM $VM -CPUCount ($Processors -as [int])
    } catch {
        Write-Error-Message "Failed to configure CPUs: ${PSItem}"
        exit 1
    }
}

if($Memory -or $MaxMemory) {
    try {
        Set-VagrantVMMemory -VM $VM -Memory $Memory -MaxMemory $MaxMemory
    } catch {
        Write-Error-Message "Failed to configure memory: ${PSItem}"
        exit 1
    }
}

if($AutoStartAction -or $AutoStopAction) {
    try {
        Set-VagrantVMAutoActions -VM $VM -AutoStartAction $AutoStartAction -AutoStopAction $AutoStopAction
    } catch {
        Write-Error-Message "Failed to configure automatic actions: ${PSItem}"
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
    Write-Error-Message "Failed to configure virtualization extensions: ${PSItem}"
    exit 1
}

if($SwitchID) {
    try {
        $SwitchName = Get-VagrantVMSwitch -NameOrID $SwitchID
        Set-VagrantVMSwitch -VM $VM -SwitchName $SwitchName
    } catch {
        Write-Error-Message "Failed to configure network adapter: ${PSItem}"
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
    Write-Error-Message "Failed to ${CheckpointAction} checkpoints on VM: ${PSItem}"
    exit 1
}
