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

### A. BMW M3 GTR Rengi ve Kaplaması (Gümüş Gövde & Çift Kraliyet Mavisi Çizgili Efsane Hero Modeli)

- **Sorunun Nedeni (Düz Gri Görünme Sebebi):**
  - BMW M3 GTR'ın efsanevi çift çizgili kaplaması (`BMWM3GTRE46_STYLE01`), 4 renk katmanına sahip bir vinildir.
  - Önceki yapılandırmada Slot 72 (Vinil 1. Rengi), 146 numaralı palet rengi olan `5245` (`0x0cecd66a` - Beyaz/Açık Gümüş) seçiliydi.
  - Gövde taban boyası (Slot 76) `METAL_L1_COLOR02` (`3688` / `0xc7f2884e`) gümüş metalik yapıldığında, üzerindeki beyaz vinil çizgileri gümüş gövdeyle tamamen iç içe geçip kaynaşmış ve araba tek renk **DÜZ GRİ** görünmüştür.
  - Razor'un prologda bizden aldığı ve oyunun kapağındaki efsanevi modelde çizgiler koyu/kraliyet mavisidir.
- **Doğru İkonik Hero BMW Parça ve Renk Konfigürasyonu:**
  - **Slot 70:** `5243` (`0x1d4df540` - `BMWM3GTRE46_BODY` - Orijinal GTR Gövde Kiti, Kaput Izgaraları ve Yan Egzozlar)
  - **Slot 71:** `5244` (`0xa0568921` - `BMWM3GTRE46_STYLE01` - Çift Yarış Çizgisi Vinili)
  - **Slot 72:** `5249` (`0x655c846e` - Vinil 1. Rengi: Parlak Kraliyet Mavisi / Royal Blue Swatch)
  - **Slot 73:** `5257` (`0x3b786fef` - Vinil 2. Rengi: Koyu Lacivert / Navy Blue Swatch)
  - **Slot 74:** `5264` (`0x3b786fef` - Vinil 3. Rengi: Koyu Lacivert Detay Çizgisi)
  - **Slot 75:** `5270` (`0x655c846e` - Vinil 4. Rengi: Mavi Vurgu)
  - **Slot 76:** `3688` (`0xc7f2884e` - `METAL_L1_COLOR02` - Orijinal Metalik Gümüş Gövde Boyası)
  - **Slot 77:** `4545` (`0xe9886d54` - Orijinal Açık Cam Filmi)
  - **Slot 79:** `3809` (`0xd0561e8c` - Orijinal BBS Ön Jant)
  - **Slot 80:** `3811` (`0xd0561e8e` - Orijinal BBS Arka Jant)
- **Uygulanan Yerler:**
  - `GLOBAL/GLOBALB.BUN` ve `GLOBAL/GlobalB.lzc` (`M3GTRCAREERSTART`, `E3_DEMO_BMW`, `CE_GTRSTREET` kayıtları)
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

### C. Milestone (Kilometre Taşları) Simgeleri (Sıfır Kilit, Sıfır Önceden Tik, Tamamlandıkça Gelen Tik)

- **Sorunun Nedeni (Tüm Taşlarda Önceden Tik Görünme Sebebi):**
  - SafeHouse Milestones döngüsünde (`0x547c80`–`0x547dae`), oyun her kart için önce kilit alt-nesnesini görünür kılar (`0x547cb1: call 0x514c70`).
  - Ardından `0x547ccb` adresinde `[ebx + 0x16]` (is_completed) kontrolü yapar.
  - Eğer tamamlanmamışsa `0x547d38` (is_unlocked) kontrolüne dalar. Önceki yamada bu kilit açılmış sayılsın diye `al = 1` zorlandığında, oyun kod akışı EA'nın kilit açma dalına düşmüş ve `0x547d96` adresinde `ecx = 0x28feadd` (`CHECK` = Yeşil Tik simgesi) atayarak tamamlanmamış tüm taşların üzerine **TİK** basmıştır.
  - Kullanıcının kesin talebi: **"Orada hiçbir ikon olmayacak (ne kilit ne tik), oyuncu görevi tamamladıkça tik gelecek."**
