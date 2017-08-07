param([string]$networks, [string]$VMId, [string]$mac, [string]$vlan)

$vm = Get-VM -Id $VMId

$networklist = $networks.Split("|")
$maclist = $mac.Split("|")
$vlanlist = $vlan.Split("|")

#clear out existing nics
Get-VMNetworkAdapter -VM $vm | Remove-VMNetworkAdapter

for ($i = 0; $i -lt $networklist.Count; $i++)
{
    $adapter = $null 
    if ($maclist[$i] -eq "auto")
    {
        $adapter = Add-VMNetworkAdapter -VM $vm -SwitchName $networklist[$i] -Passthru
    }
    else
    {
        $adapter = Add-VMNetworkAdapter -VM $vm -SwitchName $networklist[$i] -StaticMacAddress $maclist[$i] -Passthru
    }

    if ($vlanlist[$i] -ne "none")
    {
        Set-VMNetworkAdapterVlan -VMNetworkAdapter $adapter -Access -VlanId [int]::Parse($vlanlist[$i])
    }
}