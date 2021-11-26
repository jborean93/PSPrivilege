# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

. ([IO.Path]::Combine($PSScriptRoot, 'common.ps1'))

# These tests rely on the default Windows settings, they may fail if certain
# settings have been modified
Describe "$module_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It "Gets all privileges and rights" {
            $res = Get-WindowsRight
            $res.Count | Should -Be 43
            $res[0].Name.GetType().Name | Should -Be "String"
            $res[0].Description.GetType().Name | Should -Be "String"
            $res[0].ComputerName | Should -Be $env:COMPUTERNAME
            $res[0].Accounts.GetType().Name | Should -Be "IdentityReference[]"
        }

        It "Get individual right" {
            $res = Get-WindowsRight -Name SeDebugPrivilege
            $res.Name | Should -Be "SeDebugPrivilege"
            $res.ComputerName | Should -Be $env:COMPUTERNAME
            $res.Description | Should -Be "Debug programs"
            $res.Accounts | Should -Be @(New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-544")
        }

        It "Get individual right as pipeline input string" {
            $res = "SeDebugPrivilege" | Get-WindowsRight
            $res.Name | Should -Be "SeDebugPrivilege"
            $res.ComputerName | Should -Be $env:COMPUTERNAME
            $res.Description | Should -Be "Debug programs"
            $res.Accounts | Should -Be @(New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-544")
        }

        It "Get individual right as pipeline input object" {
            $res = [PSCustomObject]@{Name="SeDebugPrivilege"} | Get-WindowsRight
            $res.Name | Should -Be "SeDebugPrivilege"
            $res.ComputerName | Should -Be $env:COMPUTERNAME
            $res.Description | Should -Be "Debug programs"
            $res.Accounts | Should -Be @(New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-544")
        }

        It "Get multiple rights" {
            $admin_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-544"
            $backup_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-551"
            $user_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-545"

            $res = Get-WindowsRight -Name SeDebugPrivilege, SeInteractiveLogonRight
            $res.Count | Should -Be 2
            $res[0].Name | Should -Be "SeDebugPrivilege"
            $res[0].ComputerName | Should -Be $env:COMPUTERNAME
            $res[0].Description | Should -Be "Debug programs"
            $res[0].Accounts | Should -Be @($admin_sid)
            $res[1].Name | Should -Be "SeInteractiveLogonRight"
            $res[1].ComputerName | Should -Be $env:COMPUTERNAME
            $res[1].Description | Should -Be "Allow log on locally"
            $res[1].Accounts | Should -Be @($backup_sid, $user_sid, $admin_sid)
        }

        It "Get multiple rights as pipeline input string" {
            $admin_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-544"
            $backup_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-551"
            $user_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-545"

            $res = "SeDebugPrivilege", "SeInteractiveLogonRight" | Get-WindowsRight
            $res.Count | Should -Be 2
            $res[0].Name | Should -Be "SeDebugPrivilege"
            $res[0].ComputerName | Should -Be $env:COMPUTERNAME
            $res[0].Description | Should -Be "Debug programs"
            $res[0].Accounts | Should -Be @($admin_sid)
            $res[1].Name | Should -Be "SeInteractiveLogonRight"
            $res[1].ComputerName | Should -Be $env:COMPUTERNAME
            $res[1].Description | Should -Be "Allow log on locally"
            $res[1].Accounts | Should -Be @($backup_sid, $user_sid, $admin_sid)
        }

        It "Get multiple rights as pipeline input object" {
            $admin_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-544"
            $backup_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-551"
            $user_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-545"

            $res = @([PSCustomObject]@{Name="SeDebugPrivilege"}, [PSCustomObject]@{Name="SeInteractiveLogonRight"}) | Get-WindowsRight
            $res.Count | Should -Be 2
            $res[0].Name | Should -Be "SeDebugPrivilege"
            $res[0].ComputerName | Should -Be $env:COMPUTERNAME
            $res[0].Description | Should -Be "Debug programs"
            $res[0].Accounts | Should -Be @($admin_sid)
            $res[1].Name | Should -Be "SeInteractiveLogonRight"
            $res[1].ComputerName | Should -Be $env:COMPUTERNAME
            $res[1].Description | Should -Be "Allow log on locally"
            $res[1].Accounts | Should -Be @($backup_sid, $user_sid, $admin_sid)
        }

        It "Get right on computer" {
            $res = Get-WindowsRight -Name SeDebugPrivilege -ComputerName $env:COMPUTERNAME
            $res.Name | Should -Be "SeDebugPrivilege"
            $res.ComputerName | Should -Be $env:COMPUTERNAME
            $res.Description | Should -Be "Debug programs"
            $res.Accounts | Should -Be @(New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-544")
        }

        It "Get rights for specific user" {
            $admin_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-544"
            $res = Get-WindowsRight -Account $admin_sid
            $res.Count -gt 0 | Should -Be $true
            $right_res = $res | Where-Object { $_.Name -eq "SeRemoteInteractiveLogonRight" }
            $right_res.Name | Should -Be "SeRemoteInteractiveLogonRight"
            $right_res.ComputerName | Should -Be $env:COMPUTERNAME
            $admin_sid -in $right_res.Accounts | Should -Be $true
        }

        It "Get rights filtered for specific user" {
            $admin_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-544"
            $res = Get-WindowsRight -Name SeSystemtimePrivilege, SeCreateSymbolicLinkPrivilege, SeCreateTokenPrivilege -Account $admin_sid
            $res.Count | Should -Be 2
            $res[0].Name | Should -Be "SeSystemtimePrivilege"
            $res[0].ComputerName | Should -Be $env:COMPUTERNAME
            $admin_sid -in $res[0].Accounts | Should -Be $true
            $res[1].Name | Should -Be "SeCreateSymbolicLinkPrivilege"
            $res[1].ComputerName | Should -Be $env:COMPUTERNAME
            $admin_sid -in $res[1].Accounts | Should -Be $true
        }

        It "Get invalid right" {
            $res = Get-WindowsRight -Name SeFake, SeDebugPrivilege -ErrorVariable err -ErrorAction SilentlyContinue -WarningVariable war
            $res.Name | Should -Be "SeDebugPrivilege"
            $res.ComputerName | Should -Be $env:COMPUTERNAME
            $res.Description | Should -Be "Debug programs"
            $res.Accounts | Should -Be @(New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-544")
            $err.Count | Should -Be 1
            $err[0].CategoryInfo.Category | Should -Be "InvalidArgument"
            $err[0].Exception.Message | Should -Be "No such privilege/right SeFake"
            $war.Count | Should -Be 1
            $war[0].Message | Should -Be "Unknown right SeFake, cannot get description"
        }

        It "Autocompletes rights - no value" {
            $actual = [System.Management.Automation.CommandCompletion]::CompleteInput(
                "Get-WindowsRight -Name ",
                23,
                $null)
            $actual.CompletionMatches.Count -gt 0 | Should -Be $true
        }

        It "Autocompletes rights - one match" {
            $actual = [System.Management.Automation.CommandCompletion]::CompleteInput(
                "Get-WindowsRight -Name SeDenySer",
                32,
                $null)
            $actual.CompletionMatches.Count | Should -Be 1
            $actual.CompletionMatches[0].CompletionText | Should -Be "SeDenyServiceLogonRight"
            $actual.CompletionMatches[0].ListItemText | Should -Be "SeDenyServiceLogonRight"
            $actual.CompletionMatches[0].ResultType | Should -Be ([System.Management.Automation.CompletionResultType]::ParameterValue)
            $actual.CompletionMatches[0].ToolTip | Should -Be "Deny log on as a service"
        }
    }
}
