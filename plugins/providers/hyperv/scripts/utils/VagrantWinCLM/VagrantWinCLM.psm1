# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

$ErrorActionPreference = "Stop"

# Detect language mode at module load time
$script:IsConstrainedLanguageMode = $ExecutionContext.SessionState.LanguageMode -eq 'ConstrainedLanguage'

function Test-VagrantSystemAccount {
    <#
    .SYNOPSIS
    Check if ACL identity is SYSTEM account (S-1-5-18), CLM compatible
    #>
    param(
        [Parameter(Mandatory=$true)]$IdentityReference
    )
    if (-not $script:IsConstrainedLanguageMode) {
        try {
            return $IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).Value -eq "S-1-5-18"
        } catch {
            return $false
        }
    }
    # In CLM, compare string directly, may fail if localized
    $identity = $IdentityReference.Value
    return ($identity -eq "NT AUTHORITY\SYSTEM") -or ($identity -eq "S-1-5-18")
}

function Get-VagrantFileName {
    <#
    .SYNOPSIS
    Get file name from path, CLM compatible
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    if (-not $script:IsConstrainedLanguageMode) {
        return [System.IO.Path]::GetFileName($Path)
    }
    return Split-Path -Leaf $Path
}

function Get-VagrantDirectoryName {
    <#
    .SYNOPSIS
    Get directory name from path, CLM compatible
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    if (-not $script:IsConstrainedLanguageMode) {
        return [System.IO.Path]::GetDirectoryName($Path)
    }
    return Split-Path -Parent $Path
}

function Get-VagrantFileExtension {
    <#
    .SYNOPSIS
    Get file extension from path, CLM compatible
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    if (-not $script:IsConstrainedLanguageMode) {
        return [System.IO.Path]::GetExtension($Path)
    }
    # CLM fallback: extract extension from filename
    $fileName = Split-Path -Leaf $Path
    if ($fileName -match '\.[^\.]+$') {
        return $matches[0]
    }
    return ""
}

Export-ModuleMember -Function @(
    'Test-VagrantSystemAccount',
    'Get-VagrantFileName',
    'Get-VagrantDirectoryName',
    'Get-VagrantFileExtension'
)
