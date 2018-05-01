Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
 )

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

$vm = Hyper-V\Get-VM -Id $VmId -ErrorAction "Stop"
$networks = Hyper-V\Get-VMNetworkAdapter -VM $vm
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
  } else {
    # Try to discover the IP address from the neighbor cache entries
    try {
      $mac = (Get-VMNetworkAdapter -VM $vm).MacAddress
      $macaddr = ($mac -replace "(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})", '$1-$2-$3-$4-$5-$6')
      $ip_address = (Get-NetNeighbor -LinkLayerAddress $macaddr).IPAddress
      if (-Not ([string]::IsNullOrEmpty($ip_address))) {
        # It's our lucky day
        $ip4_address = $ip_address
        break
      }
    } catch {
      $ip_address = ""
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
