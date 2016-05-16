Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

$VM = Get-VM -Id $VmId -ErrorAction "Stop"
$Snapshots = @(Get-VMSnapshot $VM | Select-Object Name)
$result = ConvertTo-json $Snapshots

Write-Host "===Begin-Output==="
Write-Host $result
Write-Host "===End-Output==="