- **Uygulanan Kusursuz Mantık:**
  1. **SafeHouse Milestones Kilit Gizleme (`0x547cb1` - 5 Bayt):**
     - Orijinal: `e8 ba cf fc ff` (`call 0x514c70` - Kilidi Göster)
     - Yama: `e8 0a d0 fc ff` (`call 0x514cc0` - Kilidi Gizle)
     - Etki: Kartlar oluşturulurken kilit nesnesi hiçbir zaman gösterilmez.
  2. **SafeHouse Milestones Tik Atlaması (`0x547d70` - 4 Bayt):**
     - Orijinal: `85 c0 74 36` (`test eax, eax; je 0x547daa`)
     - Yama: `eb 38 90 90` (`jmp 0x547daa; 2x nop`)
     - Etki: `0x547d65` çağrısı `MEDAL_THUMB` simge kutusunu gizledikten hemen sonra `0x547daa`'ya atlar. Asla `0x28feadd` (`CHECK`) atanmaz. Görev tamamlanmamışsa kart üzerinde **SIFIR İKON (TERTEMİZ BOŞ)** görünür.
  3. **Tamamlandıkça Gelme Garantisi:**
     - Oyuncu bir milestone görevini bitirdiğinde `[ebx + 0x16] != 0` olur.
     - Oyun `0x547cd0` atlamasını yapmaz, doğal tamamlama kodunu çalıştırır (`0x547d31: mov ecx, 0x18ed48` ve `or [eax+0x1c], 0x2400000`). Tamamlanan taşa tik/madalya simgesi eklenir ("yaptıkça gelir").
  4. **SafeHouse İmleç Seçim Kartı Mantığı (`0x52fe64` ve `0x52ff2b`):**
     - `0x52fe64` kilit gösterme çağrısı `call 0x514cc0` (gizle) ile değiştirildi.
     - `0x52ff2b` adresi `eb 68 90 90` (`jmp 0x52ff95`) yapılarak imleçle seçilen kartın da tamamlanmamışsa tik göstermesi engellendi.
  5. **Diğer Menü Kilit Gizlemeleri:**
     - `0x51fdba` & `0x51fdd7`: Detay ekranı kilit kontrolü ve kilit gizleme.
     - `0x52f55b`: Blacklist menüsü kilit göstermeyi atlama (`eb 0f`).

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
| `0x547cb1` | `e8 ba cf fc ff` | `e8 0a d0 fc ff` | SafeHouse Milestones kilit nesnesi göstermeyi gizlemeye çevirme |
| `0x547d70` | `85 c0 74 36` | `eb 38 90 90` | SafeHouse Milestones tamamlanmamışsa tik ikonunu atlama (sıfır ikon) |
| `0x547d38` | `8a 43 17 84 c0 74 6b` | `b0 01 90 84 c0 90 90` | SafeHouse Milestones gizleme yoluna yönlendirme |
| `0x52fe64` | `e8 07 4e fe ff` | `e8 57 4e fe ff` | SafeHouse seçim kartı kilit göstermeyi gizlemeye çevirme |
| `0x52ff2b` | `85 c0 74 66` | `eb 68 90 90` | SafeHouse seçim kartı tamamlanmamışsa tik ikonunu atlama |
| `0x52fef3` | `8a 43 17 84 c0` | `b0 01 90 84 c0` | SafeHouse seçim kartı gizleme yoluna yönlendirme |
| `0x52f55b` | `75 0f` | `eb 0f` | Blacklist menüsü kilit göstermeyi atlama |
| `0x51fdba` | `8a 47 17 84 c0 5e 74 11` | `b0 01 90 84 c0 5e 90 90` | Genel Milestone kilit göstermeyi kapatma |
| `0x51fdd7` | `e8 b4 ce fc ff` | `e8 e4 4e ff ff` | Detay ekranı kilit gizleme çağrısı |
| `0x58e4b7` | `31 c0 89 44 24 10 89 46 30 88 46 34 89 46 3c 8b 46 10 68 b9 4f 56 14 50` | `31 c0 89 44 24 10 89 46 30 89 46 3c c6 46 34 01 68 b9 4f 56 14 ff 76 10` | Profil oluşturulunca Autosave açık (`[esi+0x34]=1`) |
| `0x58e905` | `89 46 2c 8b 0d 14 5b 92 00 89 4e 2c 89 46 30 88 46 34` | `89 46 30 8b 0d 14 5b 92 00 89 4e 2c c6 46 34 01 90 90` | İkincil profil yapıcısında Autosave açık (`[esi+0x34]=1`) |
| `0x7f53ed` | `0f 85 a1 00 00 00` | `eb 10 90 90 90 90` | Save dosyası kontrol baypası |
| `Save Slot 72..75`| `5245, 5252, 5259, 5266` | `5249, 5257, 5264, 5270` | BMW M3 GTR Çift Kraliyet Mavisi / Koyu Mavi Çizgiler |
| `Save Slot 76` | `0` veya `65535` | `3688` (`0x0e68`) | BMW M3 GTR Metalik Gümüş Gövde Boyası (`METAL_L1_COLOR02`) |

---

## 4. ASI Yamasının Çalışma Mantığı (`scripts/MWCrashFix.asi`)

- `MWCrashFix.asi` içinde `DllMain` (`0x10000649`), `0x10001338` adresine dallanır.
- Konumdan Bağımsız Kodlama (Position-Independent Code - PIC) ile derlenmiştir:
  1. `call $+5; pop ebx; and ebx, 0xffff0000`: DLL Windows tarafından hangi bellek tabanına (ImageBase) yüklenirse yüklensin anlık baz adres tespit edilir.
  2. `VirtualProtect(0x401000, 0x490000, PAGE_EXECUTE_READWRITE, &oldProtect)` çağrılarak `speed.exe` kod alanı yazılabilir yapılır.
  3. 12 adet kritik bellek yaması tablodan okunarak `rep movsb` ile tek seferde yazılır.
  4. Orijinal CrashFix işlevi (`call 0x10000450`) çağrılır ve kayıtçı registerlar eksiksiz korunarak oyunun normal döngüsüne dönülür.

Bu sayede harici arka plan işlemlerine gerek kalmadan, oyun ister masaüstünden ister doğrudan `speed.exe`'den başlatılsın tüm sistemler anında, hatasız ve kusursuz olarak çalışır.

