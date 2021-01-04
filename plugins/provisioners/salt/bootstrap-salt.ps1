# Powershell supports only TLS 1.0 by default. Add support for TLS 1.2 and TLS 1.3
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls12,Tls13'

# Download the upstream bootstrap script
(New-Object System.Net.WebClient).DownloadFile('https://winbootstrap.saltstack.com', 'upstream-bootstrap.ps1')

# Run the upstream bootstrap script with passthrough arguments
./upstream-bootstrap.ps1 @args
