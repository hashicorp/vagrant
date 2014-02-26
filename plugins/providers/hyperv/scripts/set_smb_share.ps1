Param(
    [Parameter(Mandatory=$true)]
    [string]$path,
    [Parameter(Mandatory=$true)]
    [string]$share_name,
    [Parameter(Mandatory=$true)]
    [string]$host_share_username
)

$ErrorAction = "Stop"

# See all available shares and check alert user for
# existing/conflicting share name
$shared_folders = net share
$reg = "$share_name(\s+)$path(\s)"
$existing_share = $shared_folders -Match $reg
if ($existing_share) {
    # Always clear the existing share name and create a new one
    net share $share_name /delete /y
}

$computer_name = $(Get-WmiObject Win32_Computersystem).name
$grant_permission = "$computer_name\$host_share_username,Full"
$result = net share $share_name=$path /unlimited /GRANT:$grant_permission
if ($result -Match "$share_name was shared successfully.") {
    exit 0
}

$host.ui.WriteErrorLine("Error: $result")
exit 1
