# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Clear-WindowsRight {
    <#
    .SYNOPSIS
    Clears all accounts in a privilege/right or all privilges/rights of an
    account.

    .DESCRIPTION
    This cmdlet will run on localhost by default but a remote host can be
    specified. This requires administrative privileges to run.

    .PARAMETER Name
    [String[]] Privilege(s) or Right(s) to clear all members off. See
    https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/privilege-constants
    for a list of valid privilege constants and
    https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/account-rights-constants
    for a list of valid account rights. This is mutually exclusive to the
    Account parameter.

    .PARAMETER Account
    [System.Security.Principal.IdentityReference[]] Remove all the rights of
    the specified account(s). This is mutually exclusive to the Name parameter.

    .PARAMETER ComputerName
    [String] The host to clear the rights on, if not set then this will run on
    the localhost. This uses the current user's credentials to authenticate
    with the remote host.

    .INPUTS
    [String] The privilege/right name(s) to clear.

    .EXAMPLE
    $user_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-545"
    $guest_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-546"

    # clear the membership of a single privilege
    Clear-WindowsRight -Name SeDebugPrivilege

    # clear the membership of multiple privileges
    Clear-WindowsRight -Name SeDebugPrivilege, SeInteractiveLogonRight

    # clear the rights of a single account
    Clear-WindowsRight -Account $user_sid

    # clear the rights of multiple accounts
    Clear-WindowsRight -Account $user_sid, $guest_sid

    .NOTES
    This cmdlets opens up the LSA policy object with the POLICY_LOOKUP_NAMES,
    and POLICY_VIEW_LOCAL_INFORMATION access right (if Name is used). This will
    fail if the current user does not have these access rights.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName="Name", Mandatory=$true)][String[]]$Name,
        [Parameter(Position=0, ParameterSetName="Account", Mandatory=$true)][System.Security.Principal.IdentityReference[]]$Account,
        [Parameter(Position=1)][String]$ComputerName
    )

    Begin {
        if ($PSCmdlet.ParameterSetName -eq "Name") {
            $access_mask = "LookupNames, ViewLocalInformation"
        } else {
            $access_mask = "LookupNames"
        }
        $policy = Open-LsaPolicy -AccessMask $access_mask -ComputerName $ComputerName
    }

    Process {
        if ($PSCmdlet.ParameterSetName -eq "Name") {
            foreach ($right in $Name) {
                Write-Verbose -Message "Getting current membership for the privilege/right '$right'"
                try {
                    $actual_members = [PSPrivilege.Lsa]::EnumerateAccountsWithUserRight($policy, $right)
                } catch [ArgumentException] {
                    Write-Error -Message "Invalid privilege or right name '$right'" -Category InvalidArgument
                    continue
                }

                if ($actual_members.Count -gt 0) {
                    Write-Verbose -Message "Privilege/right '$right' contains members, removing"
                    foreach ($member in $actual_members) {
                        if ($PSCmdlet.ShouldProcess($member, "Remove from the rights $($right -join ", ")")) {
                            [PSPrivilege.Lsa]::RemoveAccountRights($policy, $member, [String[]]@($right))
                        }
                    }
                } else {
                    Write-Verbose -Message "Privilege/right '$right' has no members, no action required"
                }
            }
        } elseif ($PSCmdlet.ParameterSetName -eq "Account") {
            Write-Verbose -Message "Running Clear-WindowsRight with the Account parameter set"
            foreach ($acct in $Account) {
                $rights = [PSPrivilege.Lsa]::EnumerateAccountRights($policy, $acct)
                if ($rights.Count -gt 0) {
                    Write-Verbose -Message "Removing all account rights of account"
                    if ($PSCmdlet.ShouldProcess($acct, "Remove all rights")) {
                        [PSPrivilege.Lsa]::RemoveAllAccountRights($policy, $acct)
                    }
                } else {
                    Write-Verbose -Message "Account does not have any rights, no action required"
                }
            }
        }
    }

    End {
        Write-Verbose -Message "Closing opened LSA policy"
        $policy.Dispose()
    }
}