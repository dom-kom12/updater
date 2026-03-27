@echo off
chcp 65001 >nul
title Nebula Launcher Updater
setlocal EnableDelayedExpansion

:: Konfiguracja
set "UPDATE_URL=https://huggingface.co/datasets/qwdqdqwe/system-gier/resolve/main/Nebulauncher.exe"
set "LAUNCHER_NAME=Nebulauncher.exe"
set "TEMP_FILE=%TEMP%\launcher_update.exe"
set "INSTALL_DIR=%~dp0"
set "LAUNCHER_PATH=%INSTALL_DIR%%LAUNCHER_NAME%"

:: Sprawdź czy launcher jest uruchomiony
tasklist | findstr /I "%LAUNCHER_NAME%" >nul
if %errorlevel% == 0 (
    echo Zamykam uruchomiony launcher...
    taskkill /F /IM "%LAUNCHER_NAME%" >nul 2>&1
    timeout /T 2 /NOBREAK >nul
)

:: Pobierz nową wersję
echo Pobieram aktualizację...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference = 'SilentlyContinue'; try { Invoke-WebRequest -Uri '%UPDATE_URL%' -OutFile '%TEMP_FILE%' -UseBasicParsing -MaximumRedirection 10 -ErrorAction Stop; $size = (Get-Item '%TEMP_FILE%').Length; if ($size -gt 1000) { exit 0 } else { exit 1 } } catch { exit 1 }"

if %errorlevel% NEQ 0 (
    echo Błąd: Nie udało się pobrać aktualizacji.
    pause
    exit /b 1
)

:: Sprawdź czy plik istnieje i ma sensowny rozmiar
if not exist "%TEMP_FILE%" (
    echo Błąd: Pobrany plik nie istnieje.
    pause
    exit /b 1
)

for %%F in ("%TEMP_FILE%") do set "FILE_SIZE=%%~zF"
if %FILE_SIZE% LSS 1000 (
    echo Błąd: Pobrany plik jest za mały.
    del "%TEMP_FILE%" >nul 2>&1
    pause
    exit /b 1
)

:: Zrób kopię zapasową starej wersji
if exist "%LAUNCHER_PATH%" (
    echo Tworzę kopię zapasową...
    copy /Y "%LAUNCHER_PATH%" "%LAUNCHER_PATH%.backup" >nul 2>&1
)

:: Zamień plik
echo Instaluję aktualizację...
move /Y "%TEMP_FILE%" "%LAUNCHER_PATH%" >nul 2>&1

if %errorlevel% NEQ 0 (
    echo Błąd: Nie udało się zainstalować aktualizacji.
    if exist "%LAUNCHER_PATH%.backup" (
        echo Przywracam starą wersję...
        copy /Y "%LAUNCHER_PATH%.backup" "%LAUNCHER_PATH%" >nul 2>&1
    )
    pause
    exit /b 1
)

:: Uruchom zaktualizowany launcher
echo Aktualizacja zakończona sukcesem!
echo Uruchamiam launcher...
start "" "%LAUNCHER_PATH%"

:: Wyczyść kopię zapasową po 5 sekundach
timeout /T 5 /NOBREAK >nul
if exist "%LAUNCHER_PATH%.backup" del "%LAUNCHER_PATH%.backup" >nul 2>&1

exit
