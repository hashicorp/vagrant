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
if ($result -Match "$share_name was shared successfully.") {
    exit 0
}

$host.ui.WriteErrorLine("Error: $result")
exit 1
