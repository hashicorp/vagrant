#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

param (
    [string]$vm_id = $(throw "-vm_id is required.")
 )

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

try {
  $vm = Get-VM -Id $vm_id -ErrorAction "stop"
  Start-VM $vm
  $state = $vm.state
  $status = $vm.status
  $name = $vm.name
  $resultHash = @{
    state = "$state"
    status = "$status"
    name = "$name"
  }
  $result = ConvertTo-Json $resultHash
  Write-Output-Message $result
}
catch {
  Write-Error-Message "Failed to start a VM $_"
}
