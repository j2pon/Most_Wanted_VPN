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

            // 3. Skip Prologue / Ambush (DDay) races (0x5a3a47 -> NOP je 0x5a3a7c) -> Enter Safehouse directly
            patch(0x5a3a47, new byte[] { 0x90, 0x90 });

            // 4. Ensure rival Sonny #15 is set (0x5a3a6c -> NOP je 0x5a3b4e)
            patch(0x5a3a6c, new byte[] { 0x90, 0x90 });

            // 5. Set dev skip intro flags
            patch(0x926125, new byte[] { 0x01, 0x01 });

            // 6. Bypass save checksum mismatch / corruption check (0x7f53ed: je -> jmp 0x7f53ff)
            patch(0x7f53ed, new byte[] { 0xeb, 0x10, 0x90, 0x90, 0x90, 0x90 });

            // 7. Safehouse detail card lock icon: Force unlocked state + hide padlock
            patch(0x51fdba, new byte[] { 0xb0, 0x01, 0x90, 0x84, 0xc0, 0x5e, 0x90, 0x90 });
            patch(0x51fdc0, new byte[] { 0x90, 0x90 });
            patch(0x51fdd7, new byte[] { 0xe8, 0xe4, 0x4e, 0xff, 0xff }); // call 0x514cc0 HIDE

            // 8. Safehouse Milestones Loop: Hide padlock child + SKIP 0x28feadd CHECK mark (Clean Blank Card by default)
            patch(0x547cb1, new byte[] { 0xe8, 0x0a, 0xd0, 0xfc, 0xff }); // call 0x514cc0 HIDE
            patch(0x547d38, new byte[] { 0xb0, 0x01, 0x90, 0x84, 0xc0, 0x90, 0x90 });
            patch(0x547d70, new byte[] { 0xeb, 0x38, 0x90, 0x90 }); // jmp 0x547daa (skips default checkmark)

            // 9. Safehouse Milestones Cursor Selection: Hide padlock + SKIP 0x28feadd CHECK mark (Clean Blank Card by default)
            patch(0x52fe64, new byte[] { 0xe8, 0x57, 0x4e, 0xfe, 0xff }); // call 0x514cc0 HIDE
            patch(0x52fef3, new byte[] { 0xb0, 0x01, 0x90, 0x84, 0xc0 });
            patch(0x52ff2b, new byte[] { 0xeb, 0x68, 0x90, 0x90 }); // jmp 0x52ff95 (skips default checkmark)

            // 10. Blacklist menu: Skip padlock
            patch(0x52f55b, new byte[] { 0xeb, 0x0f });

            // 11. Hide padlock in car customization shop item selection (0x7a5c16: NOP NOP)
            patch(0x7a5c16, new byte[] { 0x90, 0x90 });

            // 12. Redirect shop show-padlock to hide-padlock (0x7a5c60 -> jmp 0x7a5c40)
            patch(0x7a5c60, new byte[] { 0xe9, 0xdb, 0xff, 0xff, 0xff });

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
        $procs = @(Get-Process speed -ErrorAction SilentlyContinue)
        $activeIds = @($procs | ForEach-Object { $_.Id })
        foreach ($p in $procs) {
            if (-not $patchedPids.Contains($p.Id)) {
                Start-Sleep -Milliseconds 350
                $ok = [VPNMemoryPatcher]::Apply($p.Id)
                if ($ok) {
                    [void]$patchedPids.Add($p.Id)
                    Log-Message "[+] speed.exe (PID: $($p.Id)) basariyla yamalandi! Safehouse, Sonny #15, Hero BMW M3 GTR, Kilitler (Sifir Ikon) aktif."
                }
            }
        }
        $toRemove = @($patchedPids | Where-Object { $_ -notin $activeIds })
        foreach ($id in $toRemove) {
            [void]$patchedPids.Remove($id)
        }
    } catch {}
    Start-Sleep -Milliseconds 500
}
