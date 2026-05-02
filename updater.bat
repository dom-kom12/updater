@echo off
chcp 65001 >nul
title Nebula Launcher Updater

setlocal EnableDelayedExpansion

:: Konfiguracja
set "UPDATE_URL=https://huggingface.co/datasets/qwdqdqwe/system-gier/resolve/main/Nebulauncher.exe"
set "LAUNCHER_NAME=Nebulauncher.exe"
set "INSTALL_DIR=%USERPROFILE%\AppData\Local\NebulaLauncher"
set "INSTALL_EXE=%INSTALL_DIR%\%LAUNCHER_NAME%"
set "OLD_FILE=%INSTALL_DIR%\%LAUNCHER_NAME%.old"
set "TEMP_FILE=%TEMP%\launcher_update_%RANDOM%.exe"
set "USER_DIR=%USERPROFILE%\NebulaLauncher"

echo ========================================
echo  Nebula Launcher Updater
echo ========================================
echo.

:: NIE usuwam pliku launcher.db - ten krok został pominięty

:: USUN STARY PLIK .old
echo [INFO] Usuwam stary plik .old...

if exist "%OLD_FILE%" (
    echo [INFO] Znaleziono plik .old
    del /F /Q "%OLD_FILE%" >nul 2>&1
    
    if exist "%OLD_FILE%" (
        echo [OSTRZEZENIE] Nie udalo sie usunac .old
    ) else (
        echo [OK] Usunieto plik .old
    )
) else (
    echo [OK] Brak pliku .old
)

echo.

:: ZAMKNIJ LAUNCHER JESLI DZIALA
echo [INFO] Sprawdzam czy launcher dziala...
tasklist | findstr /I "%LAUNCHER_NAME%" >nul
if %errorlevel% == 0 (
    echo [INFO] Zamykanie launchera...
    taskkill /F /IM "%LAUNCHER_NAME%" >nul 2>&1
    set "CLOSED=1"
) else (
    echo [OK] Launcher nie dzialal
    set "CLOSED=0"
)

timeout /T 2 /NOBREAK >nul

tasklist | findstr /I "%LAUNCHER_NAME%" >nul
if %errorlevel% == 0 (
    echo [BLAD] Nie udalo sie zamknac launchera!
    echo [INFO] Zamknij launcher recznie i sprobuj ponownie.
    pause
    exit /b 1
)

if %CLOSED% == 1 echo [OK] Launcher zamkniety

echo.

:: Pobierz
echo [INFO] Pobieram plik...

if exist "%TEMP_FILE%" del /F /Q "%TEMP_FILE%" >nul 2>&1

curl -L -o "%TEMP_FILE%" "%UPDATE_URL%" >nul 2>&1
if %errorlevel% EQU 0 goto VERIFY

powershell -NoProfile -Command "try{Invoke-WebRequest -Uri '%UPDATE_URL%' -OutFile '%TEMP_FILE%' -UseBasicParsing -MaximumRedirection 5}catch{exit 1}" >nul 2>&1
if %errorlevel% EQU 0 goto VERIFY

bitsadmin /transfer nebula /download /priority normal "%UPDATE_URL%" "%TEMP_FILE%" >nul 2>&1
if %errorlevel% EQU 0 goto VERIFY

echo [BLAD] Pobieranie nieudane
pause
exit /b 1

:VERIFY
echo [OK] Plik pobrany

if not exist "%TEMP_FILE%" (
    echo [BLAD] Brak pliku po pobraniu
    pause
    exit /b 1
)

for %%F in ("%TEMP_FILE%") do set "FILE_SIZE=%%~zF"
echo [INFO] Rozmiar: %FILE_SIZE% bajtow

if %FILE_SIZE% LSS 1000 (
    echo [BLAD] Plik za maly
    del /F /Q "%TEMP_FILE%" >nul 2>&1
    pause
    exit /b 1
)

:: Instaluj
echo [INFO] Instaluje do %INSTALL_DIR%...

if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%" >nul 2>&1
)

:: Usun obecna wersje
if exist "%INSTALL_EXE%" (
    echo [INFO] Usuwam obecna wersje...
    del /F /Q "%INSTALL_EXE%" >nul 2>&1
    
    if exist "%INSTALL_EXE%" (
        echo [BLAD] Nie mozna usunac obecnej wersji
        pause
        exit /b 1
    )
)

echo [INFO] Kopiowanie nowej wersji...
copy /Y "%TEMP_FILE%" "%INSTALL_EXE%" >nul 2>&1
if %errorlevel% NEQ 0 (
    echo [BLAD] Kopiowanie nieudane
    del /F /Q "%TEMP_FILE%" >nul 2>&1
    pause
    exit /b 1
)

del /F /Q "%TEMP_FILE%" >nul 2>&1

if not exist "%INSTALL_EXE%" (
    echo [BLAD] Plik nie istnieje po instalacji
    pause
    exit /b 1
)

echo [OK] Zainstalowano

:: Popup z informacja
powershell -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Aktualizacja zakonczona pomyslnie!', 'Nebula Launcher Updater', 'OK', 'Information')" >nul 2>&1

:: AUTOMATYCZNIE URUCHOM LAUNCHER PO AKTUALIZACJI
echo [INFO] Uruchamianie launchera...
start "" "%INSTALL_EXE%"

exit
