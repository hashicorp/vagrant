#Requires -Modules VagrantMessages

# Windows version 10 and up have support for binary format
$check = [System.Environment]::OSVersion.Version.Major -ge 10
$result = @{
    result = $check
}

Write-OutputMessage $(ConvertTo-Json $result)
