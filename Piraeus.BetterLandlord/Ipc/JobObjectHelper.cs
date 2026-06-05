using System.Diagnostics;
using System.Runtime.InteropServices;

namespace Piraeus.BetterLandlord.Ipc;

/// <summary>
/// Wraps Windows Job Object API.
/// Attaches a child process to a job with JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
/// so the OS auto-kills it when the parent exits — even on crash or force-kill.
/// </summary>
internal static class JobObjectHelper
{
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr CreateJobObject(IntPtr lpJobAttributes, string? lpName);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool SetInformationJobObject(
        IntPtr hJob,
        JobObjectInfoType infoType,
        ref JOBOBJECT_EXTENDED_LIMIT_INFORMATION lpJobObjectInfo,
        uint cbJobObjectInfoLength);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool AssignProcessToJobObject(IntPtr hJob, IntPtr hProcess);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr hObject);

    private enum JobObjectInfoType : int
    {
        ExtendedLimitInformation = 9
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct IO_COUNTERS
    {
        public ulong ReadOperationCount;
        public ulong WriteOperationCount;
        public ulong OtherOperationCount;
        public ulong ReadTransferCount;
        public ulong WriteTransferCount;
        public ulong OtherTransferCount;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct JOBOBJECT_BASIC_LIMIT_INFORMATION
    {
        public long PerProcessUserTimeLimit;
        public long PerJobUserTimeLimit;
        public uint LimitFlags;
        public UIntPtr MinimumWorkingSetSize;
        public UIntPtr MaximumWorkingSetSize;
        public uint ActiveProcessLimit;
        public UIntPtr Affinity;
        public uint PriorityClass;
        public uint SchedulingClass;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct JOBOBJECT_EXTENDED_LIMIT_INFORMATION
    {
        public JOBOBJECT_BASIC_LIMIT_INFORMATION BasicLimitInformation;
        public IO_COUNTERS IoInfo;
        public UIntPtr ProcessMemoryLimit;
        public UIntPtr JobMemoryLimit;
        public UIntPtr PeakProcessMemoryUsed;
        public UIntPtr PeakJobMemoryUsed;
    }

    /// <summary>
    /// Creates a Job Object that auto-kills all assigned processes when its last handle closes.
    /// Returns the handle. Caller must close it via CloseJob().
    /// </summary>
    public static IntPtr CreateKillOnCloseJob()
    {
        var hJob = CreateJobObject(IntPtr.Zero, null);
        if (hJob == IntPtr.Zero)
            throw new InvalidOperationException(
                $"CreateJobObject failed: {Marshal.GetLastWin32Error()}");

        var info = new JOBOBJECT_EXTENDED_LIMIT_INFORMATION
        {
            BasicLimitInformation = new JOBOBJECT_BASIC_LIMIT_INFORMATION
            {
                LimitFlags = 0x2000 // JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
            }
        };

        if (!SetInformationJobObject(hJob, JobObjectInfoType.ExtendedLimitInformation,
                ref info, (uint)Marshal.SizeOf(info)))
            throw new InvalidOperationException(
                $"SetInformationJobObject failed: {Marshal.GetLastWin32Error()}");

        return hJob;
    }

    /// <summary>
    /// Assigns a process to the job. Must be called after Process.Start().
    /// </summary>
    public static void AssignProcess(IntPtr hJob, Process process)
    {
        if (!AssignProcessToJobObject(hJob, process.Handle))
            throw new InvalidOperationException(
                $"AssignProcessToJobObject failed: {Marshal.GetLastWin32Error()}");
    }

    /// <summary>
    /// Closes the job handle. When the last handle to a kill-on-close job closes,
    /// the OS terminates all assigned processes.
    /// </summary>
    public static void CloseJob(IntPtr hJob)
    {
        if (hJob != IntPtr.Zero) CloseHandle(hJob);
    }
}
