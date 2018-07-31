# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Remove-WindowsRight {
    <#
    .SYNOPSIS
    Remove an account from the privilege/right membership on the host
    specified.

    .DESCRIPTION
    This cmdlet will run on localhost by default but a remote host can be
    specified. This requires administrative privileges to run.

    .PARAMETER Name
    [String[]] Privilege(s) or Right(s) to remove the account from. See
    https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/privilege-constants
    for a list of valid privilege constants and
    https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/account-rights-constants
    for a list of valid account rights.

    .PARAMETER Account
    [System.Security.Principal.IdentityReference[]] Remove the accounts
    specified from the privilege/right.

    .PARAMETER ComputerName
    [String] The host to remove the accounts from, if not set then this will
    run on the localhost. This uses the current user's credentials to
    authenticate with the remote host.

    .INPUTS
    [String] The privilege/right name(s) to remove the accounts from.

    .EXAMPLE
    $admin_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-544"
    $user_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-545"

    # remove a privilege from a single account
    Remove-WindowsRight -Name SeDebugPrivilege -Account $admin_sid

    # remove a privilege from multiple accounts
    Remove-WindowsRight -Name SeInteractiveLogonRight -Account $admin_sid, $user_sid

    # remove multiple privileges from a single account
    Remove-WindowsRight -Name SeDebugPrivilege, SeInteractiveLogonRight -Account $admin_sid

    # remove multiple privileges from multiple accounts
    Remove-WindowsRight -Name SeDebugPrivilege, SeInteractiveLogonRight -Account $admin_sid, $user_sid

    # remove a privilege from an account on a remote host
    Remove-WindowsRight -Name SeDebugPrivilege -Account $admin_sid -ComputerName server-remote

    .NOTES
    This cmdlets opens up the LSA policy object with the POLICY_LOOKUP_NAMES,
    and POLICY_VIEW_LOCAL_INFORMATION access rights. This will fail if the
    current user does not have these access rights.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true)][String[]]$Name,
        [Parameter(Position=1, Mandatory=$true)][System.Security.Principal.IdentityReference[]]$Account,
        [Parameter(Position=2)][String]$ComputerName
    )

    Begin {
        $policy = Open-LsaPolicy -AccessMask "LookupNames, ViewLocalInformation" -ComputerName $ComputerName
        $actual_membership = @{}
        $remove_members = [String[]]@($Account | ForEach-Object { $_.Translate([System.Security.Principal.SecurityIdentifier]).ToString() })
    }

    Process {
        foreach ($right in $Name) {
            Write-Verbose -Message "Getting current membership for the privilege/right '$right'"
            try {
                $actual_members = [String[]]@([PSPrivilege.Lsa]::EnumerateAccountsWithUserRight($policy, $right) | ForEach-Object { $_.ToString() })
            } catch [ArgumentException] {
                Write-Error -Message "Invalid privilege or right name '$right'" -Category InvalidArgument
                continue
            }

            $accounts_to_remove = [String[]]@([Linq.Enumerable]::Intersect($remove_members, $actual_members))
            $actual_membership.$right = $accounts_to_remove
        }
    }

    End {
        foreach ($acct in $Account) {
            $sid = $acct.Translate([System.Security.Principal.SecurityIdentifier]).ToString()
            $rights = ($actual_membership.GetEnumerator() | Where-Object { $_.Value.Contains($sid) }).Name
            if ($rights.Count -gt 0) {
                Write-Verbose -Message "Removing privileges/rights for the account '$sid'"
                if ($PSCmdlet.ShouldProcess($sid, "Remove the account rights $($rights -join ", ")")) {
                    [PSPrivilege.Lsa]::RemoveAccountRights($policy, $acct, $rights)
                }
            } else {
                Write-Verbose -Message "No action required for account '$sid'"
            }
        }

        Write-Verbose -Message "Closing opened LSA policy"
        $policy.Dispose()
    }
}