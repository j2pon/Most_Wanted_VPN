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

            // 7. Autosave automatic enable on new profile creation (0x58e4b7, 0x58e905 & 0x58e984)
            // 0x58e4b7: xor eax, eax; mov [esp+10], eax; mov [esi+30], eax; mov [esi+3c], eax; mov byte ptr [esi+34], 1; push 0x14564fb9; push [esi+10]
            patch(0x58e4b7, new byte[] { 0x31, 0xc0, 0x89, 0x44, 0x24, 0x10, 0x89, 0x46, 0x30, 0x89, 0x46, 0x3c, 0xc6, 0x46, 0x34, 0x01, 0x68, 0xb9, 0x4f, 0x56, 0x14, 0xff, 0x76, 0x10 });
            // 0x58e905: mov [esi+30], eax; mov ecx, [0x925b14]; mov [esi+2c], ecx; mov byte ptr [esi+34], 1; nop; nop
            patch(0x58e905, new byte[] { 0x89, 0x46, 0x30, 0x8b, 0x0d, 0x14, 0x5b, 0x92, 0x00, 0x89, 0x4e, 0x2c, 0xc6, 0x46, 0x34, 0x01, 0x90, 0x90 });
            // 0x58e984: mov ecx, [0x925b14]; mov [esi+2c], ecx; mov [esi+30], ebx; mov byte ptr [esi+34], 1; nop; nop
            patch(0x58e984, new byte[] { 0x8b, 0x0d, 0x14, 0x5b, 0x92, 0x00, 0x89, 0x4e, 0x2c, 0x89, 0x5e, 0x30, 0xc6, 0x46, 0x34, 0x01, 0x90, 0x90 });

            // 8. UNLOCK MILESTONES IN ENGINE:
            // 8a. Rival Milestone Init Loop: NOP je 0x7aea4f (0x7aea37: 74 16 -> 90 90) -> sets is_unlocked = 1
            patch(0x7aea37, new byte[] { 0x90, 0x90 });
            // 8b. Safehouse Milestone Refresh: NOP je 0x547ee7 (0x547ecd: 74 18 -> 90 90) -> sets is_unlocked = 1
            patch(0x547ecd, new byte[] { 0x90, 0x90 });
            // 8c. Safehouse Milestone List: NOP je 0x548128 (0x5480e3: 74 43 -> 90 90) -> populates all milestones
            patch(0x5480e3, new byte[] { 0x90, 0x90 });
            // 8d. Safehouse Detail Refresh: NOP je 0x51fea3 (0x51fe8a: 74 17 -> 90 90) -> sets is_unlocked = 1
            patch(0x51fe8a, new byte[] { 0x90, 0x90 });
            // 8e. CareerManager::IsEventUnlocked: NOP je 0x5326df (0x5326d9: 74 04 -> 90 90) -> returns true (1)
            patch(0x5326d9, new byte[] { 0x90, 0x90 });
            // 8f. Milestone Start/Engage Event: JMP 0x532015 (0x531fb9: 75 5a -> eb 5a) -> starts pursuit directly
            patch(0x531fb9, new byte[] { 0xeb, 0x5a });

            // 9. SAFEHOUSE MILESTONE VISUALS (Zero Padlock Icon + Progressive Completion Medal/Check):
            // 9a. Safehouse card padlock child: call 0x514cc0 HIDE (instead of 0x514c70 SHOW)
            patch(0x547cb1, new byte[] { 0xe8, 0x0a, 0xd0, 0xfc, 0xff });
            // 9b. Safehouse hide path: execute hide unconditionally
            patch(0x547d38, new byte[] { 0xb0, 0x01, 0x90, 0x84, 0xc0, 0x90, 0x90 });
            // 9c. Safehouse skip default checkmark: jmp 0x547daa (uncompleted card remains clean & blank; completed cards get medal)
            patch(0x547d70, new byte[] { 0xeb, 0x38, 0x90, 0x90 });

            // 10. CURSOR SELECTION CARD VISUALS:
            // 10a. Cursor selection padlock: call 0x514cc0 HIDE
            patch(0x52fe64, new byte[] { 0xe8, 0x57, 0x4e, 0xfe, 0xff });
            // 10b. Cursor selection hide path
            patch(0x52fef3, new byte[] { 0xb0, 0x01, 0x90, 0x84, 0xc0 });
            // 10c. Cursor selection skip default checkmark: jmp 0x52ff95
            patch(0x52ff2b, new byte[] { 0xeb, 0x68, 0x90, 0x90 });
            // 10d. Cursor selection fallback padlock: call 0x514cc0 HIDE
            patch(0x52ff8d, new byte[] { 0xe8, 0x2e, 0x4d, 0xfe, 0xff });

            // 11. Detail Card Lock Icon:
            patch(0x51fdba, new byte[] { 0xb0, 0x01, 0x90, 0x84, 0xc0, 0x5e, 0x90, 0x90 });
            patch(0x51fdc0, new byte[] { 0x90, 0x90 });
            patch(0x51fdd7, new byte[] { 0xe8, 0xe4, 0x4e, 0xff, 0xff }); // call 0x514cc0 HIDE

            // 12. Blacklist menu: Skip padlock
            patch(0x52f55b, new byte[] { 0xeb, 0x0f });

            // 13. Hide padlock in car customization shop item selection
            patch(0x7a5c16, new byte[] { 0x90, 0x90 });
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
                    Log-Message "[+] speed.exe (PID: $($p.Id)) basariyla yamalandi! Safehouse, Sonny #15, Hero BMW M3 GTR, Milestones (Sifir Kilit & Oynanabilir), Autosave aktif."
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
