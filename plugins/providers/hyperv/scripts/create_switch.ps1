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
    [Parameter(Mandatory=$true)]
    [string]$adapter
 )

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

try {

  # Find the current IP address of the host. This will be used later to test the
  # network connectivity upon creating a new switch to a network adapter
  $ip = (Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter 'ipenabled = "true"').ipaddress[0]

  $max_attempts = 5
  $operation_pass = $false
  do {
    try {
      if ($type -eq "external") {
        New-VMSwitch -Name "$name" -NetAdapterName $adapter -ErrorAction "stop"
      }
      $operation_pass = $true
    } catch {
      $max_attempts = $max_attempts - 1
      sleep 5
    }
  }
  while (!$operation_pass -and $max_attempts -gt 0)

   # On creating a new switch / a new network adapter, there are chances that
   # the network may get disconnected for a while.

   # Keep checking for network availability before exiting this script
   $max_attempts = 10
   $network_available = $false
   do {
     try {
      $ping_response = Test-Connection "$ip" -ErrorAction "stop"
      $network_available = $true
     } catch {
        $max_attempts = $max_attempts - 1
        sleep 5
     }
   }
   while (!$network_available -and $max_attempts -gt 0)
   if (-not $network_available) {
    $resptHash = @{
      message = "Network down"
    }
   } else {
    $resptHash = @{
      message = "Success"
    }
   }
   Write-Output-Message $(ConvertTo-JSON $resptHash)
   return
} catch {
    $errortHash = @{
      type = "PowerShellError"
      error = "$_"
    }
    Write-Error-Message $(ConvertTo-JSON $errortHash)
}
