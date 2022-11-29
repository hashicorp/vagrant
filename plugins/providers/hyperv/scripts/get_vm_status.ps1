#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

try {
    $VM = Hyper-V\Get-VM -Id $VmId -ErrorAction "Stop"
    $State = $VM.state
    $Status = $VM.status
} catch [Exception] {
    # "ObjectNotFound" when Hyper-V  >= 10 (Microsoft.HyperV.PowerShell.VirtualizationException)
    # "NotSpecified" when Hyper-V < 10 (Microsoft.HyperV.PowerShell.VirtualizationOperationFailedException)
    if(("ObjectNotFound", "NotSpecified") -Contains $_.Exception.ErrorCategory)
    {
        $State = "not_created"
        $Status = $State
    }
    else
    {
        throw;
    }
}

$resultHash = @{
    state = "$State"
    status = "$Status"
}
$result = ConvertTo-Json $resultHash
Write-OutputMessage $result
