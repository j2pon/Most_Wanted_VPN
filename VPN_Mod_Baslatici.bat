@echo off
setlocal enabledelayedexpansion
title Need for Speed: Most Wanted - VPN Edition Baslatici (v1.2)
chcp 65001 >nul
cd /d "%~dp0"

:: Otomatik Save Yapısı Onarımı (save\NFS Most Wanted\ yapısını doğrula)
call :OTO_SAVE_ONAR

:MENU
cls
echo ====================================================================
echo      NEED FOR SPEED: MOST WANTED (2005) - VPN EDITION v1.2
echo           "Bir damla yağ bir şehrin kaderini değiştirir..."
echo ====================================================================
echo.

:: Grafik Modu Kontrolü
if exist "d3d9.dll" (
    set "GFX_STATUS=[DXVK - Vulkan 60+ FPS Aktif ⚡]"
) else if exist "d3d9.dll.dxvk" (
    set "GFX_STATUS=[Native DirectX 9 - Discord Yayın Modu Aktif 🎮]"
) else (
    set "GFX_STATUS=[Bilinmiyor / Orijinal DirectX 9]"
)

echo [Mevcut Grafik Modu]: !GFX_STATUS!
echo.
echo --------------------------------------------------------------------
echo  [1] Oyunu Başlat (speed.exe)
echo  [2] Grafik Modunu Değiştir (DXVK Vulkan ^<--^> DirectX 9 / Discord)
echo  [3] Tüm Saveleri Eşitle ve Geri Getir (MuratVPN, VPN, VPN_Kopru)
echo  [4] Kaze (#7) Profilini Yükle (Baron Geçilmiş - Kaze Yarışları)
echo  [5] Başlangıç Profilini Yükle (Razor #15 ^& BMW M3 GTR)
echo  [6] Final Köprü Kaçışı Profilini Yükle (Blacklist #1 Zaferi)
echo  [7] Hikaye ve Kısayol Rehberini Aç
echo  [8] Çıkış
echo --------------------------------------------------------------------
echo.
set /p SECIM="Lutfen bir secim yapin [1-8]: "

if "%SECIM%"=="1" goto BASLAT
if "%SECIM%"=="2" goto GFX_TOGGLE
if "%SECIM%"=="3" goto ESITLE_SAVELER
if "%SECIM%"=="4" goto YUKLE_KAZE
if "%SECIM%"=="5" goto YUKLE_BASLANGIC
if "%SECIM%"=="6" goto YUKLE_FINAL
if "%SECIM%"=="7" goto REHBER_AC
if "%SECIM%"=="8" goto CIKIS

echo.
echo [!] Gecersiz secim! Lutfen 1-8 arasinda bir tusa basin.
timeout /t 2 >nul
goto MENU

:BASLAT
cls
echo ====================================================================
echo  Need for Speed: Most Wanted - VPN Edition Baslatiliyor...
echo ====================================================================
echo.
if not exist "speed.exe" (
    echo [HATA] speed.exe bulunamadi!
    pause
    goto MENU
)
echo [i] VPN Bellek Yamalayicisi arka planda aktif ediliyor...
if exist "scripts\VPN_Watcher.vbs" (
    start "" wscript.exe //B "scripts\VPN_Watcher.vbs"
) else if exist "scripts\VPN_Patcher.ps1" (
    start "" /min powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "scripts\VPN_Patcher.ps1"
)
echo [i] speed.exe baslatiliyor...
start "" "speed.exe"
timeout /t 3 >nul
exit

:GFX_TOGGLE
cls
echo ====================================================================
echo  Grafik Modu Degistiriliyor...
echo ====================================================================
echo.
if exist "d3d9.dll" (
    if exist "d3d9.dll.dxvk" del /f /q "d3d9.dll.dxvk"
    if exist "dxgi.dll.dxvk" del /f /q "dxgi.dll.dxvk"
    ren "d3d9.dll" "d3d9.dll.dxvk"
    if exist "dxgi.dll" ren "dxgi.dll" "dxgi.dll.dxvk"
    echo [+] Discord Yayin Modu (Native DirectX 9) Aktif Edildi!
    echo     - Discord yayinlarinda siyah ekran sorunu yasanmaz.
) else if exist "d3d9.dll.dxvk" (
    if exist "d3d9.dll" del /f /q "d3d9.dll"
    if exist "dxgi.dll" del /f /q "dxgi.dll"
    ren "d3d9.dll.dxvk" "d3d9.dll"
    if exist "dxgi.dll.dxvk" ren "dxgi.dll.dxvk" "dxgi.dll"
    echo [+] DXVK (Vulkan) Modu Aktif Edildi!
    echo     - Yuksek performans ve modern GPU optimizasyonu devrede.
) else (
    echo [!] DXVK dosyalari (d3d9.dll) bulunamadi. Varsayilan DirectX 9 kullaniliyor.
)
echo.
echo Menuye donmek icin bir tusa basin...
pause >nul
goto MENU

:ESITLE_SAVELER
cls
echo ====================================================================
echo  Tum Kayitli Profiller Esitleniyor ve Geri Yukleniyor...
echo ====================================================================
echo.
call :OTO_SAVE_ONAR
echo [+] MuratVPN, VPN ve VPN_Kopru profilleri hem 'save' klasorune
echo     hem de 'Belgelerim\NFS Most Wanted' klasorune basariyla esitlendi!
echo.
echo Menuye donmek icin bir tusa basin...
pause >nul
goto MENU

:YUKLE_KAZE
cls
echo ====================================================================
echo  Kaze (#7) Save Profili Yukleniyor (Baron Gecilmis)...
echo ====================================================================
echo.
if not exist "save_kaze\MuratVPN\MuratVPN" (
    echo [HATA] save_kaze kayit dosyasi bulunamadi!
    pause
    goto MENU
)

:: Hedef klasörleri hazırla
if not exist "save\NFS Most Wanted\MuratVPN" mkdir "save\NFS Most Wanted\MuratVPN"
if not exist "save\NFS Most Wanted\VPN" mkdir "save\NFS Most Wanted\VPN"
if not exist "save\MuratVPN" mkdir "save\MuratVPN"
if not exist "save\VPN" mkdir "save\VPN"
if not exist "%USERPROFILE%\Documents\NFS Most Wanted\MuratVPN" mkdir "%USERPROFILE%\Documents\NFS Most Wanted\MuratVPN"
if not exist "%USERPROFILE%\Documents\NFS Most Wanted\VPN" mkdir "%USERPROFILE%\Documents\NFS Most Wanted\VPN"

:: Kopyala
copy /y "save_kaze\MuratVPN\MuratVPN" "save\NFS Most Wanted\MuratVPN\MuratVPN" >nul
copy /y "save_kaze\MuratVPN\MuratVPN" "save\NFS Most Wanted\VPN\VPN" >nul
copy /y "save_kaze\MuratVPN\MuratVPN" "save\MuratVPN\MuratVPN" >nul
copy /y "save_kaze\MuratVPN\MuratVPN" "save\VPN\VPN" >nul
copy /y "save_kaze\MuratVPN\MuratVPN" "%USERPROFILE%\Documents\NFS Most Wanted\MuratVPN\MuratVPN" >nul
copy /y "save_kaze\MuratVPN\MuratVPN" "%USERPROFILE%\Documents\NFS Most Wanted\VPN\VPN" >nul

echo [+] Kaze (#7) profili basariyla tum kayit konumlarina yuklendi!
echo     - Blacklist #7 Kaze yarislari aktif.
echo     - Garajda 8 arac ve $49,600 bakiye hazir!
echo.
echo Menuye donmek icin bir tusa basin...
pause >nul
goto MENU

:YUKLE_BASLANGIC
cls
echo ====================================================================
echo  Baslangic Save Profili Yukleniyor (Razor #15 ^& BMW M3 GTR)...
echo ====================================================================
echo.
if not exist "save_baslangic\MuratVPN\MuratVPN" (
    echo [HATA] save_baslangic kayit dosyasi bulunamadi!
    pause
    goto MENU
)

:: Hedef klasörleri hazırla
if not exist "save\NFS Most Wanted\MuratVPN" mkdir "save\NFS Most Wanted\MuratVPN"
if not exist "save\NFS Most Wanted\VPN" mkdir "save\NFS Most Wanted\VPN"
if not exist "save\MuratVPN" mkdir "save\MuratVPN"
if not exist "save\VPN" mkdir "save\VPN"
if not exist "%USERPROFILE%\Documents\NFS Most Wanted\MuratVPN" mkdir "%USERPROFILE%\Documents\NFS Most Wanted\MuratVPN"
if not exist "%USERPROFILE%\Documents\NFS Most Wanted\VPN" mkdir "%USERPROFILE%\Documents\NFS Most Wanted\VPN"

:: Kopyala
copy /y "save_baslangic\MuratVPN\MuratVPN" "save\NFS Most Wanted\MuratVPN\MuratVPN" >nul
copy /y "save_baslangic\MuratVPN\MuratVPN" "save\NFS Most Wanted\VPN\VPN" >nul
copy /y "save_baslangic\MuratVPN\MuratVPN" "save\MuratVPN\MuratVPN" >nul
copy /y "save_baslangic\MuratVPN\MuratVPN" "save\VPN\VPN" >nul
copy /y "save_baslangic\MuratVPN\MuratVPN" "%USERPROFILE%\Documents\NFS Most Wanted\MuratVPN\MuratVPN" >nul
copy /y "save_baslangic\MuratVPN\MuratVPN" "%USERPROFILE%\Documents\NFS Most Wanted\VPN\VPN" >nul

echo [+] Baslangic profili basariyla tum kayit konumlarina yuklendi!
echo     - Garajda BMW M3 GTR hazir.
echo     - Blacklist #15 Razor sizi bekliyor!
echo.
echo Menuye donmek icin bir tusa basin...
pause >nul
goto MENU

:YUKLE_FINAL
cls
echo ====================================================================
echo  Final Kopru Kacisi Profili Yukleniyor (Blacklist #1 Zaferi)...
echo ====================================================================
echo.
if not exist "save_kopru_final\MuratVPN\MuratVPN" (
    echo [HATA] save_kopru_final kayit dosyasi bulunamadi!
    pause
    goto MENU
)

:: Hedef klasörleri hazırla
if not exist "save\NFS Most Wanted\MuratVPN" mkdir "save\NFS Most Wanted\MuratVPN"
if not exist "save\NFS Most Wanted\VPN_Kopru" mkdir "save\NFS Most Wanted\VPN_Kopru"
if not exist "save\MuratVPN" mkdir "save\MuratVPN"
if not exist "save\VPN_Kopru" mkdir "save\VPN_Kopru"
if not exist "%USERPROFILE%\Documents\NFS Most Wanted\MuratVPN" mkdir "%USERPROFILE%\Documents\NFS Most Wanted\MuratVPN"
if not exist "%USERPROFILE%\Documents\NFS Most Wanted\VPN_Kopru" mkdir "%USERPROFILE%\Documents\NFS Most Wanted\VPN_Kopru"

:: Kopyala
copy /y "save_kopru_final\MuratVPN\MuratVPN" "save\NFS Most Wanted\MuratVPN\MuratVPN" >nul
copy /y "save_kopru_final\MuratVPN\MuratVPN" "save\NFS Most Wanted\VPN_Kopru\VPN_Kopru" >nul
copy /y "save_kopru_final\MuratVPN\MuratVPN" "save\MuratVPN\MuratVPN" >nul
copy /y "save_kopru_final\MuratVPN\MuratVPN" "save\VPN_Kopru\VPN_Kopru" >nul
copy /y "save_kopru_final\MuratVPN\MuratVPN" "%USERPROFILE%\Documents\NFS Most Wanted\MuratVPN\MuratVPN" >nul
copy /y "save_kopru_final\MuratVPN\MuratVPN" "%USERPROFILE%\Documents\NFS Most Wanted\VPN_Kopru\VPN_Kopru" >nul

echo [+] Final Kopru Kacisi profili basariyla tum kayit konumlarina yuklendi!
echo     - Blacklist #1 Razor (Siyah Mustang GT) maglup edildi.
echo     - Heat 5/6 kovalamacasi basladi! Eski kirik kopruye surun!
echo.
echo Menuye donmek icin bir tusa basin...
pause >nul
goto MENU

:REHBER_AC
start "" "VPN_Modu_Hikaye_Rehberi.md"
goto MENU

:CIKIS
exit

:: ====================================================================
:: ALT ROUTINE: SAVE DOSYALARINI OTOMATIK ONARMA VE ESITLEME
:: ====================================================================
:OTO_SAVE_ONAR
:: 1. save\NFS Most Wanted klasör yapısını kur
if not exist "save\NFS Most Wanted\MuratVPN" mkdir "save\NFS Most Wanted\MuratVPN"
if not exist "save\NFS Most Wanted\VPN" mkdir "save\NFS Most Wanted\VPN"
if not exist "save\NFS Most Wanted\VPN_Kopru" mkdir "save\NFS Most Wanted\VPN_Kopru"

:: 2. Belgelerim klasör yapısını kur
if not exist "%USERPROFILE%\Documents\NFS Most Wanted\MuratVPN" mkdir "%USERPROFILE%\Documents\NFS Most Wanted\MuratVPN"
if not exist "%USERPROFILE%\Documents\NFS Most Wanted\VPN" mkdir "%USERPROFILE%\Documents\NFS Most Wanted\VPN"
if not exist "%USERPROFILE%\Documents\NFS Most Wanted\VPN_Kopru" mkdir "%USERPROFILE%\Documents\NFS Most Wanted\VPN_Kopru"

:: 3. MuratVPN Profilini Eşitle (En güncel olanı yay)
if exist "%USERPROFILE%\Documents\NFS Most Wanted\MuratVPN\MuratVPN" (
    copy /y "%USERPROFILE%\Documents\NFS Most Wanted\MuratVPN\MuratVPN" "save\NFS Most Wanted\MuratVPN\MuratVPN" >nul
    copy /y "%USERPROFILE%\Documents\NFS Most Wanted\MuratVPN\MuratVPN" "save\MuratVPN\MuratVPN" >nul
) else if exist "save\NFS Most Wanted\MuratVPN\MuratVPN" (
    copy /y "save\NFS Most Wanted\MuratVPN\MuratVPN" "%USERPROFILE%\Documents\NFS Most Wanted\MuratVPN\MuratVPN" >nul
    copy /y "save\NFS Most Wanted\MuratVPN\MuratVPN" "save\MuratVPN\MuratVPN" >nul
) else if exist "save\MuratVPN\MuratVPN" (
    copy /y "save\MuratVPN\MuratVPN" "save\NFS Most Wanted\MuratVPN\MuratVPN" >nul
    copy /y "save\MuratVPN\MuratVPN" "%USERPROFILE%\Documents\NFS Most Wanted\MuratVPN\MuratVPN" >nul
)

:: 4. VPN Profilini Eşitle
if exist "%USERPROFILE%\Documents\NFS Most Wanted\VPN\VPN" (
    copy /y "%USERPROFILE%\Documents\NFS Most Wanted\VPN\VPN" "save\NFS Most Wanted\VPN\VPN" >nul
    copy /y "%USERPROFILE%\Documents\NFS Most Wanted\VPN\VPN" "save\VPN\VPN" >nul
) else if exist "save\NFS Most Wanted\VPN\VPN" (
    copy /y "save\NFS Most Wanted\VPN\VPN" "%USERPROFILE%\Documents\NFS Most Wanted\VPN\VPN" >nul
    copy /y "save\NFS Most Wanted\VPN\VPN" "save\VPN\VPN" >nul
) else if exist "save\VPN\VPN" (
    copy /y "save\VPN\VPN" "save\NFS Most Wanted\VPN\VPN" >nul
    copy /y "save\VPN\VPN" "%USERPROFILE%\Documents\NFS Most Wanted\VPN\VPN" >nul
)

:: 5. VPN_Kopru Profilini Eşitle
if exist "%USERPROFILE%\Documents\NFS Most Wanted\VPN_Kopru\VPN_Kopru" (
    copy /y "%USERPROFILE%\Documents\NFS Most Wanted\VPN_Kopru\VPN_Kopru" "save\NFS Most Wanted\VPN_Kopru\VPN_Kopru" >nul
    copy /y "%USERPROFILE%\Documents\NFS Most Wanted\VPN_Kopru\VPN_Kopru" "save\VPN_Kopru\VPN_Kopru" >nul
) else if exist "save\NFS Most Wanted\VPN_Kopru\VPN_Kopru" (
    copy /y "save\NFS Most Wanted\VPN_Kopru\VPN_Kopru" "%USERPROFILE%\Documents\NFS Most Wanted\VPN_Kopru\VPN_Kopru" >nul
    copy /y "save\NFS Most Wanted\VPN_Kopru\VPN_Kopru" "save\VPN_Kopru\VPN_Kopru" >nul
) else if exist "save\VPN_Kopru\VPN_Kopru" (
    copy /y "save\VPN_Kopru\VPN_Kopru" "save\NFS Most Wanted\VPN_Kopru\VPN_Kopru" >nul
    copy /y "save\VPN_Kopru\VPN_Kopru" "%USERPROFILE%\Documents\NFS Most Wanted\VPN_Kopru\VPN_Kopru" >nul
)
goto :eof
