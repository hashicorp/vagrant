Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

$VM = Hyper-V\Get-VM -Id $VmId -ErrorAction "Stop"
$Snapshots = @(Hyper-V\Get-VMSnapshot $VM | Select-Object Name)
$result = ConvertTo-json $Snapshots

Write-Host "===Begin-Output==="
Write-Host $result
Write-Host "===End-Output==="
