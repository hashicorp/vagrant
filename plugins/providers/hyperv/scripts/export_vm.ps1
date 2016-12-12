Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId,
    [Parameter(Mandatory=$true)]
    [string]$Path
)

$vm = Get-VM -Id $VmId -ErrorAction "Stop"
$vm | Export-VM -Path $Path

# Prepare directory structure for box import
$name = $vm.Name
Move-Item $Path/$name/* $Path
Remove-Item -Path $Path/Snapshots -Force -Recurse
Remove-Item -Path $Path/$name -Force