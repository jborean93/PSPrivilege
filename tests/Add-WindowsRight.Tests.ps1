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

        It "Adds a single account to a single right" {
            $pre_state = Get-WindowsRight -Name $test_right1
            $pre_state.Accounts.Count | Should -Be 0

            Add-WindowsRight -Name $test_right1 -Account $admin_sid
            $res = Get-WindowsRight -Name $test_right1
            $res.Accounts | Should -Be @($admin_sid)

            # 2nd run to test idempotency
            Add-WindowsRight -Name $test_right1 -Account $admin_sid
        }

        It "Adds a single account to a single right as string input" {
            $pre_state = Get-WindowsRight -Name $test_right1
            $pre_state.Accounts.Count | Should -Be 0

            $test_right1 | Add-WindowsRight -Account $admin_sid
            $res = Get-WindowsRight -Name $test_right1
            $res.Accounts | Should -Be @($admin_sid)

            # 2nd run to test idempotency
            $test_right1 | Add-WindowsRight -Account $admin_sid
        }

        It "Adds a single account to a single right as object input" {
            $pre_state = Get-WindowsRight -Name $test_right1
            $pre_state.Accounts.Count | Should -Be 0

            [PSCustomObject]@{Name=$test_right1} | Add-WindowsRight -Account $admin_sid
            $res = Get-WindowsRight -Name $test_right1
            $res.Accounts | Should -Be @($admin_sid)

            # 2nd run to test idempotency
            [PSCustomObject]@{Name=$test_right1} | Add-WindowsRight -Account $admin_sid
        }

        It "Adds a single account to multiple rights" {
            $pre_state = Get-WindowsRight -Name $test_right1
            $pre_state.Accounts.Count | Should -Be 0

            Add-WindowsRight -Name $test_right1, $test_right2 -Account $admin_sid
            $res = Get-WindowsRight -Name $test_right1, $test_right2
            $res.Count | Should -Be 2
            $res[0].Accounts | Should -Be @($admin_sid)
            $res[1].Accounts | Should -Be @($admin_sid)

            # 2nd run to test idempotency
            Add-WindowsRight -Name $test_right1, $test_right2 -Account $admin_sid
        }

        It "Adds a single account to multiple rights as string input" {
            $pre_state = Get-WindowsRight -Name $test_right1
            $pre_state.Accounts.Count | Should -Be 0

            $test_right1, $test_right2 | Add-WindowsRight -Account $admin_sid
            $res = Get-WindowsRight -Name $test_right1, $test_right2
            $res.Count | Should -Be 2
            $res[0].Accounts | Should -Be @($admin_sid)
            $res[1].Accounts | Should -Be @($admin_sid)

            # 2nd run to test idempotency
            $test_right1, $test_right2 | Add-WindowsRight -Account $admin_sid
        }

        It "Adds a single account to multiple rights as object input" {
            $pre_state = Get-WindowsRight -Name $test_right1, $test_right2
            $pre_state[0].Accounts.Count | Should -Be 0
            $pre_state[1].Accounts.Count | Should -Be 0

            @([PSCustomObject]@{Name=$test_right1}, [PSCustomObject]@{Name=$test_right2}) | Add-WindowsRight -Account $admin_sid
            $res = Get-WindowsRight -Name $test_right1, $test_right2
            $res.Count | Should -Be 2
            $res[0].Accounts | Should -Be @($admin_sid)
            $res[1].Accounts | Should -Be @($admin_sid)

            # 2nd run to test idempotency
            @([PSCustomObject]@{Name=$test_right1}, [PSCustomObject]@{Name=$test_right2}) | Add-WindowsRight -Account $admin_sid
        }

        It "Adds multiple accounts to one right" {
            $pre_state = Get-WindowsRight -Name $test_right1
            $pre_state.Accounts.Count | Should -Be 0

            Add-WindowsRight -Name $test_right1 -Account $user_sid, $admin_sid
            $res = Get-WindowsRight -Name $test_right1
            $res.Accounts | Should -Be @($user_sid, $admin_sid)

            # 2nd run to test idempotency
            Add-WindowsRight -Name $test_right1 -Account $user_sid, $admin_sid
        }

        It "Adds multiple accounts to multiple rights" {
            $pre_state = Get-WindowsRight -Name $test_right1, $test_right2
            $pre_state[0].Accounts.Count | Should -Be 0
            $pre_state[1].Accounts.Count | Should -Be 0

            Add-WindowsRight -Name $test_right1, $test_right2 -Account $user_sid, $admin_sid
            $res = Get-WindowsRight -Name $test_right1, $test_right2
            $res.Count | Should -Be 2
            $res[0].Accounts | Should -Be @($user_sid, $admin_sid)
            $res[1].Accounts | Should -Be @($user_sid, $admin_sid)

            # 2nd run to test idempotency
            Add-WindowsRight -Name $test_right1, $test_right2 -Account $user_sid, $admin_sid
        }

        It "Adds an invalid privilege" {
            $pre_state = Get-WindowsRight -Name $test_right1
            $pre_state.Accounts.Count | Should -Be 0

            Add-WindowsRight -Name "SeFake", $test_right1 -Account $admin_sid -ErrorVariable err -ErrorAction SilentlyContinue
            $res = Get-WindowsRight -Name $test_right1
            $res.Accounts | Should -Be @($admin_sid)
            $err[-1].Exception.Message | Should -Be "No such privilege/right SeFake"
            $err[-1].CategoryInfo.Category | Should -be "InvalidArgument"
        }

        AfterEach {
            Clear-WindowsRight -Name $test_right1, $test_right2
        }
    }
}
