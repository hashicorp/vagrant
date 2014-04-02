Param(
    [Parameter(Mandatory=$true)]
    [string]$path,
    [Parameter(Mandatory=$true)]
    [string]$share_name,
    [string]$host_share_username = $null
)

$ErrorAction = "Stop"

if (net share | Select-String $share_name) {
  net share $share_name /delete /y
}

# The names of the user are language dependent!
$objSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-1-0")
$objUser = $objSID.Translate([System.Security.Principal.NTAccount])

$grant = "$objUser,Full"

if (![string]::IsNullOrEmpty($host_share_username)) {
    $computer_name = $(Get-WmiObject Win32_Computersystem).name
    $grant         = "$computer_name\$host_share_username,Full"

    # Here we need to set the proper ACL for this folder. This lets full
    # recursive access to this folder.
    <#
    Get-ChildItem $path -recurse -Force |% {
        $current_acl = Get-ACL $_.fullname
        $permission = "$computer_name\$host_share_username","FullControl","ContainerInherit,ObjectInherit","None","Allow"
        $acl_access_rule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
        $current_acl.SetAccessRule($acl_access_rule)
        $current_acl | Set-Acl $_.fullname
    }
    #>
}

$result = net share $share_name=$path /unlimited /GRANT:$grant
if ($LastExitCode -eq 0) {
    exit 0
}

$host.ui.WriteErrorLine("Error: $result")
exit 1
