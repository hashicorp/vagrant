Param(
    [Parameter(Mandatory=$true)]
    [string]$vm_xml_config,
    [Parameter(Mandatory=$true)]
    [string]$image_path,

    [string]$switchname=$null,
    [string]$memory=$null,
    [string]$maxmemory=$null,   
    [string]$cpus=$null,
    [string]$vmname=$null
)

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

[xml]$vmconfig = Get-Content -Path  $vm_xml_config

$generation = [int]($vmconfig.configuration.properties.subtype.'#text')+1

if (!$vmname) {
    # Get the name of the vm
    $vm_name = $vmconfig.configuration.properties.name.'#text'
}else {
    $vm_name = $vmname
}

if (!$cpus) {
    # Get the name of the vm
    $processors = $vmconfig.configuration.settings.processors.count.'#text'
}else {
    $processors = $cpus
}

function GetUniqueName($name) {
    Get-VM | ForEach-Object -Process {
        if ($name -eq $_.Name) {
            $name =  $name + "_1"
        }
    }
    return $name
}

do {
    $name = $vm_name
    $vm_name = GetUniqueName $name
} while ($vm_name -ne $name)

if (!$memory) {
    $xmlmemory = (Select-Xml -xml $vmconfig -XPath "//memory").node.Bank
    if ($xmlmemory.dynamic_memory_enabled."#text" -eq "True") {
        $dynamicmemory = $True
    }
    else {
        $dynamicmemory = $False
    }
    # Memory values need to be in bytes
    $MemoryMaximumBytes = ($xmlmemory.limit."#text" -as [int]) * 1MB
    $MemoryStartupBytes = ($xmlmemory.size."#text" -as [int]) * 1MB
    $MemoryMinimumBytes = ($xmlmemory.reservation."#text" -as [int]) * 1MB
}
else {
    if (!$maxmemory){
        $dynamicmemory = $False
        $MemoryMaximumBytes = ($memory -as [int]) * 1MB
        $MemoryStartupBytes = ($memory -as [int]) * 1MB
        $MemoryMinimumBytes = ($memory -as [int]) * 1MB
    }
    else {
        $dynamicmemory = $True
        $MemoryMaximumBytes = ($maxmemory -as [int]) * 1MB
        $MemoryStartupBytes = ($memory -as [int]) * 1MB
        $MemoryMinimumBytes = ($memory -as [int]) * 1MB
    }
}


if (!$switchname) {
    # Get the name of the virtual switch
    $switchname = (Select-Xml -xml $vmconfig -XPath "//AltSwitchName").node."#text"
}

# Determine boot device
Switch ((Select-Xml -xml $vmconfig -XPath "//boot").node.device0."#text") {
    "Floppy"    { $bootdevice = "floppy" }
    "HardDrive" { $bootdevice = "IDE" }
    "Optical"   { $bootdevice = "CD" }
    "Network"   { $bootdevice = "LegacyNetworkAdapter" }
    "Default"   { $bootdevice = "IDE" }
} #switch

# Determine secure boot options
$secure_boot_enabled = (Select-Xml -xml $vmconfig -XPath "//secure_boot_enabled").Node."#text"

# Define a hash map of parameter values for New-VM

$vm_params = @{
    Name = $vm_name
    Generation = $generation
    NoVHD = $True
    MemoryStartupBytes = $MemoryStartupBytes
    SwitchName = $switchname
    BootDevice = $bootdevice
    ErrorAction = "Stop"
}

# Create the VM using the values in the hash map

$vm = New-VM @vm_params

$notes = (Select-Xml -xml $vmconfig -XPath "//notes").node.'#text'

# Set-VM parameters to configure new VM with old values

$more_vm_params = @{
    ProcessorCount = $processors
    MemoryStartupBytes = $MemoryStartupBytes
}

If ($dynamicmemory) {
    $more_vm_params.Add("DynamicMemory",$True)
    $more_vm_params.Add("MemoryMinimumBytes",$MemoryMinimumBytes)
    $more_vm_params.Add("MemoryMaximumBytes", $MemoryMaximumBytes)
} else {
    $more_vm_params.Add("StaticMemory",$True)
}

if ($notes) {
    $more_vm_params.Add("Notes",$notes)
}

# Set the values on the VM
$vm | Set-VM @more_vm_params -Passthru

# Add drives to the virtual machine
$controllers = Select-Xml -xml $vmconfig -xpath "//*[starts-with(name(.),'controller')]"

# Only set EFI secure boot for Gen 2 machines, not gen 1
if ($generation -ne 1) {
	# Set EFI secure boot 
	if ($secure_boot_enabled -eq "True") {
		Set-VMFirmware -VM $vm -EnableSecureBoot On
	}  else {
		Set-VMFirmware -VM $vm -EnableSecureBoot Off
	}
}

# A regular expression pattern to pull the number from controllers
[regex]$rx="\d"

foreach ($controller in $controllers) {
    $node = $controller.Node

    # Check for SCSI
    if ($node.ParentNode.ChannelInstanceGuid) {
        $ControllerType = "SCSI"
    } else {
        $ControllerType = "IDE"
    }

    $drives = $node.ChildNodes | where {$_.pathname."#text"}
    foreach ($drive in $drives) {
        #if drive type is ISO then set DVD Drive accordingly
        $driveType = $drive.type."#text"

        $addDriveParam = @{
            ControllerNumber = $rx.Match($controller.node.name).value
            Path = $image_path
        }

        if ($drive.pool_id."#text") {
            $ResourcePoolName = $drive.pool_id."#text"
            $addDriveParam.Add("ResourcePoolname",$ResourcePoolName)
        }

        if ($drivetype -eq 'VHD') {
            $addDriveParam.add("ControllerType",$ControllerType)
            $vm | Add-VMHardDiskDrive @AddDriveparam
        }
    }
}

$vm_id = (Get-VM $vm_name).id.guid
$resultHash = @{
    name = $vm_name
    id = $vm_id
}

$result = ConvertTo-Json $resultHash
Write-Output-Message $result
