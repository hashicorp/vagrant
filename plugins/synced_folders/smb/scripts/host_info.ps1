$ErrorAction = "Stop"

$net = Get-NetIPAddress
$result = @{
	ip_addresses = $net.IPAddress
}

Write-Output $(ConvertTo-Json $result)
