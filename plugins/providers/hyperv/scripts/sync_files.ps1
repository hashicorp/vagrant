#Requires -Modules VagrantMessages
#-------------------------------------------------------------------------
# Copyright (c) 2019 Microsoft
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

param (
    [parameter (Mandatory=$true)]
    [string]$vm_id,
    [parameter (Mandatory=$true)]
    [string]$guest_ip,
    [parameter (Mandatory=$true)]
    [string]$file_list,
    [string]$path_separator
)

function copy-file($machine, $file_list, $path_separator) {
  $files = Get-Content $file_list | ConvertFrom-Json
  $succeeded = @()
  $failed = @()
  foreach ($line in $files.PSObject.Properties) {
    $from = $sourceDir = $line.Name
    $to = $destDir = $line.Value
    Write-Host "Copying $from to $($machine) => $to..."
    Try {
      Hyper-V\Copy-VMFile -VM $machine -SourcePath $from -DestinationPath $to -CreateFullPath -FileSource Host -Force
      $succeeded += $from
      Write-Host "Copied $from to $($machine) => $to."
    } Catch {
      $failed += $from
    }
  }
  [hashtable]$return = @{}
  $return.succeeded = $succeeded
  $return.failed = $failed
  return $return
}

$machine = Hyper-V\Get-VM -Id $vm_id

$status = copy-file $machine $file_list $path_separator

$resultHash = @{
  message = "OK"
  status = $status
}
$result = ConvertTo-Json $resultHash
Write-OutputMessage $result
