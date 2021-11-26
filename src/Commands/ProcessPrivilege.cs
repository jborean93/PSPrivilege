using Microsoft.Win32.SafeHandles;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Language;
using System.Runtime.InteropServices;

namespace PSPrivilege.Commands
{
    internal class PrivilegeCompletor : IArgumentCompleter
    {
        public IEnumerable<CompletionResult> CompleteArgument(string commandName, string parameterName,
            string wordToComplete, CommandAst commandAst, IDictionary fakeBoundParameters)
        {
            return PrivilegeHelper.ALL_PRIVILEGES
                .Where(p => p.StartsWith(wordToComplete, true, CultureInfo.InvariantCulture))
                .Select(p => ProcessPrivilege(p));
        }

        private CompletionResult ProcessPrivilege(string privilege)
        {
            string displayName = PrivilegeHelper.GetPrivilegeDisplayName(privilege);
            return new CompletionResult(privilege, privilege, CompletionResultType.ParameterValue, displayName);
        }
    }

    [Cmdlet(
        VerbsLifecycle.Disable, "ProcessPrivilege",
        SupportsShouldProcess = true
    )]
    public class DisableProcessPrivilege : ActionProcessPrivilege
    {
        internal override string Action => "disable";
    }

    [Cmdlet(
        VerbsLifecycle.Enable, "ProcessPrivilege",
        SupportsShouldProcess = true
    )]
    public class EnableProcessPrivilege : ActionProcessPrivilege
    {
        internal override string Action => "enable";
    }

    [Cmdlet(
        VerbsCommon.Get, "ProcessPrivilege"
    )]
    [OutputType(typeof(Privilege))]
    public class GetProcessPrivilege : PSCmdlet
    {
        [Parameter(
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true
        )]
        [ArgumentCompleter(typeof(PrivilegeCompletor))]
        public string[] Name { get; set; } = Array.Empty<string>();

        protected override void ProcessRecord()
        {
            WriteVerbose("Getting current process handle");
            using SafeHandle processToken = PrivilegeHelper.GetCurrentProcess();

            WriteVerbose("Getting privilege info for all privileges on the current process");
            Dictionary<string, PrivilegeAttributes> privilegeInfo = PrivilegeHelper.GetAllPrivilegeInfo(processToken);

            if (Name.Length == 0)
                Name = privilegeInfo.Keys.ToArray();

            foreach (string privName in Name)
            {
                if (!PrivilegeHelper.CheckPrivilegeName(privName))
                {
                    ItemNotFoundException exp = new ItemNotFoundException($"Invalid privilege name '{privName}'");
                    WriteError(new ErrorRecord(exp, "PrivilegeNotFound", ErrorCategory.ObjectNotFound, privName));
                    continue;
                }

                string description = PrivilegeHelper.GetPrivilegeDisplayName(privName);
                bool enabled = false;
                bool enableByDefault = false;
                PrivilegeAttributes attr = PrivilegeAttributes.Removed;
                bool isRemoved = true;

                if (privilegeInfo.ContainsKey(privName))
                {
                    attr = privilegeInfo[privName];
                    enabled = (attr & PrivilegeAttributes.Enabled) != 0;
                    enableByDefault = (attr & PrivilegeAttributes.EnabledByDefault) != 0;
                    isRemoved = false;
                }

                WriteObject(new Privilege()
                {
                    Name = privName,
                    Description = description,
                    Enabled = enabled,
                    EnabledByDefault = enableByDefault,
                    Attributes = attr,
                    IsRemoved = isRemoved,
                });
            }
        }
    }

    [Cmdlet(
        VerbsCommon.Remove, "ProcessPrivilege",
        SupportsShouldProcess = true
    )]
    public class RemoveProcessPrivilege : ActionProcessPrivilege
    {
        internal override string Action => "remove";
    }

    public abstract class ActionProcessPrivilege : PSCmdlet
    {
        private SafeHandle _process = new SafeWaitHandle(IntPtr.Zero, false);
        private readonly Dictionary<string, bool?> _setInfo = new Dictionary<string, bool?>();
        private Dictionary<string, PrivilegeAttributes> _privInfo = new Dictionary<string, PrivilegeAttributes>();

        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true
        )]
        [ArgumentCompleter(typeof(PrivilegeCompletor))]
        public string[] Name { get; set; } = Array.Empty<string>();

        internal abstract string Action { get; }

        protected override void BeginProcessing()
        {
            WriteVerbose("Getting current process handle");
            _process = PrivilegeHelper.GetCurrentProcess();

            WriteVerbose("Getting privilege info for all privileges on the current process");
            _privInfo = PrivilegeHelper.GetAllPrivilegeInfo(_process);
        }

        protected override void ProcessRecord()
        {
            foreach (string privName in Name)
            {
                if (!PrivilegeHelper.CheckPrivilegeName(privName))
                {
                    ItemNotFoundException exp = new ItemNotFoundException($"Invalid privilege name '{privName}'");
                    WriteError(new ErrorRecord(exp, "PrivilegeNotFound", ErrorCategory.ObjectNotFound, privName));
                    continue;
                }
                else if (!_privInfo.ContainsKey(privName))
                {
                    if (Action == "remove")
                    {
                        WriteVerbose($"The privilege '{privName}' is already removed, no action necessary");
                    }
                    else
                    {
                        InvalidOperationException exp = new InvalidOperationException(
                            $"Cannot {Action} privilege '{privName}' as it is not set on the current process");
                        WriteError(new ErrorRecord(exp, "", ErrorCategory.InvalidOperation, privName));
                    }
                    continue;
                }

                bool enabled = (_privInfo[privName] & PrivilegeAttributes.Enabled) != 0;
                if (Action == "remove")
                {
                    WriteVerbose($"The privilege '{privName}' is set, removing from process token");
                    _setInfo[privName] = null;
                }
                else if (enabled && Action == "disable")
                {
                    WriteVerbose($"The privilege '{privName}' is enabled, setting new state to disabled");
                    _setInfo[privName] = false;
                }
                else if (!enabled && Action == "enable")
                {
                    WriteVerbose($"The privilege '{privName}' is disabled, setting new state to enabled");
                    _setInfo[privName] = true;
                }
                else
                {
                    WriteVerbose($"The privilege '{privName}' is already {Action}d, no action necessary");
                }
            }
        }

        protected override void EndProcessing()
        {
            if (_setInfo.Count > 0)
            {
                WriteVerbose("Setting token privileges on the current process");
                if (ShouldProcess(String.Join(", ", _setInfo.Keys), $"{Action} the specified privilege(s)"))
                    PrivilegeHelper.SetTokenPrivileges(_process, _setInfo);
            }
            _process.Dispose();
        }
    }
}
