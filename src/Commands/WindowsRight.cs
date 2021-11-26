using Microsoft.Win32.SafeHandles;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Language;
using System.Runtime.InteropServices;
using System.Security.Principal;

namespace PSPrivilege.Commands
{
    internal class PrivilegeAndRightCompletor : IArgumentCompleter
    {
        public IEnumerable<CompletionResult> CompleteArgument(string commandName, string parameterName,
            string wordToComplete, CommandAst commandAst, IDictionary fakeBoundParameters)
        {
            return PrivilegeHelper.ALL_PRIVILEGES
                .Concat(Lsa.ALL_RIGHTS.Keys)
                .Where(p => p.StartsWith(wordToComplete, true, CultureInfo.InvariantCulture))
                .Select(p => ProcessPrivilege(p));
        }

        private CompletionResult ProcessPrivilege(string privilege)
        {
            string displayName;
            if (Lsa.ALL_RIGHTS.ContainsKey(privilege))
                displayName = Lsa.ALL_RIGHTS[privilege];
            else
                displayName = PrivilegeHelper.GetPrivilegeDisplayName(privilege);

            return new CompletionResult(privilege, privilege, CompletionResultType.ParameterValue, displayName);
        }
    }

    public abstract class WindowsRightCmdlet : PSCmdlet
    {
        internal SafeHandle _lsa = new SafeWaitHandle(IntPtr.Zero, false);

        [Parameter()]
        public string ComputerName { get; set; } = "";

        internal abstract LsaPolicyAccessMask AccessMask { get; }

        protected override void BeginProcessing()
        {
            WriteVerbose($"Opening handle to LSA with {AccessMask}");
            _lsa = Lsa.OpenPolicy(ComputerName, AccessMask);
        }

        protected override void EndProcessing()
        {
            WriteVerbose("Closing opened LSA policy");
            _lsa.Dispose();
        }
    }

