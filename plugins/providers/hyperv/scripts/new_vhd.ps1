#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$Path,
    [Parameter(Mandatory=$true)]
    [UInt64]$SizeBytes,
    [switch]$Fixed,
    [switch]$Differencing,
    [string]$ParentPath,
    [Uint32]$BlockSizeBytes,
    [UInt32]$LogicalSectorSizeBytes,
    [UInt32]$PhysicalSectorSizeBytes,
    [UInt32]$SourceDisk
)

$Params = @{}

foreach ($key in $MyInvocation.BoundParameters.keys) {
  $value = (Get-Variable -Exclude "ErrorAction" $key).Value
  if ($key -ne "ErrorAction") {
    $Params.Add($key, $value)
  }
}

try {
    Hyper-V\New-VHD @Params
} catch {
    Write-ErrorMessage "Failed to create disk ${DiskFilePath}: ${PSItem}"
    exit 1
}
