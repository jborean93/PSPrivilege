# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

. ([IO.Path]::Combine($PSScriptRoot, 'common.ps1'))

Describe "$module_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        BeforeEach {
            $privileges = Get-ProcessPrivilege | Where-Object { $_.Enabled -eq $true }

            $test_privilege1 = $privileges[0].Name
            $test_privilege2 = $privileges[1].Name
        }

        It 'Disables a single privilege' {
            $pre_state = Get-ProcessPrivilege -Name $test_privilege1
            $pre_state.Enabled | Should -Be $true

            Disable-ProcessPrivilege -Name $test_privilege1
            $actual = Get-ProcessPrivilege -Name $test_privilege1
            $actual.Enabled | Should -Be $false

            # run a 2nd time to ensure no errors occur
            Disable-ProcessPrivilege -Name $test_privilege1 -ErrorVariable err -ErrorAction SilentlyContinue
            $err.Count | Should -Be 0
        }

        It 'Disables a single privilege from input as string' {
            $pre_state = Get-ProcessPrivilege -Name $test_privilege1
            $pre_state.Enabled | Should -Be $true

            $test_privilege1 | Disable-ProcessPrivilege
            $actual = Get-ProcessPrivilege -Name $test_privilege1
            $actual.Enabled | Should -Be $false

            # run a 2nd time to ensure no errors occur
            $test_privilege1 | Disable-ProcessPrivilege -ErrorVariable err -ErrorAction SilentlyContinue
            $err.Count | Should -Be 0
        }

        It 'Disables a single privilege from input as object' {
            $pre_state = Get-ProcessPrivilege -Name $test_privilege1
            $pre_state.Enabled | Should -Be $true

            [PSCustomObject]@{Name=$test_privilege1} | Disable-ProcessPrivilege
            $actual = Get-ProcessPrivilege -Name $test_privilege1
            $actual.Enabled | Should -Be $false

            # run a 2nd time to ensure no errors occur
            [PSCustomObject]@{Name=$test_privilege1} | Disable-ProcessPrivilege -ErrorVariable err -ErrorAction SilentlyContinue
            $err.Count | Should -Be 0
        }

        It 'Disables multiple privileges' {
            $pre_state = Get-ProcessPrivilege -Name $test_privilege1, $test_privilege2
            $pre_state.Enabled | Should -Be @($true, $true)

            Disable-ProcessPrivilege -Name $test_privilege1, $test_privilege2
            $actual = Get-ProcessPrivilege -Name $test_privilege1, $test_privilege2
            $actual.Enabled | Should -Be @($false, $false)

            # run a 2nd time to ensure no errors occur
            Disable-ProcessPrivilege -Name $test_privilege1, $test_privilege2 -ErrorVariable err -ErrorAction SilentlyContinue
            $err.Count | Should -Be 0
        }

        It 'Disables multiple privileges from input as string' {
            $pre_state = Get-ProcessPrivilege -Name $test_privilege1, $test_privilege2
            $pre_state.Enabled | Should -Be @($true, $true)

            $test_privilege1, $test_privilege2 | Disable-ProcessPrivilege
            $actual = Get-ProcessPrivilege -Name $test_privilege1, $test_privilege2
            $actual.Enabled | Should -Be @($false, $false)

            # run a 2nd time to ensure no errors occur
            $test_privilege1, $test_privilege2 | Disable-ProcessPrivilege -ErrorVariable err -ErrorAction SilentlyContinue
            $err.Count | Should -Be 0
        }

        It 'Disables multiple privileges from input as object' {
            $pre_state = Get-ProcessPrivilege -Name $test_privilege1, $test_privilege2
            $pre_state.Enabled | Should -Be @($true, $true)

            @([PSCustomObject]@{Name=$test_privilege1}, [PSCustomObject]@{Name=$test_privilege2}) | Disable-ProcessPrivilege
            $actual = Get-ProcessPrivilege -Name $test_privilege1, $test_privilege2
            $actual.Enabled | Should -Be @($false, $false)

            # run a 2nd time to ensure no errors occur
            @([PSCustomObject]@{Name=$test_privilege1}, [PSCustomObject]@{Name=$test_privilege2}) | Disable-ProcessPrivilege -ErrorVariable err -ErrorAction SilentlyContinue
            $err.Count | Should -Be 0
        }

        It 'Writes error for invalid and removed privilege' {
            $pre_state = Get-ProcessPrivilege -Name $test_privilege1
            $pre_state.Enabled | Should -Be $true

            Disable-ProcessPrivilege -Name "SeInvalid", "SeCreateTokenPrivilege", $test_privilege1 -ErrorVariable err -ErrorAction SilentlyContinue
            $actual = Get-ProcessPrivilege -Name $test_privilege1
            $actual.Enabled | Should -Be  $false
            $err.Count | Should -Be 2
            $err[0].CategoryInfo.Category | Should -Be "ObjectNotFound"
            $err[0].Exception.Message | Should -Be "Invalid privilege name 'SeInvalid'"
            $err[1].CategoryInfo.Category | Should -Be "InvalidOperation"
            $err[1].Exception.Message | Should -Be "Cannot disable privilege 'SeCreateTokenPrivilege' as it is not set on the current process"
        }

        AfterEach {
            Enable-ProcessPrivilege -Name $test_privilege1, $test_privilege2
        }
    }
}
