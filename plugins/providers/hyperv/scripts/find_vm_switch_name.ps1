#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

param (
    [Parameter(Mandatory=$true)]
    [string]$VmId
 )

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))


try {
  $vm = Get-VM -Id $VmId -ErrorAction "stop"
  $network_adapter = Get-VMNetworkAdapter -vm $vm
  $resultHash = @{}
  $resultHash["switch_name"] = $network_adapter.SwitchName
  $resultHash["network_adapter"] = $network_adapter.Name
  Write-Output-Message $(ConvertTo-JSON $resultHash)
} catch [Microsoft.HyperV.PowerShell.VirtualizationOperationFailedException] {
  $errortHash = @{
    type = "PowerShellError"
    error = "$_"
  }
  Write-Error-Message $(ConvertTo-JSON $errortHash)
}
