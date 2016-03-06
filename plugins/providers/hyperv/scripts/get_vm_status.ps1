Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))


if($PSVersionTable.PSVersion.Major -le 4) {
  $ExceptionType = [Microsoft.HyperV.PowerShell.VirtualizationOperationFailedException]
} else {
  $ExceptionType = [Microsoft.HyperV.PowerShell.VirtualizationException]
}

try {
    $VM = Get-VM -Id $VmId -ErrorAction "Stop"
    $State = $VM.state
    $Status = $VM.status
} catch $ExceptionType {
    $State = "not_created"
    $Status = $State
}

$resultHash = @{
    state = "$State"
    status = "$Status"
}
$result = ConvertTo-Json $resultHash
Write-Output-Message $result
