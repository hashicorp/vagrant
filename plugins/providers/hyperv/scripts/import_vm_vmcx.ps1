Param(
    [Parameter(Mandatory=$true)]
    [string]$vm_config_file,
    [Parameter(Mandatory=$true)]
    [string]$image_path,

    [string]$switchname=$null,
    [string]$memory=$null,
    [string]$maxmemory=$null,   
    [string]$cpus=$null,
    [string]$vmname=$null,
    [string]$auto_start_action=$null,
    [string]$auto_stop_action=$null
)

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

# load the config from the vmcx and make a copy for editing, use TMP path so we are sure there is no vhd at the destination
$vmConfig = (Compare-VM -Copy -Path $vm_config_file -GenerateNewID -VhdDestinationPath $env:Temp)

$generation = $vmConfig.VM.Generation

if (!$vmname) {
    # Get the name of the vm
    $vm_name = $vmconfig.VM.VMName
}else {
    $vm_name = $vmname
}

if (!$cpus) {
    # Get the processorcount of the VM
    $processors = (Get-VMProcessor -VM $vmConfig.VM).Count
    
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
    $configMemory = Get-VMMemory -VM $vmConfig.VM
    $dynamicmemory = $configMemory.DynamicMemoryEnabled

    # Memory values need to be in bytes
    $MemoryMaximumBytes = ($configMemory.Maximum)
    $MemoryStartupBytes = ($configMemory.Startup)
    $MemoryMinimumBytes = ($configMemory.Minimum)
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
    $switchname = (Get-VMNetworkAdapter -VM $vmConfig.VM).SwitchName
}

$vm_params = @{
    Name = $vm_name
    NoVHD = $True
    MemoryStartupBytes = $MemoryStartupBytes
    SwitchName = $switchname
    ErrorAction = "Stop"
}

# Generation parameter was added in ps v4
if((get-command New-VM).Parameters.Keys.Contains("generation")) {
    $vm_params.Generation = $generation
}

# Create the VM using the values in the hash map
$vm = New-VM @vm_params

$notes = $vmConfig.VM.Notes

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

if ($auto_start_action) {
    $more_vm_params.Add("AutomaticStartAction",$auto_start_action)
}

if ($auto_stop_action) {
    $more_vm_params.Add("AutomaticStopAction",$auto_stop_action)
}

# Set the values on the VM
$vm | Set-VM @more_vm_params -Passthru

# Only set EFI secure boot for Gen 2 machines, not gen 1
if ($generation -ne 1) {
    Set-VMFirmware -VM $vm -EnableSecureBoot (Get-VMFirmware -VM $vmConfig.VM).SecureBoot
}

# Get all controller on the VM, first scsi, then IDE if it is a Gen 1 device
$controllers = Get-VMScsiController -VM $vmConfig.VM
if($generation -eq 1){
    $controllers = @($controllers) + @(Get-VMIdeController -VM $vmConfig.VM)
}

foreach($controller in $controllers){
    foreach($drive in $controller.Drives){
        $addDriveParam = @{
            ControllerNumber = $drive.ControllerNumber
            Path = $image_path
        }
        if($drive.PoolName){
            $addDriveParam.Add("ResourcePoolname",$drive.PoolName)
        }

        # If the drive path is set, it is a harddisk, only support single harddisk
        if ($drive.Path) {
            $addDriveParam.add("ControllerType", $ControllerType)
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
