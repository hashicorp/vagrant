Param(
    [Parameter(Mandatory=$true)]
    [string]$share_name
)

Write-Host "Delete share $share_name"

$ErrorAction = "Stop"

$result = net share "$share_name"
if ($LastExitCode -eq 0) {
    $result = net share "$share_name" /delete /y

    if ($LastExitCode -ne 0) {
        $host.ui.WriteErrorLine("Error: $result")
        exit 1
    }
}