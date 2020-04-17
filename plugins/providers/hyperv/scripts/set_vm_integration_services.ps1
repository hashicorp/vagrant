#Requires -Modules VagrantVM, VagrantMessages

param (
    [parameter (Mandatory=$true)]
    [string] $VMID,
    [parameter (Mandatory=$true)]
    [string] $Id,
    [parameter (Mandatory=$false)]
    [switch] $Enable
)

$ErrorActionPreference = "Stop"

try {
    $VM = Hyper-V\Get-VM -Id $VMID
} catch {
    Write-ErrorMessage "Failed to locate VM: ${PSItem}"
    exit 1
}

try {
    Set-VagrantVMService -VM $VM -Id $Id -Enable $Enable
} catch {
    if($Enable){ $action = "enable" } else { $action = "disable" }
    Write-ErrorMessage "Failed to ${action} VM integration service id ${Id}: ${PSItem}"
    exit 1
}
