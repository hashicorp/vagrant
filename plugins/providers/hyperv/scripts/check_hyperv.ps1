# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: MIT

#Requires -Modules VagrantMessages

$check = $(-Not (-Not (Get-Command "Hyper-V\Get-VMSwitch" -ErrorAction SilentlyContinue)))
$result = @{
    result = $check
}

Write-OutputMessage $(ConvertTo-Json $result)
