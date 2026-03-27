@echo off
chcp 65001 >nul
title Nebula Launcher Updater
setlocal EnableDelayedExpansion

:: Konfiguracja
set "UPDATE_URL=https://huggingface.co/datasets/qwdqdqwe/system-gier/resolve/main/Nebulauncher.exe"
set "LAUNCHER_NAME=Nebulauncher.exe"
set "TEMP_FILE=%TEMP%\launcher_update_%RANDOM%.exe"
set "INSTALL_DIR=%~dp0"
set "LAUNCHER_PATH=%INSTALL_DIR%%LAUNCHER_NAME%"
set "LOG_FILE=%TEMP%\nebula_updater.log"

:: Rozpocznij logowanie
echo [%date% %time%] Updater uruchomiony > "%LOG_FILE%"
echo [%date% %time%] Katalog instalacji: %INSTALL_DIR% >> "%LOG_FILE%"

:: Sprawdź czy mamy uprawnienia administratora (opcjonalnie, ale pomocne)
net session >nul 2>&1
if %errorlevel% == 0 (
    echo [%date% %time%] Uruchomiono z uprawnieniami administratora >> "%LOG_FILE%"
) else (
    echo [%date% %time%] Uruchomiono bez uprawnień administratora >> "%LOG_FILE%"
)

:: Sprawdź czy katalog instalacji istnieje, jeśli nie - utwórz go
if not exist "%INSTALL_DIR%" (
    echo Tworzę katalog instalacji...
    mkdir "%INSTALL_DIR%" 2>nul
    if %errorlevel% NEQ 0 (
        echo [%date% %time%] BŁĄD: Nie można utworzyć katalogu %INSTALL_DIR% >> "%LOG_FILE%"
        echo Błąd: Nie można utworzyć katalogu instalacji.
        pause
        exit /b 1
    )
)

:: Sprawdź czy można pisać w katalogu instalacji
echo test > "%INSTALL_DIR%.write_test" 2>nul
if exist "%INSTALL_DIR%.write_test" (
    del "%INSTALL_DIR%.write_test" >nul 2>&1
    echo [%date% %time%] Uprawnienia do zapisu: OK >> "%LOG_FILE%"
) else (
    echo [%date% %time%] BŁĄD: Brak uprawnień do zapisu w %INSTALL_DIR% >> "%LOG_FILE%"
    echo Błąd: Brak uprawnień do zapisu w katalogu instalacji.
    echo Uruchom updater jako administrator lub zmień katalog instalacji.
    pause
    exit /b 1
)

:: Zamknij launcher jeśli działa - sprawdzenie w pętli z wieloma próbami
set "RETRY_COUNT=0"
:CHECK_LOOP
tasklist | findstr /I "%LAUNCHER_NAME%" >nul
if %errorlevel% == 0 (
    if %RETRY_COUNT% == 0 (
        echo Zamykam uruchomiony launcher...
        echo [%date% %time%] Zamykanie procesu %LAUNCHER_NAME% >> "%LOG_FILE%"
    )
    taskkill /F /IM "%LAUNCHER_NAME%" >nul 2>&1
    timeout /T 1 /NOBREAK >nul
    set /a RETRY_COUNT+=1
    if %RETRY_COUNT% LSS 5 goto CHECK_LOOP
    echo [%date% %time%] Ostrzeżenie: Nie udało się zamknąć launchera po 5 próbach >> "%LOG_FILE%"
)

:: Dodatkowe opóźnienie aby upewnić się że proces został zamknięty
timeout /T 2 /NOBREAK >nul

:: Sprawdź czy plik jest nadal zablokowany
if exist "%LAUNCHER_PATH%" (
    move "%LAUNCHER_PATH%" "%LAUNCHER_PATH%.test_lock" >nul 2>&1
    if %errorlevel% NEQ 0 (
        echo [%date% %time%] BŁĄD: Plik %LAUNCHER_NAME% jest nadal zablokowany >> "%LOG_FILE%"
        echo Błąd: Launcher jest nadal uruchomiony lub plik jest zablokowany.
        echo Zamknij launcher ręcznie i spróbuj ponownie.
        pause
        exit /b 1
    )
    move "%LAUNCHER_PATH%.test_lock" "%LAUNCHER_PATH%" >nul 2>&1
)

