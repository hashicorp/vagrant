#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$Path,
    [Parameter(Mandatory=$true)]
    [UInt64]$SizeBytes,
    [switch]$Fixed,
    [UInt32]$BlockSizeBytes,
    [UInt32]$LogicalSectorSizeBytes,
    [UInt32]$PhysicalSectorSizeBytes
)

$Params = @{
  Path = $Path
  SizeBytes = $SizeBytes
}

if ($Fixed -ne '') {
  $Params.Add("Fixed", $true)
}

if ($BlockSizeBytes -ne '') {
  $Params.Add("BlockSizeBytes", $BlockSizeBytes)
}

if ($LogicalSectorSizeBytes -ne '') {
  $Params.Add("LogicalSectorSizeBytes", $LogicalSectorSizeBytes)
}


if ($PhysicalSectorSizeBytes -ne '') {
  $Params.Add("PhysicalSectorSizeBytes", $PhysicalSectorSizeBytes)
}

# Maybe try default values for params so don't have to deal with null

#foreach ($key in $MyInvocation.BoundParameters.keys) {
#  $value = (Get-Variable -Exclude "ErrorAction" $key).Value
#
#  if ($value -ne $null) {
#    $Params.Add($key, $value)
#  }
#}

try {
    Hyper-V\New-VHD @Params
} catch {
    Write-ErrorMessage "Failed to create disk ${DiskFilePath}: ${PSItem}"
    exit 1
}
