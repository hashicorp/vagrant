#Requires -Modules VagrantVM, VagrantMessages

param (
    [parameter (Mandatory=$true)]
    [string] $VMID,
    [parameter (Mandatory=$true)]
    [string] $Name,
    [parameter (Mandatory=$false)]
    [switch] $Enable
)

$ErrorActionPreference = "Stop"

try {
    $VM = Hyper-V\Get-VM -Id $VMID
} catch {
    Write-Error-Message "Failed to locate VM: ${PSItem}"
    exit 1
}

try {
    Set-VagrantVMService -VM $VM -Name $Name -Enable $enabled
} catch {
    if($enabled){ $action = "enable" } else { $action = "disable" }
    Write-Error-Message "Failed to ${action} VM integration service ${Name}: ${PSItem}"
    exit 1
}
