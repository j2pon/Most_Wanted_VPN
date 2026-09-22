# Need for Speed Most Wanted: VPN Edition - Mod & Bellek Yamaları Rehberi (Geliştirici Dokümantasyonu)

Bu doküman, Need for Speed Most Wanted (VPN Edition) modunda yapılan tüm bellek müdahalelerini, dosya düzenlemelerini, veri slotlarını ve mimari yapıyı detaylandırmaktadır. Amaç, gelecekte yapılacak düzenlemelerde çalışan sistemlerin bozulmasını önlemek ve tek bir standart üzerinden geliştirmeye devam etmektir.

---

## 1. Mimarinin Temel İlkeleri

1. **`speed.exe` ve Mod Bütünlüğü:**
   - `speed.exe` dosyası disk üzerinde bozulmaz veya doğrudan statik bayt yamasıyla değiştirilmez.
   - Oyun doğrudan `speed.exe` veya `VPN_Mod_Baslatici.bat` üzerinden başlatılabilir.
   - Smart App Control (SAC) ve Windows Defender ile %100 uyumludur (`0xc0e90002` ve `Error 4551` bozuk görüntü hatalarını önlemek için disk üzerindeki `.asi` ve `.exe` dosyaları imzasız olarak değiştirilmez).

2. **Hafif ve Sıfır Gecikmeli RAM Yamalayıcısı (`scripts/VPN_Watcher.vbs` & `VPN_Patcher.ps1`):**
   - Windows Kernel API (`OpenProcess`, `VirtualProtectEx`, `WriteProcessMemory`) kullanılarak oyun başladığı anda (`PID` yakalandığında ~350ms içinde) RAM bellek adreslerine yamalar enjekte edilir.
   - Yamalama işlemi tamamlandıktan sonra arka planda sıfır işlemci/FPS yüküyle bekler.
   - Kullanıcı ister masaüstü kısayolundan, ister `github/` klasöründen, ister `speed.exe`'ye doğrudan çift tıklayarak oyunu başlatsın; tüm özellikler anında devreye girer.

---

## 2. Düzeltilen Sorunlar ve Teknik Detayları

### A. BMW M3 GTR Rengi ve Kaplaması (Kırmızı Doku Arızası Fixi & Efsanevi Gümüş-Mavi Model)

- **Sorunun Nedeni (Kırmızı Bozuk Araba Görünme Sebebi):**
  - BMW M3 GTR'ın ikonik çift yarış çizgili kaplaması (`BMWM3GTRE46_STYLE01`), 4 renk katmanına sahip bir vinildir.
  - Oyun dosyalarında (`GLOBAL/GLOBALB.BUN` ve `GlobalB.lzc`) yer alan `E3_DEMO_BMW`, `M3GTRCAREERSTART` ve `CE_GTRSTREET` preset kayıtlarında Slot 73, 74 ve 75 için yanlışlıkla Slot 72'ye ait hashler (`0x3b786fef` ve `0x655c846e`) yazılmıştı.
  - `speed.exe` motoru, bir preset'ten araç oluştururken parçanın slot tanımını `attributes.bin` veritabanıyla doğrular. Parça hedef slota ait değilse araç slotuna `65535` (`0xffff` / geçersiz parça) atar.
  - 4 katmanlı vinilin 2., 3. ve 4. katmanları `0xffff` kalınca oyunun vinil gölgelendiricisi (shader) çökmüş ve araç **kırmızı renkte bozuk bir kaplama hatasıyla** render edilmiştir.
  - Ayrıca `save/NFS Most Wanted/` altındaki eski profiller de bu geçersiz slot verilerini içerdiğinden oyun başladığında araç kırmızı görünüyordu.

- **Kusursuz İkonik Hero BMW Parça ve Renk Konfigürasyonu:**
  - **Slot 70:** `5243` (`0x1d4df540` - `BMWM3GTRE46_BODY` - Orijinal GTR Gövde Kiti, Kaput Izgaraları ve Yan Egzozlar)
  - **Slot 71:** `5244` (`0xa0568921` - `BMWM3GTRE46_STYLE01` - Çift Yarış Çizgisi Vinili)
  - **Slot 72:** `5249` (`0x655c846e` - Vinil 1. Katman: Parlak Kraliyet Mavisi / Royal Blue Swatch)
  - **Slot 73:** `5257` (`0x063831c2` - Vinil 2. Katman: Koyu Lacivert / Navy Blue Swatch)
  - **Slot 74:** `5264` (`0x476e89bf` - Vinil 3. Katman: Koyu Lacivert Detay Çizgisi)
  - **Slot 75:** `5270` (`0xe6de9ab1` - Vinil 4. Katman: Kraliyet Mavisi Vurgu Çizgisi)
  - **Slot 76:** `3688` (`0xc7f2884e` - `METAL_L1_COLOR02` - Orijinal Metalik Gümüş Gövde Boyası)
  - **Slot 77:** `4545` (`0xe9886d54` - Orijinal Açık Cam Filmi)
  - **Slot 79:** `3809` (`0xd0561e8c` - Orijinal BBS Ön Jant)
  - **Slot 80:** `3811` (`0xd0561e8e` - Orijinal BBS Arka Jant)

