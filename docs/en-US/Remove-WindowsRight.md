---
external help file: PSPrivilege.dll-Help.xml
Module Name: PSPrivilege
online version: github.com/jborean93/PSPrivilege/blob/main/docs/en-US/Remove-WindowsRight.md
schema: 2.0.0
---

# Remove-WindowsRight

## SYNOPSIS
Removes privilege/right account membership.

## SYNTAX

```
Remove-WindowsRight [-Name] <String[]> [-Account] <IdentityReference[]> [[-ComputerName] <String>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Remove an account from the privilege/right membership on the host specified.
This cmdlet will run on localhost by default but a remote host can be specified.
This requires administrative privileges to run.

## EXAMPLES

### EXAMPLE 1: Remove privilege from a single account
```powershell
PS C:\> $admin = [System.Security.Principal.SecurityIdentifier]::new("S-1-5-32-544")
PS C:\> Remove-WindowsRight -Name SeDebugPrivilege -Account $admin
```

Removes the local Administrators group from `SeDebugPrivilege` membership.

## PARAMETERS

### -Account
Remove the accounts specified from the privilege/right.

```yaml
Type: IdentityReference[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
The host to remove the accounts from, if not set then this will run on the localhost.
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

### -Name
Privilege(s) or Right(s) to remove the account from.
See related links for a list of privileges and account right constants that can be used here.

```yaml
Type: String[]
Parameter Sets: (All)
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
The privilege/right name(s) to remove the accounts from.

## OUTPUTS

### None
## NOTES
This cmdlets opens up the LSA policy object with the `POLICY_LOOKUP_NAMES`, and `POLICY_VIEW_LOCAL_INFORMATION` access rights.
This will fail if the current user does not have these access rights.

## RELATED LINKS

[Privileges](https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/privilege-constants)
[Account Rights](https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/account-rights-constants)
