Param(
    [Parameter(Mandatory=$true)]
    [string]$vm_xml_config,
    [Parameter(Mandatory=$true)]
    [string]$vhdx_path,

    [string]$switchname=$null
)

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

[xml]$vmconfig = Get-Content -Path  $vm_xml_config

$vm_name = $vmconfig.configuration.properties.name.'#text'
$processors = $vmconfig.configuration.settings.processors.count.'#text'

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

$memory = (Select-Xml -xml $vmconfig -XPath "//memory").node.Bank
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

# Define a hash map of parameter values for New-VM

$vm_params = @{
    Name = $vm_name
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
            Path = $vhdx_path
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
