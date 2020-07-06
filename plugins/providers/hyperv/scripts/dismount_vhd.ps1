#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$DiskFilePath
)

try {
    Hyper-V\Dismount-VHD -path $DiskFilePath
} catch {
    Write-ErrorMessage "Failed to dismount disk info from disk file path ${DiskFilePath}: ${PSItem}"
    exit 1
}
