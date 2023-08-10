# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

#Requires -Modules VagrantMessages

$check = $(-Not (-Not (Get-Command "Hyper-V\Get-VMSwitch" -ErrorAction SilentlyContinue)))
$result = @{
    result = $check
}

Write-OutputMessage $(ConvertTo-Json $result)
