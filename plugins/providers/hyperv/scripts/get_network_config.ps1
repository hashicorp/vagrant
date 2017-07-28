Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
 )

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

$vm = Get-VM -Id $VmId -ErrorAction "Stop"
$networks = Get-VMNetworkAdapter -VM $vm
foreach ($network in $networks) {
  if ($network.IpAddresses.Length -gt 0) {
    foreach ($ip_address in $network.IpAddresses) {
      if ($ip_address.Contains(".")) {
        $ip4_address = $ip_address
      } elseif ($ip_address.Contains(":")) {
        $ip6_address = $ip_address
      }
      if (-Not ([string]::IsNullOrEmpty($ip4_address)) -Or -Not ([string]::IsNullOrEmpty($ip6_address))) {
        # We found our IP address!
        break
      }
    }
  }
}

if (-Not ([string]::IsNullOrEmpty($ip4_address))) {
  $guest_ipaddress = $ip4_address
} elseif (-Not ([string]::IsNullOrEmpty($ip6_address))) {
  $guest_ipaddress = $ip6_address
}

if (-Not ([string]::IsNullOrEmpty($guest_ipaddress))) {
  $resultHash = @{
      ip = $guest_ipaddress
  }
  $result = ConvertTo-Json $resultHash
  Write-Output-Message $result
} else {
  Write-Error-Message "Failed to determine IP address"
}
