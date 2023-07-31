# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

Write-Output "Downloading virtualbox guest additions"
$vboxadd_url = "http://download.virtualbox.org/virtualbox/5.2.2/VBoxGuestAdditions_5.2.2.iso"
$vboxadd_output = "C:/Windows/Temp/vboxguestadditions.iso"

(New-Object System.Net.WebClient).DownloadFile($vboxadd_url, $vboxadd_output)

Write-Output "Mounting virtualbox guest additions"
Mount-DiskImage -ImagePath $vboxadd_output

Write-Output "Installing Virtualbox Guest Additions"
Write-Output "Checking for Certificates in vBox ISO"
if(test-path E:\ -Filter *.cer)
{
  Get-ChildItem E:\cert -Filter *.cer | ForEach-Object { certutil -addstore -f "TrustedPublisher" $_.FullName }
}
Start-Process -FilePath "E:\VBoxWindowsAdditions.exe" -ArgumentList "/S" -Wait

Write-Output "Downloading virtualbox"
$vbox_url = "http://download.virtualbox.org/virtualbox/5.2.2/VirtualBox-5.2.2-119230-Win.exe"
$vbox_output = "C:/Windows/Temp/virtualbox.exe"

(New-Object System.Net.WebClient).DownloadFile($vbox_url, $vbox_output)

Write-Output "Installing virtualbox"
# Extract the contents of the installer
Start-Process -FilePath $vbox_output `
    -ArgumentList ('--extract','--silent','--path','C:\Windows\Temp') `
    -Wait `
    -NoNewWindow

# Find the installer
# Determine if this is a 64-bit or 32-bit CPU
$architecture="x86"
if ((Get-WmiObject -Class Win32_OperatingSystem).OSArchitecture -eq "64-bit") {
    $architecture = "amd64"
}

cd "C:\Windows\Temp"

$matches = Get-ChildItem | Where-Object { $_.Name -match "VirtualBox-.*_$($architecture).msi" }
if ($matches.Count -ne 1) {
   Write-Host "Multiple matches for VirtualBox MSI found: $($matches.Count)"
   exit 1
}
$installerPath = Resolve-Path $matches[0]

# Run the installer
Start-Process -FilePath "$($env:systemroot)\System32\msiexec.exe" `
    -ArgumentList "/i `"$installerPath`" /qn /norestart /l*v `"$($pwd)\vbox_install.log`"" `
    -Verb RunAs `
    -Wait `
    -WorkingDirectory "$pwd"

cd "C:\vagrant\pkg\dist"
$vagrant_matches = Get-ChildItem | Where-Object { $_.Name -match "vagrant.*_x86_64.msi" }
if ($vagrant_matches.Count -ne 1) {
   Write-Host "Could not find vagrant installer"
   exit 1
}
$vagrant_installerPath = Resolve-Path $vagrant_matches[0]

Write-Output $vagrant_installerPath

Write-Output "Installing vagrant"
Start-Process -FilePath "$($env:systemroot)\System32\msiexec.exe" `
    -ArgumentList "/i `"$vagrant_installerPath`" /qn /norestart /l*v `"$($pwd)\vagrant_install.log`"" `
    -Verb RunAs `
    -Wait `
    -WorkingDirectory "$pwd"
