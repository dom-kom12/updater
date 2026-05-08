@echo off
chcp 65001 >nul
title Nebula Launcher Updater

:: Sprawdź czy uruchomiono jako administrator
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo [INFO] Wymagane uprawnienia administratora...
    powershell -Command "Start-Process '%~f0' -Verb runAs"
    exit /b
)

setlocal EnableDelayedExpansion

:: Konfiguracja
set "UPDATE_URL=https://huggingface.co/datasets/qwdqdqwe/system-gier/resolve/main/Nebulauncher.exe"
set "LAUNCHER_NAME=Nebulauncher.exe"
set "INSTALL_DIR=C:\Program Files (x86)\NebulaLauncher"
set "INSTALL_EXE=%INSTALL_DIR%\%LAUNCHER_NAME%"
set "OLD_FILE=%INSTALL_DIR%\%LAUNCHER_NAME%.old"
set "TEMP_FILE=%TEMP%\launcher_update_%RANDOM%.exe"

:: Folder użytkownika - NIE USUWAMY launcher.db
set "USER_DIR=C:\Users\domru\NebulaLauncher"

echo ========================================
echo  Nebula Launcher Updater v2.0
echo ========================================
echo.

:: INFORMACJA - NIE USUWAMY launcher.db
echo [INFO] Zachowuje plik launcher.db w %USER_DIR%...
echo.

:: USUŃ STARY PLIK .old
echo [INFO] Usuwam stary plik .old...

if exist "%OLD_FILE%" (
    echo [INFO] Znaleziono plik .old
    
    takeown /F "%OLD_FILE%" /A >nul 2>&1
    icacls "%OLD_FILE%" /grant Administrators:F >nul 2>&1
    attrib -R -S -H "%OLD_FILE%" >nul 2>&1
    
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

:: ZAMKNIJ LAUNCHER JEŚLI DZIAŁA
echo [INFO] Sprawdzam czy launcher dziala...
tasklist | findstr /I "%LAUNCHER_NAME%" >nul
if %errorlevel% == 0 (
    echo [INFO] Zamykanie launchera...
    taskkill /F /IM "%LAUNCHER_NAME%" >nul 2>&1
    set "CLOSED=1"
    echo [OK] Launcher zamkniety
) else (
    echo [OK] Launcher nie dzialal
    set "CLOSED=0"
)

:: Czekaj na zamknięcie procesu
timeout /T 2 /NOBREAK >nul

:: Sprawdź czy na pewno zamknięty
tasklist | findstr /I "%LAUNCHER_NAME%" >nul
if %errorlevel% == 0 (
    echo [BLAD] Nie udalo sie zamknac launchera!
    echo [INFO] Zamknij launcher recznie i sprobuj ponownie.
    pause
    exit /b 1
)

echo.

:: Pobieranie pliku
echo [INFO] Pobieram nowa wersje...

if exist "%TEMP_FILE%" del /F /Q "%TEMP_FILE%" >nul 2>&1

:: Próba 1: curl
curl -L -o "%TEMP_FILE%" "%UPDATE_URL%" >nul 2>&1
if %errorlevel% EQU 0 goto VERIFY

:: Próba 2: PowerShell
echo [INFO] Uzywam PowerShell...
powershell -NoProfile -Command "try{Invoke-WebRequest -Uri '%UPDATE_URL%' -OutFile '%TEMP_FILE%' -UseBasicParsing -MaximumRedirection 5}catch{exit 1}" >nul 2>&1
if %errorlevel% EQU 0 goto VERIFY

:: Próba 3: bitsadmin (tylko Windows 7/8)
echo [INFO] Uzywam BITS...
bitsadmin /transfer nebula /download /priority high "%UPDATE_URL%" "%TEMP_FILE%" >nul 2>&1
if %errorlevel% EQU 0 goto VERIFY

:: Próba 4: certutil (degradacja)
echo [INFO] Uzywam certutil...
certutil -urlcache -split -f "%UPDATE_URL%" "%TEMP_FILE%" >nul 2>&1

:VERIFY
:: Sprawdź czy plik istnieje
if not exist "%TEMP_FILE%" (
    echo [BLAD] Nie udalo sie pobrac pliku!
    pause
    exit /b 1
)

:: Sprawdź rozmiar pliku
for %%F in ("%TEMP_FILE%") do set "FILE_SIZE=%%~zF"
echo [INFO] Rozmiar pliku: %FILE_SIZE% bajtow

:: Plik nie może być za mały (minimum 1bit)
if %FILE_SIZE% LSS 1 (
    echo [BLAD] Plik pobrany nieprawidlowo (za maly)
    echo [INFO] Rozmiar: %FILE_SIZE% bajtow (oczekiwano min 1bit)
    del /F /Q "%TEMP_FILE%" >nul 2>&1
    pause
    exit /b 1
)

echo [OK] Plik pobrany prawidlowo
echo.

:: Instalacja
echo [INFO] Instaluje do Program Files...

:: Utwórz folder jeśli nie istnieje
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%" >nul 2>&1
    echo [OK] Utworzono folder: %INSTALL_DIR%
)

