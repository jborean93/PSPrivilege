# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

@{
    RootModule = 'PSPrivilege.psm1'
    ModuleVersion = '0.2.0'
    GUID = 'c1b49738-292a-433f-808a-ee6aa408bf2f'
    Author = 'Jordan Borean'
    Copyright = 'Copyright (c) 2018 by Jordan Borean, Red Hat, licensed under MIT.'
    Description = "Adds cmdlets that can be used to enable/disable/remove privileges on a process. Also adds cmdlets that can be used to configure the members of Windows rights and privileges.`nSee https://github.com/jborean93/PSPrivilege for more info"
    PowerShellVersion = '5.1'
    DotNetFrameworkVersion = '4.7.2'
    ClrVersion = '4.0'
    FormatsToProcess = @(
        'PSPrivilege.Format.ps1xml'
    )
    NestedModules = @()
    FunctionsToExport = @()
    CmdletsToExport = @(
        'Add-WindowsRight'
        'Clear-WindowsRight'
        'Disable-ProcessPrivilege'
        'Enable-ProcessPrivilege'
        'Get-ProcessPrivilege'
        'Get-WindowsRight'
        'Remove-ProcessPrivilege'
        'Remove-WindowsRight'
    )
    PrivateData = @{
        PSData = @{
            Tags = @(
                "Automation",
                "DevOps",
                "Windows",
                "Security",
                "Configuration"
            )
            LicenseUri = 'https://github.com/jborean93/PSPrivilege/blob/master/LICENSE'
            ProjectUri = 'https://github.com/jborean93/PSPrivilege'
            ReleaseNotes = 'See https://github.com/jborean93/PSPrivilege/blob/master/CHANGELOG.md'
        }
    }
}
