# Vagrant SSH capability functions

function Set-SSHKeyPermissions {
    param (
        [parameter(Mandatory=$true)]
        [string] $SSHKeyPath,
        [parameter(Mandatory=$false)]
        [string] $Principal=$null
    )

    if(!$Principal) {
        $Principal = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    }

    # Create the new ACL we want to apply
    $NewAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $Principal, "FullControl", "None", "None", "Allow")
    # Scrub all existing ACLs from the file
    $ACL = Get-ACL "${SSHKeyPath}"
    $ACL.Access | %{$ACL.RemoveAccessRule($_)}
    # Apply the new ACL
    $ACL.SetAccessRule($NewAccessRule)
    Set-ACL "${SSHKeyPath}" $ACL
}
