# Need for Speed Most Wanted: VPN Edition - Mod & Bellek Yamaları Rehberi (Geliştirici Dokümantasyonu)

Bu doküman, Need for Speed Most Wanted (VPN Edition) modunda yapılan tüm bellek müdahalelerini, dosya düzenlemelerini, veri slotlarını ve mimari yapıyı detaylandırmaktadır. Amaç, gelecekte yapılacak düzenlemelerde çalışan sistemlerin bozulmasını önlemek ve tek bir standart üzerinden geliştirmeye devam etmektir.

---

## 1. Mimarinin Temel İlkeleri

1. **`speed.exe` Bütünlüğü:**
   - `speed.exe` dosyası disk üzerinde bozulmaz veya doğrudan bayt yamasıyla değiştirilmez.
   - Oyun doğrudan `speed.exe`'den başlatılır.
   - Harici arka plan scriptlerine (PowerShell watcher vb.) bağımlılık yoktur.

2. **ASI Eklenti Motoruyla Sıfır Gecikmeli RAM Yaması (`scripts/MWCrashFix.asi`):**
   - Oyun başlatıldığında `dinput8.dll` ASI yükleyicisi, `scripts/` klasöründeki eklentileri yükler.
   - `MWCrashFix.asi` içerisine entegre edilen hafif bellek yamalama rutini (`0x10001f38`), DLL yüklenme anında (`DLL_PROCESS_ATTACH`) tek seferde `VirtualProtect` çağırarak oyunun kod segmentine yamaları enjekte eder.
   - Bu işlem 0.1 milisaniyeden kısa sürer, oyun çalışırken sıfır işlemci/FPS yükü bindirir.

---

## 2. Düzeltilen Sorunlar ve Teknik Detayları

### A. BMW M3 GTR Rengi ve Kaplaması (Gümüş - Çift Mavi Çizgili İkonik Görünüm)

- **Sorunun Nedeni:**
  - `GLOBALB.BUN` ve `GlobalB.lzc` dosyalarında BMW ön ayar kayıtlarında (`M3GTRCAREERSTART`, `E3_DEMO_BMW`, `CE_GTRSTREET`) boya slotu (Slot 76 / Veri dizininde index 82) sıfırlandığında (`0x00000000`), oyun araca hiçbir boya partı yükleyemez (`0xffff` / 65535).
  - NFSMW shader motoru, boya tanımlanmadığında aracı varsayılan olarak **KIRMIZI** boyar.
  - Daha önce sarı/siyah görünmesinin nedeni ise sarı/altın tonlu `METAL_L1_COLOR41` (`0xc7f288d1`) veya koyu swatcher kullanılmasıydı.
