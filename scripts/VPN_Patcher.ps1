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

            // 2. Add ONLY Hero BMW M3 GTR (E3_DEMO_BMW: 0x03a94520) to garage and set as Active Car (0x5a39d1)
            // CRITICAL: Only set [esi] = active car slot. Do NOT touch CareerProfile+0xa8 here!
            // 0x5a3a8f will correctly write the preset hash (0x03a94520) to CareerProfile+0xa8 later.
            patch(0x5a39d1, new byte[] {
                0x68, 0x20, 0x45, 0xa9, 0x03, // push 0x03a94520 (E3_DEMO_BMW: Iconic Hero BMW M3 GTR)
                0x8b, 0xcf,                   // mov ecx, edi
                0xe8, 0x43, 0x63, 0xff, 0xff, // call 0x599d20 (AddCar)
                0x85, 0xc0,                   // test eax, eax
                0x74, 0x10,                   // je 0x5a39f1 (safe null check)
                0x8b, 0x08,                   // mov ecx, [eax] (car slot value)
                0x89, 0x0e,                   // mov [esi], ecx (CareerSettings->mActiveCar only)
                0x90, 0x90, 0x90, 0x90, 0x90, 0x90, // 12 NOPs (fill remaining space)
                0x90, 0x90, 0x90, 0x90, 0x90, 0x90
            });

            // 3. Skip Prologue / Ambush (DDay) races -> Enter Safehouse directly (0x5a3a47: jmp 0x5a3a7c)
            // After jmp, 0x5a3a7c computes bhash("E3_DEMO_BMW") = 0x03a94520 and 0x5a3a8f writes it
            // to CareerProfile+0xa8 — Safehouse uses this hash to find and render the iconic BMW!
            patch(0x5a3a47, new byte[] { 0xeb, 0x33 });

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
            // 8b. Safehouse card padlock bypass -> ALWAYS execute is_completed check (0x547cd0: 74 66 -> eb 66)
            patch(0x547cd0, new byte[] { 0xeb, 0x66 });
            // 8c. Safehouse refresh loop: skip padlock texture, allow checkmark show call (0x5301bd: 75 16 -> eb 16)
            patch(0x5301bd, new byte[] { 0xeb, 0x16 });

            // 9. CURSOR SELECTION CARD VISUALS (Zero Padlock + Proper Checkmark):
            // 9a. Cursor selection padlock show loop skip: jmp 0x52fe76 (0x52fe5f: 7e 15 -> eb 15)
            patch(0x52fe5f, new byte[] { 0xeb, 0x15 });
            // 9b. Cursor selection padlock bypass -> ALWAYS execute is_completed check (0x52fe81: 74 6e -> eb 6e)
            patch(0x52fe81, new byte[] { 0xeb, 0x6e });

            // 10. PHOTO TICKET / SPEED TRAP MILESTONE: DISABLED - types 9 & 10 lack valid handler
            // in 0x56e010 switch table, causing crash in 0x5881c0 constructor when selected.
            // patch(0x51f146, new byte[] { 0xeb, 0x1f, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 });

            // 11. Detail Card Lock Icon: Redirect show call to 0x514cc0 (HIDE)
            patch(0x51fdd7, new byte[] { 0xe8, 0xe4, 0x4e, 0xff, 0xff }); // call 0x514cc0 HIDE

            // 12. Blacklist menu: Skip padlock
            patch(0x52f55b, new byte[] { 0xeb, 0x0f });

            // 13. Hide padlock in car customization shop item selection
            patch(0x7a5c16, new byte[] { 0x90, 0x90 });
            patch(0x7a5c60, new byte[] { 0xe9, 0xdb, 0xff, 0xff, 0xff });

            // 14. MILESTONE MENU NULL GUARD (Crash fix at 0x5b15c4):
            // Comparator callback dereferences [eax+0x10] without null check on eax.
            // When milestone list contains uninitialized entries, eax=NULL -> crash.
            patch(0x5b15c0, new byte[] {
                0x8b, 0x44, 0x24, 0x04,  // mov eax, [esp+4]
                0x85, 0xc0,              // test eax, eax
                0x74, 0x10,              // je 0x5b15d8 (return true = skip)
                0x8b, 0x50, 0x10,        // mov edx, [eax+0x10]
                0x3b, 0x51, 0x04,        // cmp edx, [ecx+4]
                0x75, 0x08,              // jne 0x5b15d8
                0x89, 0x41, 0x08,        // mov [ecx+8], eax
                0x30, 0xc0,              // xor al, al
                0xc2, 0x04, 0x00,        // ret 4
                0xb0, 0x01,              // mov al, 1
                0xc2, 0x04, 0x00         // ret 4
            });

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