:: Usuń starą wersję jeśli istnieje
if exist "%INSTALL_EXE%" (
    echo [INFO] Usuwam stara wersje...
    
    takeown /F "%INSTALL_EXE%" /A >nul 2>&1
    icacls "%INSTALL_EXE%" /grant Administrators:F >nul 2>&1
    attrib -R -S -H "%INSTALL_EXE%" >nul 2>&1
    
    del /F /Q "%INSTALL_EXE%" >nul 2>&1
    
    if exist "%INSTALL_EXE%" (
        echo [BLAD] Nie mozna usunac starej wersji!
        echo [INFO] Sprawdz czy plik nie jest uzywany przez inny proces.
        pause
        exit /b 1
    )
    echo [OK] Stara wersja usunieta
)

:: Kopiuj nową wersję
echo [INFO] Kopiuje nowa wersje...
copy /Y "%TEMP_FILE%" "%INSTALL_EXE%" >nul 2>&1
if %errorlevel% NEQ 0 (
    echo [BLAD] Kopiowanie nieudane!
    echo [INFO] Sprawdz uprawnienia do folderu: %INSTALL_DIR%
    del /F /Q "%TEMP_FILE%" >nul 2>&1
    pause
    exit /b 1
)

:: Usuń plik tymczasowy
del /F /Q "%TEMP_FILE%" >nul 2>&1

:: Sprawdź czy plik istnieje po instalacji
if not exist "%INSTALL_EXE%" (
    echo [BLAD] Plik nie istnieje po instalacji!
    pause
    exit /b 1
)

:: Sprawdź czy plik nie jest uszkodzony
for %%F in ("%INSTALL_EXE%") do set "NEW_SIZE=%%~zF"
if %NEW_SIZE% LSS 1048576 (
    echo [BLAD] Zainstalowany plik jest uszkodzony (za maly)
    pause
    exit /b 1
)

echo [OK] Instalacja zakonczona pomyslnie!
echo.

:: Wyświetl powiadomienie
echo [INFO] Aktualizacja zakonczona!
echo.

:: Uruchom launcher
echo [INFO] Uruchamianie Nebula Launcher...
timeout /T 2 /NOBREAK >nul

if exist "%INSTALL_EXE%" (
    start "" "%INSTALL_EXE%"
    echo [OK] Launcher uruchomiony
) else (
    echo [BLAD] Nie znaleziono pliku launchera!
    pause
    exit /b 1
)

:: Powiadomienie w PowerShell (opcjonalne)
powershell -NoProfile -Command "& {[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('Aktualizacja zakonczona! Nebula Launcher zostanie uruchomiony.', 'Nebula Launcher', 'OK', 'Information')}" >nul 2>&1

exit /b 0