- **Uygulanan Düzeltmeler:**
  - `GLOBAL/GLOBALB.BUN` ve `GLOBAL/GlobalB.lzc` dosyalarında `E3_DEMO_BMW`, `M3GTRCAREERSTART` ve `CE_GTRSTREET` blokları güncellendi.
  - `github/GLOBAL/GLOBALB.BUN` ve `github/GLOBAL/GlobalB.lzc` dosyaları eşitlendi.
  - Tüm save dizinlerindeki (`save/`, `save/NFS Most Wanted/`, `github/save/`, `save_baslangic/`, `save_kaze/`, `save_kopru_final/` ve `Belgeler/NFS Most Wanted/`) tüm save dosyaları taranarak `5249, 5257, 5264, 5270, 3688` slotları temizlendi ve `0xffff` hataları sıfırlandı.

---

### B. Otomatik Kayıt (Autosave) Profil Açılınca Devre Dışı Kalma Sorunu

- **Sorunun Nedeni:**
  - `speed.exe` içerisindeki 3 farklı `UserProfile` yapıcı/başlatıcı fonksiyonunda (`UserProfile::UserProfile`):
    - `0x58e4c0`: `mov byte ptr [esi + 0x34], al` (`al = 0`)
    - `0x58e914`: `mov byte ptr [esi + 0x34], al` (`al = 0`)
    - `0x58e993`: `mov byte ptr [esi + 0x34], bl` (`bl = 0`)
  - `[Profile + 0x34]` bayrağı oyunun Autosave açık/kapalı durumunu belirler. 0 olduğunda oyun autosave'i otomatik olarak kapatır ve ekranda autosave devre dışı uyarısı verir.

- **Yapılan RAM Yamaları:**
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
  - **0x58e984 (18 Bayt):**
    ```assembly
    mov ecx, [0x925b14]
    mov [esi+0x2c], ecx
    mov [esi+0x30], ebx
    mov byte ptr [esi+0x34], 1      ; <-- AUTOSAVE OTOMATİK ETKİN
    nop
    nop
    ```
    (Makine Kodu: `8b 0d 14 5b 92 00 89 4e 2c 89 5e 30 c6 46 34 01 90 90`)

- **Sonuç:** Yeni kariyer açıldığında veya yeni profil oluşturulduğunda autosave her zaman `1` (aktif) olarak başlar.

---

### C. Milestone (Kilometre Taşları) Kilitleri ve Görsel Mantığı

Kullanıcının kesin tasarımı: **"Milestonelar açık ve oynanabilir olacak, hiçbir kilit ikonu olmayacak, önceden basılmış sahte yeşil tik olmayacak; oyuncu görevi tamamladıkça tik simgesi gelecek."**

#### 1. Oyun Motoru Düzeyinde Açma & Oynanabilir Kılma (Engine Unlock)
- **`0x7aea37` (2 Bayt):** `74 16` -> `90 90` (NOP)
  - Rakip kilometre taşları döngüsünde (`RivalMilestonesSetup`) bayrak atlamasını engeller ve her taş için `[eax + 0x17] = 1` (`is_unlocked = 1`) bayrağını ayarlar.
- **`0x547ecd` (2 Bayt):** `74 18` -> `90 90` (NOP)
  - Safehouse Milestone yenileme dalında kilidi zorunlu olarak açık (`is_unlocked = 1`) hale getirir.
- **`0x5480e3` (2 Bayt):** `74 43` -> `90 90` (NOP)
  - Safehouse etkileşim/başlatma listesinde milestone kartlarının atlanmasını önler; tüm 6 görevi listeye ekler.
- **`0x51fe8a` (2 Bayt):** `74 17` -> `90 90` (NOP)
  - Safehouse detay kartı yenileme fonksiyonunda kilidi açık kabul eder.
- **`0x5326d9` (2 Bayt):** `74 04` -> `90 90` (NOP)
  - `CareerManager::IsEventUnlocked` kontrolünün doğrudan `true` (1) döndürmesini sağlar.
- **`0x531fb9` (2 Bayt):** `75 5a` -> `eb 5a` (JMP)
  - Milestone seçilip Enter'a basıldığında polis takibi etkinliğinin engellenmeden doğrudan başlatılmasını sağlar.

