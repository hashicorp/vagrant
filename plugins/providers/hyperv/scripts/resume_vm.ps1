#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

Param(
    [Parameter(Mandatory=$true)]
    [string]$vm_id
)

$VM = Get-VM -Id $vm_id -ErrorAction "Stop"
Resume-VM $VM
