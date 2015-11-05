Param(
    [Parameter(Mandatory=$True)]
    [string]$path
)

# Stop on first error
$ErrorActionPreference = "Stop"

# Make the path complete
$path = Resolve-Path $path

# Determine if this is a 64-bit or 32-bit CPU
$architecture="x86"
if ((Get-WmiObject -Class Win32_OperatingSystem).OSArchitecture -eq "64-bit") {
    $architecture = "amd64"
}

# Extract the contents of the installer
Start-Process -FilePath $path `
    -ArgumentList ('--extract','--silent','--path','.') `
    -Wait `
    -NoNewWindow

# Find the installer
$matches = Get-ChildItem | Where-Object { $_.Name -match "VirtualBox-.*_$($architecture).msi" }
if ($matches.Count -ne 1) {
    Write-Host "Multiple matches for VirtualBox MSI found: $($matches.Count)"
    exit 1
}
$installerPath = Resolve-Path $matches[0]

# Run the installer
Start-Process -FilePath "$($env:systemroot)\System32\msiexec.exe" `
    -ArgumentList "/i `"$installerPath`" /qn /norestart /l*v `"$($pwd)\install.log`"" `
    -Verb RunAs `
    -Wait `
    -WorkingDirectory "$pwd"
