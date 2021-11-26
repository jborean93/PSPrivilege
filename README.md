# PSPrivilege

[![Test workflow](https://github.com/jborean93/PSPrivilege/workflows/Test%20PSPrivilege/badge.svg)](https://github.com/jborean93/PSPrivilege/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/jborean93/PSPrivilege/branch/main/graph/badge.svg?token=b51IOhpLfQ)](https://codecov.io/gh/jborean93/PSPrivilege)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PSPrivilege.svg)](https://www.powershellgallery.com/packages/PSPrivilege)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/jborean93/PSPrivilege/blob/main/LICENSE)

PowerShell module that allows you to enable/disable/remove privileges on the current process as well as modify the membership of rights and privileges for a Windows host.

## Documentation

Documentation for this module and details on the cmdlets included can be found [here](docs/en-US/PSPrivilege.md).

## Requirements

These cmdlets have the following requirements

* PowerShell v5.1 or newer
* .NET Framework 4.7.2+ or .NET Core+
* Windows Server 2008 R2/Windows 7 or newer

## Installing

The easiest way to install this module is through
[PowerShellGet](https://docs.microsoft.com/en-us/powershell/gallery/overview).

You can install this module by running;

```powershell
# Install for only the current user
Install-Module -Name PSPrivilege -Scope CurrentUser

# Install for all users
Install-Module -Name PSPrivilege -Scope AllUsers
```

## Contributing

Contributing is quite easy, fork this repo and submit a pull request with the changes.
To build this module run `.\build.ps1 -Task Build` in PowerShell.
To test a build run `.\build.ps1 -Task Test` in PowerShell.
This script will ensure all dependencies are installed before running the test suite.
