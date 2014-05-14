# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

$adapters = @()

  Get-NetAdapter `
    | Select-Object Name,InterfaceDescription,Status `
    | Where-Object {$_.Status-eq "up"}  `
    | ForEach-Object  -Process {
      $adapters += $_
    }
Write-Output-Message $(ConvertTo-JSON $adapters)
