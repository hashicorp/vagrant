#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

param (
    [Parameter(Mandatory=$true)]
    [string]$type,
    [Parameter(Mandatory=$true)]
    [string]$name
 )

 # Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

try {
  if ($type -eq "external") {
    $switch_exist = Get-VMSwitch -SwitchType  "$type"
    if ($switch_exist) {
      $switch_name = $switch_exist.name
      $resptHash = @{
        message = "switch exist"
        switch_name = "$switch_name"
      }
      Write-Output-Message $(ConvertTo-JSON $resptHash)
      return
    }
  }

  $switch_exist = (Get-VMSwitch -SwitchType  "$type" `
    | Select-Object Name `
    | Where-Object { $_.name -eq $name })
  if ($switch_exist) {
    $switch_name = $switch_exist.name
    $resptHash = @{
      message = "switch exist"
      switch_name = "$switch_name"
    }
  } else {
    $resptHash = @{
      message = "switch not exist"
      switch_name = "$name"
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
