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

            // 3. Skip Prologue / Ambush (DDay) races -> Fall directly into Safehouse State 2 setup (0x5a3a47 -> NOP NOP)
            patch(0x5a3a47, new byte[] { 0x90, 0x90 });

            // 4. Force Sonny #15 setup and clean jump to save initialization (calls 0x666fe0 / 0x6596e0 at 0x5a3b30, fixing autosave)
            patch(0x5a3a66, new byte[] { 0xc6, 0x46, 0x08, 0x0f, 0xe9, 0xc1, 0x00, 0x00, 0x00, 0x90, 0x90, 0x90 });

            // 5. Bypass save checksum mismatch / corruption check (0x7f53ed: je -> jmp 0x7f53ff)
            patch(0x7f53ed, new byte[] { 0xeb, 0x10 });

            // 6. Safehouse detail card lock icon: Force unlocked state (0x51fdba: mov al, 1; nop) + NOP jump at 0x51fdc0
            patch(0x51fdba, new byte[] { 0xb0, 0x01, 0x90 });
            patch(0x51fdc0, new byte[] { 0x90, 0x90 });
            patch(0x51fdd7, new byte[] { 0xe8, 0xe4, 0x4e, 0xff, 0xff }); // call 0x514cc0 HIDE

            // 7. Safehouse milestone thumbnail cards: Force unlocked state (0x52fef3: mov al, 1; nop) -> hides lock and displays unlocked card texture
            patch(0x52fef3, new byte[] { 0xb0, 0x01, 0x90 });
            patch(0x52ff8d, new byte[] { 0xe8, 0x2e, 0x4d, 0xfe, 0xff }); // call 0x514cc0 HIDE

            // 8. Hide padlock in car customization shop item selection (0x7a5c16: NOP NOP)
            patch(0x7a5c16, new byte[] { 0x90, 0x90 });

            // 9. Redirect shop show-padlock to hide-padlock (0x7a5c60 -> jmp 0x7a5c40)
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
                    Log-Message "[+] speed.exe (PID: $($p.Id)) basariyla yamalandi! Safehouse, Sonny #15, Hero BMW M3 GTR, Kilitler ve Otomatik Kayit aktif."
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
