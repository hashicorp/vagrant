Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))


if($PSVersionTable.PSVersion.Major -le 4) {
  $ExceptionType = "Microsoft.HyperV.PowerShell.VirtualizationOperationFailedException"
} else {
  $ExceptionType = "Microsoft.HyperV.PowerShell.VirtualizationException"
}

try {
    $VM = Get-VM -Id $VmId -ErrorAction "Stop"
    $State = $VM.state
    $Status = $VM.status
} catch [System.Exception] {
    $type = [String]$_.Exception.GetType()
    if ($type -eq $ExceptionType ) {
      $State = "not_created"
      $Status = $State
    } else {
      Write-Hosts "Uncaught stuff: $($_.Exception.Gettype())"
      throw $_.Exception
    }
}

$resultHash = @{
    state = "$State"
    status = "$Status"
}
$result = ConvertTo-Json $resultHash
Write-Output-Message $result
