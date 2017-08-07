param([string]$networks, [string]$VMId)

$vm = Get-VM -Id $VMId

#clear out existing nics
Get-VMNetworkAdapter -VM $vm | Remove-VMNetworkAdapter

#setup networks to use target network switches.
foreach($net in $networks.Split("|"))
{
    Add-VMNetworkAdapter -VM $vm -SwitchName $net
}