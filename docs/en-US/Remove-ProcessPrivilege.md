---
external help file: PSPrivilege.dll-Help.xml
Module Name: PSPrivilege
online version: github.com/jborean93/PSPrivilege/blob/main/docs/en-US/Enable-ProcessPrivilege.md
schema: 2.0.0
---

# Remove-ProcessPrivilege

## SYNOPSIS
Removes privilege(s) on the current process.

## SYNTAX

```
Remove-ProcessPrivilege [-Name] <String[]> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Removes the privileges specified on the current process.
This cmdlet will remove a privilege on the current process.
Once a privilege has been removed, it cannot be added back.

## EXAMPLES

### EXAMPLE 1: Remove the SeDebugPrivilege
```powershell
PS C:\> Remove-ProcessPrivilege -Name SeDebugPrivilege
```

Removes the `SeDebugPrivilege` from the current process.

## PARAMETERS

### -Name
Privilege(s) to remove.
See related links for a list of privilege constants that can be used here.

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
The privilege name(s) to remove.

## OUTPUTS

### None
## NOTES
If the privilege specified is an invalid constant, an error is written to the error stream.

## RELATED LINKS

[Privileges](https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/privilege-constants)
