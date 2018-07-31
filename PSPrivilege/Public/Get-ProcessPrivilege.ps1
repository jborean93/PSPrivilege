# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-ProcessPrivilege {
    <#
    .SYNOPSIS
    Get information about privileges on the current process.

    .DESCRIPTION
    This cmdlet will return whether the privilege is enabled or disabled,
    or enabled by default of either a single privilege or all the privileges
    on the current process.

    .PARAMETER Name
    [String[]] Privilege(s) to get the information on. Will return all the
    privileges if not set. See https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/privilege-constants
    for a list of valid privilege constants. If not set then all privileges
    that are set on the current process will be returned

    .INPUTS
    [String] The privilege name(s) to get information for

    .OUTPUTS
    [PSCustomObject]
        Name - The name of the privilege
        Description - The description of the privilege
        Enabled - Whether the privilege is currently enabled
        EnabledByDefault - Whether the privilege was enabled by default (does not mean it is currently enabled)
        Attributes - The raw PSPrivilege.Privilege attributes (see Import-PInvokeUtils)
        IsRemoved - Whether the privilege is removed from the token

    .EXAMPLE
    # get info on all the privileges on the current process
    Get-ProcessPrivilege

    # get info on a single privilege
    Get-ProcessPrivilege -Name SeDebugPrivilege

    # get info on multiple privileges
    Get-ProcessPrivilege -Name SeShutdownPrivilege, SeTimeZonePrivilege

    # get info on a privilege using pipeline input
    "SeAuditPrivilege" | Get-ProcessPrivilege
    [PSCustomObject]@{Name="SeBackupPrivilege"} | Get-ProcessPrivilege

    .NOTES
    If the privilege specified is an invalid constant, an error is written to
    the error stream. If the privilege constant is valid but not held on the
    current process, The IsRemoved property is set to $true.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][String[]]$Name
    )

    Process {
        Write-Verbose -Message "Getting current process handle"
        $process_token = [PSPrivilege.Privileges]::GetCurrentProcess()

        Write-Verbose -Message "Getting privilege info for all privileges on the current process"
        $privilege_info = [PSPrivilege.Privileges]::GetAllPrivilegeInfo($process_token)

        if ($null -eq $Name) {
            Write-Verbose -Message "Getting info on all the privielges on the current process"
            $Name = $privilege_info.Keys
        }

        foreach ($privilege_name in $Name) {
            if (-not [PSPrivilege.Privileges]::CheckPrivilegeName($privilege_name)) {
                Write-Error -Message "Invalid privilege name '$privilege_name'" -Category ObjectNotFound
                continue
            }

            $description = [PSPrivilege.Privileges]::GetPrivilegeDisplayName($privilege_name)
            $enabled = $false
            $enabled_by_default = $false
            $attributes = $null
            $is_removed= $false
            if ($privilege_info.ContainsKey($privilege_name)) {
                $enabled = $privilege_info.$privilege_name.HasFlag([PSPrivilege.PrivilegeAttributes]::Enabled)
                $enabled_by_default = $privilege_info.$privilege_name.HasFlag([PSPrivilege.PrivilegeAttributes]::EnabledByDefault)
                $attributes = $privilege_info.$privilege_name
            } else {
                $is_removed = $true
            }

            [PSCustomObject]@{
                PSTypeName = "PSPrivilege.Privilege"
                Name = $privilege_name
                Description = $description
                Enabled = $enabled
                EnabledByDefault = $enabled_by_default
                Attributes = $attributes
                IsRemoved = $is_removed
            }
        }
    }
}