# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$Source,

    [Parameter(Mandatory=$true)]
    [string]$Destination
)

$ErrorActionPreference = "Stop"

try {
    Hyper-V\New-VHD -Path $Destination -ParentPath $Source
} catch {
    Write-ErrorMessage "Failed to clone drive: ${PSItem}"
    exit 1
}
