$ErrorAction = "Stop"

$net = Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter 'ipenabled = "true"'
$result = @{
    ip_addresses = $net.ipaddress
}

Write-Output $(ConvertTo-Json $result)
