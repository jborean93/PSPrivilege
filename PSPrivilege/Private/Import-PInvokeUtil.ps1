# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Import-PInvokeUtil
{
    Add-Type -TypeDefinition @'
using Microsoft.Win32.SafeHandles;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.ConstrainedExecution;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;

namespace PSPrivilege
{
    internal class NativeHelpers
    {
        [StructLayout(LayoutKind.Sequential)]
        internal struct LUID
        {
            public UInt32 LowPart;
            public Int32 HighPart;
        }

        [StructLayout(LayoutKind.Sequential)]
        internal struct LUID_AND_ATTRIBUTES
        {
            public LUID Luid;
            public PrivilegeAttributes Attributes;
        }

        [StructLayout(LayoutKind.Sequential)]
        internal struct LSA_ENUMERATION_INFORMATION
        {
            public IntPtr Sid;
        }

        [StructLayout(LayoutKind.Sequential)]
        internal class LSA_OBJECT_ATTRIBUTES
        {
            public UInt32 Length = 0;
            public IntPtr RootDirectory = IntPtr.Zero;
            public IntPtr ObjectName = IntPtr.Zero;
            public UInt32 Attributes = 0;
            public IntPtr SecurityDescriptor = IntPtr.Zero;
            public IntPtr SecurityQualityOfService = IntPtr.Zero;
        }

        /// <summary>
        /// This is used with LsaEnumerateAccountRights as it returns an array
        /// of LSA_UNICODE_STR. It makes it easier to marshal the data to a
        /// string compared to the standard LSA_UNICODE_STRING
        /// </summary>
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        internal struct LSA_UNICODE_STRING_PTR
        {
            public UInt16 Length;
            public UInt16 MaximumLength;
            public IntPtr Buffer;

            public static explicit operator string(LSA_UNICODE_STRING_PTR s)
            {
                byte[] strBytes = new byte[s.Length];
                Marshal.Copy(s.Buffer, strBytes, 0, s.Length);
                return Encoding.Unicode.GetString(strBytes);
            }
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        internal struct LSA_UNICODE_STRING
        {
            public UInt16 Length;
            public UInt16 MaximumLength;
            [MarshalAs(UnmanagedType.LPWStr)] public string Buffer;

            public static implicit operator string(LSA_UNICODE_STRING s)
            {
                return s.Buffer;
            }

            public static implicit operator LSA_UNICODE_STRING(string s)
            {
                if (s == null)
                    s = "";

                LSA_UNICODE_STRING unicodeStr = new LSA_UNICODE_STRING()
                {
                    Buffer = s,
                    Length = (UInt16)(s.Length * sizeof(char)),
                    MaximumLength = (UInt16)((s.Length * sizeof(char)) + sizeof(char)),
                };
                return unicodeStr;
            }
        }

        [StructLayout(LayoutKind.Sequential)]
        internal struct TOKEN_PRIVILEGES
        {
            public UInt32 PrivilegeCount;
            [MarshalAs(UnmanagedType.ByValArray, SizeConst = 1)]
            public LUID_AND_ATTRIBUTES[] Privileges;
        }
    }

    internal class NativeMethods
    {
        [DllImport("advapi32.dll", SetLastError = true)]
        internal static extern bool AdjustTokenPrivileges(
            IntPtr TokenHandle,
            [MarshalAs(UnmanagedType.Bool)] bool DisableAllPrivileges,
            IntPtr NewState,
            UInt32 BufferLength,
            IntPtr PreviousState,
            out UInt32 ReturnLength);

        [DllImport("kernel32.dll")]
        internal static extern bool CloseHandle(
            IntPtr hObject);

        [DllImport("kernel32")]
        internal static extern SafeWaitHandle GetCurrentProcess();

        [DllImport("advapi32.dll", SetLastError = true)]
        internal static extern bool GetTokenInformation(
            IntPtr TokenHandle,
            UInt32 TokenInformationClass,
            IntPtr TokenInformation,
            UInt32 TokenInformationLength,
            out UInt32 ReturnLength);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        internal static extern bool LookupPrivilegeDisplayNameW(
            string lpSystemName,
            string lpName,
            StringBuilder lpDisplayName,
            out UInt32 cchDisplayName,
            out UInt32 lpLanguageId);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        internal static extern bool LookupPrivilegeNameW(
            string lpSystemName,
            ref NativeHelpers.LUID lpLuid,
            StringBuilder lpName,
            ref UInt32 cchName);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        internal static extern bool LookupPrivilegeValueW(
            string lpSystemName,
            string lpName,
            out NativeHelpers.LUID lpLuid);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        internal static extern UInt32 LsaAddAccountRights(
            SafeLsaHandle PolicyHandle,
            byte[] AccountSid,
            NativeHelpers.LSA_UNICODE_STRING[] UserRights,
            UInt32 CountOfRights);

        [DllImport("advapi32.dll")]
        internal static extern UInt32 LsaClose(
            IntPtr ObjectHandle);

        [DllImport("advapi32.dll")]
        internal static extern UInt32 LsaEnumerateAccountRights(
            SafeLsaHandle PolicyHandle,
            byte[] AccountSid,
            out IntPtr UserRights,
            out UInt32 CountOfRights);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        internal static extern UInt32 LsaEnumerateAccountsWithUserRight(
            SafeLsaHandle PolicyHandle,
            NativeHelpers.LSA_UNICODE_STRING[] UserRight,
            out IntPtr EnumerationBuffer,
            out UInt32 CountReturned);

        [DllImport("advapi32.dll")]
        internal static extern UInt32 LsaFreeMemory(
            IntPtr Buffer);

        [DllImport("advapi32.dll")]
        internal static extern UInt32 LsaNtStatusToWinError(
            UInt32 Status);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        internal static extern UInt32 LsaOpenPolicy(
            NativeHelpers.LSA_UNICODE_STRING[] SystemName,
            NativeHelpers.LSA_OBJECT_ATTRIBUTES ObjectAttributes,
            LsaPolicyAccessMask AccessMask,
            out SafeLsaHandle PolicyHandle);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        internal static extern UInt32 LsaRemoveAccountRights(
            SafeLsaHandle PolicyHandle,
            byte[] AccountSid,
            [MarshalAs(UnmanagedType.I1)] bool AllRights,
            NativeHelpers.LSA_UNICODE_STRING[] UserRights,
            UInt32 CountOfRights);

        [DllImport("advapi32.dll", SetLastError = true)]
        internal static extern bool OpenProcessToken(
            SafeHandle ProcessHandle,
            TokenAccessLevels DesiredAccess,
            out IntPtr TokenHandle);
    }

    internal enum Win32ErrorCodes : int
    {
        ERROR_SUCCESS = 0x00000000,
        ERROR_INSUFFICIENT_BUFFER = 0x0000007A,
        ERROR_NO_SUCH_PRIVILEGE = 0x00000521,
    }

    internal enum LsaStatusCodes : uint
    {
        STATUS_SUCCESS = 0x00000000,
        STATUS_NO_MORE_ENTRIES = 0x8000001a,
        STATUS_OBJECT_NAME_NOT_FOUND = 0xc0000034,
        STATUS_NO_SUCH_PRIVILEGE = 0xc0000060,
    }

    /// <summary>
    /// AccessMask that is specified when LsaUtils.OpenPolicy is called
    /// https://docs.microsoft.com/en-us/windows/desktop/secmgmt/policy-object-access-rights
    /// </summary>
    [Flags]
    public enum LsaPolicyAccessMask : uint
    {
        ViewLocalInformation = 0x00000001,
        ViewAuditInformation = 0x00000002,
        GetPrivateInformation = 0x00000004,
        TrustAdmin = 0x00000008,
        CreateAccount = 0x00000010,
        CreateSecret = 0x00000020,
        CreatePrivilege = 0x00000040,
        SetDefaultQuotaLimits = 0x00000080,
        SetAuditRequirements = 0x00000100,
        AuditLogAdmin = 0x00000200,
        ServerAdmin = 0x00000400,
        LookupNames = 0x00000800,

        Read = 0x00020006,
        Write = 0x000207F8,
        Execute = 0x00020801,
        AllAccess = 0x000F0FFF,
    }

    /// <summary>
    /// The attributes that a LUID_AND_ATTRIBUTES can specify.
    /// https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_token_privileges
    /// </summary>
    [Flags]
    public enum PrivilegeAttributes : uint
    {
        Disabled = 0x00000000,
        EnabledByDefault = 0x00000001,
        Enabled = 0x00000002,
        Removed = 0x00000004,
        UsedForAccess = 0x80000000,
    }

    public class SafeLsaHandle : SafeHandleZeroOrMinusOneIsInvalid
    {
        internal SafeLsaHandle() : base(true) { }

        [ReliabilityContract(Consistency.WillNotCorruptState, Cer.MayFail)]
        protected override bool ReleaseHandle()
        {
            return NativeMethods.LsaClose(handle) == 0;
        }
    }

    public class Win32Exception : System.ComponentModel.Win32Exception
    {
        private string _exception_msg;

        public Win32Exception(string message) : this(Marshal.GetLastWin32Error(), message) { }
        public Win32Exception(int errorCode, string message) : base(errorCode)
        {
            _exception_msg = String.Format("{0} - {1} (Win32 Error Code {2}: 0x{3})", message, base.Message, errorCode, errorCode.ToString("X8"));
        }
        public override string Message { get { return _exception_msg; } }
        public static explicit operator Win32Exception(string message) { return new Win32Exception(message); }
    }

    public class Lsa
    {
        /// <summary>
        /// Gets an opened SafeLsaHandle on the system specified. Once finished
        /// with the handle, call the .Dispose() method to clean it up.
        /// </summary>
        /// <param name="systemName">The target system to get the open handle, set to null for localhost</param>
        /// <param name="accessMask">PSPrivilege.LsaPolicyAccessMask with the requests access rights</param>
        /// <returns>SafeLsaHandle of the opened policy</returns>
        public static SafeLsaHandle OpenPolicy(string systemName, LsaPolicyAccessMask accessMask)
        {
            SafeLsaHandle handle;
            NativeHelpers.LSA_UNICODE_STRING[] systemNameStr = new NativeHelpers.LSA_UNICODE_STRING[1];
            systemNameStr[0] = systemName;

            NativeHelpers.LSA_OBJECT_ATTRIBUTES objectAttr = new NativeHelpers.LSA_OBJECT_ATTRIBUTES();

            UInt32 res = NativeMethods.LsaOpenPolicy(systemNameStr, objectAttr, accessMask, out handle);
            if (res != (UInt32)LsaStatusCodes.STATUS_SUCCESS)
                throw new Win32Exception((int)NativeMethods.LsaNtStatusToWinError(res), String.Format("LsaOpenPolicy({0}) failed", systemName));
            return handle;
        }

        /// <summary>
        /// Assigns one or more privileges/rights to an account. The opened
        /// SafeLsaHandle must have the LookupNames access right. It will also
        /// need the CreateAccount access right if the account referenced does
        /// not exist.
        /// </summary>
        /// <param name="policy">The SafeLsaHandle opened with OpenPolicy</param>
        /// <param name="account">The account to add the right(s) to</param>
        /// <param name="rights">Array list rights that match the privilege constants</param>
        public static void AddAccountRights(SafeLsaHandle policy, IdentityReference account, string[] rights)
        {
            NativeHelpers.LSA_UNICODE_STRING[] rightsStr = new NativeHelpers.LSA_UNICODE_STRING[rights.Length];
            for (int i = 0; i < rights.Length; i++)
                rightsStr[i] = rights[i];

            SecurityIdentifier sid = (SecurityIdentifier)account.Translate(typeof(SecurityIdentifier));
            byte[] sidBytes = new byte[sid.BinaryLength];
            sid.GetBinaryForm(sidBytes, 0);

            UInt32 res = NativeMethods.LsaAddAccountRights(policy, sidBytes, rightsStr, (UInt32)rights.Length);
            if (res != (UInt32)LsaStatusCodes.STATUS_SUCCESS)
                throw new Win32Exception((int)NativeMethods.LsaNtStatusToWinError(res), "LsaAddAccountRights() failed");
        }

        /// <summary>
        /// Get a list of rights that are set on the account specified. The
        /// opened SafeLsaHandle must have the LookupNames access right.
        /// </summary>
        /// <param name="policy">The SafeLsaHandle opened with OpenPolicy</param>
        /// <param name="account">The account to enumerate the rights for</param>
        /// <returns>List of rights/privileges that are assigned to the account</returns>
        public static List<string> EnumerateAccountRights(SafeLsaHandle policy, IdentityReference account)
        {
            List<string> rights = new List<string>();
            IntPtr rightsPtr = IntPtr.Zero;
            UInt32 rightsCount;

            SecurityIdentifier sid = (SecurityIdentifier)account.Translate(typeof(SecurityIdentifier));
            byte[] sidBytes = new byte[sid.BinaryLength];
            sid.GetBinaryForm(sidBytes, 0);

            UInt32 res = NativeMethods.LsaEnumerateAccountRights(policy, sidBytes, out rightsPtr, out rightsCount);
            if (res != (UInt32)LsaStatusCodes.STATUS_SUCCESS && res != (UInt32)LsaStatusCodes.STATUS_OBJECT_NAME_NOT_FOUND)
                throw new Win32Exception((int)NativeMethods.LsaNtStatusToWinError(res), "LsaEnumerateAccountRights() failed");
            try
            {
                IntPtr strPtr = rightsPtr;
                for (int i = 0; i < rightsCount; i++)
                {
                    NativeHelpers.LSA_UNICODE_STRING_PTR uniStr = (NativeHelpers.LSA_UNICODE_STRING_PTR)Marshal.PtrToStructure(
                        strPtr, typeof(NativeHelpers.LSA_UNICODE_STRING_PTR));
                    strPtr = IntPtr.Add(strPtr, Marshal.SizeOf(typeof(NativeHelpers.LSA_UNICODE_STRING_PTR)));
                    rights.Add((string)uniStr);
                }
            }
            finally
            {
                if (rightsPtr != IntPtr.Zero)
                    NativeMethods.LsaFreeMemory(rightsPtr);
            }

            return rights;
        }

        /// <summary>
        /// Gets the accounts that hold the specified privilege. The accounts
        /// returned hold the specified privilege directly and not as part of
        /// membership to a group. The opened SafeLsaHandle must have the
        /// LookupNames and ViewLocalInformation access rights.
        /// https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/privilege-constants
        /// https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/account-rights-constants
        /// </summary>
        /// <param name="policy">The SafeLsaHandle opened with OpenPolicy</param>
        /// <param name="right">The privilege to enumerate, this matches the privilege constant names</param>
        /// <returns>List<SecurityIdentifier> of accounts that hold the specified privilege</SecurityIdentifier></returns>
        public static List<SecurityIdentifier> EnumerateAccountsWithUserRight(SafeLsaHandle policy, string right)
        {
            List<SecurityIdentifier> accounts = new List<SecurityIdentifier>();
            NativeHelpers.LSA_UNICODE_STRING[] rightsStr = new NativeHelpers.LSA_UNICODE_STRING[1];
            rightsStr[0] = right;
            IntPtr buffer = IntPtr.Zero;
            UInt32 countReturned;

            UInt32 res = NativeMethods.LsaEnumerateAccountsWithUserRight(policy, rightsStr, out buffer, out countReturned);
            switch (res)
            {
                case (UInt32)LsaStatusCodes.STATUS_SUCCESS:
                    try
                    {
                        for (int i = 0; i < (int)countReturned; i++)
                        {
                            IntPtr infoBuffer = IntPtr.Add(buffer, i * Marshal.SizeOf(typeof(NativeHelpers.LSA_ENUMERATION_INFORMATION)));
                            NativeHelpers.LSA_ENUMERATION_INFORMATION info = (NativeHelpers.LSA_ENUMERATION_INFORMATION)Marshal.PtrToStructure(
                                infoBuffer,
                                typeof(NativeHelpers.LSA_ENUMERATION_INFORMATION));
                            accounts.Add(new SecurityIdentifier(info.Sid));
                        }
                    }
                    finally
                    {
                        NativeMethods.LsaFreeMemory(buffer);
                    }

                    break;
                case (UInt32)LsaStatusCodes.STATUS_NO_MORE_ENTRIES:
                    break;
                case (UInt32)LsaStatusCodes.STATUS_NO_SUCH_PRIVILEGE:
                    throw new ArgumentException(String.Format("No such privilege/right {0}", right));
                default:
                    throw new Win32Exception((int)NativeMethods.LsaNtStatusToWinError(res), String.Format("LsaEnumerateAccountsWithUserRight({0}) failed", right));
            }

            return accounts;
        }

        /// <summary>
        /// Removes all the privileges/rights of an account. The opened
        /// SafeLsaHandle must have the LookupNames access right.
        /// </summary>
        /// <param name="policy">The SafeLsaHandle opened with OpenPolicy</param>
        /// <param name="account">The account to remove all the rights from</param>
        public static void RemoveAllAccountRights(SafeLsaHandle policy, IdentityReference account)
        {
            LsaRemoveAccountRights(policy, account, true, null);
        }

        /// <summary>
        /// Removes one or more privileges/rights of an account. The opened
        /// SafeLsaHandle must have the LookupNames access right.
        /// </summary>
        /// <param name="policy">The SafeLsaHandle opened with OpenPolicy</param>
        /// <param name="account">The account to remove all the rights from</param>
        /// <param name="rights">Array list of rights that match the privilege constants</param>
        public static void RemoveAccountRights(SafeLsaHandle policy, IdentityReference account, string[] rights)
        {
            LsaRemoveAccountRights(policy, account, false, rights);
        }

        private static void LsaRemoveAccountRights(SafeLsaHandle policy, IdentityReference account, bool allRights, string[] rights)
        {
            int rightsLength = 0;
            NativeHelpers.LSA_UNICODE_STRING[] rightsStr = null;
            if (rights != null)
                rightsLength = rights.Length;
            rightsStr = new NativeHelpers.LSA_UNICODE_STRING[rightsLength];
            for (int i = 0; i < rightsLength; i++)
                rightsStr[i] = rights[i];

            SecurityIdentifier sid = (SecurityIdentifier)account.Translate(typeof(SecurityIdentifier));
            byte[] sidBytes = new byte[sid.BinaryLength];
            sid.GetBinaryForm(sidBytes, 0);

            UInt32 res = NativeMethods.LsaRemoveAccountRights(policy, sidBytes, allRights, rightsStr, (UInt32)rightsLength);
            if (res != (UInt32)LsaStatusCodes.STATUS_SUCCESS && res != (UInt32)LsaStatusCodes.STATUS_OBJECT_NAME_NOT_FOUND)
                throw new Win32Exception((int)NativeMethods.LsaNtStatusToWinError(res), "LsaRemoveAccountRights() failed");
        }
    }

    public class Privileges
    {
        private static readonly UInt32 TOKEN_PRIVILEGES = 3;

        /// <summary>
        /// Checks if the privilege constant specified is valid or not. List of
        /// valid privileges can be found here
        /// https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/privilege-constants.
        /// </summary>
        /// <param name="name">The privilege constant to check</param>
        /// <returns>true if the privilege is valid, false if not</returns>
        public static bool CheckPrivilegeName(string name)
        {
            NativeHelpers.LUID luid;
            bool res = NativeMethods.LookupPrivilegeValueW(null, name, out luid);
            int errCode = res ? 0 : Marshal.GetLastWin32Error();
            if (errCode != (int)Win32ErrorCodes.ERROR_SUCCESS && errCode != (int)Win32ErrorCodes.ERROR_NO_SUCH_PRIVILEGE)
                throw new Win32Exception(errCode, String.Format("LookupPrivilegeValue({0}) failed", name));

            return errCode == 0;
        }

        /// <summary>
        /// Disable the privilege on the process token specified.
        /// </summary>
        /// <param name="token">The user token to disable the privilege on</param>
        /// <param name="privilege">The privilege constant string to disable</param>
        /// <returns>Dictionary<string, bool?> of the previous state which can be used with SetTokenPrivileges</string></returns>
        public static Dictionary<string, bool?> DisablePrivilege(SafeHandle token, string privilege)
        {
            return SetTokenPrivileges(token, new Dictionary<string, bool?>() { { privilege, false } });
        }

        /// <summary>
        /// Disables all the privileges on the process token specified.
        /// </summary>
        /// <param name="token">The user token to disable all the privileges on</param>
        /// <returns>Dictionary<string, bool?> of the previous state which can be used with SetTokenPrivileges</returns>
        public static Dictionary<string, bool?> DisableAllPrivileges(SafeHandle token)
        {
            return AdjustTokenPrivileges(token, null);
        }

        /// <summary>
        /// Enable a privilege on the process token specified.
        /// </summary>
        /// <param name="token">The user token to enable the privilege on</param>
        /// <param name="privilege">The privilege constant string to enable</param>
        /// <returns>Dictionary<string, bool?> of the previous state which can be used with SetTokenPrivileges</returns>
        public static Dictionary<string, bool?> EnablePrivilege(SafeHandle token, string privilege)
        {
            return SetTokenPrivileges(token, new Dictionary<string, bool?>() { { privilege, true } });
        }

        /// <summary>
        /// Get the information for all privileges on the process token
        /// specified.
        /// </summary>
        /// <param name="token">The user token to get the privilege information</param>
        /// <returns>Dictionary<String, PrivilegeAttributes> the info on all the privileges on the process token</String></returns>
        public static Dictionary<String, PrivilegeAttributes> GetAllPrivilegeInfo(SafeHandle token)
        {
            Dictionary<String, PrivilegeAttributes> info = new Dictionary<String, PrivilegeAttributes>();

            IntPtr hToken = IntPtr.Zero;
            if (!NativeMethods.OpenProcessToken(token, TokenAccessLevels.Query, out hToken))
                throw new Win32Exception("OpenProcessToken() failed");

            try
            {
                UInt32 tokenLength = 0;
                NativeMethods.GetTokenInformation(hToken, TOKEN_PRIVILEGES, IntPtr.Zero, 0, out tokenLength);

                NativeHelpers.LUID_AND_ATTRIBUTES[] privileges;
                IntPtr privilegesPtr = Marshal.AllocHGlobal((int)tokenLength);
                try
                {
                    if (!NativeMethods.GetTokenInformation(hToken, TOKEN_PRIVILEGES, privilegesPtr, tokenLength, out tokenLength))
                        throw new Win32Exception("GetTokenInformation() for TOKEN_PRIVILEGES failed");

                    NativeHelpers.TOKEN_PRIVILEGES privilegeInfo = (NativeHelpers.TOKEN_PRIVILEGES)Marshal.PtrToStructure(privilegesPtr, typeof(NativeHelpers.TOKEN_PRIVILEGES));
                    privileges = new NativeHelpers.LUID_AND_ATTRIBUTES[privilegeInfo.PrivilegeCount];
                    PtrToStructureArray(privileges, IntPtr.Add(privilegesPtr, Marshal.SizeOf(privilegeInfo.PrivilegeCount)));
                }
                finally
                {
                    Marshal.FreeHGlobal(privilegesPtr);
                }

                info = privileges.ToDictionary(p => GetPrivilegeName(p.Luid), p => p.Attributes);
            }
            finally
            {
                NativeMethods.CloseHandle(hToken);
            }
            return info;
        }

        /// <summary>
        /// Gets a safe handle of the current process for use in the other
        /// functions.
        /// </summary>
        /// <returns>SafeWaitHandle of the current process</returns>
        public static SafeWaitHandle GetCurrentProcess()
        {
            return NativeMethods.GetCurrentProcess();
        }

        /// <summary>
        /// Returns the display name/description of the privilege specified.
        /// </summary>
        /// <param name="privilege">The privilege constant to get the display name for</param>
        /// <returns>The display name of the privilege specified</returns>
        public static string GetPrivilegeDisplayName(string privilege)
        {
            StringBuilder displayName = new StringBuilder();
            UInt32 displayLength;
            UInt32 languageId;

            if (!NativeMethods.LookupPrivilegeDisplayNameW(null, privilege, displayName, out displayLength, out languageId))
            {
                int errCode = Marshal.GetLastWin32Error();
                if (errCode == (int)Win32ErrorCodes.ERROR_NO_SUCH_PRIVILEGE)
                    throw new ArgumentException(String.Format("Invalid privilege '{0}'", privilege));
                if (errCode != (int)Win32ErrorCodes.ERROR_INSUFFICIENT_BUFFER)
                    throw new Win32Exception(errCode, String.Format("LookupPrivilegeDisplayNameW({0}) failed to get length of display name string", privilege));
            }

            displayName.EnsureCapacity((int)displayLength);
            if (!NativeMethods.LookupPrivilegeDisplayNameW(null, privilege, displayName, out displayLength, out languageId))
                throw new Win32Exception(String.Format("LookupPrivilegeDisplayNameW({0}) failed", privilege));

            return displayName.ToString();
        }

        /// <summary>
        /// Remove a privilege from the token specified. Once a privilege is
        /// removed it cannot be added/enabled again.
        /// </summary>
        /// <param name="token">The process to remove the privilege on</param>
        /// <param name="privilege">The privilege constant string to remove</param>
        public static void RemovePrivilege(SafeHandle token, string privilege)
        {
            SetTokenPrivileges(token, new Dictionary<string, bool?>() { { privilege, null } });
        }

        /// <summary>
        /// Manually set the token privileges in 1 call. This can be used to
        /// enable/disable/remove privileges at the same time. Enable/Disable
        /// privileges function's return value can be used in state to undo the
        /// action of those functions.
        /// </summary>
        /// <param name="token">The current process to set the privilege state on</param>
        /// <param name="state">Dictionary<string, bool?> where the key is the privilege constant and the bool is the action; true == enable, false == disable, null == remove</string></param>
        /// <returns>Dictionary<string, bool?> of the previous state, can be used on a subsequent call to undo the action</string></returns>
        public static Dictionary<string, bool?> SetTokenPrivileges(SafeHandle token, Dictionary<string, bool?> state)
        {
            NativeHelpers.LUID_AND_ATTRIBUTES[] privilegeAttr = new NativeHelpers.LUID_AND_ATTRIBUTES[state.Count];
            int i = 0;

            foreach (KeyValuePair<string, bool?> entry in state)
            {
                NativeHelpers.LUID luid;
                if (!NativeMethods.LookupPrivilegeValueW(null, entry.Key, out luid))
                    throw new Win32Exception(String.Format("LookupPrivilegeValue({0}) failed", entry.Key));

                PrivilegeAttributes attributes;
                switch (entry.Value)
                {
                    case true:
                        attributes = PrivilegeAttributes.Enabled;
                        break;
                    case false:
                        attributes = PrivilegeAttributes.Disabled;
                        break;
                    default:
                        attributes = PrivilegeAttributes.Removed;
                        break;
                }

                privilegeAttr[i].Luid = luid;
                privilegeAttr[i].Attributes = attributes;
                i++;
            }

            return AdjustTokenPrivileges(token, privilegeAttr);
        }

        private static Dictionary<string, bool?> AdjustTokenPrivileges(SafeHandle token, NativeHelpers.LUID_AND_ATTRIBUTES[] newState)
        {
            bool disableAllPrivileges = true;
            IntPtr newStatePtr = IntPtr.Zero;
            NativeHelpers.LUID_AND_ATTRIBUTES[] oldStatePrivileges;
            UInt32 returnLength;

            if (newState != null)
            {
                disableAllPrivileges = false;

                // Need to manually marshal the bytes requires for newState as the constant size
                // of LUID_AND_ATTRIBUTES is set to 1 and can't be overridden at runtime, TOKEN_PRIVILEGES
                // always contains at least 1 entry so we need to calculate the extra size if there are
                // nore than 1 LUID_AND_ATTRIBUTES entry
                int tokenPrivilegesSize = Marshal.SizeOf(typeof(NativeHelpers.TOKEN_PRIVILEGES));
                int luidAttrSize = 0;
                if (newState.Length > 1)
                    luidAttrSize = Marshal.SizeOf(typeof(NativeHelpers.LUID_AND_ATTRIBUTES)) * (newState.Length - 1);
                int totalSize = tokenPrivilegesSize + luidAttrSize;
                byte[] newStateBytes = new byte[totalSize];

                // get the first entry that includes the struct details
                NativeHelpers.TOKEN_PRIVILEGES tokenPrivileges = new NativeHelpers.TOKEN_PRIVILEGES()
                {
                    PrivilegeCount = (UInt32)newState.Length,
                    Privileges = new NativeHelpers.LUID_AND_ATTRIBUTES[1],
                };
                if (newState.Length > 0)
                    tokenPrivileges.Privileges[0] = newState[0];
                int offset = StructureToBytes(tokenPrivileges, newStateBytes, 0);

                // copy the remaining LUID_AND_ATTRIBUTES (if any)
                for (int i = 1; i < newState.Length; i++)
                    offset += StructureToBytes(newState[i], newStateBytes, offset);

                // finally create the pointer to the byte array we just created
                newStatePtr = Marshal.AllocHGlobal(newStateBytes.Length);
                Marshal.Copy(newStateBytes, 0, newStatePtr, newStateBytes.Length);
            }

            try
            {
                IntPtr hToken = IntPtr.Zero;
                if (!NativeMethods.OpenProcessToken(token, TokenAccessLevels.Query | TokenAccessLevels.AdjustPrivileges, out hToken))
                    throw new Win32Exception("OpenProcessToken() failed with Query and AdjustPrivileges");
                try
                {
                    IntPtr oldStatePtr = Marshal.AllocHGlobal(0);
                    if (!NativeMethods.AdjustTokenPrivileges(hToken, disableAllPrivileges, newStatePtr, 0, oldStatePtr, out returnLength))
                    {
                        int errCode = Marshal.GetLastWin32Error();
                        if (errCode != (int)Win32ErrorCodes.ERROR_INSUFFICIENT_BUFFER)
                            throw new Win32Exception(errCode, "AdjustTokenPrivileges() failed to get old state size");
                    }

                    // resize the oldStatePtr based on the length returned from Windows
                    Marshal.FreeHGlobal(oldStatePtr);
                    oldStatePtr = Marshal.AllocHGlobal((int)returnLength);
                    try
                    {
                        bool res = NativeMethods.AdjustTokenPrivileges(hToken, disableAllPrivileges, newStatePtr, returnLength, oldStatePtr, out returnLength);
                        int errCode = Marshal.GetLastWin32Error();

                        // even when res == true, ERROR_NOT_ALL_ASSIGNED may be set as the last error code
                        if (!res || errCode != (int)Win32ErrorCodes.ERROR_SUCCESS)
                            throw new Win32Exception(errCode, "AdjustTokenPrivileges() failed");

                        // Marshal the oldStatePtr to the struct
                        NativeHelpers.TOKEN_PRIVILEGES oldState = (NativeHelpers.TOKEN_PRIVILEGES)Marshal.PtrToStructure(oldStatePtr, typeof(NativeHelpers.TOKEN_PRIVILEGES));
                        oldStatePrivileges = new NativeHelpers.LUID_AND_ATTRIBUTES[oldState.PrivilegeCount];
                        PtrToStructureArray(oldStatePrivileges, IntPtr.Add(oldStatePtr, Marshal.SizeOf(oldState.PrivilegeCount)));
                    }
                    finally
                    {
                        Marshal.FreeHGlobal(oldStatePtr);
                    }
                }
                finally
                {
                    NativeMethods.CloseHandle(hToken);
                }
            }
            finally
            {
                if (newStatePtr != IntPtr.Zero)
                    Marshal.FreeHGlobal(newStatePtr);
            }

            return oldStatePrivileges.ToDictionary(p => GetPrivilegeName(p.Luid), p => (bool?)p.Attributes.HasFlag(PrivilegeAttributes.Enabled));
        }

        private static string GetPrivilegeName(NativeHelpers.LUID luid)
        {
            UInt32 nameLen = 0;
            NativeMethods.LookupPrivilegeNameW(null, ref luid, null, ref nameLen);

            StringBuilder name = new StringBuilder((int)(nameLen + 1));
            if (!NativeMethods.LookupPrivilegeNameW(null, ref luid, name, ref nameLen))
                throw new Win32Exception("LookupPrivilegeName() failed");

            return name.ToString();
        }

        private static void PtrToStructureArray<T>(T[] array, IntPtr ptr)
        {
            IntPtr ptrOffset = ptr;
            for (int i = 0; i < array.Length; i++, ptrOffset = IntPtr.Add(ptrOffset, Marshal.SizeOf(typeof(T))))
                array[i] = (T)Marshal.PtrToStructure(ptrOffset, typeof(T));
        }

        private static int StructureToBytes<T>(T structure, byte[] array, int offset)
        {
            int size = Marshal.SizeOf(structure);
            IntPtr structPtr = Marshal.AllocHGlobal(size);
            try
            {
                Marshal.StructureToPtr(structure, structPtr, false);
                Marshal.Copy(structPtr, array, offset, size);
            }
            finally
            {
                Marshal.FreeHGlobal(structPtr);
            }

            return size;
        }
    }
}
'@
}