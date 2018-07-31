# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Remove-ProcessPrivilege {
    <#
    .SYNOPSIS
    Removes privilege(s) on the current process.

    .DESCRIPTION
    This cmdlet will remove a privilege on the current process. Once a
    privilege has been removed, it cannot be added back.

    .PARAMETER Name
    [String[]] Privilege(s) to remove. See
    https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/privilege-constants
    for a list of valid privilege constants.

    .INPUTS
    [String] The privilege name(s) to remove.

    .EXAMPLE
    # remove a privilege
    Remove-ProcessPrivilege -Name SeDebugPrivilege

    # remove multiple privileges
    Remove-ProcessPrivilege -Name SeUndockPrivilege, SeTimeZonePrivilege

    .NOTES
    If the privilege specified is an invalid constant, an error is written to
    the error stream.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Set-ProcessPrivilege has the ShouldProcess logic")]
    param(
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true)][String[]]$Name
    )

    Process {
        Set-ProcessPrivilege -Name $Name -Value $false -Remove
    }
}