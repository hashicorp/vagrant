param (
    [string]$VmId = $(throw "-VmId is required."),
    [string]$Mac = $(throw "-Mac ")
 )

# Include the following modules
$presentDir = Split-Path -parent $PSCommandPath
$modules = @()
$modules += $presentDir + "\utils\write_messages.ps1"
forEach ($module in $modules) { . $module }

try {
  $vm = Hyper-V\Get-VM -Id $VmId -ErrorAction "stop"
  $adapter = Hyper-V\Get-VMNetworkAdapter -VM $vm | Select-Object -First 1 
  Hyper-V\Set-VMNetworkAdapter $vm -VMNetworkAdapterName $adapter.Name  -StaticMacAddress $Mac -ErrorAction "stop"
}
catch {
  Write-Error-Message "Failed to set VM's MAC address $_"
}
