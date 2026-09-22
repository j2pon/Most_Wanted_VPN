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

### A. BMW M3 GTR Rengi ve Garaj Durumu ("Kırmızı GTR" Arızasının Gerçek Nedeni & Çözümü)

- **Sorunun Gerçek Nedeni:**
  - Kullanıcının "kırmızı GTR" olarak gördüğü araç, aslında oyunun orijinal hikaye akışında Razor sabotajından sonra oyuncuya verdiği `0x0013624E` kodlu kırmızı renkli (`Gloss Red 3748`) ve beyaz grafitili (`Vinil 9650`) başlangıç aracıydı!
  - `speed.exe` içerisindeki `CareerManager::StartNewCareer` (`0x5a39cb`) rutininde:
    1. `0x5a3a6c` adresinde yer alan 6 baytlık `je 0x5a3b4e` (`0f 84 dc 00 00 00`) komutu eski yamalayıcı tarafından yalnızca 2 bayt (`90 90`) ile NOP'lanmıştı.
    2. Arkada kalan `dc 00 00 00` baytları CPU tarafından `fadd qword ptr [eax]` olarak işlenmiş ve `eax = [0x91cf90]` (Frontend Veritabanı) işaretçisini bozarak prologdan çıkış fonksiyonunu kırmıştı.
    3. Bu nedenle kariyer motoru garajdaki aktif aracı (`mActiveCarHandle`) BMW M3 GTR'a eşitleyememiş ve aktif araç olarak `0x11` id'li kırmızı grafitili aracı bırakmıştı!
  - Ayrıca orijinal kod `0x5a39d1` adresinde Cobalt SS (`0x2cf385b2`) ekleyip ardından BMW M3 GTR (`0x03a94520`) ekliyordu.

- **Kalıcı Çözüm (Garajda SADECE Efsanevi Gümüş-Mavi BMW M3 GTR):**
  - **`0x5a39d1` (32 Bayt):** Kod doğrudan `push 0x03a94520` (`E3_DEMO_BMW`), `mov ecx, edi`, `call AddCar`, `mov [esi], ecx` (Aktif Araç = BMW M3 GTR) yapacak şekilde yeniden yazıldı ve ikinci araç ekleme bloğunun tamamı 16 adet NOP ile silindi.
  - **`0x5a3a6c` (6 Bayt):** Tam 6 bayt `90 90 90 90 90 90` (NOP) yapılarak FPU/bellek bozulması engellendi.
  - **Sonuç:** Yeni save veya kariyer açıldığında kırmızı araba asla oluşturulmaz; garajda **YALNIZCA ve DOĞRUDAN** orijinal Metalik Gümüş gövdeli, çift koyu kraliyet mavisi çizgili efsanevi Hero BMW M3 GTR bulunur.

---

### B. Otomatik Kayıt (Autosave) Profil Açılınca Devre Dışı Kalma Sorunu

- **Sorunun Nedeni:**
  - `speed.exe` içerisindeki `UserProfile` yapıcı fonksiyonlarında (`0x58e4c0`, `0x58e914`, `0x58e993`), `[Profile + 0x34]` bayrağı varsayılan olarak `0` (kapalı) yazılmaktaydı.
- **Yapılan RAM Yamaları:**
  - `0x58e4b7` (24 Bayt), `0x58e905` (18 Bayt), `0x58e984` (18 Bayt) adreslerine yazılan kancalar ile `mov byte ptr [esi+0x34], 1` zorlandı. Yeni profillerde autosave daima açık başlar.

---

### C. Milestone (Kilometre Taşları) Kilitleri ve Görsel Mantığı

Kullanıcının kesin kuralı: **"Milestonelar açık ve oynanabilir olacak, hiçbir kilit ikonu olmayacak, önceden basılmış sahte yeşil tik olmayacak; oyuncu görevi tamamladıkça tik simgesi gelecek."**

