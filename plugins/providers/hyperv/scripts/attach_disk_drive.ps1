#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$VmId,
    [Parameter(Mandatory=$true)]
    [string]$Path,
    [string]$ControllerType,
    [string]$ControllerNumber,
    [string]$ControllerLocation
)

$Params = @{}

foreach ($key in $MyInvocation.BoundParameters.keys) {
  $value = (Get-Variable -Exclude "ErrorAction" $key).Value
  if (($key -ne "VmId") -and ($key -ne "ErrorAction")) {
    $Params.Add($key, $value)
  }
}

try {
    $VM = Hyper-V\Get-VM -Id $VmId
    Hyper-V\Add-VMHardDiskDrive -VMName $VM.Name @Params
} catch {
    Write-ErrorMessage "Failed to attach disk ${DiskFilePath} to VM ${VM}: ${PSItem}"
    exit 1
}
