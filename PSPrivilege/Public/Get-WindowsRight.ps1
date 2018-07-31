# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-WindowsRight {
    <#
    .SYNOPSIS
    Get the membership information about a privilege or right on the host
    specified.

    .DESCRIPTION
    This cmdlet will return information about a Windows privilege or right such
    as it's memberships and a description. This requires administrative
    privileges to run.

    .PARAMETER Name
    [String[]] Privilege(s) or Right(s) to get the information on. Will return
    all the privileges or rights if not set. See
    https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/privilege-constants
    for a list of valid privilege constants and
    https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/account-rights-constants
    for a list of valid account rights.

    .PARAMETER Account
    [System.Security.Principal.IdentityReference] Only return rights and
    privileges that the specified account is a member of.

    .PARAMETER ComputerName
    [String] The host to enumerate the membership info on, if not set then this
    will return information on the localhost. This uses the current user's
    credentials to authenticate with the remote host.

    .INPUTS
    [String] The privilege/right name(s) to get information for

    .OUTPUTS
    [PSCustomObject]
        Name - The name of the privilege or right
        ComputerName - The hostname the information is about
        Description - The description of the privilege or right
        Accounts - [System.Security.Principal.SecurityIdentifier[]] SIDs that have been granted the privilege/right

    .EXAMPLE
    # get all the local rights and privileges
    Get-WindowsRight

    # get only the specified rights
    Get-WindowsRight -Name SeDebugPrivilege, SeInteractiveLogonRight

    # get only the specified rights that are set on the account
    $admin_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-544"
    Get-WindowsRight -Account $admin_sid

    # get only the specified rights that are also set on the account specified
    $admin_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList "S-1-5-32-544"
    Get-WindowsRight -Name SeDebugPrivilege, SeInteractiveLogonRight -Account $admin_sid

    # get all rights on the remote host
    Get-WindowsRight -ComputerName server-name

    .NOTES
    This cmdlets opens up the LSA policy object with the POLICY_LOOKUP_NAMES,
    and POLICY_VIEW_LOCAL_INFORMATION access right. This will fail if the
    current user does not have these access rights.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][String[]]$Name,
        [Parameter(Position=1)][AllowNull()][System.Security.Principal.IdentityReference]$Account,
        [Parameter(Position=2)][String]$ComputerName
    )

    Begin {
        $computer_name = $ComputerName
        if (-not $computer_name) {
            $computer_name = $env:COMPUTERNAME
        }
        $policy = Open-LsaPolicy -AccessMask "LookupNames, ViewLocalInformation" -ComputerName $ComputerName

        if ($null -eq $Name -and $null -eq $Account) {
            $Name = $psprivilege_rights.Keys + $psprivilege_privileges
        } elseif ($null -ne $Account) {
            $account_rights = [String[]][PSPrivilege.Lsa]::EnumerateAccountRights($policy, $Account).ToArray()
            if ($null -ne $Name) {
                $account_rights = [Linq.Enumerable]::Intersect($account_rights, $Name)
            }
            $Name = $account_rights
        }
        Write-Verbose -Message "Getting details for the following rights: $($Name -join ", ")"
    }

    Process {
        foreach ($right in $Name) {
            if ($psprivilege_rights.ContainsKey($right)) {
                $description = $psprivilege_rights.$right
            } else {
                if ([PSPrivilege.Privileges]::CheckPrivilegeName($right)) {
                    $description = [PSPrivilege.Privileges]::GetPrivilegeDisplayName($right)
                } else {
                    Write-Warning -Message "Unknown right '$right', cannot get description"
                    $description = ""
                }
            }

            Write-Verbose -Message "Enumerating accounts with the privilege/right '$right'"
            try {
                $right_accounts = [PSPrivilege.Lsa]::EnumerateAccountsWithUserRight($policy, $right)
            } catch [ArgumentException] {
                Write-Error -Message "Invalid privilege or right name '$right'" -Category InvalidArgument
                continue
            }

            $obj = [PSCustomObject]@{
                PSTypeName = "PSPrivilege.Right"
                Name = $right
                ComputerName = $computer_name
                Description = $description
                Accounts = $right_accounts.ToArray()
            }
            $default_display_property_set = New-Object -TypeName System.Management.Automation.PSPropertySet -ArgumentList @(
                "DefaultDisplayPropertySet",
                [String[]]@("Name", "Accounts")
            )
            $obj_standard_members = [System.Management.Automation.PSMemberInfo[]]@($default_display_property_set)
            $obj | Add-Member MemberSet PSStandardMembers $obj_standard_members
            $obj
        }
    }

    End {
        Write-Verbose -Message "Closing opened LSA policy"
        $policy.Dispose()
    }
}