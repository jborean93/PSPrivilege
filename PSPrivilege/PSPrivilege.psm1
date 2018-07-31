# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification="psprivilege_* vars are used in the cmdlets after loading")]
param()

# get public and private function definition files.
$public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

# dot source the files
foreach ($import in @($public + $private)) {
    try {
        . $import.FullName
    } catch {
        Write-Error -Message "Failed to import function $($import.FullName): $_"
    }
}
Import-PInvokeUtil

# TODO: find some way to enumerate these with an API call instead of hardcoding
# https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/privilege-constants
$psprivilege_privileges = @(
    "SeAssignPrimaryTokenPrivilege",
    "SeAuditPrivilege",
    "SeBackupPrivilege",
    "SeChangeNotifyPrivilege",
    "SeCreateGlobalPrivilege",
    "SeCreatePagefilePrivilege",
    "SeCreatePermanentPrivilege",
    "SeCreateSymbolicLinkPrivilege",
    "SeCreateTokenPrivilege",
    "SeDebugPrivilege",
    "SeEnableDelegationPrivilege",
    "SeImpersonatePrivilege",
    "SeIncreaseBasePriorityPrivilege",
    "SeIncreaseQuotaPrivilege",
    "SeIncreaseWorkingSetPrivilege",
    "SeLoadDriverPrivilege",
    "SeLockMemoryPrivilege",
    "SeMachineAccountPrivilege",
    "SeManageVolumePrivilege",
    "SeProfileSingleProcessPrivilege",
    "SeRelabelPrivilege",
    "SeRemoteShutdownPrivilege",
    "SeRestorePrivilege",
    "SeSecurityPrivilege",
    "SeShutdownPrivilege",
    "SeSyncAgentPrivilege",
    "SeSystemEnvironmentPrivilege",
    "SeSystemProfilePrivilege",
    "SeSystemtimePrivilege",
    "SeTakeOwnershipPrivilege",
    "SeTcbPrivilege",
    "SeTrustedCredManAccessPrivilege",
    "SeTrustedCredManAccessPrivilege",
    "SeUndockPrivilege"
)

# TODO: find a way to get the description from internal API
# https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/account-rights-constants
$psprivilege_rights = @{
    SeBatchLogonRight = "Log on as a batch job"
    SeDenyBatchLogonRight = "Deny log on as a batch job"
    SeDenyInteractiveLogonRight = "Deny log on locally"
    SeDenyNetworkLogonRight = "Deny access to this computer from the network"
    SeDenyRemoteInteractiveLogonRight = "Deny log on through Remote Desktop Services"
    SeDenyServiceLogonRight = "Deny log on as a service"
    SeInteractiveLogonRight = "Allow log on locally"
    SeNetworkLogonRight = "Access this computer from the network"
    SeRemoteInteractiveLogonRight = "Allow log on through Remote Desktop Services"
    SeServiceLogonRight = "Log on as a service"
}

Export-ModuleMember -Function $public.Basename
