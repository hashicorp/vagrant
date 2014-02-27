# This will have a SwitchType property. As far as I know the values are:
#
#   0 - Private
#   1 - Internal
#
$Switches = @(Get-VMSwitch `
    | Select-Object Name,SwitchType,NetAdapterInterfaceDescription)
Write-Output $(ConvertTo-JSON $Switches)
