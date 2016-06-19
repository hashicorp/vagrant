Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

# Make sure the exception type is loaded
try
{
    # Microsoft.HyperV.PowerShell is present on all versions of Windows with HyperV
    [void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.HyperV.PowerShell, Culture=neutral, PublicKeyToken=31bf3856ad364e35')
    # Microsoft.HyperV.PowerShell.Objects is only present on Windows >= 10.0, so this will fail, and we ignore it since the needed exception
    # type was loaded in Microsoft.HyperV.PowerShell
    [void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.HyperV.PowerShell.Objects, Culture=neutral, PublicKeyToken=31bf3856ad364e35')
} catch {
	# Empty catch ok, since if we didn't load the types, we will fail in the next block
}

$VmmsPath = if ([environment]::Is64BitProcess) { "$($env:SystemRoot)\System32\vmms.exe" } else { "$($env:SystemRoot)\Sysnative\vmms.exe" }
$HyperVVersion = [version](Get-Item $VmmsPath).VersionInfo.ProductVersion

if($HyperVVersion -lt ([version]'10.0')) {
  $ExceptionType = [Microsoft.HyperV.PowerShell.VirtualizationOperationFailedException]
} else {
  $ExceptionType = [Microsoft.HyperV.PowerShell.VirtualizationException]
}
try {
    $VM = Get-VM -Id $VmId -ErrorAction "Stop"
    $State = $VM.state
    $Status = $VM.status
} catch [Exception] {
    if($_.Exception.GetType() -eq $ExceptionType)
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
Write-Output-Message $result