:: Pobierz nową wersję z obsługą przekierowań i retry
echo Pobieram aktualizację...
echo [%date% %time%] Rozpoczynam pobieranie z: %UPDATE_URL% >> "%LOG_FILE%"

set "DOWNLOAD_SUCCESS=0"
set "DOWNLOAD_RETRY=0"

:DOWNLOAD_RETRY_LOOP
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ProgressPreference = 'SilentlyContinue';" ^
    "$ErrorActionPreference = 'Stop';" ^
    "try {" ^
        "$response = Invoke-WebRequest -Uri '%UPDATE_URL%' -OutFile '%TEMP_FILE%' -UseBasicParsing -MaximumRedirection 10 -TimeoutSec 60;" ^
        "$size = (Get-Item '%TEMP_FILE%').Length;" ^
        "if ($size -gt 10000) { Write-Host 'OK: Pobrano $size bajtow'; exit 0 }" ^
        "else { Write-Host 'BLAD: Plik za maly ($size bajtow)'; exit 1 }" ^
    "} catch {" ^
        "Write-Host 'BLAD: ' $_.Exception.Message;" ^
        "exit 1" ^
    "}"

if %errorlevel% EQU 0 (
    set "DOWNLOAD_SUCCESS=1"
    echo [%date% %time%] Pobieranie zakończone sukcesem >> "%LOG_FILE%"
) else (
    set /a DOWNLOAD_RETRY+=1
    if %DOWNLOAD_RETRY% LSS 3 (
        echo Błąd pobierania, ponawiam próbę %DOWNLOAD_RETRY%/3...
        echo [%date% %time%] Ponawianie próby pobierania %DOWNLOAD_RETRY% >> "%LOG_FILE%"
        timeout /T 2 /NOBREAK >nul
        goto DOWNLOAD_RETRY_LOOP
    ) else (
        echo [%date% %time%] BŁĄD: Nie udało się pobrać po 3 próbach >> "%LOG_FILE%"
    )
)

if %DOWNLOAD_SUCCESS% NEQ 1 (
    echo Błąd: Nie udało się pobrać aktualizacji.
    if exist "%TEMP_FILE%" del "%TEMP_FILE%" >nul 2>&1
    pause
    exit /b 1
)

:: Weryfikacja pobranego pliku
if not exist "%TEMP_FILE%" (
    echo [%date% %time%] BŁĄD: Plik tymczasowy nie istnieje po pobraniu >> "%LOG_FILE%"
    echo Błąd: Pobrany plik nie istnieje.
    pause
    exit /b 1
)

for %%F in ("%TEMP_FILE%") do set "FILE_SIZE=%%~zF"
echo [%date% %time%] Rozmiar pobranego pliku: %FILE_SIZE% bajtów >> "%LOG_FILE%"

if %FILE_SIZE% LSS 10000 (
    echo Błąd: Pobrany plik jest za mały (%FILE_SIZE% bajtów).
    echo [%date% %time%] BŁĄD: Plik za mały >> "%LOG_FILE%"
    type "%TEMP_FILE%" >> "%LOG_FILE%" 2>&1
    del "%TEMP_FILE%" >nul 2>&1
    pause
    exit /b 1
)

:: Sprawdź czy plik to prawdziwy EXE (sprawdzenie nagłówka MZ)
powershell -NoProfile -Command "$bytes = Get-Content '%TEMP_FILE%' -Encoding Byte -TotalCount 2; if ($bytes[0] -eq 0x4D -and $bytes[1] -eq 0x5A) { exit 0 } else { exit 1 }"
if %errorlevel% NEQ 0 (
    echo Błąd: Pobrany plik nie jest prawidłowym plikiem EXE.
    echo [%date% %time%] BŁĄD: Nieprawidłowy nagłówek pliku EXE >> "%LOG_FILE%"
    del "%TEMP_FILE%" >nul 2>&1
    pause
    exit /b 1
)

echo [%date% %time%] Weryfikacja pliku: OK >> "%LOG_FILE%"

