#Requires -Modules VagrantMessages

param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
)

$ErrorActionPreference = "Stop"

try {
    $ip_address = ""
    $vm = Hyper-V\Get-VM -Id $VmId
    $networks = Hyper-V\Get-VMNetworkAdapter -VM $vm
    foreach ($network in $networks) {
        if ($network.MacAddress -gt 0) {
            $mac_address = $network.MacAddress
            if (-Not ([string]::IsNullOrEmpty($mac_address))) {
                # We found our mac address!
                break
            }
        }
    }

    $resultHash = @{
        mac = "$mac_address"
    }
    $result = ConvertTo-Json $resultHash
    Write-OutputMessage $result
} catch {
    Write-ErrorMessage "Unexpected error while fetching MAC: ${PSItem}"
    exit 1
}
