# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Add-WindowsRight {
    <#
    .SYNOPSIS
    Add an account to the privilege/right membership on the host specified.

    .DESCRIPTION
    This cmdlet will run on localhost by default but a remote host can be
    specified. This requires administrative privileges to run.

    .PARAMETER Name
    [String[]] Privilege(s) or Right(s) to add the account to. See
    https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/privilege-constants
    for a list of valid privilege constants and
    https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/account-rights-constants
    for a list of valid account rights.

    .PARAMETER Account
    [System.Security.Principal.IdentityReference[]] Add the accounts specified
    to the privilege/right.

    .PARAMETER ComputerName
    [String] The host to add the accounts on, if not set then this will run on
    the localhost. This uses the current user's credentials to authenticate
    with the remote host.

    .INPUTS
    [String] The privilege/right name(s) to add the accounts to.

    .EXAMPLE
    $admin_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-544"
    $user_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-545"

    # add a privilege to a single account
    Add-WindowsRight -Name SeDebugPrivilege -Account $admin_sid

    # add a privilege to multiple accounts
    Add-WindowsRight -Name SeInteractiveLogonRight -Account $admin_sid, $user_sid

    # add multiple privileges to a single account
    Add-WindowsRight -Name SeDebugPrivilege, SeInteractiveLogonRight -Account $admin_sid

    # add multiple privileges to multiple accounts
    Add-WindowsRight -Name SeDebugPrivilege, SeInteractiveLogonRight -Account $admin_sid, $user_sid

    # add a privilege to an account on a remote host
    Add-WindowsRight -Name SeDebugPrivilege -Account $admin_sid -ComputerName server-remote

    .NOTES
    This cmdlets opens up the LSA policy object with the POLICY_LOOKUP_NAMES,
    POLICY_VIEW_LOCAL_INFORMATION, and POLICY_CREATE_ACCOUNT access right. This
    will fail if the current user does not have these access rights.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true)][String[]]$Name,
        [Parameter(Position=1, Mandatory=$true)][System.Security.Principal.IdentityReference[]]$Account,
        [Parameter(Position=2)][String]$ComputerName
    )

    Begin {
        $policy = Open-LsaPolicy -AccessMask "LookupNames, CreateAccount, ViewLocalInformation" -ComputerName $ComputerName
        $actual_membership = @{}
        $new_members = [String[]]@($Account | ForEach-Object { $_.Translate([System.Security.Principal.SecurityIdentifier]).ToString() })
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

            $accounts_to_add = [String[]]@([Linq.Enumerable]::Except($new_members, $actual_members))
            $actual_membership.$right = $accounts_to_add
        }
    }

    End {
        foreach ($acct in $Account) {
            $sid = $acct.Translate([System.Security.Principal.SecurityIdentifier]).ToString()
            $rights = ($actual_membership.GetEnumerator() | Where-Object { $_.Value.Contains($sid) }).Name
            if ($rights.Count -gt 0) {
                Write-Verbose -Message "Adding missing privileges/rights for the account '$sid'"
                if ($PSCmdlet.ShouldProcess($sid, "Add the account rights $($rights -join ", ")")) {
                    [PSPrivilege.Lsa]::AddAccountRights($policy, $acct, $rights)
                }
            } else {
                Write-Verbose -Message "No action required for account '$sid'"
            }
        }

        Write-Verbose -Message "Closing opened LSA policy"
        $policy.Dispose()
    }
}