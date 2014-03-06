#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

Param(
    [Parameter(Mandatory=$true)]
    [string]$vm_id
 )

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

try {
  $vm = Get-VM -Id $vm_id -ErrorAction "Stop"
  $network = Get-VMNetworkAdapter -VM $vm
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
