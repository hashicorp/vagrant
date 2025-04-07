# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

try {
    $Controller = Hyper-V\Get-VM -ID $VmId | Hyper-V\Get-VMScsiController
} catch {
    Write-ErrorMessage "Failed to retrieve scsi controller info for ${VmId}: ${PSItem}"
    exit 1
}

$result = ConvertTo-json $Controller -Depth 20
Write-OutputMessage $result
