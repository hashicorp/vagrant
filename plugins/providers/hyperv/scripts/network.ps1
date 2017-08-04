param($networks, $vmname)

#clear out existing nics
Get-VMNetworkAdapter -VMName $vmname | Remove-VMNetworkAdapter

#setup networks to use target network switches.
foreach($net in $networks)
{
    Add-VMNetworkAdapter -VMName $vmname -SwitchName $net
}