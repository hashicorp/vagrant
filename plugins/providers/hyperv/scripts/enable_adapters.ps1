param (
    [Parameter(Mandatory=$true)]
    [string]$VmId = $(throw "-VmId is required."),
    [Parameter(Mandatory=$true)]
    $adapters
 )

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

if(!$adapters) {
    Write-Error-Message "No adapters specified"
} else {
    $adapters = $adapters | ConvertFrom-Json
}

if ($adapters.length -gt 0){
    $vm = Get-VM -Id $VmId -ErrorAction "Stop"
    Stop-VM $vm -Force

    $installedAdapters = Get-VMNetworkAdapter -VM $vm

    $adapterInstance = 0
    $installedAdapters | %{
        $adapterInstance = $adapterInstance + 1
        $installedAdapter = $_
        if ($adapterInstance -gt $adapters.length){
            #Write-Output-Message "Removing adapter $adapterInstance - $($installedAdapter.MacAddress)"
            Remove-VMNetworkAdapter $vm -VMNetworkAdapterName $_.Name
        } 
    } 

    $adapterInstance = 0
    $adapters | Sort-Object adapter | %{
        $adapterInstance = $adapterInstance + 1
        $installedAdapter = $installedAdapters[$adapterInstance-1]
        $macAddress = $_.mac_address
        $switchname = $_.intnet

        if ($installedAdapter){
            if ($macAddress){
                #Write-Output-Message "Configuring adapter - $($installedAdapter.MacAddress) for switch $switchname"
                Set-VMNetworkAdapter -VMNetworkAdapter $installedAdapter -StaticMacAddress $macAddress
                Connect-VMNetworkAdapter -VMNetworkAdapter $installedAdapter -SwitchName $switchname
            } else {
                #Write-Output-Message "Configuring adapter - dynamic mac address for switch $switchname"
                Set-VMNetworkAdapter -VMNetworkAdapter $installedAdapter -DynamicMacAddress
                Connect-VMNetworkAdapter -VMNetworkAdapter $installedAdapter -SwitchName $switchname
            }
        } else {
            if ($macAddress){
                #Write-Output-Message "Adding adapter - $macAddress"
                Add-VMNetworkAdapter $vm -SwitchName $switchname -StaticMacAddress $macAddress
            } else {
                #Write-Output-Message "Adding adapter - dynamic mac address"
                Add-VMNetworkAdapter $vm -SwitchName $switchname -DynamicMacAddress
            }
        }
    }
}
$resultHash = @{
  message = "OK"
}
$result = ConvertTo-Json $resultHash
Write-Output-Message $result
