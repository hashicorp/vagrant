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
            if ($ip_address.Contains(".") -And [string]::IsNullOrEmpty($ip4_address)) {
                $ip4_address = $ip_address
            } elseif ($ip_address.Contains(":") -And [string]::IsNullOrEmpty($ip6_address)) {
                $ip6_address = $ip_address
            }
        }
    }
}

# If no address was found in the network settings, check for
# neighbor with mac address and see if an IP exists
if (([string]::IsNullOrEmpty($ip4_address)) -And ([string]::IsNullOrEmpty($ip6_address))) {
    $macaddresses = $vm | select -ExpandProperty NetworkAdapters | select MacAddress
    foreach ($macaddr in $macaddresses) {
        $macaddress = $macaddr.MacAddress -replace '(.{2})(?!$)', '${1}-'
        $addr = Get-NetNeighbor -LinkLayerAddress $macaddress -ErrorAction SilentlyContinue | select IPAddress
        if ($ip_address) {
            $ip_address = $addr.IPAddress
            if ($ip_address.Contains(".")) {
                $ip4_address = $ip_address
            } elseif ($ip_address.Contains(":")) {
                $ip6_address = $ip_address
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
