Param(
    [Parameter(Mandatory=$true)]
    [string]$vm_config_file,
    [Parameter(Mandatory=$true)]
    [string]$source_path,
    [Parameter(Mandatory=$true)]
    [string]$dest_path,
    [Parameter(Mandatory=$true)]
    [string]$data_path,

    [string]$switchname=$null,
    [string]$memory=$null,
    [string]$maxmemory=$null,
    [string]$cpus=$null,
    [string]$vmname=$null,
    [string]$auto_start_action=$null,
    [string]$auto_stop_action=$null,
    [string]$differencing_disk=$null,
    [string]$enable_virtualization_extensions=$False
)

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

$VmProperties = @{
    Path = $vm_config_file
    SnapshotFilePath   = Join-Path $data_path 'Snapshots'
    VhdDestinationPath = Join-Path $data_path 'Virtual Hard Disks'
    VirtualMachinePath = $data_path
}

$vmConfig = (Compare-VM -Copy -GenerateNewID @VmProperties)

$generation = $vmConfig.VM.Generation

if (!$vmname) {
    # Get the name of the vm
    $vm_name = $vmconfig.VM.VMName
} else {
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

    $MemoryMaximumBytes = ($configMemory.Maximum)
    $MemoryStartupBytes = ($configMemory.Startup)
    $MemoryMinimumBytes = ($configMemory.Minimum)
} else {
    if (!$maxmemory){
        $dynamicmemory = $False
        $MemoryMaximumBytes = ($memory -as [int]) * 1MB
        $MemoryStartupBytes = ($memory -as [int]) * 1MB
        $MemoryMinimumBytes = ($memory -as [int]) * 1MB
    } else {
        $dynamicmemory = $True
        $MemoryMaximumBytes = ($maxmemory -as [int]) * 1MB
        $MemoryStartupBytes = ($memory -as [int]) * 1MB
        $MemoryMinimumBytes = ($memory -as [int]) * 1MB
    }
}

if (!$switchname) {
    $switchname = (Get-VMNetworkAdapter -VM $vmConfig.VM).SwitchName
}

# Enable nested virtualization if configured
if ($enable_virtualization_extensions -eq "True") {
    Set-VMProcessor -VM $vmConfig.VM -ExposeVirtualizationExtensions $true
}

$vmNetworkAdapter = Get-VMNetworkAdapter -VM $vmConfig.VM
Connect-VMNetworkAdapter -VMNetworkAdapter $vmNetworkAdapter -SwitchName $switchname
Set-VM -VM $vmConfig.VM -NewVMName $vm_name
Set-VM -VM $vmConfig.VM -ErrorAction "Stop"
Set-VM -VM $vmConfig.VM -ProcessorCount $processors

if ($dynamicmemory) {
    Set-VM -VM $vmConfig.VM -DynamicMemory
    Set-VM -VM $vmConfig.VM -MemoryMinimumBytes $MemoryMinimumBytes -MemoryMaximumBytes $MemoryMaximumBytes -MemoryStartupBytes $MemoryStartupBytes
} else {
    Set-VM -VM $vmConfig.VM -StaticMemory
    Set-VM -VM $vmConfig.VM -MemoryStartupBytes $MemoryStartupBytes
}

if ($notes) {
    Set-VM -VM $vmConfig.VM -Notes $notes
}

if ($auto_start_action) {
    Set-VM -VM $vmConfig.VM -AutomaticStartAction $auto_start_action
}

if ($auto_stop_action) {
    Set-VM -VM $vmConfig.VM -AutomaticStopAction $auto_stop_action
}

# Only set EFI secure boot for Gen 2 machines, not gen 1
if ($generation -ne 1) {
    Set-VMFirmware -VM $vmConfig.VM -EnableSecureBoot (Get-VMFirmware -VM $vmConfig.VM).SecureBoot
}

$report = Compare-VM -CompatibilityReport $vmConfig

# Stop if there are incompatibilities
if($report.Incompatibilities.Length -gt 0){
    Write-Error-Message $(ConvertTo-Json $($report.Incompatibilities | Select -ExpandProperty Message))
    exit 0
}

if($differencing_disk){
    # Get all controller on the VM, first scsi, then IDE if it is a Gen 1 device
    $controllers = Get-VMScsiController -VM $vmConfig.VM
    if($generation -eq 1){
        $controllers = @($controllers) + @(Get-VMIdeController -VM $vmConfig.VM)
    }

    foreach($controller in $controllers){
        foreach($drive in $controller.Drives){
            if([System.IO.Path]::GetFileName($drive.Path) -eq [System.IO.Path]::GetFileName($source_path)){
                # Remove the old disk and replace it with a differencing version
                $path = $drive.Path
                Remove-VMHardDiskDrive $drive
                New-VHD -Path $dest_path -ParentPath $source_path -ErrorAction Stop
                Add-VMHardDiskDrive -VM $vmConfig.VM -Path $dest_path
            }
        }
    }
}

Import-VM -CompatibilityReport $vmConfig

$vm_id = (Get-VM $vm_name).id.guid
$resultHash = @{
    name = $vm_name
    id = $vm_id
}

$result = ConvertTo-Json $resultHash
Write-Output-Message $result
