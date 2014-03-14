$adapters = get-ciminstance win32_networkadapter -filter "macaddress is not null"
$processed = @()
foreach ($adapter in $adapters) {
  $Processed += new-object PSObject -Property @{
    mac_address = $adapter.macaddress
    net_connection_id = $adapter.netconnectionid
    interface_index = $adapter.interfaceindex
    index = $adapter.index
  }
}
convertto-json -inputobject $processed
