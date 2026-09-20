@echo off
setlocal enabledelayedexpansion
title Need for Speed: Most Wanted - VPN Edition Baslatici
chcp 65001 >nul
cd /d "%~dp0"

:MENU
cls
echo ====================================================================
echo      NEED FOR SPEED: MOST WANTED (2005) - VPN EDITION (MODU)
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
echo  [3] Hikaye ve Kısayol Rehberini Aç
echo  [4] Çıkış
echo --------------------------------------------------------------------
echo.
set /p SECIM="Lutfen bir secim yapin [1-4]: "

if "%SECIM%"=="1" goto BASLAT
if "%SECIM%"=="2" goto GFX_TOGGLE
if "%SECIM%"=="3" goto REHBER_AC
if "%SECIM%"=="4" goto CIKIS

echo.
echo [!] Gecersiz secim! Lutfen 1-4 arasinda bir tusa basin.
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
echo [i] Oyun baslatildi. Yeni profilinizi olusturup yarisa baslayin!
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

:REHBER_AC
start "" "VPN_Modu_Hikaye_Rehberi.md"
goto MENU

:CIKIS
exit
