@echo off
chcp 65001 >nul
title Nebula Launcher - Aktualizacja

echo ==========================================
echo        Nebula Launcher Updater
echo ==========================================
echo.

echo [1/4] Sprawdzanie uprawnien...

:: ===== ADMIN CHECK =====
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo [INFO] Wymagane uprawnienia administratora.
    echo [INFO] Uruchamiam ponownie jako administrator...

    powershell -Command "Start-Process '%~f0' -Verb runAs"
    exit /b
)

setlocal

:: ===== CONFIG =====
set "URL=https://huggingface.co/datasets/qwdqdqwe/system-gier/resolve/main/Nebulauncher.exe"
set "TEMP_FILE=%TEMP%\nebula_update.exe"
set "INSTALL_DIR=%ProgramFiles(x86)%\NebulaLauncher"
set "INSTALL_EXE=%INSTALL_DIR%\Nebulauncher.exe"

echo.
echo [2/4] Pobieranie najnowszej wersji...
echo.

:: ===== DOWNLOAD =====
powershell -NoProfile -Command ^
"try { Invoke-WebRequest -Uri '%URL%' -OutFile '%TEMP_FILE%' } catch { exit 1 }"

if not exist "%TEMP_FILE%" (
    echo [ERROR] Nie udalo sie pobrac aktualizacji.
    echo Sprawdz polaczenie internetowe i sprobuj ponownie.
    pause
    exit /b 1
)

:: ===== CHECK SIZE =====
for %%F in ("%TEMP_FILE%") do set SIZE=%%~zF
echo [OK] Pobrano plik (%SIZE% bajtow)

if %SIZE% LSS 1000000 (
    echo [ERROR] Plik aktualizacji jest uszkodzony.
    del "%TEMP_FILE%" >nul 2>&1
    pause
    exit /b 1
)

echo.
echo [3/4] Zamykanie uruchomionego launchera...

taskkill /IM Nebulauncher.exe /F >nul 2>&1
timeout /t 2 >nul

echo [OK] Launcher zamkniety
echo.

echo [4/4] Instalacja aktualizacji...

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

copy /Y "%TEMP_FILE%" "%INSTALL_EXE%" >nul

if errorlevel 1 (
    echo [ERROR] Nie udalo sie zainstalowac aktualizacji.
    pause
    exit /b 1
)

del "%TEMP_FILE%" >nul 2>&1

echo.
echo ==========================================
echo   ✔ Aktualizacja zakonczona sukcesem!
echo ==========================================
echo.
echo Uruchamiam Nebula Launcher...

timeout /t 2 >nul
start "" "%INSTALL_EXE%"

exit /b 0
