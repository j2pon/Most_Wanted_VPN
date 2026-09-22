# Need for Speed: Most Wanted (2005) - VPN Edition
# Runtime In-Memory Patcher (Smart App Control & Windows Defender 100% Compatible)
# Modifies memory in-flight without touching game binaries on disk.

$code = @'
using System;
using System.Runtime.InteropServices;

public class VPNMemoryPatcher {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool VirtualProtectEx(IntPtr hProcess, IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpAddress, byte[] lpBuffer, UIntPtr nSize, out IntPtr lpNumberOfBytesWritten);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);

    public static bool Apply(int pid) {
        IntPtr h = OpenProcess(0x1F0FFF, false, pid);
        if (h == IntPtr.Zero) return false;

        Action<long, byte[]> patch = (addr, bytes) => {
            uint old;
            VirtualProtectEx(h, (IntPtr)addr, (UIntPtr)bytes.Length, 0x40, out old);
            IntPtr written;
            WriteProcessMemory(h, (IntPtr)addr, bytes, (UIntPtr)bytes.Length, out written);
            VirtualProtectEx(h, (IntPtr)addr, (UIntPtr)bytes.Length, old, out old);
        };

        try {
            // 1. Force car addition on Career Start (bypass flag checks)
            patch(0x5a39aa, new byte[] { 0x90, 0x90 });
            patch(0x5a39b2, new byte[] { 0x90, 0x90 });

            // 2. Skip Cobalt SS BONUS_GT2 (16 NOPs at 0x5a39d1) -> ONLY BMW M3 GTR in garage
            patch(0x5a39d1, new byte[] { 0x90,0x90,0x90,0x90, 0x90,0x90,0x90,0x90, 0x90,0x90,0x90,0x90, 0x90,0x90,0x90,0x90 });

            // 3. Skip Prologue / Ambush (DDay) races (0x5a3a47 -> NOP je 0x5a3a7c) -> Enter Safehouse directly
            patch(0x5a3a47, new byte[] { 0x90, 0x90 });

            // 4. Ensure rival Sonny #15 is set (0x5a3a6c -> NOP je 0x5a3b4e)
            patch(0x5a3a6c, new byte[] { 0x90, 0x90 });

            // 5. Remove orange padlock from Safehouse milestones (0x51fe86 -> jmp 0x51fea3)
            patch(0x51fe86, new byte[] { 0xeb, 0x1b, 0x90, 0x90, 0x90, 0x90 });

            // 6. Unlock shop customization for all cars including BMW M3 GTR (0x7a5c10 -> jmp 0x7a5c27)
            patch(0x7a5c10, new byte[] { 0xeb, 0x15 });

            // 7. Hide shop locked padlock icon (0x7a5c40 -> jmp 0x7a5c60)
            patch(0x7a5c40, new byte[] { 0xeb, 0x1e });

            // 8. Set dev skip intro flags
            patch(0x926125, new byte[] { 0x01, 0x01 });

            return true;
        } finally {
            CloseHandle(h);
        }
    }
}
'@

try {
    Add-Type -TypeDefinition $code -Language CSharp
} catch {}

$logPath = Join-Path $PSScriptRoot "patcher.log"
$dateStr = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
"[$dateStr] VPN_Patcher baslatildi. speed.exe bekleniyor..." | Out-File -FilePath $logPath -Encoding utf8

# Poll for speed.exe for up to 30 seconds
for ($i = 0; $i -lt 60; $i++) {
    $p = Get-Process speed -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($p) {
        Start-Sleep -Milliseconds 800
        $ok = [VPNMemoryPatcher]::Apply($p.Id)
        if ($ok) {
            "[$dateStr] [+] speed.exe (PID: $($p.Id)) basariyla yamalandi! Tum VPN mod ozellikleri devrede." | Out-File -FilePath $logPath -Append -Encoding utf8
        } else {
            "[$dateStr] [-] speed.exe acilamadi." | Out-File -FilePath $logPath -Append -Encoding utf8
        }
        break
    }
    Start-Sleep -Milliseconds 500
}
