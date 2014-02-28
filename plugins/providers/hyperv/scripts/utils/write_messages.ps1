#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

function Write-Error-Message($message) {
  $error_message = @{
    error = "$message"
  }
  Write-Host "===Begin-Error==="
  $result =  ConvertTo-json $error_message
  Write-Host $result
  Write-Host "===End-Error==="
}

function Write-Output-Message($message) {
  Write-Host "===Begin-Output==="
  Write-Host $message
  Write-Host "===End-Output==="
}