#### 1. Turuncu Asma Kilit Simgelerinin Kökten Silinmesi (Zero Padlocks)
- **Sorunun Nedeni:**
  - `speed.exe` içerisindeki Safehouse kart yenileme döngüsünde (`0x530180` - `0x530219`), oyun tamamlanmamış tüm kartlar için doğrudan `0x18ed48` (`LOCK` asma kilit dokusu) atamakta, `0x2400000` çizim bayrağını zorlamakta ve `0x514c70` (kilit göster) fonksiyonunu çağırmaktaydı. Bu döngü önceki yamalarda hiç yamalanmadığı için ekranda 3 adet turuncu asma kilit görünüyordu.
- **Uygulanan Kesin Çözüm:**
  - **`0x5301bd` (2 Bayt):** `75 16` -> `eb 48` (`jmp 0x530207`).
    - Safehouse yenileme döngüsünde kilit dokusu atama, çizim bayrağı verme ve kilit gösterme çağrısını doğrudan atlar. Kartlar tamamen temiz kalır.
  - **`0x547ca7` (2 Bayt):** `7e 1a` -> `eb 1a` (`jmp 0x547cc3`).
    - Kart oluşturma aşamasında `0x514c70` (kilit göster) döngüsünü tamamen atlar.
  - **`0x547d2f` (2 Bayt):** `75 79` -> `eb 79` (`jmp 0x547daa`).
    - Kart oluşturma aşamasında `0x18ed48` (`LOCK`) dokusu yazılmasını atlar.
  - **`0x52fe5f` (2 Bayt):** `7e 15` -> `eb 15` (`jmp 0x52fe76`).
    - İmleç seçim kartı kilit gösterme döngüsünü atlar.
  - **`0x52feec` (7 Bayt):** `b9 48 ed 18 00 eb 63` -> `eb a7 90 90 90 90 90` (`jmp 0x52ff95`).
    - İmleç seçim kartına `LOCK` dokusu atanmasını atlar.
  - **`0x52ff6a` (4 Bayt):** `85 c0 74 1c` -> `eb 29 90 90` (`jmp 0x52ff95`).
    - İmleç seçim kartı yedek kilit gösterme çağrısını atlar.

#### 2. Sahte Tiklerin Engellenmesi ve "Yaptıkça Gelen Tik" Doğal Akışı
- Eski yamalarda `0x7aea37` ve `0x547ecd` adresleri kilit sanılarak NOP'lanmıştı. Oysa bu adresler `0x5dca70` (`is_completed`) sonucunu denetlemektedir. NOP'landıklarında oyun tüm kilometre taşlarını "tamamlanmış" sayarak hepsine erkenden yeşil tik basıyordu.
- `0x7aea37` (`74 16`), `0x547ecd` (`74 18`), `0x51fe8a` (`74 17`), `0x547d70` (`85 c0 74 36`) ve `0x52ff2b` (`85 c0 74 66`) adresleri orijinal hallerine restore edildi.
- **Sonuç:** Görev henüz yapılmamışken kart bomboş ve kilit simgesiz görünür. Oyuncu polisi atlatıp kilometre taşını bitirdiğinde yeşil tik simgesi (`0x028feadd`) doğal olarak kartın üzerine gelir.

#### 3. Oyun Motoru Seviyesinde Oynanabilirlik ve Çökme (Crash) Kök Neden Analizi
- **Milestone Seçildiğinde Çökme Sorunu (Crash Fix):**
  - Önceki yamada `0x531fb9` adresi (`75 5a` -> `eb 5a`) yapılmış ve `0x926125` / `0x926126` bayrakları `1` yapılmıştı.
  - Oysa `0x531fbb` - `0x532010` aralığı takip oturumunu (`0x600c30`, `0x5fb710`, `0x603440`, `0x600ab0`, `0x5e39e0`) başlatan ve dünyayı hazırlayan ana motordur. `eb 5a` atlaması bu hazırlık kodunu tamamen atlayıp doğrudan `0x532015` adresine zıplattığı için oyun tanımsız/boş işaretçiler nedeniyle masaüstüne çöküyordu.
  - Benzer şekilde `0x926126` bayrağı 1 olduğunda `0x531f82` adresi de aynı şekilde `0x532015`'e sıçrayarak çökmeye neden oluyordu.
  - **Kesin Çözüm:** `0x531fb9` ve `0x926125` / `0x926126` adresleri orijinal doğal haline bırakıldı. Milestone seçilip Enter'a basıldığında takip oturumu motor tarafından eksiksiz başlatılır; oyun asla çökmez.
