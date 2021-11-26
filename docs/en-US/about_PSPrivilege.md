# PSPrivilege
## about_PSPrivilege

# SHORT DESCRIPTION
Manage process privileges and machine wide privilege/user right settings.

# LONG DESCRIPTION

This PowerShell module contains 8 PowerShell cmdlets that are used to adjust privileges and rights on a Windows host.
There are 4 cmdlets that can be used to manage system wide privileges either on the localhost or a remote host.
These cmdlets are;

* [Add-WindowsRight](Add-WindowsRight.md): Add security principals to a privilege/right.
* [Clear-WindowsRight](Clear-WindowsRight.md): Remove all privileges/rights from a security principal OR all principals from a privilege/right.
* [Get-WindowsRight](Get-WindowsRight.md): Get info on privileges/rights.
* [Remove-WindowsRight](Remove-WindowsRight.md): Remove security principals from a privielge/right.

There are another 4 cmdlets that can be used to manage the privileges on the current process.
These cmdlets are;

* [Disable-ProcessPrivilege](Disable-ProcessPrivilege.md): Disable a privilege on the current process.
* [Enable-ProcessPrivilege](Enable-ProcessPrivilege.md): Enable a privilege on the current process.
* [Get-ProcessPrivilege](Get-ProcessPrivilege.md): Get information about privilege(s) on the current process.
* [Remove-ProcessPrivilege](Remove-ProcessPrivilege.md): Remove a privilege from the current process.

To get the list of valid privilege/right constants, Microsoft has provided some pages;

* [Privilege Constants](https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/privilege-constants)
* [Account Rights Constants](https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/account-rights-constants)

While privileges work for all cmdlets, account rights are only used in the `*-WindowsRight` cmdlets.
