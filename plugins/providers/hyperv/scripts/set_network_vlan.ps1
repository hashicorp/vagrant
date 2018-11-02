#Requires -Modules VagrantMessages

param (
    [parameter (Mandatory=$true)]
    [string]$VmId,
    [parameter (Mandatory=$true)]
    [int]$VlanId
)

try {
  $vm = Hyper-V\Get-VM -Id $VmId -ErrorAction "stop"
  Hyper-V\Set-VMNetworkAdapterVlan $vm -Access -Vlanid $VlanId
}
catch {
  Write-ErrorMessage "Failed to set VM's Vlan ID $_"
}
