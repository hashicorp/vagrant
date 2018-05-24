#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

function Write-Error-Message {
    param (
        [parameter (Mandatory=$true,Position=0)]
        [string] $Message
    )
    $error_message = @{
        error = $Message
    }
    Write-Host "===Begin-Error==="
    Write-Host (ConvertTo-Json $error_message)
    Write-Host "===End-Error==="
}

function Write-Output-Message {
    param (
        [parameter (Mandatory=$true,Position=0)]
        [string] $Message
    )
    Write-Host "===Begin-Output==="
    Write-Host $Message
    Write-Host "===End-Output==="
}
