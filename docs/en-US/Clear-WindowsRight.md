---
external help file: PSPrivilege.dll-Help.xml
Module Name: PSPrivilege
online version: github.com/jborean93/PSPrivilege/blob/main/docs/en-US/Clear-WindowsRight.md
schema: 2.0.0
---

# Clear-WindowsRight

## SYNOPSIS
Clears privilege/right of an account.

## SYNTAX

### Name
```
Clear-WindowsRight [-Name] <String[]> [[-ComputerName] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Account
```
Clear-WindowsRight [-Account] <IdentityReference[]> [[-ComputerName] <String>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Clears all accounts in a privilege/right or all privilges/rights of an account.
This cmdlet will run on localhost by default but a remote host can be specified.
This requires administrative privileges to run.

## EXAMPLES

### EXAMPLE 1: Clear membership of a single privilege
```powershell
PS C:\> Clear-WindowsRight -Name SeDebugPrivilege
```

Removes all the accounts and groups that have been granted the `SeDebugPrivilege`.

### EXAMPLE 2: Clear rights of the specified identity
```powershell
PS C:\> $user = [System.Security.Principal.SecurityIdentifier]::new("S-1-5-32-545")
PS C:\> Clear-WindowsRight -Account $user
```

Removes the `User` group from all explicit rights or privileges it has been granted.
This won't affect any rights/privileges it already gets from nested memberships, just rights/privileges that have the `User` group explicitly.

## PARAMETERS

### -Account
Remove all the rights of the specified account(s).
This is mutually exclusive to the Name parameter.

```yaml
Type: IdentityReference[]
Parameter Sets: Account
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
The host to clear the rights on, if not set then this will run on the localhost.
This uses the current user's credentials to authenticate with the remote host.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Privilege(s) or Right(s) to clear all members off.
See related links for a list of privileges and account right constants that can be used here.
This is mutually exclusive to the Account parameter.

```yaml
Type: String[]
Parameter Sets: Name
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
The privilege/right name(s) to clear.

## OUTPUTS

### None
## NOTES
This cmdlets opens up the LSA policy object with the `POLICY_LOOKUP_NAMES` and `POLICY_VIEW_LOCAL_INFORMATION` access rights.
This will fail if the current user does not have these access rights.

## RELATED LINKS

[Privileges](https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/privilege-constants)
[Account Rights](https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/account-rights-constants)
