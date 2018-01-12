$ErrorAction = "Stop"

# Find all of the NICsq
$nics = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()

# Save the IP addresses somewhere
$nic_ip_addresses = @()

foreach ($nic in $nics) {
    $nic_ip_addresses += $nic.GetIPProperties().UnicastAddresses | Where-Object {
      ($_.Address.IPAddressToString -ne "127.0.0.1") -and ($_.Address.IPAddressToString -ne "::1")
    } | Select -ExpandProperty Address
}

$nic_ip_addresses = $nic_ip_addresses | Sort-Object $_.AddressFamily

$result = @{
	ip_addresses = $nic_ip_addresses.IPAddressToString
}

Write-Output $(ConvertTo-Json $result)
