# PSPrivilege

[![Build status](https://ci.appveyor.com/api/projects/status/ry4fwmyf592aciw7?svg=true)](https://ci.appveyor.com/project/jborean93/psprivilege)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PSPrivilege.svg)](https://www.powershellgallery.com/packages/PSPrivilege)

PowerShell module that allows you to enable/disable/remove privileges on the
current process as well as modify the membership of rights and privileges for
a Windows host.

## Info

This PowerShell module contains 8 PowerShell cmdlets that are used to adjust
privileges and rights on a Windows host. There are 4 cmdlets that can be used
to manage system wide privileges either on the localhost or a remote host.
These cmdlets are;

* `Add-WindowsRight`: Add security principals to a privilege/right.
* `Clear-WindowsRight`: Remove all privileges/rights from a security principal OR all principals from a privilege/right.
* `Get-WindowsRight`: Get info on privileges/rights.
* `Remove-WindowsRight`: Remove security principals from a privielge/right.

There are another 4 cmdlets that can be used to manage the privileges on the
current process. These cmdlets are;

* `Disable-ProcessPrivilege`: Disable a privilege on the current process.
* `Enable-ProcessPrivilege`: Enable a privilege on the current process.
* `Get-ProcessPrivilege`: Get information about privilege(s) on the current process.
* `Remove-ProcessPrivilege`: Remove a privilege from the current process.

To get the list of valid privilege/right constants, Microsoft has provided
some pages;

* [Privilege Constants](https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/privilege-constants)
* [Account Rights Constants](https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/account-rights-constants)

While privileges work for all cmdlets, account rights are only used in the
`*-WindowsRight` cmdlets.


### Add-WindowsRight

Add an account(s) to the privilege/right(s) specified. This cmdlet requires
Administrator permissions to run.

#### Syntax

```
Add-WindowsRight
    -Name <String[]>
    -Account <System.Security.Principal.IdentityReference[]]>
    [[-ComputerName] <String>]
```

#### Parameters

* `Name`: <String[]> A list of privileges and/or rights that the accounts specified under `Account` will be added to
* `Account`: <System.Security.Principal.IdentityReference[]> A list of security principals to add to the privileges specified by `Name`

#### Optional Parameters

* `ComputerName`: <String> Add the members to a remote Windows host instead of the localhost

#### Input

* `<String[]>`: A string array can be passed as a pipeline input of the `Name` parameter

#### Output

None

### Clear-WindowsRight

Clears all the principals in a privilege/right OR removes all privileges/rights
that a principal has. This cmdlet requires Administrator permissions to run.

#### Syntax

```
# clear the members of a privilege/right
Clear-WindowsRight
    -Name <String[]>
    [[-ComputerName] <String>]

# clear the privileges/rights of a security principal
Clear-WindowsRight
    -Account <System.Security.Principal.IdentityReference[]>
    [[-ComputerName] <String>]
```

#### Parameters

* `Name`: <String[]> A list of privileges and/or rights to clear
* `Account`: <System.Security.Principal.IdentityReference[]> A list of security principals to remove all privileges from

#### Optional Parameters

* `ComputerName`: <String> Clear the members on a remote Windows host instead of the localhost

#### Input

* `<String[]>`: A string array can be passed as a pipeline input of the `Name` parameter

#### Output

None

### Get-WindowsRight

Gets the membership information about a privilege or right on the host
specified. This cmdlet requires Administrator permissions to run.

#### Syntax

```
Get-WindowsRight
    [[-Name] <String[]>]
    [[-Account] <System.Security.Principal.IdentityReference[]> ]
    [[-ComputerName] <String>]
```

#### Parameters

No mandatory parameters

#### Optional Parameters

* `Name`: <String[]> A list of privileges and/or rights to get info on, if omitted then this will get all the privileges/rights
* `Account`: <System.Security.Principal.IdentityReference[]> A list of security principals which will filter the output to only show privileges/rights a principal specified is a member of
* `ComputerName`: <String> Get the information on the host specified instead of the localhost

#### Input

* `<String[]>`: A string array can be passed as a pipeline input of the `Name` parameter

#### Output

* `[PSCustomObject]`: A custom object containing the following fields
    * `Name`: <String> The name of the privilege or right
    * `ComputerName`: <String> The name of the host the info is from
    * `Description`: <String> A brief description of the privilege/right
    * `Accounts`: <System.Security.Principal.SecurityIdentifier[]> A list of SIDs that are members of the privilege/right

### Remove-WindowsRight

Remove a security principal from a privilege and/or right. This cmdlet requires
Administrator permissions to run.

#### Syntax

```
Remove-WindowsRight
    -Name <String[]>
    -Account <System.Security.Principal.IdentityReference[]>
    [[-ComputerName] <String>
```

#### Parameters

* `Name`: <String[]> A list of privileges and/or rights that the specified `Account` will be removed from
* `Account`: <System.Security.Principal.IdentityReference[]> A list of security principals to remove from the privilege/right(s) specified by `Name`

#### Optional Parameters

* `ComputerName`: <String> Remove the principals on the host specified instead of the localhost

#### Input

* `<String[]>`: A string array can be passed as a pipeline input of the `Name` parameter

#### Output

None

### Disable-ProcessPrivilege

Disable a privilege on the current process. Only privileges that are set on
the current process can be disabled, any privileges that are removed will
result in an error.

#### Syntax

```
Disable-ProcessPrivilege
    -Name <String[]>
```

### Parameters

* `Name`: <String[]> A list of privileges to disable

#### Optional Parameters

None

#### Input

* `<String[]>`: A string array that can be passed as a pipeline input of the `Name` paramter

#### Output

None

### Enable-ProcessPrivilege

Enable a privilege on the current process. Only privileges that are set on the
current process can be enabled, any privielges that are removed will result in
an error.

#### Syntax

```
Enable-ProcessPrivilege
    -Name <String[]>
```

#### Parameters

* `Name`: <String[]> A list of privileges to enable

#### Optional Parameters

None

#### Input

* `<String[]>`: A string array that can be passed as a pipeline input of the `Name` parameter

#### Output

None

### Get-ProcessPrivilege

Get information about privileges on the current process. Unless specified
by the `Name` parameter, any removed privileges will not be returned by this
cmdlet.

#### Syntax

```
Get-ProcessPrivilege
    [[-Name] <String[]>]
```

#### Parameters

No mandatory parameters

#### Optional Parameters

* `Name`: <String[]> A list of privileges to get the info for, if omitted then all the processes privileges are returned

#### Input

* `<String[]>`: A string array that can be passed as a pipeline input of the `Name` parameter

#### Output

* `[PSCustomObject]`: A obj containing the following information
    * `Name`: <String> The name of the privilege
    * `Description`: <String> A brief description of the privilege
    * `Enabled`: <Boolean> Whether the privilege is enabled or not
    * `EnabledByDefault`: <Boolean> Whether the privilege was originaly enabled by default when the process was spawned
    * `Attributes`: <PSPrivilege.PrivilegeAttributes> The raw Privilege attributes returned by Windows
    * `IsRemoved`: <Boolean> Whether the privilege was removed from the process or is still present

### Remove-ProcessPrivilege

Remove a privilege on the current process. Once a privilege is removed, it
cannot be added back. Only by spawning a new process will the privilege be
restored.

#### Syntax

```
Remove-ProcessPrivilege
    -Name <String[]>
```

#### Parameters

* `Name`: <String[]> A list of privileges to remove

#### Optional Parameters

None

#### Input

* `<String[]>`: A string array that can be passed as a pipeline input of the `Name` parmaeter

#### Output

None


## Requirements

These cmdlets have the following requirements

* PowerShell v3.0 or newer
* Windows PowerShell (not PowerShell Core)
* Windows Server 2008 R2/Windows 7 or newer


## Installing

The easiest way to install this module is through
[PowerShellGet](https://docs.microsoft.com/en-us/powershell/gallery/overview).
This is installed by default with PowerShell 5 but can be added on PowerShell
3 or 4 by installing the MSI [here](https://www.microsoft.com/en-us/download/details.aspx?id=51451).

Once installed, you can install this module by running;

```
# Install for all users
Install-Module -Name PSPrivilege

# Install for only the current user
Install-Module -Name PSPrivilege -Scope CurrentUser
```

If you wish to remove the module, just run
`Uninstall-Module -Name PSPrivilege`.

If you cannot use PowerShellGet, you can still install the module manually,
here are some basic steps on how to do this;

1. Download the latext zip from GitHub [here](https://github.com/jborean93/PSPrivilege/releases/latest)
2. Extract the zip
3. Copy the folder `PSPrivilege` inside the zip to a path that is set in `$env:PSModulePath`. By default this could be `C:\Program Files\WindowsPowerShell\Modules` or `C:\Users\<user>\Documents\WindowsPowerShell\Modules`
4. Reopen PowerShell and unblock the downloaded files with `$path = (Get-Module -Name PSPrivilege -ListAvailable).ModuleBase; Unblock-File -Path $path\*.psd1; Unblock-File -Path $path\Public\*.ps1; Unblock-File -Path $path\Private\*.ps1`
5. Reopen PowerShell one more time and you can start using the cmdlets

_Note: You are not limited to installing the module to those example paths, you can add a new entry to the environment variable `PSModulePath` if you want to use another path._


## Examples

Here are some examples of how you can use these cmdlets;

```
# get all privileges on the current process
Get-ProcessPrivilege

# get info on only the specific privileges
Get-ProcessPrivilege -Name SeDebugPrivilege, SeTcbPrivilege

# get info on all the user rights and privileges on the localhost
Get-WindowsRight

# get info on the specified rights/privileges
Get-WindowsRight -Name SeDebugPrivilege, SeBatchLogonRight

# add the Administrators group to the SeTcbPrivilege
$admin_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-544"
Add-WindowsRight -Name SeTcbPrivilege -Account $admin_sid

# remove all the principals from the SeTcbPrivilege
Clear-WindowsRight -Name SeTcbPrivilege
```


## Contributing

Contributing is quite easy, fork this repo and submit a pull request with the
changes. To test out your changes locally you can just run `.\build.ps1` in
PowerShell. This script will ensure all dependencies are installed before
running the test suite.

_Note: this requires PowerShellGet or WMF 5 to be installed_


## Backlog

* Add the ability to specify a custom process handle and just default to the current process.
