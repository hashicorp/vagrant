# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$VmId,
    [Parameter(Mandatory=$true)]
    [string]$ISOPath
)

try {
    Hyper-V\Get-VM -ID $VmId | Hyper-V\Add-VMDvdDrive -Path $ISOPath
} catch {
    Write-ErrorMessage "Failed to add DVD drive for path - ${ISOPath}: ${PSItem}"
    exit 1
}
