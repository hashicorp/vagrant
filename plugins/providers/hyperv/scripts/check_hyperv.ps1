# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

$check = $(-Not (-Not (Get-Command "Get-VMSwitch" -errorAction SilentlyContinue)))
$result = @{
    result = $check
}

Write-Output-Message $(ConvertTo-Json $result)
