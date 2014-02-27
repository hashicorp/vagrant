# This will have a SwitchType property. As far as I know the values are:
#
#   0 - Private
#   1 - Internal
#
# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

$Switches = @(Get-VMSwitch `
    | Select-Object Name,SwitchType,NetAdapterInterfaceDescription)
Write-Output-Message $(ConvertTo-JSON $Switches)
