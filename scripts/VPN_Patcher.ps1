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

            // 2. Skip Cobalt SS BONUS_GT2 (16 NOPs at 0x5a39d1) -> ONLY Hero BMW M3 GTR in garage
            patch(0x5a39d1, new byte[] { 0x90,0x90,0x90,0x90, 0x90,0x90,0x90,0x90, 0x90,0x90,0x90,0x90, 0x90,0x90,0x90,0x90 });

            // 3. Skip Prologue / Ambush (DDay) races -> Jump straight to Safehouse setup (EB 29 = jmp 0x5a3a72)
            patch(0x5a3a47, new byte[] { 0xeb, 0x29 });

            // 4. Hide milestone orange padlock icon in Safehouse menu (0x51fdc0 -> jmp short 0x51fdd3)
            patch(0x51fdc0, new byte[] { 0xeb, 0x11 });

            // 5. Remove orange padlock from Safehouse milestones creation (0x51fe86 -> jmp 0x51fea3)
            patch(0x51fe86, new byte[] { 0xeb, 0x1b, 0x90, 0x90, 0x90, 0x90 });

            // 6. Unlock shop customization for all cars including BMW M3 GTR (0x7a5c10 -> jmp 0x7a5c27)
            patch(0x7a5c10, new byte[] { 0xeb, 0x15 });

            // 7. Hide shop locked padlock icon (0x7a5c40 -> jmp 0x7a5c60)
            patch(0x7a5c40, new byte[] { 0xeb, 0x1e });

            // 8. Keep dev skip flags at 0 to ensure Sonny's races/milestones are 100% fresh (uncompleted)
            patch(0x926125, new byte[] { 0x00, 0x00 });

            return true;
        } catch {
            return false;
        } finally {
            CloseHandle(h);
        }
    }
}
'@

try {
    Add-Type -TypeDefinition $code -Language CSharp
} catch {}

$patchedPids = [System.Collections.Generic.HashSet[int]]::new()
$logPath = Join-Path $PSScriptRoot "patcher.log"

function Log-Message($msg) {
    $dateStr = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "[$dateStr] $msg" | Out-File -FilePath $logPath -Append -Encoding utf8
}

Log-Message "VPN_Patcher aktif. speed.exe bekleniyor..."

# Continuous monitoring loop
while ($true) {
    try {
        $procs = Get-Process speed -ErrorAction SilentlyContinue
        if ($procs) {
            foreach ($p in $procs) {
                if (-not $patchedPids.Contains($p.Id)) {
                    Start-Sleep -Milliseconds 600
                    $ok = [VPNMemoryPatcher]::Apply($p.Id)
                    if ($ok) {
                        $patchedPids.Add($p.Id)
                        Log-Message "[+] speed.exe (PID: $($p.Id)) basariyla yamalandi! Safehouse, Sonny #15 ve Hero BMW M3 GTR aktif."
                    }
                }
            }
        }
        $currentIds = if ($procs) { @($procs | ForEach-Object { $_.Id }) } else { @() }
        [void]$patchedPids.RemoveWhere({ -not ($currentIds -contains $_) })
    } catch {}
    Start-Sleep -Seconds 1
}
