param(
    ## The path on the local computer
    [Parameter(Mandatory = $true)]
    $Source,

    ## The target path on the remote computer
    [Parameter(Mandatory = $true)]
    $Destination,

    ## The session that represents the remote computer
    [Parameter(Mandatory = $true)]
    [System.Management.Automation.Runspaces.PSSession] $Session
)

Set-StrictMode -Version 3

$remoteScript = {
    param($destination, $bytes)

    ## Convert the destination path to a full filesystem path (to support
    ## relative paths)
    $Destination = $executionContext.SessionState.`
        Path.GetUnresolvedProviderPathFromPSPath($Destination)

    ## Write the content to the new file
    $file = [IO.File]::Open($Destination, "OpenOrCreate")
    $null = $file.Seek(0, "End")
    $null = $file.Write($bytes, 0, $bytes.Length)
    $file.Close()
}

## Get the source file, and then start reading its content
$sourceFile = Get-Item $source

## Delete the previously-existing file if it exists
Invoke-Command -Session $session {
    if(Test-Path $args[0]) { Remove-Item $args[0] }
} -ArgumentList $Destination

## Now break it into chunks to stream
Write-Progress -Activity "Sending $Source" -Status "Preparing file"

$streamSize = 1MB
$position = 0
$rawBytes = New-Object byte[] $streamSize
$file = [IO.File]::OpenRead($sourceFile.FullName)

while(($read = $file.Read($rawBytes, 0, $streamSize)) -gt 0)
{
    Write-Progress -Activity "Writing $Destination" `
        -Status "Sending file" `
        -PercentComplete ($position / $sourceFile.Length * 100)

    ## Ensure that our array is the same size as what we read
    ## from disk
    if($read -ne $rawBytes.Length)
    {
        [Array]::Resize( [ref] $rawBytes, $read)
    }

    ## And send that array to the remote system
    Invoke-Command -Session $session $remoteScript `
        -ArgumentList $destination,$rawBytes

    ## Ensure that our array is the same size as what we read
    ## from disk
    if($rawBytes.Length -ne $streamSize)
    {
        [Array]::Resize( [ref] $rawBytes, $streamSize)
    }
    
    [GC]::Collect()
    $position += $read
}

$file.Close()

## Show the result
Invoke-Command -Session $session { Get-Item $args[0] } -ArgumentList $Destination