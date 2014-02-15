#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

# Include the following modules
$presentDir = Split-Path -parent $PSCommandPath
$modules = @()
$modules += $presentDir + "\utils\write_messages.ps1"
forEach ($module in $modules) { . $module }

try {
$hostname =  $(whoami)
$ip = (Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter 'ipenabled = "true"').ipaddress[0]
  $resultHash = @{
    host_name = "$username"
    host_ip = "$ip"
  }
  $result = ConvertTo-Json $resultHash
  Write-Output-Message $result
}
catch {
  Write-Error-Message $_
}