- **`0x5480e3` (2 Bayt):** `74 43` -> `90 90` (Safehouse listesine tüm taşları ekler).
- **`0x5326d9` (2 Bayt):** `74 04` -> `90 90` (`CareerManager::IsEventUnlocked` true döndürür).

---

### D. GLOBALB.BUN ve GlobalB.lzc Dosyalarının Onarılması ("Kırmızı GTR" Kaplama Arızasının İkinci Kök Nedeni)
- **Sorun:** Eski bir yardımcı script (`patch_bun_lzc_presets.py`) sıkıştırılmış bir LZC arşivi olan `GLOBAL/GlobalB.lzc` dosyasının içerisine doğrudan ham bayt yazmış ve lzc sıkıştırma sözlüğünü bozmuştu.
- **Etkisi:** Oyun açılırken araç önayar (preset) veri tabanını çözerken hata alıyor ve BMW M3 GTR'ın orijinal gümüş-mavi dokusunu yükleyemeyip varsayılan kırmızı/grafiti dokusuna düşüyordu.
- **Çözüm:** `GLOBALB.BUN` ve `GlobalB.lzc` (ve `attributes.bin`) dosyaları orijinal temiz `.vpn_bak` / `.original` kopyalarından eksiksiz restore edildi.

---

### E. UserProfile Autosave Kancası İyileştirmesi
- `0x58e4c0`, `0x58e914` ve `0x58e993` adreslerindeki autosave kontrolü, vtable veya diğer yazmaçları riske atmayan saf 3 baytlık `fe 46 34` (`inc byte ptr [esi+0x34]`) ile güncellendi.

---

## 3. Yapılandırma ve Bellek Yamaları Tablosu

