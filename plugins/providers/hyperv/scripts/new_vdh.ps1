#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$DiskFilePath
    [Parameter(Mandatory=$true)]
    [UInt64]$DiskSizeBytes
)

try {
    Hyper-V\New-VHD -Path $DiskFilePath -SizeBytes $DiskSizeBytes
} catch {
    Write-ErrorMessage "Failed to create disk ${DiskFilePath}: ${PSItem}"
    exit 1
}