:: Zrób kopię zapasową starej wersji z timestampem
if exist "%LAUNCHER_PATH%" (
    for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set "MYDATE=%%c-%%a-%%b")
    for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set "MYTIME=%%a%%b")
    set "BACKUP_NAME=%LAUNCHER_PATH%.backup_%MYDATE%_%MYTIME%"
    
    echo Tworzę kopię zapasową...
    echo [%date% %time%] Tworzenie kopii zapasowej: !BACKUP_NAME! >> "%LOG_FILE%"
    
    copy /Y "%LAUNCHER_PATH%" "!BACKUP_NAME!" >nul 2>&1
    if %errorlevel% NEQ 0 (
        echo Ostrzeżenie: Nie udało się utworzyć kopii zapasowej z timestampem, próbuję standardową...
        copy /Y "%LAUNCHER_PATH%" "%LAUNCHER_PATH%.backup" >nul 2>&1
        set "BACKUP_NAME=%LAUNCHER_PATH%.backup"
    )
) else (
    echo [%date% %time%] Brak istniejącej instalacji do backupu >> "%LOG_FILE%"
)

:: Zamień plik - użycie copy zamiast move dla bezpieczeństwa
echo Instaluję aktualizację...
echo [%date% %time%] Instalacja nowej wersji... >> "%LOG_FILE%"

:: Jeśli plik docelowy istnieje, usuń go najpierw
if exist "%LAUNCHER_PATH%" (
    del "%LAUNCHER_PATH%" >nul 2>&1
    if exist "%LAUNCHER_PATH%" (
        echo [%date% %time%] BŁĄD: Nie można usunąć starego pliku >> "%LOG_FILE%"
        echo Błąd: Nie można usunąć starej wersji. Plik może być zablokowany.
        pause
        exit /b 1
    )
)

:: Kopiuj nowy plik
copy /Y "%TEMP_FILE%" "%LAUNCHER_PATH%" >nul 2>&1

if %errorlevel% NEQ 0 (
    echo Błąd: Nie udało się zainstalować aktualizacji.
    echo [%date% %time%] BŁĄD: Kopiowanie nie powiodło się >> "%LOG_FILE%"
    
    :: Przywróć kopię zapasową
    if defined BACKUP_NAME (
        if exist "!BACKUP_NAME!" (
            echo Przywracam starą wersję...
            echo [%date% %time%] Przywracanie kopii zapasowej >> "%LOG_FILE%"
            copy /Y "!BACKUP_NAME!" "%LAUNCHER_PATH%" >nul 2>&1
        )
    )
    del "%TEMP_FILE%" >nul 2>&1
    pause
    exit /b 1
)

:: Wyczyść plik tymczasowy
del "%TEMP_FILE%" >nul 2>&1

:: Sprawdź czy nowy plik istnieje i ma prawidłowy rozmiar
if not exist "%LAUNCHER_PATH%" (
    echo Błąd: Plik instalacyjny zniknął!
    echo [%date% %time%] BŁĄD: Plik docelowy nie istnieje po instalacji >> "%LOG_FILE%"
    pause
    exit /b 1
)

for %%F in ("%LAUNCHER_PATH%") do set "NEW_SIZE=%%~zF"
echo [%date% %time%] Nowy plik: %NEW_SIZE% bajtów >> "%LOG_FILE%"

:: Uruchom zaktualizowany launcher
echo.
echo ========================================
echo  Aktualizacja zakończona sukcesem!
echo  Wersja: %NEW_SIZE% bajtów
echo ========================================
echo.
echo Uruchamiam launcher...
echo [%date% %time%] Uruchamianie %LAUNCHER_NAME% >> "%LOG_FILE%"

timeout /T 1 /NOBREAK >nul

start "" "%LAUNCHER_PATH%"

if %errorlevel% NEQ 0 (
    echo [%date% %time%] BŁĄD: Nie udało się uruchomić launchera >> "%LOG_FILE%"
    echo Ostrzeżenie: Nie udało się automatycznie uruchomić launchera.
    echo Możesz uruchomić go ręcznie z: %LAUNCHER_PATH%
    pause
) else (
    echo [%date% %time%] Launcher uruchomiony pomyślnie >> "%LOG_FILE%"
)

:: Wyczyść stare kopie zapasowe (zostaw tylko ostatnie 3)
echo [%date% %time%] Czyszczenie starych kopii zapasowych... >> "%LOG_FILE%"
for /f "skip=3 delims=" %%F in ('dir /B /O-D "%LAUNCHER_PATH%.backup_*" 2^>nul') do (
    del "%INSTALL_DIR%%%F" >nul 2>&1
)

:: Opcjonalnie: zachowaj log
echo [%date% %time%] Updater zakończony >> "%LOG_FILE%"

timeout /T 2 /NOBREAK >nul
exit
