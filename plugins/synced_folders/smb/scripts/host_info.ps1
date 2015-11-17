$ErrorAction = "Stop"

Try{
	$net = Get-NetIPAddress | Where-Object {
	    ($_.IPAddress -ne "127.0.0.1") -and ($_.IPAddress -ne "::1")
	} | Sort-Object $_.AddressFamily
}
Catch{
	$net = get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {
	    $_.IPAddress -and ($_.IPAddress -ne "127.0.0.1") -and ($_.IPAddress -ne "::1")
	}
}

$result = @{
	ip_addresses = $net.IPAddress
}

Write-Output $(ConvertTo-Json $result)
