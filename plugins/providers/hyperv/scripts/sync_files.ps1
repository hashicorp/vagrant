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
    [string]$dir_list,
    [string]$path_separator
)

function copy-file($machine, $dir_list, $path_separator) {
  $files = Get-Content $dir_list | ConvertFrom-Json
  $succeeded = @()
  $failed = @()
  foreach ($line in $files.PSObject.Properties) {
    $sourceDir = $line.Name
    $destDir = $line.Value
    Get-ChildItem $sourceDir -File | ForEach-Object -Process {
      $from = $sourceDir + "\" + $_.Name
      $to = $destDir
      Write-Host "Copying $from to $($machine) => $to..."
      Try {
        Hyper-V\Copy-VMFile -VM $machine -SourcePath $from -DestinationPath $to -CreateFullPath -FileSource Host -Force
        $succeeded += $from
        Write-Host "Copied $from to $($machine) => $to."
      } Catch {
        $failed += $from
        Break
      }
    }
  }
  [hashtable]$return = @{}
  $return.succeeded = $succeeded
  $return.failed = $failed
  return $return
}

$machine = Hyper-V\Get-VM -Id $vm_id

$status = copy-file $machine $dir_list $path_separator

$resultHash = @{
  message = "OK"
  status = $status
}
$result = ConvertTo-Json $resultHash
Write-OutputMessage $result
