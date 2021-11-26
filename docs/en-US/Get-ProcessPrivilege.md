---
external help file: PSPrivilege.dll-Help.xml
Module Name: PSPrivilege
online version: github.com/jborean93/PSPrivilege/blob/main/docs/en-US/Get-ProcessPrivilege.md
schema: 2.0.0
---

# Get-ProcessPrivilege

## SYNOPSIS
Get information about privileges on the current process.

## SYNTAX

```
Get-ProcessPrivilege [[-Name] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Get information about privileges on the current process.
This cmdlet will return whether the privilege is enabled or disabled, or enabled by default of either a single privilege or all the privileges on the current process.

## EXAMPLES

### EXAMPLE 1: Get info on all the privileges on the current process
```powershell
PS C:\> Get-ProcessPrivilege
```

Returns information on all the privileges on the current process.

### EXAMPLE 2: Get info on a specific privilege
```powershell
PS C:\> Get-ProcessPrivilege -Name SeDebugPrivilege
```

Gets information about the `SeDebugPrivilege` on the current process.

## PARAMETERS

### -Name
Privilege(s) to get the information on.
Will return all the privileges if not set.
If not set then all privileges that are set on the current process will be returned
See related links for a list of privilege constants that can be used here.

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
The privilege name(s) to get information for

## OUTPUTS

### PSPrivilege.Privilege
Information about the requested privilege(s) on the current process. It includes the following properties:

- Name - The name of the privilege

- Description - The description of the privilege

- Enabled - Whether the privilege is currently enabled

- EnabledByDefault - Whether the privilege was enabled by default (does not mean it is currently enabled)

- Attributes - The raw PSPrivilege.Privilege attributes

- IsRemoved - Whether the privilege is removed from the token

## NOTES
If the privilege specified is an invalid constant, an error is written to the error stream.
If the privilege constant is valid but not held on the current process, the IsRemoved property is set to $true.

## RELATED LINKS

[Privileges](https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/privilege-constants)
