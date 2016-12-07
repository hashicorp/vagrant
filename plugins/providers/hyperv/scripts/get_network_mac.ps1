Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
 )

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

$ip_address = ""
$vm = Get-VM -Id $VmId -ErrorAction "Stop"
$networks = Get-VMNetworkAdapter -VM $vm
foreach ($network in $networks) {
  if ($network.MacAddress -gt 0) {
    $mac_address = $network.MacAddress
    if (-Not ([string]::IsNullOrEmpty($mac_address))) {
      # We found our mac address!
      break
    }
  }
}


$resultHash = @{
    mac = "$mac_address"
}
$result = ConvertTo-Json $resultHash
Write-Output-Message $result