$ErrorAction = "Stop"

$ipAddresses = Get-NetIPAddress | Where-Object {($_.IPAddress -ne "127.0.0.1") -and ($_.IPAddress -ne "::1") -and (!$_.IPAddress.StartsWith("169.254."))} | Sort-Object -Property AddressFamily, InterfaceIndex | %{ ($_.IpAddress -split '%')[0]}

$result = @{
	ip_addresses = $ipAddresses
}

Write-Output $(ConvertTo-Json $result)
