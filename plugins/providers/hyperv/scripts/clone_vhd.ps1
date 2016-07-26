Param(
    [Parameter(Mandatory=$true)]
    [string]$Source,

    [Parameter(Mandatory=$true)]
    [string]$Destination
)

New-VHD -Path $Destination -ParentPath $Source -ErrorAction Stop