    public abstract class AddRemoveWindowsRightCmdlet : WindowsRightCmdlet
    {
        private readonly Dictionary<SecurityIdentifier, List<string>> _setInfo =
            new Dictionary<SecurityIdentifier, List<string>>();

        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true
        )]
        [ArgumentCompleter(typeof(PrivilegeAndRightCompletor))]
        [ValidateNotNullOrEmpty]
        public string[] Name { get; set; } = Array.Empty<string>();

        [Parameter(
            Mandatory = true,
            Position = 1
        )]
        [ValidateNotNullOrEmpty]
        public IdentityReference[] Account { get; set; } = Array.Empty<IdentityReference>();

        internal delegate void ActionDelegate(SafeHandle lsa, SecurityIdentifier sid, string[] rights);

        internal abstract ActionDelegate ActionRunner { get; }

        internal abstract string Action { get; }

        internal abstract SecurityIdentifier[] CalculateChanges(List<SecurityIdentifier> existingMembers);

        protected override void ProcessRecord()
        {
            foreach (string right in Name)
            {
                List<SecurityIdentifier> actualMembers;
                try
                {
                    actualMembers = Lsa.EnumerateAccountsWithUserRight(_lsa, right);
                }
                catch (ArgumentException e)
                {
                    WriteError(new ErrorRecord(e, "InvalidPrivilegeRightName", ErrorCategory.InvalidArgument, right));
                    continue;
                }

                SecurityIdentifier[] toChange = CalculateChanges(actualMembers);
                foreach (SecurityIdentifier id in toChange)
                {
                    if (!_setInfo.ContainsKey(id))
                        _setInfo[id] = new List<string>();

                    _setInfo[id].Add(right);
                }
            }
        }

        protected override void EndProcessing()
        {
            foreach (KeyValuePair<SecurityIdentifier, List<string>> kvp in _setInfo)
            {
                WriteVerbose($"{Action} missing privileges/rights for the account '{kvp.Key.Value}'");
                if (ShouldProcess(kvp.Key.Value, $"{Action} account rights " + String.Join(", ", kvp.Value)))
                    ActionRunner(_lsa, kvp.Key, kvp.Value.ToArray());
            }
            base.EndProcessing();
        }
    }

    [Cmdlet(
        VerbsCommon.Add, "WindowsRight",
        SupportsShouldProcess = true
    )]
    public class AddWindowRight : AddRemoveWindowsRightCmdlet
    {
        internal override LsaPolicyAccessMask AccessMask => LsaPolicyAccessMask.LookupNames |
            LsaPolicyAccessMask.CreateAccount | LsaPolicyAccessMask.ViewLocalInformation;

        internal override string Action => "Add";

        internal override ActionDelegate ActionRunner => Lsa.AddAccountRights;

        internal override SecurityIdentifier[] CalculateChanges(List<SecurityIdentifier> existingMembers)
        {
            return Account
                .Select(a => a.Translate(typeof(SecurityIdentifier)))
                .Cast<SecurityIdentifier>()
                .Except(existingMembers)
                .ToArray();
        }
    }

    [Cmdlet(
        VerbsCommon.Clear, "WindowsRight",
        SupportsShouldProcess = true
    )]
    public class ClearWindowsRight : WindowsRightCmdlet
    {
        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "Name"
        )]
        [ArgumentCompleter(typeof(PrivilegeAndRightCompletor))]
        [ValidateNotNullOrEmpty]
        public string[] Name { get; set; } = Array.Empty<string>();

        [Parameter(
            Mandatory = true,
            Position = 0,
            ParameterSetName = "Account"
        )]
        [ValidateNotNullOrEmpty]
        public IdentityReference[] Account { get; set; } = Array.Empty<IdentityReference>();

        internal override LsaPolicyAccessMask AccessMask => ParameterSetName == "Name"
            ? LsaPolicyAccessMask.LookupNames | LsaPolicyAccessMask.ViewLocalInformation
            : LsaPolicyAccessMask.LookupNames;

        protected override void ProcessRecord()
        {
            if (ParameterSetName == "Name")
                ProcessName();
            else
                ProcessAccount();
        }

        private void ProcessName()
        {
            foreach (string right in Name)
            {
                WriteVerbose($"Getting current membership for the privilege/right '{right}'");
                IdentityReference[] actualMembers;
                try
                {
                    actualMembers = Lsa.EnumerateAccountsWithUserRight(_lsa, right).ToArray();
                }
                catch (ArgumentException e)
                {
                    WriteError(new ErrorRecord(e, "InvalidPrivilegeRightName", ErrorCategory.InvalidArgument, right));
                    continue;
                }

                if (actualMembers.Length > 0)
                {
                    WriteVerbose($"Privilege/right '{right}' contains members, removing");
                    foreach (IdentityReference member in actualMembers)
                    {
                        if (ShouldProcess(member.Value, $"Remove from the rights {right}"))
                            Lsa.RemoveAccountRights(_lsa, member, new string[] { right });
                    }
                }
                else
                {
                    WriteVerbose($"Privilege/right '{right}' has no members, no action required");
                }
            }
        }

        private void ProcessAccount()
        {
            foreach (IdentityReference acct in Account)
            {
                WriteVerbose($"Getting current rights for '{acct.Value}'");
                string[] rights = Lsa.EnumerateAccountRights(_lsa, acct).ToArray();
                if (rights.Length > 0)
                {
                    WriteVerbose($"Removing all rights for account '{acct.Value}'");
                    if (ShouldProcess(acct.Value, "Remove all rights"))
                        Lsa.RemoveAllAccountRights(_lsa, acct);
                }
                else
                {
                    WriteVerbose($"Account '{acct.Value} does not have any rights, no action required");
                }
            }
        }
    }

    [Cmdlet(
        VerbsCommon.Get, "WindowsRight"
    )]
    [OutputType(typeof(Right))]
    public class GetWindowsRight : WindowsRightCmdlet
    {
        [Parameter(
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true
        )]
        [ArgumentCompleter(typeof(PrivilegeAndRightCompletor))]
        public string[] Name { get; set; } = Array.Empty<string>();

        [Parameter(
            Position = 1
        )]
        [AllowNull]
        public IdentityReference? Account { get; set; }

        [Parameter()]
        public Type IdentityType { get; set; } = typeof(SecurityIdentifier);

        internal override LsaPolicyAccessMask AccessMask => LsaPolicyAccessMask.LookupNames |
            LsaPolicyAccessMask.ViewLocalInformation;

        protected override void BeginProcessing()
        {
            base.BeginProcessing();

            if (String.IsNullOrWhiteSpace(ComputerName))
                ComputerName = Environment.GetEnvironmentVariable("COMPUTERNAME") ?? "localhost";
        }

        protected override void ProcessRecord()
        {
            // Will be invalid if it failed to be opened in begin.
            if (_lsa.IsInvalid)
                return;

            if (Account == null && Name.Length == 0)
            {
                Name = PrivilegeHelper.ALL_PRIVILEGES.Concat(Lsa.ALL_RIGHTS.Keys).ToArray();
            }
            else if (Account != null)
            {
                string[] accountRights = Lsa.EnumerateAccountRights(_lsa, Account).ToArray();
                if (Name.Length > 0)
                    accountRights = accountRights.Intersect(Name).ToArray();

                Name = accountRights;
            }

            WriteVerbose("Getting details for the following rights: " + String.Join(", ", Name));
            foreach (string right in Name)
            {
                string description = "";
                if (Lsa.ALL_RIGHTS.ContainsKey(right))
                    description = Lsa.ALL_RIGHTS[right];
                else if (PrivilegeHelper.CheckPrivilegeName(right))
                    description = PrivilegeHelper.GetPrivilegeDisplayName(right);
                else
                    WriteWarning($"Unknown right {right}, cannot get description");

                WriteVerbose($"Enumerating accounts with the privilege/rights '{right}'");
                IdentityReference[] rightAccounts;
                try
                {
                    rightAccounts = Lsa.EnumerateAccountsWithUserRight(_lsa, right)
                        .Select(i => TranslateIdentity(i, IdentityType))
                        .ToArray();
                }
                catch (ArgumentException e)
                {
                    WriteError(new ErrorRecord(e, "InvalidPrivilegeRightName", ErrorCategory.InvalidArgument, right));
                    continue;
                }

                WriteObject(new Right()
                {
                    Name = right,
                    ComputerName = ComputerName,
                    Description = description,
                    Accounts = rightAccounts,
                });
            }
        }

        private IdentityReference TranslateIdentity(IdentityReference id, Type idType)
        {
            try
            {
                return id.Translate(idType);
            }
            catch (IdentityNotMappedException e)
            {
                WriteWarning($"Failed to translate SID '{id.Value}' to {idType.Name}: {e.Message}");
                return id;
            }
        }
    }

    [Cmdlet(
        VerbsCommon.Remove, "WindowsRight",
        SupportsShouldProcess = true
    )]
    public class RemoveWindowRight : AddRemoveWindowsRightCmdlet
    {
        internal override LsaPolicyAccessMask AccessMask => LsaPolicyAccessMask.LookupNames |
            LsaPolicyAccessMask.ViewLocalInformation;

        internal override string Action => "Remove";

        internal override ActionDelegate ActionRunner => Lsa.RemoveAccountRights;

        internal override SecurityIdentifier[] CalculateChanges(List<SecurityIdentifier> existingMembers)
        {
            return Account
                .Select(a => a.Translate(typeof(SecurityIdentifier)))
                .Cast<SecurityIdentifier>()
                .Intersect(existingMembers)
                .ToArray();
        }
    }
}
