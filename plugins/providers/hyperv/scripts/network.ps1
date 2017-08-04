param([string[]]$networks, [string]$vmname)

"$networks and $vmname" | Set-Content c:\test.txt


Write-Host "Networks: $networks"
Write-Host "VMName: $vmname"


#clear out existing nics
Get-VMNetworkAdapter -VMName $vmname | Remove-VMNetworkAdapter

#setup networks to use target network switches.
foreach($net in $networks)
{
    Add-VMNetworkAdapter -VMName $vmname -SwitchName $net
}