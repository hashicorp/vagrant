# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

#Requires -Modules VagrantVM, VagrantMessages

param(
    [parameter (Mandatory=$true)]
    [string] $VMConfigFile,
    [parameter (Mandatory=$true)]
    [string] $DestinationPath,
    [parameter (Mandatory=$true)]
    [string] $DataPath,
    [parameter (Mandatory=$true)]
    [string] $SourcePath,
    [parameter (Mandatory=$false)]
    [switch] $LinkedClone,
    [parameter (Mandatory=$false)]
    [int] $Memory = $null,
    [parameter (Mandatory=$false)]
    [int] $MaxMemory = $null,
    [parameter (Mandatory=$false)]
    [int] $Processors = $null,
    [parameter (Mandatory=$false)]
    [string] $VMName=$null
)

$ErrorActionPreference = "Stop"

try {
    if($LinkedClone) {
        $linked = $true
    } else {
        $linked = $false
    }

    $VM = New-VagrantVM -VMConfigFile $VMConfigFile -DestinationPath $DestinationPath `
      -DataPath $DataPath -SourcePath $SourcePath -LinkedClone $linked -Memory $Memory `
      -MaxMemory $MaxMemory -CPUCount $Processors -VMName $VMName

    $Result = @{
        id = $VM.Id.Guid;
    }
    Write-OutputMessage (ConvertTo-Json $Result)
} catch {
    Write-ErrorMessage "${PSItem}"
    exit 1
}
