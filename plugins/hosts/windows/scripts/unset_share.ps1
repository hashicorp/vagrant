Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

ForEach ($share_name in $args) {
    Remove-SmbShare `
        -Name $share_name `
        -Force
}
Write-Output "share removal completed"
exit 0
