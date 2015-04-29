Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
 )

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

$vm = Get-VM -Id $VmId -ErrorAction "Stop"
$network = Get-VMNetworkAdapter -VM $vm

$result = ConvertTo-Json $network
Write-Output-Message $result