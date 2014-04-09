#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

param (
    [string]$vm_id = $(throw "-vm_id is required."),
    [string]$guest_ip = $(throw "-guest_ip is required."),
    [string]$username = $(throw "-guest_username is required."),
    [string]$password = $(throw "-guest_password is required."),
    [string]$host_path = $(throw "-host_path is required."),
    [string]$guest_path = $(throw "-guest_path is required.")
 )

# Include the following modules
$presentDir = Split-Path -parent $PSCommandPath
$modules = @()
$modules += $presentDir + "\utils\write_messages.ps1"
forEach ($module in $modules) { . $module }

function Get-file-hash($source_path, $delimiter) {
    $source_files = @()
    (Get-ChildItem $source_path -rec | ForEach-Object -Process {
      Get-FileHash -Path $_.FullName -Algorithm MD5 } ) |
        ForEach-Object -Process {
          $source_files += $_.Path.Replace($source_path, "") + $delimiter + $_.Hash
        }
    $source_files
}

function Get-Remote-Session($guest_ip, $username, $password) {
    $secstr = convertto-securestring -AsPlainText -Force -String $password
    $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr
    New-PSSession -ComputerName $guest_ip -Credential $cred
}

function Get-remote-file-hash($source_path, $delimiter, $session) {
    Invoke-Command -Session $session -ScriptBlock ${function:Get-file-hash} -ArgumentList $source_path, $delimiter
    # TODO:
    # Check if remote PS Scripting errors
}

function Sync-Remote-Machine($machine, $remove_files, $copy_files, $host_path, $guest_path) {
    ForEach ($item in $copy_files) {
      $from = $host_path + $item
      $to = $guest_path + $item
      # Copy VM can also take a VM object
      Copy-VMFile  -VM $machine -SourcePath $from -DestinationPath $to -CreateFullPath -FileSource Host -Force
    }
}

function Create-Remote-Folders($empty_source_folders, $guest_path) {
    ForEach ($item in $empty_source_folders) {
        $new_name =  $guest_path + $item
        New-Item "$new_name" -type directory -Force
    }
}

function Get-Empty-folders-From-Source($host_path) {
  Get-ChildItem $host_path -recurse |
        Where-Object {$_.PSIsContainer -eq $True} |
            Where-Object {$_.GetFiles().Count -eq 0} |
                Select-Object FullName | ForEach-Object -Process {
                    $empty_source_folders += ($_.FullName.Replace($host_path, ""))
                }
}

$delimiter = " || "

$machine = Get-VM -Id $vm_id

# FIXME: PowerShell guys please fix this.
# The below script checks for all VMIntegrationService which are not enabled
# and will enable this.
# When when all the services are enabled this throws an error.
# Enable VMIntegrationService to true
try {
  Get-VM -Id $vm_id | Get-VMIntegrationService -Name "Guest Service Interface" | Enable-VMIntegrationService -Passthru
  }
  catch { }

$session = Get-Remote-Session $guest_ip $username $password

$source_files = Get-file-hash $host_path $delimiter
$destination_files = Get-remote-file-hash $guest_path $delimiter $session

if (!$destination_files) {
  $destination_files = @()
}
if (!$source_files) {
  $source_files = @()
}

# Compare source and destination files
$remove_files = @()
$copy_files = @()


Compare-Object -ReferenceObject $source_files -DifferenceObject $destination_files | ForEach-Object {
  if ($_.SideIndicator -eq '=>') {
      $remove_files += $_.InputObject.Split($delimiter)[0]
  } else {
      $copy_files += $_.InputObject.Split($delimiter)[0]
  }
}

# Update the files to remote machine
Sync-Remote-Machine $machine $remove_files $copy_files $host_path $guest_path

# Create any empty folders which missed to sync to remote machine
$empty_source_folders = @()
$directories = Get-Empty-folders-From-Source $host_path

$result = Invoke-Command -Session $session -ScriptBlock ${function:Create-Remote-Folders} -ArgumentList $empty_source_folders, $guest_path
# Always remove the connection after Use
Remove-PSSession -Id $session.Id

$resultHash = @{
  message = "OK"
}
$result = ConvertTo-Json $resultHash
Write-Output-Message $result

