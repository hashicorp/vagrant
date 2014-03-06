#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

Param(
    [Parameter(Mandatory=$true)]
    [string]$vm_id
)

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

# Get the VM with the given name
try {
    $VM = Get-VM -Id $vm_id -ErrorAction "Stop"
    $State = $VM.state
    $Status = $VM.status
} catch [Microsoft.HyperV.PowerShell.VirtualizationOperationFailedException] {
    $State = "not_created"
    $Status = $State
}

$resultHash = @{
    state = "$State"
    status = "$Status"
}
$result = ConvertTo-Json $resultHash
Write-Output-Message $result
