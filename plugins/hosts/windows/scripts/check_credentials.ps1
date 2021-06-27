Param(
    [Parameter(Mandatory=$true)]
    [string]$username,
    [Parameter(Mandatory=$true)]
    [string]$password,
    [Parameter(Mandatory=$false)]
    [string]$contextType="Machine"
)

Add-Type -AssemblyName System.DirectoryServices.AccountManagement

$DSContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
    [System.DirectoryServices.AccountManagement.ContextType]::$contextType,
    $env:COMPUTERNAME
)

if ( $DSContext.ValidateCredentials( $username, $password ) ) {
    exit 0
} else {
    exit 1
}
