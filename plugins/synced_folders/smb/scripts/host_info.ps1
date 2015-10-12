$ErrorAction = "Stop"

$net = Get-NetIPAddress | Where-Object {
    ($_.IPAddress -ne "127.0.0.1") -and ($_.IPAddress -ne "::1")
} | Sort-Object $_.AddressFamily

$result = @{
	ip_addresses = $net.IPAddress
}

Write-Output $(ConvertTo-Json $result)
