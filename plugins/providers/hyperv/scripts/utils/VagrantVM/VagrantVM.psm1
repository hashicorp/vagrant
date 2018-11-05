# Always stop when errors are encountered unless instructed not to
$ErrorActionPreference = "Stop"

# Vagrant VM creation functions

function New-VagrantVM {
    param (
        [parameter(Mandatory=$true)]
        [string] $VMConfigFile,
        [parameter(Mandatory=$true)]
        [string] $DestinationPath,
        [parameter (Mandatory=$true)]
        [string] $DataPath,
        [parameter (Mandatory=$true)]
        [string] $SourcePath,
        [parameter (Mandatory=$false)]
        [bool] $LinkedClone = $false,
        [parameter(Mandatory=$false)]
        [string] $VMName
    )
    if([IO.Path]::GetExtension($VMConfigFile).ToLower() -eq ".xml") {
        return New-VagrantVMXML @PSBoundParameters
    } else {
        return New-VagrantVMVMCX @PSBoundParameters
    }
<#
.SYNOPSIS

Create a new Vagrant Hyper-V VM by cloning original. This
is the general use function with will call the specialized
function based on the extension of the configuration file.

.DESCRIPTION

Using an existing Hyper-V VM a new Hyper-V VM is created
by cloning the original.

.PARAMETER VMConfigFile
Path to the original Hyper-V VM configuration file.

.PARAMETER DestinationPath
Path to new Hyper-V VM hard drive.

.PARAMETER DataPath
Directory path of the original Hyper-V VM to be cloned.

.PARAMETER SourcePath
Path to the original Hyper-V VM hard drive.

.PARAMETER LinkedClone
New Hyper-V VM should be linked clone instead of complete copy.

.PARAMETER VMName
Name of the new Hyper-V VM.

.INPUTS

None.

.OUTPUTS

VirtualMachine. The cloned Hyper-V VM.
#>
}

function New-VagrantVMVMCX {
    param (
        [parameter(Mandatory=$true)]
        [string] $VMConfigFile,
        [parameter(Mandatory=$true)]
        [string] $DestinationPath,
        [parameter (Mandatory=$true)]
        [string] $DataPath,
        [parameter (Mandatory=$true)]
        [string] $SourcePath,
        [parameter (Mandatory=$false)]
        [bool] $LinkedClone = $false,
        [parameter(Mandatory=$false)]
        [string] $VMName
    )

    $NewVMConfig = @{
        Path = $VMConfigFile;
        SnapshotFilePath = Join-Path $DataPath "Snapshots";
        VhdDestinationPath = Join-Path $DataPath "Virtual Hard Disks";
        VirtualMachinePath = $DataPath;
    }
    $VMConfig = (Hyper-V\Compare-VM -Copy -GenerateNewID @NewVMConfig)

    # If the config is empty it means the import failed. Attempt to provide
    # context for failure
    if($VMConfig -eq $null) {
        Report-ErrorVagrantVMImport -VMConfigFile $VMConfigFile
    }

    $VM = $VMConfig.VM
    $Gen = $VM.Generation

    # Set VM name if name has been provided
    if($VMName) {
        Hyper-V\Set-VM -VM $VM -NewVMName $VMName
    }

    # Set EFI secure boot on machines after Gen 1
    if($Gen -gt 1) {
        Hyper-V\Set-VMFirmware -VM $VM -EnableSecureBoot (Hyper-V\Get-VMFirmware -VM $VM).SecureBoot
    }

    # Disconnect adapters from switches
    Hyper-V\Get-VMNetworkAdapter -VM $VM | Hyper-V\Disconnect-VMNetworkAdapter

    # Verify new VM
    $Report = Hyper-V\Compare-VM -CompatibilityReport $VMConfig
    if($Report.Incompatibilities.Length -gt 0){
        throw $(ConvertTo-Json $($Report.Incompatibilities | Select -ExpandProperty Message))
    }

    if($LinkedClone) {
        $Controllers = Hyper-V\Get-VMScsiController -VM $VM
        if($Gen -eq 1){
            $Controllers = @($Controllers) + @(Hyper-V\Get-VMIdeController -VM $VM)
        }
        foreach($Controller in $Controllers) {
            foreach($Drive in $Controller.Drives) {
                if([System.IO.Path]::GetFileName($Drive.Path) -eq [System.IO.Path]::GetFileName($SourcePath)) {
                    $Path = $Drive.Path
                    Hyper-V\Remove-VMHardDiskDrive $Drive
                    Hyper-V\New-VHD -Path $DestinationPath -ParentPath $SourcePath -Differencing
                    Hyper-V\Add-VMHardDiskDrive -VM $VM -Path $DestinationPath
                    break
                }
            }
        }

    }
    return Hyper-V\Import-VM -CompatibilityReport $VMConfig
<#
.SYNOPSIS

Create a new Vagrant Hyper-V VM by cloning original (VMCX based).

.DESCRIPTION

Using an existing Hyper-V VM a new Hyper-V VM is created
by cloning the original.

.PARAMETER VMConfigFile
Path to the original Hyper-V VM configuration file.

.PARAMETER DestinationPath
Path to new Hyper-V VM hard drive.

.PARAMETER DataPath
Directory path of the original Hyper-V VM to be cloned.

.PARAMETER SourcePath
Path to the original Hyper-V VM hard drive.

.PARAMETER LinkedClone
New Hyper-V VM should be linked clone instead of complete copy.

.PARAMETER VMName
Name of the new Hyper-V VM.

.INPUTS

None.

.OUTPUTS

VirtualMachine. The cloned Hyper-V VM.
#>
}

