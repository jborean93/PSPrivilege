using System;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;

namespace PSPrivilege.Native
{
    internal static class Helpers
    {
        [StructLayout(LayoutKind.Sequential)]
        public struct LSA_ENUMERATION_INFORMATION
        {
            public IntPtr Sid;
        }

        [StructLayout(LayoutKind.Sequential)]
        public class LSA_OBJECT_ATTRIBUTES
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
        public struct LSA_UNICODE_STRING_PTR
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
        public struct LSA_UNICODE_STRING
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
        public struct LUID
        {
            public UInt32 LowPart;
            public Int32 HighPart;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct LUID_AND_ATTRIBUTES
        {
            public LUID Luid;
            public PrivilegeAttributes Attributes;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct TOKEN_PRIVILEGES
        {
            public UInt32 PrivilegeCount;
            [MarshalAs(UnmanagedType.ByValArray, SizeConst = 1)]
            public LUID_AND_ATTRIBUTES[] Privileges;
        }
    }

    internal static class Advapi32
    {
        [DllImport("Advapi32.dll", SetLastError = true)]
        public static extern bool AdjustTokenPrivileges(
            IntPtr TokenHandle,
            [MarshalAs(UnmanagedType.Bool)] bool DisableAllPrivileges,
            IntPtr NewState,
            UInt32 BufferLength,
            IntPtr PreviousState,
            out UInt32 ReturnLength);

        [DllImport("Advapi32.dll", SetLastError = true)]
        public static extern bool GetTokenInformation(
            IntPtr TokenHandle,
            UInt32 TokenInformationClass,
            IntPtr TokenInformation,
            UInt32 TokenInformationLength,
            out UInt32 ReturnLength);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool LookupPrivilegeDisplayNameW(
            string? lpSystemName,
            string lpName,
            StringBuilder lpDisplayName,
            ref UInt32 cchDisplayName,
            out UInt32 lpLanguageId);

        [DllImport("Advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool LookupPrivilegeNameW(
            string? lpSystemName,
            ref Helpers.LUID lpLuid,
            StringBuilder? lpName,
            ref UInt32 cchName);

        [DllImport("Advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool LookupPrivilegeValueW(
            string? lpSystemName,
            string lpName,
            out Helpers.LUID lpLuid);

        [DllImport("Advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern UInt32 LsaAddAccountRights(
            SafeHandle PolicyHandle,
            byte[] AccountSid,
            Helpers.LSA_UNICODE_STRING[] UserRights,
            UInt32 CountOfRights);

        [DllImport("Advapi32.dll")]
        public static extern UInt32 LsaClose(
            IntPtr ObjectHandle);

        [DllImport("Advapi32.dll")]
        public static extern UInt32 LsaEnumerateAccountRights(
            SafeHandle PolicyHandle,
            byte[] AccountSid,
            out IntPtr UserRights,
            out UInt32 CountOfRights);

        [DllImport("Advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern UInt32 LsaEnumerateAccountsWithUserRight(
            SafeHandle PolicyHandle,
            Helpers.LSA_UNICODE_STRING[] UserRight,
            out IntPtr EnumerationBuffer,
            out UInt32 CountReturned);

        [DllImport("Advapi32.dll")]
        public static extern UInt32 LsaFreeMemory(
            IntPtr Buffer);

        [DllImport("Advapi32.dll")]
        public static extern UInt32 LsaNtStatusToWinError(
            UInt32 Status);

        [DllImport("Advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern UInt32 LsaOpenPolicy(
            Helpers.LSA_UNICODE_STRING[] SystemName,
            Helpers.LSA_OBJECT_ATTRIBUTES ObjectAttributes,
            LsaPolicyAccessMask AccessMask,
            out SafeLsaHandle PolicyHandle);

        [DllImport("Advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern UInt32 LsaRemoveAccountRights(
            SafeHandle PolicyHandle,
            byte[] AccountSid,
            [MarshalAs(UnmanagedType.I1)] bool AllRights,
            Helpers.LSA_UNICODE_STRING[] UserRights,
            UInt32 CountOfRights);

        [DllImport("Advapi32.dll", SetLastError = true)]
        public static extern bool OpenProcessToken(
            SafeHandle ProcessHandle,
            TokenAccessLevels DesiredAccess,
            out IntPtr TokenHandle);
    }
}
