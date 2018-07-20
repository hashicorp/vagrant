#Requires -Modules VagrantVM, VagrantMessages

param(
    [parameter (Mandatory=$true)]
    [string] $VMConfigFile,
    [parameter (Mandatory=$true)]
    [string] $DestinationPath,
    [parameter (Mandatory=$true)]
    [string] $DataPath,
    [parameter (Mandatory=$true)]
    [string] $SourcePath,
    [parameter (Mandatory=$false)]
    [switch] $LinkedClone,
    [parameter (Mandatory=$false)]
    [string] $VMName=$null,
    [parameter (Mandatory=$false)]
    [string] $DisksToCreate=$null
)

$ErrorActionPreference = "Stop"

try {
    if($LinkedClone) {
        $linked = $true
    } else {
        $linked = $false
    }

    $VM = New-VagrantVM -VMConfigFile $VMConfigFile -DestinationPath $DestinationPath `
      -DataPath $DataPath -SourcePath $SourcePath -LinkedClone $linked -VMName $VMName

    $Result = @{
        id = $VM.Id.Guid;
    }
    Write-OutputMessage (ConvertTo-Json $Result)
} catch {
    Write-ErrorMessage "${PSItem}"
    exit 1
}


#controller -  path (for existent)
#              path,
#              sizeMB, name (for new)
function AddDisks($vm, $controller) {
    #get controller

    $contNumber =  ($vm | Add-VMScsiController -PassThru).ControllerNumber
    foreach($disk in $controller) {
        #get vhd
        $vhd = $null
        if($disk.Path) {
            if (Test-Path -Path $disk.Path) {
                $vhd = Resolve-Path -Path $disk.Path
            }
        }
        else {
            $vhd = $disk.Name
            if (!(Test-Path -Path $vhd)) {
                New-VHD -Path $vhd -SizeBytes ([UInt64]$disk.Size * 1MB) -Dynamic
            }
        }
        if (!(Test-Path -Path $vhd)) {
            Write-Error "There is error in virtual disk (VHD) configuration"
            break
        }

        $driveParam = @{
            ControllerNumber = $contNumber
            Path = $vhd
            ControllerType = "SCSI"
        }
        $vm | Add-VMHardDiskDrive @driveParam
    }
}

if ($DisksToCreate) {
    $ParsedDisksToCreate = $DisksToCreate | ConvertFrom-Json
    $ParsedDisksToCreate | ForEach-Object { AddDisks -vm $VMName -controller $_ }
}

