# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Set-ProcessPrivilege {
    <#
    .SYNOPSIS
    Enables, disables, or removes privilege(s) on the current process.

    .DESCRIPTION
    This cmdlet will enable, disable, or remove a privilege on the current
    process. Only privileges that are set on the process can be enabled or
    disabled. Trying to enable/disable a removed privilege will result in an
    error.

    .PARAMETER Name
    [String[]] Privilege(s) to enable, disable, or remove. See
    https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/privilege-constants
    for a list of valid privilege constants.

    .PARAMETER Value
    [Boolean] Set to $true to enable, $false to disable, and $null to remove
    the privilege(s).

    .INPUTS
    [String] The privilege name(s) to set.

    .EXAMPLE
    # enable a privilege
    Set-ProcessPrivilege -Name SeDebugPrivilege -Value $true

    # enable multiple privileges
    Set-ProcessPrivilege -Name SeUndockPrivilege, SeTimeZonePrivilege -Value $true

    # disable a privilege
    Set-ProcessPrivilege -Name SeDebugPrivilege -Value $false

    # disable multiple privileges
    Set-ProcessPrivilege -Name SeUndockPrivilege, SeTimeZonePrivilege -Value $false

    # remove a privilege
    Set-ProcessPrivilege -Name SeDebugPrivilege -Value $null

    # remove multiple privileges
    Set-ProcessPrivilege -Name SeUndockPrivilege, SeTimeZonePrivilege -Value $null

    .NOTES
    If the privilege specified is an invalid constant, an error is written to
    the error stream. If the privilege constant is valid but not held on the
    current process, an error is written to the error stream if not trying to
    remove it.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true)][String[]]$Name,
        [Parameter(Position=1, Mandatory=$true)][Boolean]$Value,
        [Parameter()][Switch]$Remove
    )

    Begin {
        Write-Verbose -Message "Getting current process handle"
        $process_token = [PSPrivilege.Privileges]::GetCurrentProcess()

        Write-Verbose -Message "Getting privilege info for all privileges on the current process"
        $privilege_info = [PSPrivilege.Privileges]::GetAllPrivilegeInfo($process_token)

        $set_info = New-Object -TypeName 'System.Collections.Generic.Dictionary`2[[System.String], [System.Nullable`1[System.Boolean]]]'
        if ($Remove.IsPresent) {
            $action = "remove"
        } elseif ($Value -eq $true) {
            $action = "enable"
        } else {
            $action = "disable"
        }
    }

    Process {
        foreach ($privilege_name in $Name) {
            if (-not [PSPrivilege.Privileges]::CheckPrivilegeName($privilege_name)) {
                Write-Error -Message "Invalid privilege name '$privilege_name'" -Category ObjectNotFound
                continue
            } elseif (-not $privilege_info.ContainsKey($privilege_name)) {
                if (-not $Remove.IsPresent) {
                    Write-Error -Message "Cannot $action privilege '$privilege_name' as it is not set on the current process" -Category InvalidOperation
                }
                continue
            }

            $enabled = $privilege_info.$privilege_name.HasFlag([PSPrivilege.PrivilegeAttributes]::Enabled)
            if ($Remove.IsPresent) {
                Write-Verbose -Message "The privilege '$privilege_name' is current set, removing from process token"
                $set_info.Add($privilege_name, $null)
            } elseif ($enabled -eq $true -and $Value -eq $false) {
                Write-Verbose -Message "The privilege '$privilege_name' is currently enabled, setting new state to disabled"
                $set_info.Add($privilege_name, $false)
            } elseif ($enabled -eq $false -and $value -eq $true) {
                Write-Verbose -Message "The privilege '$privilege_name' is currently disabled, setting new state to enabled"
                $set_info.Add($privilege_name, $true)
            } else {
                Write-Verbose -Message "The privilege '$privilege_name' is already $($action)d, no action necessary"
            }
        }
    }

    End {
        if ($set_info.Count -gt 0) {
            Write-Verbose -Message "Setting token privileges on the current process"
            if ($PSCmdlet.ShouldProcess($set_info.Keys, "$action the specified privilege(s)")) {
                $null = [PSPrivilege.Privileges]::SetTokenPrivileges($process_token, $set_info)
            }
        }
    }
}