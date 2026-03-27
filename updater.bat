@echo off
chcp 65001 >nul
title Nebula Launcher Updater
setlocal EnableDelayedExpansion

:: Konfiguracja
set "UPDATE_URL=https://huggingface.co/datasets/qwdqdqwe/system-gier/resolve/main/Nebulauncher.exe"
set "LAUNCHER_NAME=Nebulauncher.exe"
set "DESKTOP_PATH=%USERPROFILE%\Desktop"
set "LAUNCHER_PATH=%DESKTOP_PATH%\%LAUNCHER_NAME%"
set "TEMP_FILE=%TEMP%\launcher_update_%RANDOM%.exe"

echo ========================================
echo  Nebula Launcher Updater
echo ========================================
echo.

:: Sprawdz czy katalog pulpitu istnieje
if not exist "%DESKTOP_PATH%" (
    echo [BLAD] Nie znaleziono pulpitu: %DESKTOP_PATH%
    pause
    exit /b 1
)

echo [OK] Pulpit: %DESKTOP_PATH%

:: Zamknij launcher jesli dziala
taskkill /F /IM "%LAUNCHER_NAME%" >nul 2>&1
timeout /T 2 /NOBREAK >nul

:: Pobierz - prostsza metoda z curl (Windows 10/11 ma curl)
echo [INFO] Pobieram plik...

if exist "%TEMP_FILE%" del "%TEMP_FILE%" >nul 2>&1

:: Proba 1: curl (najszybszy)
curl -L -o "%TEMP_FILE%" "%UPDATE_URL%" >nul 2>&1
if %errorlevel% EQU 0 goto VERIFY

:: Proba 2: powershell z -UseBasicParsing
powershell -NoProfile -Command "try{Invoke-WebRequest -Uri '%UPDATE_URL%' -OutFile '%TEMP_FILE%' -UseBasicParsing -MaximumRedirection 5}catch{exit 1}" >nul 2>&1
if %errorlevel% EQU 0 goto VERIFY

:: Proba 3: bitsadmin
bitsadmin /transfer nebula /download /priority normal "%UPDATE_URL%" "%TEMP_FILE%" >nul 2>&1
if %errorlevel% EQU 0 goto VERIFY

echo [BLAD] Wszystkie metody pobierania nieudane
pause
exit /b 1

:VERIFY
echo [OK] Plik pobrany

:: Sprawdz czy plik istnieje i ma rozmiar
if not exist "%TEMP_FILE%" (
    echo [BLAD] Plik nie istnieje po pobraniu
    pause
    exit /b 1
)

for %%F in ("%TEMP_FILE%") do set "FILE_SIZE=%%~zF"
echo [INFO] Rozmiar: %FILE_SIZE% bajtow

if %FILE_SIZE% LSS 1000 (
    echo [BLAD] Plik za maly - prawdopodobnie blad 404 lub przekierowanie
    type "%TEMP_FILE%"
    del "%TEMP_FILE%" >nul 2>&1
    pause
    exit /b 1
)

:: Kopia zapasowa
if exist "%LAUNCHER_PATH%" (
    echo [INFO] Tworze kopie zapasowa...
    copy /Y "%LAUNCHER_PATH%" "%LAUNCHER_PATH%.old" >nul 2>&1
)

:: Instaluj na pulpit
echo [INFO] Instaluje na pulpit...

if exist "%LAUNCHER_PATH%" (
    del "%LAUNCHER_PATH%" >nul 2>&1
)

move /Y "%TEMP_FILE%" "%LAUNCHER_PATH%" >nul 2>&1
if %errorlevel% NEQ 0 (
    copy /Y "%TEMP_FILE%" "%LAUNCHER_PATH%" >nul 2>&1
    del "%TEMP_FILE%" >nul 2>&1
)

if not exist "%LAUNCHER_PATH%" (
    echo [BLAD] Instalacja nieudana
    pause
    exit /b 1
)

echo.
echo ========================================
echo  SUKCES! Plik zainstalowany na pulpicie:
echo  %LAUNCHER_PATH%
echo ========================================
echo.
echo Uruchamiam...

timeout /T 1 >nul
start "" "%LAUNCHER_PATH%"
exit
