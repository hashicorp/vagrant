#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

Param(
    [Parameter(Mandatory=$true)]
    [string]$vm_id
)

# Shuts down virtual machine regardless of any unsaved application data
$VM = Get-VM -Id $vm_id -ErrorAction "Stop"
Stop-VM $VM -Force
