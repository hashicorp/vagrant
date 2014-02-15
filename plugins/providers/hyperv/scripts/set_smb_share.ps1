#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

param (
    [string]$path = $(throw "-path is required."),
    [string]$share_name = $(throw "-share_name is required."),
    [string]$host_share_username = $(throw "-host_share_username is required")
 )

# Include the following modules
$presentDir = Split-Path -parent $PSCommandPath
$modules = @()
$modules += $presentDir + "\utils\write_messages.ps1"
forEach ($module in $modules) { . $module }

try {
  # See all available shares and check alert user for existing / conflicting share name
  $shared_folders = net share
  $reg = "$share_name(\s+)$path(\s)"
  $existing_share = $shared_folders -Match $reg
  if ($existing_share) {
    # Always clear the existing share name and create a new one
    net share $share_name /delete /y
  }

  $computer_name = $(Get-WmiObject Win32_Computersystem).name
  $grant_permission = "$computer_name\$host_share_username,Full"
  $result = net share $share_name=$path /unlimited /GRANT:$grant_permission
  if ($result -Match "$share_name was shared successfully.") {
    $resultHash = @{
      message = "OK"
    }
    $result = ConvertTo-Json $resultHash
    Write-Output-Message $result
  } else {
    $reg = "^$share_name(\s+)"
    $existing_share = $shared_folders -Match $reg
    Write-Error-Message "IGNORING Conflicting share name, A share name already exist $existing_share"
  }
} catch {
  Write-Error-Message $_
  return
}

