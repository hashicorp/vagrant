param (
    [string] $VmId,
    [string] $guest_service_interface = $null,
    [string] $heartbeat = $null,
    [string] $key_value_pair_exchange = $null,
    [string] $shutdown = $null,
    [string] $time_synchronization = $null,
    [string] $vss = $null
)

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

$vm = Get-VM -Id $VmId -ErrorAction "stop"

# Set the service based on value
function VmSetService
{
    param ([string] $Name, [string] $Value, [Microsoft.HyperV.PowerShell.VirtualMachine] $Vm)

    if ($Value -ne $null){
        if($Value -eq "true"){
            Enable-VMIntegrationService -VM $Vm -Name $Name
        }
        if($Value -eq "false"){
            Disable-VMIntegrationService -VM $Vm -Name $Name
        }
    }
}

VmSetService -Name "Guest Service Interface" -Value $guest_service_interface -Vm $vm
VmSetService -Name "Heartbeat" -Value $heartbeat -Vm $vm
VmSetService -Name "Key-Value Pair Exchange" -Value $key_value_pair_exchange -Vm $vm
VmSetService -Name "Shutdown" -Value $shutdown -Vm $vm
VmSetService -Name "Time Synchronization" -Value $time_synchronization -Vm $vm
VmSetService -Name "VSS" -Value $vss -Vm $vm