function New-VagrantVMXML {
    param (
        [parameter(Mandatory=$true)]
        [string] $VMConfigFile,
        [parameter(Mandatory=$true)]
        [string] $DestinationPath,
        [parameter (Mandatory=$true)]
        [string] $DataPath,
        [parameter (Mandatory=$true)]
        [string] $SourcePath,
        [parameter (Mandatory=$false)]
        [bool] $LinkedClone = $false,
        [parameter(Mandatory=$false)]
        [string] $VMName
    )

    $DestinationDirectory = [System.IO.Path]::GetDirectoryName($DestinationPath)
    New-Item -ItemType Directory -Force -Path $DestinationDirectory

    if($LinkedClone){
        Hyper-V\New-VHD -Path $DestinationPath -ParentPath $SourcePath -ErrorAction Stop
    } else {
        Copy-Item $SourcePath -Destination $DestinationPath -ErrorAction Stop
    }

    [xml]$VMConfig = Get-Content -Path $VMConfigFile
    $Gen = [int]($VMConfig.configuration.properties.subtype."#text") + 1
    if(!$VMName) {
        $VMName = $VMConfig.configuration.properties.name."#text"
    }

    # Determine boot device
    if($Gen -eq 1) {
        Switch ((Select-Xml -xml $VMConfig -XPath "//boot").node.device0."#text") {
            "Floppy"    { $BootDevice = "Floppy" }
            "HardDrive" { $BootDevice = "IDE" }
            "Optical"   { $BootDevice = "CD" }
            "Network"   { $BootDevice = "LegacyNetworkAdapter" }
            "Default"   { $BootDevice = "IDE" }
        }
    } else {
        Switch ((Select-Xml -xml $VMConfig -XPath "//boot").node.device0."#text") {
            "HardDrive" { $BootDevice = "VHD" }
            "Optical"   { $BootDevice = "CD" }
            "Network"   { $BootDevice = "NetworkAdapter" }
            "Default"   { $BootDevice = "VHD" }
        }
    }

    # Determine if secure boot is enabled
    $SecureBoot = (Select-Xml -XML $VMConfig -XPath "//secure_boot_enabled").Node."#text"

    $NewVMConfig = @{
        Name = $VMName;
        NoVHD = $true;
        BootDevice = $BootDevice;
    }

    # Generation parameter in PS4 so validate before using
    if((Get-Command Hyper-V\New-VM).Parameters.Keys.Contains("generation")) {
        $NewVMConfig.Generation = $Gen
    }

    # Create new VM instance
    $VM = Hyper-V\New-VM @NewVMConfig

    # Configure secure boot
    if($Gen -gt 1) {
        if($SecureBoot -eq "True") {
            Hyper-V\Set-VMFirmware -VM $VM -EnableSecureBoot On
        } else {
            Hyper-V\Set-VMFirmware -VM $VM -EnableSecureBoot Off
        }
    }

    # Configure drives
    [regex]$DriveNumberMatcher = "\d"
    $Controllers = Select-Xml -XML $VMConfig -XPath "//*[starts-with(name(.),'controller')]"

    foreach($Controller in $Controllers) {
        $Node = $Controller.Node
        if($Node.ParentNode.ChannelInstanceGuid) {
            $ControllerType = "SCSI"
        } else {
            $ControllerType = "IDE"
        }
        $Drives = $Node.ChildNodes | where {$_.pathname."#text"}
        foreach($Drive in $Drives) {
            $DriveType = $Drive.type."#text"
            if($DriveType -ne "VHD") {
                continue
            }

            $NewDriveConfig = @{
                ControllerNumber = $DriveNumberMatcher.Match($Controller.node.name).value;
                Path = $DestinationPath;
                ControllerType = $ControllerType;
            }
            if($Drive.pool_id."#text") {
                $NewDriveConfig.ResourcePoolname = $Drive.pool_id."#text"
            }
            $VM | Hyper-V\Add-VMHardDiskDrive @NewDriveConfig
        }
    }

    # Apply original VM configuration to new VM instance

    $processors = $VMConfig.configuration.settings.processors.count."#text"
    $notes = (Select-Xml -XML $VMConfig -XPath "//notes").node."#text"
    $memory = (Select-Xml -XML $VMConfig -XPath "//memory").node.Bank
    if ($memory.dynamic_memory_enabled."#text" -eq "True") {
        $dynamicmemory = $True
    }
    else {
        $dynamicmemory = $False
    }
    # Memory values need to be in bytes
    $MemoryMaximumBytes = ($memory.limit."#text" -as [int]) * 1MB
    $MemoryStartupBytes = ($memory.size."#text" -as [int]) * 1MB
    $MemoryMinimumBytes = ($memory.reservation."#text" -as [int]) * 1MB

    $Config = @{
        ProcessorCount = $processors;
        MemoryStartupBytes = $MemoryStartupBytes
    }
    if($dynamicmemory) {
        $Config.DynamicMemory = $true
        $Config.MemoryMinimumBytes = $MemoryMinimumBytes
        $Config.MemoryMaximumBytes = $MemoryMaximumBytes
    } else {
        $Config.StaticMemory = $true
    }
    if($notes) {
        $Config.Notes = $notes
    }
    Hyper-V\Set-VM -VM $VM @Config

    return $VM
<#
.SYNOPSIS

Create a new Vagrant Hyper-V VM by cloning original (XML based).

.DESCRIPTION

Using an existing Hyper-V VM a new Hyper-V VM is created
by cloning the original.

.PARAMETER VMConfigFile
Path to the original Hyper-V VM configuration file.

.PARAMETER DestinationPath
Path to new Hyper-V VM hard drive.

.PARAMETER DataPath
Directory path of the original Hyper-V VM to be cloned.

.PARAMETER SourcePath
Path to the original Hyper-V VM hard drive.

.PARAMETER LinkedClone
New Hyper-V VM should be linked clone instead of complete copy.

.PARAMETER VMName
Name of the new Hyper-V VM.

.INPUTS

None.

.OUTPUTS

VirtualMachine. The cloned Hyper-V VM.
#>
}

