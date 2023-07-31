# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

$ErrorActionPreference = "Stop"

try{
    $VM = Hyper-V\Get-VM -Id $VmId
    Hyper-V\Suspend-VM $VM
} catch {
    Write-ErrorMessage "Failed to suspend VM: ${PSItem}"
    exit 1
}
