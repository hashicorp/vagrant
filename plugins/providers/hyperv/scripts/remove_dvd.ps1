# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$VmId,
    [Parameter(Mandatory=$true)]
    [Int32]$ControllerNumber,
    [Parameter(Mandatory=$true)]
    [Int32]$ControllerLocation
)

try {
    $vm = Hyper-V\Get-VM -ID $VmId
    Hyper-V\Remove-VMDvdDrive -ControllerNumber $ControllerNumber -ControllerLocation $ControllerLocation -VMName $vm.Name
} catch {
    Write-ErrorMessage "Failed to remove DVD drive (Location: '${ControllerLocation}' Number '${ControllerNumber}'): ${PSItem}"
    exit 1
}
