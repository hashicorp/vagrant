Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
 )

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

$ip_address = ""
$vm = Get-VM -Id $VmId -ErrorAction "Stop"
$network = Get-VMNetworkAdapter -VM $vm | Select-Object -First 1

if ($network.MacAddress -gt 0) {
  $mac_address = $network.MacAddress
}

$resultHash = @{
    mac = "$mac_address"
}
$result = ConvertTo-Json $resultHash
Write-Output-Message $result