# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

. ([IO.Path]::Combine($PSScriptRoot, 'common.ps1'))

# These tests rely on the default Windows settings, they may fail if certain
# settings have been modified
Describe "$module_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        BeforeEach {
            $test_right1 = "SeDenyServiceLogonRight"
            $test_right2 = "SeCreatePermanentPrivilege"
            $admin_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-544"
            $user_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-545"

            Clear-WindowsRight -Name $test_right1, $test_right2
        }

        It "Clears accounts of single privilege" {
            $pre_state = Get-WindowsRight -Name $test_right1
            $pre_state.Accounts.Count | Should -Be 0

            Add-WindowsRight -Name $test_right1 -Account $admin_sid, $user_sid
            Clear-WindowsRight -Name $test_right1
            $res = Get-WindowsRight -Name $test_right1
            $res.Accounts | Should -Be @()

            # 2nd run to test idempotency
            Clear-WindowsRight -Name $test_right1
        }

        It "Clears accounts of multiple privileges" {
            $pre_state = Get-WindowsRight -Name $test_right1
            $pre_state.Accounts.Count | Should -Be 0

            Add-WindowsRight -Name $test_right1, $test_right2 -Account $admin_sid, $user_sid
            Clear-WindowsRight -Name $test_right1, $test_right2
            $res = Get-WindowsRight -Name $test_right1, $test_right2
            $res[0].Accounts | Should -Be @()
            $res[1].Accounts | Should -Be @()

            # 2nd run to test idempotency
            Clear-WindowsRight -Name $test_right1, $test_right2
        }

        It "Clears the account of invalid privilege" {
            $pre_state = Get-WindowsRight -Name $test_right1
            $pre_state.Accounts.Count | Should -Be 0

            Add-WindowsRight -Name $test_right1 -Account $admin_sid, $user_sid
            Clear-WindowsRight -Name "SeFake", $test_right1 -ErrorVariable err -ErrorAction SilentlyContinue
            $res = Get-WindowsRight -Name $test_right1
            $res.Accounts | Should -Be @()
            $err.Count | Should -Be 1
            $err[0].Exception.Message | Should -Be "No such privilege/right SeFake"
            $err[0].FullyQualifiedErrorId | Should -Be "InvalidPrivilegeRightName,PSPrivilege.Commands.ClearWindowsRight"
        }

        It "Clears the rights of a single account" {
            $pre_state = Get-WindowsRight -Name $test_right1
            $pre_state.Accounts.Count | Should -Be 0

            $current_user = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User

            Add-WindowsRight -Name $test_right1 -Account $admin_sid, $current_user
            Clear-WindowsRight -Account $current_user
            $res = Get-WindowsRight -Name $test_right1
            $res.Accounts | Should -Be @($admin_sid)

            # 2nd run to test idempotency
            Clear-WindowsRight -Account $current_user
        }

        It "Clears the rights of multiple accounts" {
            $pre_state = Get-WindowsRight -Name $test_right1
            $pre_state.Accounts.Count | Should -Be 0

            $current_user = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User
            $anon_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-1-0"

            Add-WindowsRight -Name $test_right1 -Account $admin_sid, $current_user, $anon_sid
            Clear-WindowsRight -Account $current_user, $anon_sid
            $res = Get-WindowsRight -Name $test_right1
            $res.Accounts | Should -Be @($admin_sid)

            # 2nd run to test idempotency
            Clear-WindowsRight -Account $current_user, $anon_sid
        }

        AfterEach {
            Clear-WindowsRight -Name $test_right1, $test_right2
        }
    }
}
