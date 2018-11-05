#Requires -Modules VagrantMessages, VagrantVM

param(
    [parameter (Mandatory=$true)]
    [string] $Path
)

$check = Check-VagrantHyperVAccess -Path $Path
$result = @{
    root_dir = ($Path -split '\\')[0,1] -join '\';
    result = $check
}

Write-OutputMessage $(ConvertTo-Json $result)
