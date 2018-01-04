param (
    [string]$VmId = $(throw "-VmId is required.")
 )

# Include the following modules
$presentDir = Split-Path -parent $PSCommandPath
$modules = @()
$modules += $presentDir + "\utils\write_messages.ps1"
forEach ($module in $modules) { . $module }

try {
  $vm = Hyper-V\Get-VM -Id $VmId -ErrorAction "stop"
  Hyper-V\Start-VM $vm -ErrorAction "stop"
  $state = $vm.state
  $status = $vm.status
  $name = $vm.name
  $resultHash = @{
    state = "$state"
    status = "$status"
    name = "$name"
  }
  $result = ConvertTo-Json $resultHash
  Write-Output-Message $result
}
catch {
  Write-Error-Message "Failed to start a VM $_"
}