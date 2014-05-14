#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

param (
  [Parameter(Mandatory=$true)]
  [string]$type,
  [Parameter(Mandatory=$true)]
  [string]$name,
  [Parameter(Mandatory=$true)]
  [string]$vm_id,
  [Parameter(Mandatory=$false)]
  [string]$adapter
 )

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

try {

   $vm = Get-VM -Id $vm_id -ErrorAction "stop"
    Get-VMSwitch "$name" | Where-Object { $_.SwitchType -eq "$type" } `
    | Connect-VMNetworkAdapter -VMName $vm.Name

   $resultHash = @{
     message = "OK"
   }
   Write-Output-Message $(ConvertTo-JSON $resultHash)
 }
 catch {
  $errortHash = @{
    type = "PowerShellError"
    error = "$_"
  }
  Write-Error-Message $(ConvertTo-JSON $errortHash)
 }
