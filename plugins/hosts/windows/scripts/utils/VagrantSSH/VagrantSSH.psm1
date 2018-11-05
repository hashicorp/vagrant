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
    $ACL = Get-ACL "${SSHKeyPath}"
    # Disable inherited rules
    $ACL.SetAccessRuleProtection($true, $false)
    # Scrub all existing ACLs from the file
    $ACL.Access | %{$ACL.RemoveAccessRule($_)}
    # Apply the new ACL
    $ACL.SetAccessRule($NewAccessRule)
    Set-ACL "${SSHKeyPath}" $ACL
}