- **Doğru İkonik Hero BMW Parça Konfigürasyonu:**
  - **Slot 70:** `0x1d4df540` (`BMWM3GTRE46_BODY` - Orijinal Gövde/Kaput)
  - **Slot 71:** `0xa0568921` (`BMWM3GTRE46_STYLE01` - Çift Mavi Çizgili İkonik Vinil)
  - **Slot 76 (Save dosyası Part Index 3688 / GlobalB Index 82):** `0xc7f2884e` (`METAL_L1_COLOR02` - Challenge Series #68'deki Orijinal Metalik Gümüş Boya)
  - **Slot 77:** `0xe9886d54` (Cam Filmi)
  - **Slot 79:** `0xd0561e8c` (Gümüş BBS Jant)
  - **Slot 80:** `0xd0561e8e` (Gümüş BBS Jant)
- **Uygulanan Yerler:**
  - `GLOBAL/GLOBALB.BUN` ve `GLOBAL/GlobalB.lzc`
  - `github/GLOBAL/GLOBALB.BUN` ve `github/GLOBAL/GlobalB.lzc`
  - `save/`, `save_baslangic/`, `save_kaze/` ve `Belgeler/NFS Most Wanted/` altındaki tüm 32 adet save dosyasındaki Car 00, Car 29 ve Car 30 kayıtları.
  - Aktif oyun oturumu (PID 2884) RAM belleği.

---

### B. Otomatik Kayıt (Autosave) Profil Açılınca Devre Dışı Kalma Sorunu

- **Sorunun Nedeni:**
  - `speed.exe` içerisindeki profil yapıcı fonksiyonlarında (`UserProfile::UserProfile`):
    - `0x58e4c0`: `mov byte ptr [esi + 0x34], al` (`al = 0`)
    - `0x58e914`: `mov byte ptr [esi + 0x34], al` (`al = 0`)
  - `[Profile + 0x34]` bayrağı oyunun Autosave etkin/devre dışı durumunu belirler. 0 olduğunda oyun autosave'i otomatik olarak kapatır ve arayüzde autosave devre dışı uyarısı çıkar.
- **Yapılan RAM Yaması:**
  - **0x58e4b7 (24 Bayt):**
    ```assembly
    xor eax, eax
    mov [esp+0x10], eax
    mov [esi+0x30], eax
    mov [esi+0x3c], eax
    mov byte ptr [esi+0x34], 1      ; <-- AUTOSAVE OTOMATİK ETKİN
    push 0x14564fb9
    push dword ptr [esi+0x10]
    ```
    (Makine Kodu: `31 c0 89 44 24 10 89 46 30 89 46 3c c6 46 34 01 68 b9 4f 56 14 ff 76 10`)
  - **0x58e905 (18 Bayt):**
    ```assembly
    mov [esi+0x30], eax
    mov ecx, [0x925b14]
    mov [esi+0x2c], ecx
    mov byte ptr [esi+0x34], 1      ; <-- AUTOSAVE OTOMATİK ETKİN
    nop
    nop
    ```
    (Makine Kodu: `89 46 30 8b 0d 14 5b 92 00 89 4e 2c c6 46 34 01 90 90`)
- **Sonuç:** Yeni kariyer veya profil açıldığında autosave varsayılan olarak `1` (açık) gelir.

---

### C. Milestone (Kilometre Taşları) Kilit Simgeleri

- **Sorunun Nedeni:**
  - SafeHouse Milestones ekranı oluşturulurken (`0x547c30` döngüsü), oyun ilk başta her `MEDAL_THUMB` için kilit simgesini görünür kılar.
  - Ardından `0x547d38` adresinde `[ebx + 0x17]` (is_unlocked) kontrolü yapar. Eğer kilitliyse (`je 0x547daa`), kilit gizleme çağrısını (`0x547d65: call 0x514cc0`) atlar ve kilit simgesi ekranda kalır.
  - Benzer şekilde menü gezinmesinde (`0x52fef3`), Blacklist listesinde (`0x52f55b`) ve Milestone kontrolünde (`0x51fdba`) kilit gösterme çağrıları tetiklenir.
- **Yapılan RAM Yamaları:**
  1. **SafeHouse Milestones Ana Render Döngüsü (`0x547d38` - 7 Bayt):**
     - Orijinal: `8a 43 17 84 c0 74 6b` (`mov al, [ebx+0x17]; test al, al; je 0x547daa`)
     - Yama: `b0 01 90 84 c0 90 90` (`mov al, 1; nop; test al, al; nop; nop`)
     - Etki: Tüm milestone kartlarında kilit simgesi anında gizlenir (`call 0x514cc0`).
  2. **SafeHouse Milestones Seçim Gezinmesi (`0x52fef3` - 5 Bayt):**
     - Orijinal: `8a 43 17 84 c0` (`mov al, [ebx+0x17]; test al, al`)
     - Yama: `b0 01 90 84 c0` (`mov al, 1; nop; test al, al`)
     - Etki: Liste üzerinde gezinirken kilit açılmaz, açık kabul edilir.
  3. **Blacklist Menüsü Milestone Listesi (`0x52f55b` - 2 Bayt):**
     - Orijinal: `75 0f` (`jne 0x52f56c`)
     - Yama: `eb 0f` (`jmp 0x52f56c`)
     - Etki: `0x514c70` (kilit göster) çağrısını doğrudan atlayarak `0x514cc0` (kilit gizle) çağrısına yönlendirir.
  4. **Milestone Kilit Kontrolü 2 (`0x51fdba` - 8 Bayt):**
     - Orijinal: `8a 47 17 84 c0 5e 74 11`
     - Yama: `b0 01 90 84 c0 5e 90 90`
     - Etki: Kilit simgesi gösterme çağrısını devre dışı bırakır.

---

### D. Save Dosyası Bütünlüğü ve Bozuk Save Hatası Engeli

- **Adres `0x7f53ed` (6 Bayt):**
  - Orijinal: `0f 85 a1 00 00 00` (`jne 0x7f5494`)
  - Yama: `eb 10 90 90 90 90` (`jmp +0x10; 4x nop`)
  - Etki: Modlu save dosyaları yüklenirken oluşabilecek sahte "Save file is corrupt" kontrolünü baypas eder.

---

## 3. Yapılandırma Tablosu (Hızlı Referans)

| Offset / Adres | Orijinal Baytlar | Yeni Baytlar | Fonksiyon / Amaç |
|---|---|---|---|
| `0x547d38` | `8a 43 17 84 c0 74 6b` | `b0 01 90 84 c0 90 90` | SafeHouse Milestones kilit simgelerini gizleme |
| `0x52fef3` | `8a 43 17 84 c0` | `b0 01 90 84 c0` | SafeHouse seçim esnasında kilit gizleme |
| `0x52f55b` | `75 0f` | `eb 0f` | Blacklist menüsü kilit göstermeyi atlama |
| `0x51fdba` | `8a 47 17 84 c0 5e 74 11` | `b0 01 90 84 c0 5e 90 90` | Genel Milestone kilit göstermeyi kapatma |
| `0x58e4b7` | `31 c0 89 44 24 10 89 46 30 88 46 34 89 46 3c 8b 46 10 68 b9 4f 56 14 50` | `31 c0 89 44 24 10 89 46 30 89 46 3c c6 46 34 01 68 b9 4f 56 14 ff 76 10` | Profil oluşturulunca Autosave açık (`[esi+0x34]=1`) |
| `0x58e905` | `89 46 2c 8b 0d 14 5b 92 00 89 4e 2c 89 46 30 88 46 34` | `89 46 30 8b 0d 14 5b 92 00 89 4e 2c c6 46 34 01 90 90` | İkincil profil yapıcısında Autosave açık (`[esi+0x34]=1`) |
| `0x7f53ed` | `0f 85 a1 00 00 00` | `eb 10 90 90 90 90` | Save dosyası kontrol baypası |
| `GLOBALB Index 82` | `0x00000000` | `0xc7f2884e` | BMW M3 GTR Orijinal Gümüş Metalik Boya (`METAL_L1_COLOR02`) |
| `Save Slot 76` | `0` veya `65535` | `3688` (`0x0e68`) | Save içindeki BMW M3 GTR Metalik Gümüş Parça Kodu |

---

## 4. ASI Yamasının Çalışma Mantığı (`MWCrashFix.asi`)

- `MWCrashFix.asi` içinde boş olan `.text` bölümünün sonundaki 207 baytlık alana (`VA 0x10001f38`) kompakt bir bellek kopyalama döngüsü yerleştirilmiştir.
- `DllMain` (`0x10001249`) çağrısı buraya yönlendirilmiştir.
- Çalışma sırası:
  1. Orijinal kaza düzeltme yaması çağrılır (`call 0x10001050`).
  2. `VirtualProtect(0x401000, 0x490000, PAGE_EXECUTE_READWRITE, &oldProtect)` çağrılarak `speed.exe`'nin kod alanı yazılabilir yapılır.
  3. Yukarıdaki 7 adet yama tablodan okunarak `rep movsb` ile bellek adreslerine yazılır.
  4. Registerlar geri yüklenir (`popal; pop ebp; ret`) ve oyun standart açılışına devam eder.

Bu sayede oyun hangi klasörden veya doğrudan `speed.exe` üzerinden çalıştırılırsa çalıştırılsın, tüm yamalar otomatik ve anlık olarak devreye girer.