function Report-ErrorVagrantVMImport {
    param (
        [parameter(Mandatory=$true)]
        [string] $VMConfigFile
    )

    $ManagementService = Get-WmiObject -Namespace 'root\virtualization\v2' -Class 'Msvm_VirtualSystemManagementService'

    # Relative path names will fail when attempting to import a system
    # definition so always ensure we are using the full path to the
    # configuration file.
    $FullPathFile = (Resolve-Path $VMConfigFile).Path

    $Result = $ManagementService.ImportSystemDefinition($FullPathFile, $null, $true)
    if($Result.ReturnValue -eq 0) {
        throw "Unknown error encountered while importing VM"
    } elseif($Result.ReturnValue -eq 4096) {
        $job = Get-WmiObject -Namespace 'root\virtualization\v2' -Query 'select * from Msvm_ConcreteJob' | Where {$_.__PATH -eq $Result.Job}
        while($job.JobState -eq 3 -or $job.JobState -eq 4) {
            start-sleep 1
            $job = Get-WmiObject -Namespace 'root\virtualization\v2' -Query 'select * from Msvm_ConcreteJob' | Where {$_.__PATH -eq $Result.Job}
        }
        $ErrorMsg = $job.ErrorDescription + "`n`n"
        $ErrorMsg = $ErrorMsg + "Error Code: " + $job.ErrorCode + "`n"
        $cause = "Unknown"
        switch($job.ErrorCode) {
            32768 { $cause = "Failed" }
            32769 { $cause = "Access Denied" }
            32770 { $cause = "Not Supported" }
            32771 { $cause = "Status is unknown" }
            32772 { $cause = "Timeout" }
            32773 { $cause = "Invalid parameter" }
            32774 { $cause = "System is in use" }
            32775 { $cause = "Invalid state for this operation" }
            32776 { $cause = "Incorrect data type" }
            32777 { $cause = "System is not available" }
            32778 { $cause = "Out of memory" }
            32779 { $cause = "File in Use" }
            32784 { $cause = "VM version is unsupported" }
        }
        $ErrorMsg = $ErrorMsg + "Cause: ${cause}"
        throw $ErrorMsg
    } else {
        throw "Failed to run VM import job. Error value: ${Result.ReturnValue}"
    }
<#
.SYNOPSIS

Determines cause of error for VM import.

.DESCRIPTION

Runs a local import of the VM configuration and attempts to determine
the underlying cause of the import failure.

.PARAMETER VMConfigFile
Path to the Hyper-V VM configuration file.

.INPUTS

None.

.OUTPUTS

None.
#>
}

