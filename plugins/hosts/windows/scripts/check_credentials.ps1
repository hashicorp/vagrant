# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

Param(
    [Parameter(Mandatory=$true)]
    [string]$username,
    [Parameter(Mandatory=$true)]
    [string]$password
)

Add-Type -AssemblyName System.DirectoryServices.AccountManagement

$DSContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
    [System.DirectoryServices.AccountManagement.ContextType]::Machine,
    $env:COMPUTERNAME
)
if ( $DSContext.ValidateCredentials( $username, $password ) ) {
    exit 0
} 

$DSContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
    [System.DirectoryServices.AccountManagement.ContextType]::Domain,
    $env:COMPUTERNAME
)
if ( $DSContext.ValidateCredentials( $username, $password ) ) {
    exit 0
} 

$DSContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
    [System.DirectoryServices.AccountManagement.ContextType]::ApplicationDirectory,
    $env:COMPUTERNAME
)
if ( $DSContext.ValidateCredentials( $username, $password ) ) {
    exit 0
} 

exit 1
