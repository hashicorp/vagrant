# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

Param(
    [string]$hostname
)

$trustedHosts = (
    Get-Item "wsman:\localhost\client\trustedhosts").Value.Replace(
    $hostname, '')
$trustedHosts = $trustedHosts.Replace(",,","")
if($trustedHosts.EndsWith(",")){
    $trustedHosts = $trustedHosts.Substring(0,$trustedHosts.length-1)
}
Set-Item "wsman:\localhost\client\trustedhosts" -Value $trustedHosts -Force