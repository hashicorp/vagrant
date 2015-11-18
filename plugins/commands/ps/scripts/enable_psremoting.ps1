Param(
    [string]$hostname,
    [string]$port,
    [string]$username,
    [string]$password
)
# If we are in this script, we know basic winrm is working
# If the user is not using a domain acount and chances are
# they are not, PS Remoting will not work if the guest is not
# listed in the trusted hosts.

$encrypted_password = ConvertTo-SecureString $password -asplaintext -force
$creds = New-Object System.Management.Automation.PSCredential (
    "$hostname\\$username", $encrypted_password)

$result = @{
    Success = $false
    PreviousTrustedHosts = $null
}
try {
    invoke-command -computername $hostname `
                   -Credential $creds `
                   -Port $port `
                   -ScriptBlock {} `
                   -ErrorAction Stop
    $result.Success = $true
} catch{}

if(!$result.Success) { 
    $newHosts = @()
    $result.PreviousTrustedHosts=(
        Get-Item "wsman:\localhost\client\trustedhosts").Value
    $hostArray=$result.PreviousTrustedHosts.Split(",").Trim()
    if($hostArray -contains "*") {
        $result.PreviousTrustedHosts = $null
    }
    elseif(!($hostArray -contains $hostname)) {
        $strNewHosts = $hostname
        if($result.PreviousTrustedHosts.Length -gt 0){
            $strNewHosts = $result.PreviousTrustedHosts + "," + $strNewHosts
        }
        Set-Item -Path "wsman:\localhost\client\trustedhosts" `
          -Value $strNewHosts -Force

        try {
            invoke-command -computername $hostname `
                           -Credential $creds `
                           -Port $port `
                           -ScriptBlock {} `
                           -ErrorAction Stop
            $result.Success = $true
        } catch{
            Set-Item -Path "wsman:\localhost\client\trustedhosts" `
              -Value $result.PreviousTrustedHosts -Force
            $result.PreviousTrustedHosts = $null
        }
    }
}

Write-Output $(ConvertTo-Json $result)
