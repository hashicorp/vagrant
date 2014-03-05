Param(
    [Parameter(Mandatory=$true)]
    [string]$path,
    [Parameter(Mandatory=$true)]
    [string]$share_name,
    [string]$host_share_username = $null
)

$ErrorAction = "Stop"

# See all available shares and check alert user for existing/conflicting
# share names.
$path_regexp = [System.Text.RegularExpressions.Regex]::Escape($path)
$name_regexp = [System.Text.RegularExpressions.Regex]::Escape($share_name)
$reg = "(?m)$name_regexp\s+$path_regexp\s"
$existing_share = $($(net share) -join "`n") -Match $reg
if ($existing_share) {
    # Always clear the existing share name and create a new one
    net share $share_name /delete /y
}

$grant = "Everyone,Full"
if (![string]::IsNullOrEmpty($host_share_username)) {
    $computer_name = $(Get-WmiObject Win32_Computersystem).name
    $grant         = "$computer_name\$host_share_username,Full"

    # Just net share will not be enough, here we need to set the proper ACL for this folder
    # For the host_share_username
    # ACL lets the system grant privileges for the current host_share_username for this
    # folder
    $current_acl = Get-ACL $path
    $permission = "$computer_name\$host_share_username","FullControl","ContainerInherit,ObjectInherit","None","Allow"
    $acl_access_rule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $current_acl.SetAccessRule($acl_access_rule)
    $current_acl | Set-Acl $path
}

$result = net share $share_name=$path /unlimited /GRANT:$grant
if ($result -Match "$share_name was shared successfully.") {
    exit 0
}

$host.ui.WriteErrorLine("Error: $result")
exit 1
