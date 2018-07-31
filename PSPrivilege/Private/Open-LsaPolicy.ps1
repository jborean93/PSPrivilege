# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Open-LsaPolicy {
    <#
    .SYNOPSIS
    Opens the LSA Policy object on the server specified.

    .DESCRIPTION
    This cmdlet will return an opened handle of an LSA policy object either
    on the localhost host or a remote server. This requires administrative
    privileges to run.

    .PARAMETER AccessMask
    [String] A comma separate string of the [PSPrivilege.LsaPolicyAccessMask]
    used as part of the connection.

    .PARAMETER ComputerName
    [String] The host to connect to, if not set then this will open the policy
    on the localhost. This uses the current user's credentials to authenticate
    with the remote host.

    .OUTPUTS
    [PSPrivilege.SafeLsaHandle] The opened handle.

    .EXAMPLE
    Open-LsaPolicy -AccessMask "LookupNames, ViewLocalInformation"

    .NOTES
    Once finished with the policy, .Dipose() should be called to close the
    connection and free up any system resources.
    #>
    [CmdletBinding()]
    [OutputType([PSPrivilege.SafeLsaHandle])]
    param(
        [Parameter(Mandatory=$true)][String]$AccessMask,
        [Parameter()][String]$ComputerName
    )

    $computer_name = $ComputerName
    if ($null -ne $computer_name) {
        $computer_name = $env:COMPUTERNAME
    }
    $access_mask = [PSPrivilege.LsaPolicyAccessMask]$AccessMask
    Write-Verbose -Message "Opening LSA Policy on '$computer_name' with access mask '$AccessMask'"
    return [PSPrivilege.Lsa]::OpenPolicy($ComputerName, $access_mask)
}