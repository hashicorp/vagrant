#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

param (
    [string]$vm_id = $(throw "-vm_id is required."),
    [string]$host_path = $(throw "-host_path is required."),
    [string]$guest_path = $(throw "-guest_path is required.")
 )


# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

try {

  # Enable Guest Service Interface if they are disabled
  try {
    Get-VM -Id $vm_id | Get-VMIntegrationService -Name "Guest Service Interface" | Enable-VMIntegrationService -Passthru
    }
    catch { }

  $machine = Get-VM -Id $vm_id
  Copy-VMFile  -VM $machine -SourcePath $host_path -DestinationPath $guest_path -CreateFullPath -FileSource Host -Force -ErrorAction stop
  $resultHash = @{
    message = "OK"
    temp_path = "$guest_path"
  }
  $result = ConvertTo-Json $resultHash
  Write-Output-Message $result
} catch {
  Write-Error-Message "Failed to copy file  $_"
  return
}
