# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Enable-ProcessPrivilege {
    <#
    .SYNOPSIS
    Enables privilege(s) on the current process.

    .DESCRIPTION
    This cmdlet will enable a privilege on the current process. Only
    privileges that are set on the process can be enabled, privileges that are
    removed will result in an error.

    .PARAMETER Name
    [String[]] Privilege(s) to enable. See
    https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/privilege-constants
    for a list of valid privilege constants.

    .INPUTS
    [String] The privilege name(s) to enable.

    .EXAMPLE
    # enable a privilege
    Enable-ProcessPrivilege -Name SeDebugPrivilege

    # enable multiple privileges
    Enable-ProcessPrivilege -Name SeUndockPrivilege, SeTimeZonePrivilege

    .NOTES
    If the privilege specified is an invalid constant, an error is written to
    the error stream. If the privilege constant is valid but not held on the
    current process, an error is written to the error stream.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Set-ProcessPrivilege has the ShouldProcess logic")]
    param(
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true)][String[]]$Name
    )

    Process {
        Set-ProcessPrivilege -Name $Name -Value $true
    }
}