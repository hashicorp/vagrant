#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

param (
    [string]$vm_id = $(throw "-vm_id is required.")
 )

# Include the following modules
$presentDir = Split-Path -parent $PSCommandPath
$modules = @()
$modules += $presentDir + "\utils\write_messages.ps1"
forEach ($module in $modules) { . $module }

try {
  $vm = Get-VM -Id $vm_id -ErrorAction "stop"
  $network = Get-VMNetworkAdapter  -VM $vm
  $ip_address = $network.IpAddresses[0]
  $resultHash = @{
    ip = "$ip_address"
  }
  $result = ConvertTo-Json $resultHash
  Write-Output-Message $result
}
catch {
  Write-Error-Message "Failed to obtain network info of VM $_"
}