# Vagrant VM configuration functions

function Set-VagrantVMMemory {
    param (
        [parameter (Mandatory=$true)]
        [Microsoft.HyperV.PowerShell.VirtualMachine] $VM,
        [parameter (Mandatory=$false)]
        [int] $Memory,
        [parameter (Mandatory=$false)]
        [int] $MaxMemory
    )

    $ConfigMemory = Hyper-V\Get-VMMemory -VM $VM

    if(!$Memory) {
        $MemoryStartupBytes = ($ConfigMemory.Startup)
        $MemoryMinimumBytes = ($ConfigMemory.Minimum)
        $MemoryMaximumBytes = ($ConfigMemory.Maximum)
    } else {
        $MemoryStartupBytes = $Memory * 1MB
        $MemoryMinimumBytes = $Memory * 1MB
        $MemoryMaximumBytes = $Memory * 1MB
    }

    if($MaxMemory) {
        $DynamicMemory = $true
        $MemoryMaximumBytes = $MaxMemory * 1MB
    }

    if($DynamicMemory) {
        if($MemoryMaximumBytes -lt $MemoryMinimumBytes) {
            throw "Maximum memory value is less than required minimum memory value."
        }
        if ($MemoryMaximumBytes -lt $MemoryStartupBytes) {
            throw "Maximum memory value is less than configured startup memory value."
        }

        Hyper-V\Set-VM -VM $VM -DynamicMemory
        Hyper-V\Set-VM -VM $VM -MemoryMinimumBytes $MemoryMinimumBytes -MemoryMaximumBytes `
          $MemoryMaximumBytes -MemoryStartupBytes $MemoryStartupBytes
    } else {
        Hyper-V\Set-VM -VM $VM -StaticMemory
        Hyper-V\Set-VM -VM $VM -MemoryStartupBytes $MemoryStartupBytes
    }
    return $VM
<#
.SYNOPSIS

Configure VM memory settings.

.DESCRIPTION

Adjusts the VM memory settings. If MaxMemory is defined, dynamic memory
is enabled on the VM.

.PARAMETER VM

Hyper-V VM for modification.

.Parameter Memory

Memory to allocate to the given VM in MB.

.Parameter MaxMemory

Maximum memory to allocate to the given VM in MB. When this value is
provided dynamic memory is enabled for the VM. The Memory value or
the currently configured memory of the VM will be used as the minimum
and startup memory value.

.Output

VirtualMachine.
#>
}

function Set-VagrantVMCPUS {
    param (
        [parameter (Mandatory=$true)]
        [Microsoft.HyperV.PowerShell.VirtualMachine] $VM,
        [parameter (Mandatory=$false)]
        [int] $CPUCount
    )

    if($CPUCount) {
        Hyper-V\Set-VM -VM $VM -ProcessorCount $CPUCount
    }
    return $VM
<#
.SYNOPSIS

Configure VM CPU count.

.DESCRIPTION

Configure the number of CPUs on the given VM.

.PARAMETER VM

Hyper-V VM for modification.

.PARAMETER CPUCount

Number of CPUs.

.Output

VirtualMachine.
#>
}

function Set-VagrantVMVirtExtensions {
    param (
        [parameter (Mandatory=$true)]
        [Microsoft.HyperV.PowerShell.VirtualMachine] $VM,
        [parameter (Mandatory=$false)]
        [bool] $Enabled=$false
    )

    # Check that this option is available
    if((Get-Command Hyper-V\Set-VMProcessor).Parameters["ExposeVirtualizationExtensions"] -eq $null) {
        if($Enabled) {
            throw "ExposeVirtualizationExtensions is not available"
        } else {
            return $VM
        }
    }

    Hyper-V\Set-VMProcessor -VM $VM -ExposeVirtualizationExtensions $Enabled
    return $VM
<#
.SYNOPSIS

Enable virtualization extensions on VM.

.PARAMETER VM

Hyper-V VM for modification.

.PARAMETER Enabled

Enable virtualization extensions on given VM.

.OUTPUT

VirtualMachine.
#>
}

function Set-VagrantVMAutoActions {
    param (
        [parameter (Mandatory=$true)]
        [Microsoft.HyperV.PowerShell.VirtualMachine] $VM,
        [parameter (Mandatory=$false)]
        [string] $AutoStartAction="Nothing",
        [parameter (Mandatory=$false)]
        [string] $AutoStopAction="ShutDown"
    )

    Hyper-V\Set-VM -VM $VM -AutomaticStartAction $AutoStartAction
    Hyper-V\Set-VM -VM $VM -AutomaticStopAction $AutoStopAction
    return $VM
<#
.SYNOPSIS

Configure automatic start and stop actions for VM

.DESCRIPTION

Configures the automatic start and automatic stop actions for
the given VM.

.PARAMETER VM

Hyper-V VM for modification.

.PARAMETER AutoStartAction

Action the VM should automatically take when the host is started.

.PARAMETER AutoStopAction

Action the VM should automatically take when the host is stopped.

.OUTPUT

VirtualMachine.
#>
}

function Set-VagrantVMService {
    param (
        [parameter (Mandatory=$true)]
        [Microsoft.HyperV.PowerShell.VirtualMachine] $VM,
        [parameter (Mandatory=$true)]
        [string] $Name,
        [parameter (Mandatory=$true)]
        [bool] $Enable
    )

    if($Enable) {
        Hyper-V\Enable-VMIntegrationService -VM $VM -Name $Name
    } else {
        Hyper-V\Disable-VMIntegrationService -VM $VM -Name $Name
    }
    return $VM
<#
.SYNOPSIS

Enable or disable Hyper-V VM integration services.

.PARAMETER VM

Hyper-V VM for modification.

.PARAMETER Name

Name of the integration service.

.PARAMETER Enable

Enable or disable the service.

.OUTPUT

VirtualMachine.
#>
}

# Vagrant networking functions

function Get-VagrantVMSwitch {
    param (
        [parameter (Mandatory=$true)]
        [string] $NameOrID
    )
    $SwitchName = $(Hyper-V\Get-VMSwitch -Id $NameOrID).Name
    if(!$SwitchName) {
        $SwitchName = $(Hyper-V\Get-VMSwitch -Name $NameOrID).Name
    }
    if(!$SwitchName) {
        throw "Failed to locate switch with name or ID: ${NameOrID}"
    }
    return $SwitchName
<#
.SYNOPSIS

Get name of VMSwitch.

.DESCRIPTION

Find VMSwitch by name or ID and return name.

.PARAMETER NameOrID

Name or ID of VMSwitch.

.OUTPUT

Name of VMSwitch.
#>
}

function Set-VagrantVMSwitch {
    param (
        [parameter (Mandatory=$true)]
        [Microsoft.HyperV.PowerShell.VirtualMachine] $VM,
        [parameter (Mandatory=$true)]
        [String] $SwitchName
    )
    $Adapter = Hyper-V\Get-VMNetworkAdapter -VM $VM
    Hyper-V\Connect-VMNetworkAdapter -VMNetworkAdapter $Adapter -SwitchName $SwitchName
    return $VM
<#
.SYNOPSIS

Configure VM to use given switch.

.DESCRIPTION

Configures VM adapter to use the the VMSwitch with the given name.

.PARAMETER VM

Hyper-V VM for modification.

.PARAMETER SwitchName

Name of the VMSwitch.

.OUTPUT

VirtualMachine.
#>
}

function Check-VagrantHyperVAccess {
    param (
        [parameter (Mandatory=$true)]
        [string] $Path
    )
    $acl = Get-ACL -Path $Path
    $systemACL = $acl.Access | where {
        $_.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).Value -eq "S-1-5-18" -and
        $_.FileSystemRights -eq "FullControl" -and
        $_.AccessControlType -eq "Allow" -and
        $_.IsInherited -eq $true}
    if($systemACL) {
        return $true
    }
    return $false
<#
.SYNOPSIS

Check Hyper-V access at given path.

.DESCRIPTION

Checks that the given path has the correct access rules for Hyper-V

.PARAMETER PATH

Path to check

.OUTPUT

Boolean
#>
}