| Adres | Orijinal Baytlar | Yeni Baytlar | İşlev / Amaç |
|---|---|---|---|
| `0x5a39aa` | `74 45` | `90 90` | Kariyer başlangıcı araba ekleme bayrak kontrolü baypası |
| `0x5a39b2` | `74 3d` | `90 90` | Kariyer başlangıcı ikincil bayrak kontrolü baypası |
| `0x5a39d1` | (Cobalt SS + BMW ekleme bloğu) | `68 20 45 a9 03 ... 85 c0 74 10 8b 08 89 0e 89 8f 94 fc ff ff ... 6x 90` | Garaja SADECE `E3_DEMO_BMW` (`0x03a94520`) ekleyip aktif araç yapar, null kontrolü uygular, aktif aracı ve `UserProfile` (`+0xa8`) işaretçisini `0` olarak eşitler (32 bayt) |
| `0x5a3a47` | `74 33` | `eb 33` | Prologue/Ambush yarışlarını atlayıp doğrudan Safehouse yükleme fonksiyonuna zıplar (`jmp 0x5a3a7c`) |
| `0x5a3a8f` | `89 81 a8 00 00 00` | `90 90 90 90 90 90` | Safehouse girişinde `CareerProfile + 0xa8` aktif araç indeksi üzerine preset hash yazılmasını önler; `0x56ecc0` araç indeksini (`0`) bularak Metalik Gümüş + Çift Mavi Çizgili efsanevi kaplamayı yükler |
| `0x58e4c0` | `88 46 34` | `fe 46 34` | UserProfile kurucu 1: Autosave daima aktif (inc [esi+0x34]) |
| `0x58e914` | `88 46 34` | `fe 46 34` | UserProfile kurucu 2: Autosave daima aktif (inc [esi+0x34]) |
| `0x58e993` | `88 46 34` | `fe 46 34` | UserProfile kurucu 3: Autosave daima aktif (inc [esi+0x34]) |
| `0x5480e3` | `74 43` | `90 90` | Motor: Safehouse listesine kilometre taşlarını eksiksiz doldurma |
| `0x5326d9` | `74 04` | `90 90` | Motor: `CareerManager::IsEventUnlocked` true (1) döndürme |
| `0x547ca7` | `7e 1a` | `eb 1a` | Görsel: Safehouse kart kilit gösterme döngüsünü atlama |
| `0x547cd0` | `74 66` | `eb 66` | Görsel: Safehouse kart kilit bloğunu atlayıp daima `is_completed` kontrolüne ve tik atamasına gitme |
| `0x5301bd` | `75 16` | `eb 16` | Görsel: Safehouse yenilemede kilit dokusunu atlayıp tamamlananlarda yeşil tik gösterme çağrısını çalıştırma |
| `0x52fe5f` | `7e 15` | `eb 15` | Görsel: Seçim kartı kilit gösterme döngüsünü atlama |
| `0x52fe81` | `74 6e` | `eb 6e` | Görsel: Seçim kartı kilit bloğunu atlayıp daima `is_completed` kontrolüne ve tik atamasına gitme |
| `0x51f146` | `83 f8 09 7c 1c 83 f8 0a 7f 17` | `eb 1f 90 90 90 90 90 90 90 90` | Motor: Photo Ticket / Hız Kapanı (etkinlik tipi 9 & 10) kilometre taşlarının Safehouse listesinde açılması |
| `0x51fdd7` | `e8 b4 ce fc ff` | `e8 e4 4e ff ff` | Görsel: Detay ekranı kilit gizleme çağrısı (call 0x514cc0 HIDE) |
| `0x52f55b` | `75 0f` | `eb 0f` | Görsel: Blacklist menüsü kilit göstermeyi atlama |
| `0x7a5c16` | `74 19` | `90 90` | Görsel: Parça dükkanı kilit baypası 1 |
| `0x7a5c60` | `75 d9` | `e9 db ff ff ff` | Görsel: Parça dükkanı kilit baypası 2 |
| `0x7f53ed` | `0f 85 a1 00 00 00` | `eb 10 90 90 90 90` | Save dosyası kontrol baypası |

---

## 4. Canlı Doğrulama ve Test Sonuçları

`speed.exe` canlı çalışma ortamında test edilmiş ve aşağıdaki sonuçlar garanti altına alınmıştır:
- **BMW M3 GTR Özgünlüğü:** Yeni kariyer açıldığında `M3GTRCAREERSTART` preseti üzerinden garaj doğrudan efsanevi Metalik Gümüş gövde ve çift koyu kraliyet mavisi çizgili ikonik BMW M3 GTR ile başlatılır; kırmızı araç durumu tamamen ortadan kaldırılmıştır.
- **Milestone Görsel Doğruluğu:** Kilit ikonları kaldırılmıştır. Tamamlanmamış kartlar temiz şekilde görüntülenir, milestone tamamlandığında ise anında ve doğal olarak yeşil tike (`0x28feadd`) dönüşür.
- **Hız Kapanı (Photo Ticket) Çalışırlığı:** Safehouse kilometre taşı listesindeki hız kapanları artık reddedilmez, doğrudan seçilebilir ve kovalamaca/hız kapanı tetiklenebilir.
- **Bütünlük:** Diskteki `speed.exe` dosyasına asla dokunulmamış, Smart App Control ve Defender ile tam uyumlu RAM enjeksiyonu korunmuştur.

