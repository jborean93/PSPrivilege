# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

. ([IO.Path]::Combine($PSScriptRoot, 'common.ps1'))

# these tests can only run once in 1 process as once a privilege is removed
# it cannot be added back in
Describe "$module_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Removes a privilege' {
            $pre_state = Get-ProcessPrivilege -Name "SeChangeNotifyPrivilege"
            $pre_state.IsRemoved | Should -Be $false

            Remove-ProcessPrivilege -Name "SeChangeNotifyPrivilege"
            $res = Get-ProcessPrivilege -Name "SeChangeNotifyPrivilege"
            $res.IsRemoved | Should -Be $true

            Remove-ProcessPrivilege -Name "SeChangeNotifyPrivilege" -ErrorAction SilentlyContinue -ErrorVariable err
            $err.Count | Should -Be 0
        }
    }
}
