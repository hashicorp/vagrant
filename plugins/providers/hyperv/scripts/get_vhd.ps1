#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$DiskFilePath
)

try {
    $Disk = Hyper-V\Get-VHD -path $DiskFilePath
} catch {
    Write-ErrorMessage "Failed to retrieve disk info from disk file path ${DiskFilePath}: ${PSItem}"
    exit 1
}

$result = ConvertTo-json $Disk
Write-OutputMessage $result
