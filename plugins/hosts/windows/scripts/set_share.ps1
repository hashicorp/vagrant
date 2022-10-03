Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# The names of the user are language dependent!
$objSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-1-0")
$objUser = $objSID.Translate([System.Security.Principal.NTAccount])

for ($i = 0; ($i+2) -lt $args.length; $i = $i + 3) {
    $path = $args[$i]
    $share_name = $args[$i+1]
    $share_id = $args[$i+2]

    if (!$path) {
        Write-Error "error - no share path provided"
        exit 1
    }

    if (!$share_name) {
        Write-Output "share path: ${path}"
        Write-Error "error - no share name provided"
        exit 1
    }

    if (!$share_id) {
        Write-Output "share path: ${path}"
        Write-Error "error - no share ID provided"
        exit 1
    }

    New-SmbShare `
        -Name $share_id `
        -Path $path `
        -FullAccess $objUser `
        -Description $share_name
}
exit 0