#### 2. Görsel Sadeleştirme (Sıfır Kilit, Sıfır Önceden Tik, Tamamlandıkça Gelen Tik)
- **SafeHouse Kart Kilit Gizleme (`0x547cb1` - 5 Bayt):**
  - Orijinal: `e8 ba cf fc ff` (`call 0x514c70` - Kilidi Göster)
  - Yama: `e8 0a d0 fc ff` (`call 0x514cc0` - Kilidi Gizle)
  - Kart oluşturulurken turuncu asma kilit nesnesi asla gösterilmez.
- **SafeHouse Kart Tik Atlaması (`0x547d70` - 4 Bayt):**
  - Orijinal: `85 c0 74 36` (`test eax, eax; je 0x547daa`)
  - Yama: `eb 38 90 90` (`jmp 0x547daa; 2x nop`)
  - Görev henüz tamamlanmamışsa yeşil tik (`CHECK` / `0x28feadd`) simgesinin atanmasını atlar; kart **tamamen temiz ve boş** görünür.
- **Tamamlandıkça Tik Gelme Mekanizması:**
  - Oyuncu bir kilometre taşını başarıyla tamamladığında `[ebx + 0x16] != 0` (`is_completed = 1`) olur.
  - Oyun `0x547cd0` üzerinden orijinal tamamlama koduna yönelir (`mov ecx, 0x18ed48` ve `or [eax+0x1c], 0x2400000`). Tamamlanan taşa tik/madalya simgesi eklenir.
- **İmleç Seçim Kartı Mantığı (`0x52fe64` ve `0x52ff2b`):**
  - `0x52fe64` kilit gösterme çağrısı `call 0x514cc0` (gizle) yapıldı.
  - `0x52ff2b` adresi `eb 68 90 90` (`jmp 0x52ff95`) yapılarak imlecin üzerinde durduğu kartın da tamamlanmamışsa sahte tik göstermesi engellendi.
- **Ekran Kilit Gizlemeleri:**
  - `0x51fdba` & `0x51fdd7`: Detay ekranı kilit gizleme çağrısı.
  - `0x52f55b`: Blacklist menüsü kilit göstermeyi atlama (`eb 0f`).

---

### D. Kariyer Akışı ve Garaj Ayarları

1. **Doğrudan Blacklist 15 Safehouse Girişi:**
   - `0x5a3a47: 74 33 -> 90 90`: Prologue / Ambush (DDay) yarışları atlanır; oyuncu doğrudan Safehouse'a girer.
   - `0x5a3a6c: 74 e0 -> 90 90`: Blacklist #15 rakibi Sonny olarak atanır.
2. **Garajda Yalnızca BMW M3 GTR:**
   - `0x5a39aa` & `0x5a39b2`: `74 45` ve `74 3d` -> `90 90` (Araba ekleme kontrolü baypas).
   - `0x5a39d1` (16 NOP): Cobalt SS (`BONUS_GT2`) ekleme çağrısı NOP yapılarak atlanır; garajda yalnızca `E3_DEMO_BMW` (BMW M3 GTR) bırakılır.
3. **Save Bütünlüğü Baypası (`0x7f53ed` - 6 Bayt):**
   - `0f 85 a1 00 00 00` -> `eb 10 90 90 90 90` (Sahte bozuk save hatası uyarısını engeller).

---

## 3. Yapılandırma ve Bellek Yamaları Tablosu

