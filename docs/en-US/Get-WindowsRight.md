---
external help file: PSPrivilege.dll-Help.xml
Module Name: PSPrivilege
online version: github.com/jborean93/PSPrivilege/blob/main/docs/en-US/Get-WindowsRight.md
schema: 2.0.0
---

# Get-WindowsRight

## SYNOPSIS
Get the membership information about a privilege or right on the host specified.

## SYNTAX

```
Get-WindowsRight [[-Name] <String[]>] [[-Account] <IdentityReference>] [-IdentityType <Type>]
 [[-ComputerName] <String>] [<CommonParameters>]
```

## DESCRIPTION
This cmdlet will return information about a Windows privilege or right such as it's memberships and a description.
This requires administrative privileges to run.

## EXAMPLES

### EXAMPLE 1: Get membership info on all local rights and privileges
```powershell
PS C:\> Get-WindowsRight
```

Get the membership information about all the privileges and rights on the localhost.

### EXAMPLE 2: Get membership for specific rights
```powershell
PS C:\> Get-WindowsRight -Name SeDebugPrivilege, SeInteractiveLogonRight
```

Get the membership information about the `SeDebugPrivilege` and `SeInteractiveLogonRight`.

### EXAMPLE 3: Get rights and privilege information that a specific account has
```powershell
PS C:\> $admin = [System.Security.Principal.SecurityIdentifier]::new("S-1-5-32-544")
PS C:\> Get-WindowsRight -Account $admin
```

Gets the rights and privileges that the local Administrators group is set for.

### EXAMPLE 4: Output accounts as an NTAccount
```powershell
PS C:\> Get-WindowsRight -Name SeDebugPrivilege -IdentityType ([System.Security.Principal.NTAccount])
```

Gets the accounts that have the `SeDebugPrivilege` and displays the `Account` property as an `NTAccount` value rather than a SID.

## PARAMETERS

### -Account
Only return rights and privileges that the specified account is a member of.

```yaml
Type: IdentityReference
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
The host to enumerate the membership info on, if not set then this will return information on the localhost.
This uses the current user's credentials to authenticate with the remote host.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IdentityType
Change the type used for the `Account` output type.
The default is `[System.Security.Principal.SecurityIdentifier]` which represents the Security Identifier (SID) of each account.
Can be set to `[System.Security.Principal.NTAccount]` to display a human readable representation of the account.
If the SID fails to be translated to the requested type a warning will be emitted and the output will continue to be a `SID`.

```yaml
Type: Type
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Privilege(s) or Right(s) to get the information on.
Will return all the privileges or rights if not set.
See related links for a list of privileges and account right constants that can be used here.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
The privilege/right name(s) to get information for

## OUTPUTS

### Privilege.Right
Information about the requested privilege/right(s). It includes the following properties:

- Name - The name of the privilege or right

- ComputerName - The hostname the information is from

- Description - The description of the privilege or right

- Accounts - [System.Security.Principal.IdentityReference[]] Accounts that have been granted the privilege/right, the type is based on the value of `-IdentityType`

## NOTES
This cmdlets opens up the LSA policy object with the `POLICY_LOOKUP_NAMES`, and `POLICY_VIEW_LOCAL_INFORMATION` access right.
This will fail if the current user does not have these access rights.

## RELATED LINKS

[Privileges](https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/privilege-constants)
[Account Rights](https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/account-rights-constants)
