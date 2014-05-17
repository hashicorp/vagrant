# Copy minion keys to correct location
New-Item c:\salt\conf\pki\minion\ -ItemType directory
cp C:\tmp\minion.pem C:\salt\conf\pki\minion\
cp C:\tmp\minion.pub C:\salt\conf\pki\minion\

# Detect architecture
if ([IntPtr]::Size -eq 4) {
  $arch = "win32"
} else {
  $arch = "AMD64"
}

# Download minion setup file
Write-Host "Downloading Salt minion installer ($arch)..."
$webclient = New-Object System.Net.WebClient
$url = "https://docs.saltstack.com/downloads/Salt-Minion-2014.1.3-1-$arch-Setup.exe"
$file = "C:\tmp\salt.exe"
$webclient.DownloadFile($url, $file)

# Install minion silently
Write-Host "Installing Salt minion..."
C:\tmp\salt.exe /S

Write-Host "Waiting for Salt minion to start..."
# Give the minion some time to start before the highstate is called
Start-Sleep -s 5