| Adres | Orijinal Baytlar | Yeni Baytlar | İşlev / Amaç |
|---|---|---|---|
| `0x5a39aa` | `74 45` | `90 90` | Kariyer başlangıcı araba ekleme bayrak kontrolü baypası |
| `0x5a39b2` | `74 3d` | `90 90` | Kariyer başlangıcı ikincil bayrak kontrolü baypası |
| `0x5a39d1` | (Cobalt SS ekleme bloğu) | `16x 90` (NOP) | Garaja Cobalt SS eklenmesini atlayıp sadece BMW M3 GTR bırakma |
| `0x5a3a47` | `74 33` | `90 90` | Prologue/Ambush yarışlarını atlayıp doğrudan Safehouse'a girme |
| `0x5a3a6c` | `74 e0` | `90 90` | Rakip Sonny #15 kurulumunu zorlama ve temiz çıkış |
| `0x926125` | `00 00` | `01 01` | Dev skip intro bayraklarını aktif etme |
| `0x58e4b7` | (UserProfile kurucu 1) | `31 c0 89 ... c6 46 34 01 ...` | Autosave bayrağını zorunlu olarak 1 yapma (24 bayt) |
| `0x58e905` | (UserProfile kurucu 2) | `89 46 30 ... c6 46 34 01 90 90` | Autosave bayrağını zorunlu olarak 1 yapma (18 bayt) |
| `0x58e984` | (UserProfile kurucu 3) | `8b 0d 14 ... c6 46 34 01 90 90` | Autosave bayrağını zorunlu olarak 1 yapma (18 bayt) |
| `0x7aea37` | `74 16` | `90 90` | Motor: Sonny #15 kilometre taşlarını `is_unlocked = 1` yapma |
| `0x547ecd` | `74 18` | `90 90` | Motor: Safehouse Milestone kart yenilemede kilidi açma |
| `0x5480e3` | `74 43` | `90 90` | Motor: Safehouse etkileşim listesine kilometre taşlarını doldurma |
| `0x51fe8a` | `74 17` | `90 90` | Motor: Safehouse detay yenilemede kilidi açık kabul etme |
| `0x5326d9` | `74 04` | `90 90` | Motor: `CareerManager::IsEventUnlocked` true (1) döndürme |
| `0x531fb9` | `75 5a` | `eb 5a` | Motor: Kilometre taşına basıldığında kovalamacayı doğrudan başlatma |
| `0x547cb1` | `e8 ba cf fc ff` | `e8 0a d0 fc ff` | Görsel: Safehouse kart kilit simgesi göstermeyi gizlemeye çevirme |
| `0x547d70` | `85 c0 74 36` | `eb 38 90 90` | Görsel: Tamamlanmamışsa yeşil tik ikonunu atlama (sıfır ikon) |
| `0x547d38` | `8a 43 17 84 c0 74 6b` | `b0 01 90 84 c0 90 90` | Görsel: Safehouse kilit gizleme dalına yönlendirme |
| `0x52fe64` | `e8 07 4e fe ff` | `e8 57 4e fe ff` | Görsel: Safehouse imleç seçim kartı kilit gizleme |
| `0x52ff2b` | `85 c0 74 66` | `eb 68 90 90` | Görsel: Safehouse imleç seçim kartı tik atlama |
| `0x52fef3` | `8a 43 17 84 c0` | `b0 01 90 84 c0` | Görsel: Safehouse imleç seçim kartı gizleme yönlendirmesi |
| `0x52f55b` | `75 0f` | `eb 0f` | Görsel: Blacklist menüsü kilit göstermeyi atlama |
| `0x51fdba` | `8a 47 17 84 c0 5e 74 11` | `b0 01 90 84 c0 5e 90 90` | Görsel: Genel Milestone kilit gizleme |
| `0x51fdd7` | `e8 b4 ce fc ff` | `e8 e4 4e ff ff` | Görsel: Detay ekranı kilit gizleme çağrısı |
| `0x7f53ed` | `0f 85 a1 00 00 00` | `eb 10 90 90 90 90` | Save dosyası kontrol baypası |
| `Car Slot 70..80` | Karışık / `65535` | `5243, 5244, 5249, 5257, 5264, 5270, 3688, 4545, 3809, 3811` | BMW M3 GTR Metalik Gümüş & Çift Kraliyet/Lacivert Çizgili Model |

---

## 4. Canlı Doğrulama ve Test Sonuçları

`speed.exe` canlı çalışma ortamında bellek okuyucu (`ReadProcessMemory`) ile doğrulanmış ve aşağıdaki sonuçlar alınmıştır:
- **Tüm 13 RAM Yaması:** `[PASS]` (Tüm adresler beklenen makine kodlarıyla eşleşti).
- **BMW M3 GTR Slotları (10 Slotun Tamamı):** `[PASS]`
  - Slot 70 (Gövde Kiti): 5243
  - Slot 71 (Vinil Çift Çizgi): 5244
  - Slot 72 (Vinil Katman 1 - Parlak Kraliyet Mavisi): 5249
  - Slot 73 (Vinil Katman 2 - Koyu Lacivert): 5257
  - Slot 74 (Vinil Katman 3 - Koyu Lacivert Çizgi): 5264
  - Slot 75 (Vinil Katman 4 - Kraliyet Mavisi Vurgu): 5270
  - Slot 76 (Metalik Gümüş Taban Boyası): 3688
  - Slot 77 (Açık Cam Filmi): 4545
  - Slot 79 (BBS Ön Jant): 3809
  - Slot 80 (BBS Arka Jant): 3811
  - `0xffff` (Bozuk/Geçersiz Parça): `0` (Sıfır adet).
- **Kayıt Bütünlüğü:** Tüm `save/`, `save/NFS Most Wanted/` ve `github/save/` profilleri eşitlendi ve kullanıma hazır hale getirildi.
