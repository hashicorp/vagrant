param([string]$networks, [string]$VMId, [string]$mac, [string]$vlan)

Write-Host "`$VMId='$VMId'"
Write-Host "`$mac='$mac'"
Write-Host "`$vlan='$vlan'"

$vm = Get-VM -Id $VMId

$networklist = $networks.Split("|")
$maclist = $mac.Split("|")
$vlanlist = $vlan.Split("|")

$networkAdaptors = @(Get-VMNetworkAdapter -VM $vm)

for ($i = $networkAdaptors.Count - 1; $i -ge $networklist.Count; $i--)
{
    $networkAdaptors[$i] | Remove-VMNetworkAdapter
}

for ($i = 0; $i -lt $networklist.Count; $i++)
{
    if ($i -lt $networkAdaptors.Count) {
        $adapter = $networkAdaptors[$i]
        $adapter | Connect-VMNetworkAdapter -SwitchName $networklist[$i]
    } else {
        $adapter = Add-VMNetworkAdapter -VM $vm -SwitchName $networklist[$i]
    }
     
    if ($maclist[$i] -eq "auto")
    {
        $adapter | Set-VMNetworkAdapter -DynamicMacAddress
    }
    else
    {
        $adapter | Set-VMNetworkAdapter -StaticMacAddress $maclist[$i]
    }

    if ($vlanlist[$i] -ne "none")
    {
        $adapter | Set-VMNetworkAdapterVlan -Access -VlanId [int]::Parse($vlanlist[$i])
    } else {
        $adapter | Set-VMNetworkAdapterVlan -Untagged
    }
}