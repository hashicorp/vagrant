# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

# Windows version 10 and up have support for binary format
$check = [System.Environment]::OSVersion.Version.Major -ge 10
$result = @{
    result = $check
}

Write-Output-Message $(ConvertTo-Json $result)
