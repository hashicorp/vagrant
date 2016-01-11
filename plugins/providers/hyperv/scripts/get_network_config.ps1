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
  if ($network.IpAddresses.Length -gt 0) {
    $ip_address = $network.IpAddresses[0]
    if (-Not ([string]::IsNullOrEmpty($ip_address))) {
      # We found our IP address!
      break
    }
  }
}

$resultHash = @{
    ip = "$ip_address"
}
$result = ConvertTo-Json $resultHash
Write-Output-Message $result
