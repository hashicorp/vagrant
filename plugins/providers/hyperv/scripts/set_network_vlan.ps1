#Requires -Modules VagrantMessages

param (
    [parameter (Mandatory=$true)]
    [string]$VmId,
    [parameter (Mandatory=$true)]
    [int]$VlanId
)

# Include the following modules
$presentDir = Split-Path -parent $PSCommandPath
$modules = @()
$modules += $presentDir + "\utils\write_messages.ps1"
forEach ($module in $modules) { . $module }

try {
  $vm = Hyper-V\Get-VM -Id $VmId -ErrorAction "stop"
  Hyper-V\Set-VMNetworkAdapterVlan $vm -Access -Vlanid $VlanId
}
catch {
  Write-ErrorMessage "Failed to set VM's Vlan ID $_"
}
