ForEach ($share_name in $args) {
    $result = net share $share_name /DELETE /YES
    if ($LastExitCode -ne 0) {
        Write-Output "share name: ${share_name}"
        Write-Error "error - ${result}"
        exit 1
    }
}
Write-Output "share removal completed"
exit 0
