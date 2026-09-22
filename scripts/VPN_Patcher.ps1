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

            // 2. Add ONLY Hero BMW M3 GTR to garage and set as Active Car (0x5a39d1)
            patch(0x5a39d1, new byte[] {
                0x68, 0x20, 0x45, 0xa9, 0x03, // push 0x03a94520 (E3_DEMO_BMW)
                0x8b, 0xcf,                   // mov ecx, edi
                0xe8, 0x43, 0x63, 0xff, 0xff, // call 0x599d20 (AddCar)
                0x8b, 0x08,                   // mov ecx, [eax]
                0x89, 0x0e,                   // mov [esi], ecx (Active car = BMW M3 GTR!)
                // 16 NOPs to completely eliminate Cobalt SS addition:
                0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90,
                0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90
            });

            // 3. Skip Prologue / Ambush (DDay) races (0x5a3a47 -> NOP je 0x5a3a7c) -> Enter Safehouse directly
            patch(0x5a3a47, new byte[] { 0x90, 0x90 });

            // 4. Ensure rival Sonny #15 is set (0x5a3a6c: 6x NOP je 0x5a3b4e - avoids FPU corruption)
            patch(0x5a3a6c, new byte[] { 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 });

            // 5. Bypass save checksum mismatch / corruption check (0x7f53ed: je -> jmp 0x7f53ff)
            patch(0x7f53ed, new byte[] { 0xeb, 0x10, 0x90, 0x90, 0x90, 0x90 });

            // 6. Autosave automatic enable on new profile creation (exact 3-byte 'inc byte ptr [esi+0x34]' - preserves all vtables & registers)
            patch(0x58e4c0, new byte[] { 0xfe, 0x46, 0x34 });
            patch(0x58e914, new byte[] { 0xfe, 0x46, 0x34 });
            patch(0x58e993, new byte[] { 0xfe, 0x46, 0x34 });

            // 7. UNLOCK MILESTONES IN ENGINE (Playable & Selectable):
            // 7a. Safehouse Milestone List: NOP je 0x548128 (0x5480e3: 74 43 -> 90 90) -> populates all milestones
            patch(0x5480e3, new byte[] { 0x90, 0x90 });
            // 7b. CareerManager::IsEventUnlocked: NOP je 0x5326df (0x5326d9: 74 04 -> 90 90) -> returns true (1)
            patch(0x5326d9, new byte[] { 0x90, 0x90 });

            // 8. SAFEHOUSE MILESTONE VISUALS (Zero Padlock Icon + Progressive Completion Checkmark):
            // 8a. Safehouse card padlock show loop skip: jmp 0x547cc3 (0x547ca7: 7e 1a -> eb 1a)
            patch(0x547ca7, new byte[] { 0xeb, 0x1a });
            // 8b. Safehouse card padlock texture skip: jmp 0x547daa (0x547d2f: 75 79 -> eb 79)
            patch(0x547d2f, new byte[] { 0xeb, 0x79 });
            // 8c. Safehouse refresh loop: skip padlock texture, render flag and show call (0x5301bd: 75 16 -> eb 48)
            patch(0x5301bd, new byte[] { 0xeb, 0x48 });

            // 9. CURSOR SELECTION CARD VISUALS (Crash-proof forward jump):
            // 9a. Cursor selection padlock show loop skip: jmp 0x52fe76 (0x52fe5f: 7e 15 -> eb 15)
            patch(0x52fe5f, new byte[] { 0xeb, 0x15 });
            // 9b. Cursor selection skip lock texture & render: clean forward jmp 0x52ff95 (0x52fee6: 0f 85 a9 00 00 00 -> e9 aa 00 00 00 90)
            patch(0x52fee6, new byte[] { 0xe9, 0xaa, 0x00, 0x00, 0x00, 0x90 });

            // 10. Detail Card Lock Icon: Redirect show call to 0x514cc0 (HIDE)
            patch(0x51fdd7, new byte[] { 0xe8, 0xe4, 0x4e, 0xff, 0xff }); // call 0x514cc0 HIDE

            // 11. Blacklist menu: Skip padlock
            patch(0x52f55b, new byte[] { 0xeb, 0x0f });

            // 12. Hide padlock in car customization shop item selection
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
    Start-Sleep -Milliseconds 100
}
