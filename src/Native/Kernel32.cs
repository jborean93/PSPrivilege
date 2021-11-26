using Microsoft.Win32.SafeHandles;
using System;
using System.Runtime.InteropServices;

namespace PSPrivilege.Native
{
    internal static class Kernel32
    {
        [DllImport("Kernel32.dll")]
        internal static extern bool CloseHandle(
            IntPtr hObject);

        [DllImport("Kernel32")]
        internal static extern SafeWaitHandle GetCurrentProcess();
    }
}
