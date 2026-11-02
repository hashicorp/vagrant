# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

# The names of the user are language dependent!
$objSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-1-0")
$objUser = $objSID.Translate([System.Security.Principal.NTAccount])

$grant = "$objUser,Full"

for ($i=0; $i -le $args.length; $i = $i + 3) {
    $path = $args[$i]
    $share_name = $args[$i+1]
    $share_id = $args[$i+2]


    if ($path -eq $null) {
        Write-Warning "empty path argument encountered - complete"
        exit 0
    }

    if ($share_name -eq $null) {
        Write-Output "share path: ${path}"
        Write-Error "error - no share name provided"
        exit 1
    }

    if ($share_id -eq $null) {
        Write-Output "share path: ${path}"
        Write-Error "error - no share ID provided"
        exit 1
    }

    $result = net share $share_id=$path /unlimited /GRANT:$grant /REMARK:"${share_name}"
    if ($LastExitCode -ne 0) {
        $host.ui.WriteLine("share path: ${path}")
        $host.ui.WriteErrorLine("error ${result}")
        exit 1
    }
}
exit 0
