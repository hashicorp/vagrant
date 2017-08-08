Param(
    [Parameter(Mandatory=$true)]
    [string]$Source,

    [Parameter(Mandatory=$true)]
    [string]$Destination
)

Hyper-V\New-VHD -Path $Destination -ParentPath $Source -ErrorAction Stop
