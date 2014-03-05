#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

param (
    [string]$path = $(throw "-path is required."),
    [string]$vm_id = $(throw "-vm_id is required."),
    [string]$guest_ip = $(throw "-guest_ip is required."),
    [string]$username = $(throw "-guest_username is required."),
    [string]$password = $(throw "-guest_password is required."),
    [string]$params = ""
)


# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))
. ([System.IO.Path]::Combine($Dir, "utils\create_session.ps1"))

try {
  function Remote-Execute($path, $params) {
    $old = Get-ExecutionPolicy
    Set-ExecutionPolicy Unrestricted -force
    . $path $params
    Set-ExecutionPolicy $old -force
  }

  $response = Create-Remote-Session $guest_ip $username $password
  if (!$response["session"] -and $response["error"]) {
      Write-Host $response["error"]
      return
  }
  Invoke-Command -Session $response["session"] -ScriptBlock ${function:Remote-Execute} -ArgumentList $path, $params -ErrorAction "stop"
} catch {
  Write-Host $_
  return
}
