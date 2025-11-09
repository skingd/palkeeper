@echo off
REM Palworld Server Start Script
REM Deploy this to G:\steamcmd\palworld.bat on the server
REM This script should launch the server and EXIT (so monitoring script can detect it)

echo ========================================
echo Starting Palworld Dedicated Server
echo ========================================
echo.

REM Change to the actual Palworld installation directory
cd /d "G:\palworld"

if not exist "G:\palworld\PalServer.exe" (
    echo ERROR: Server executable not found!
    echo Looking for: G:\palworld\PalServer.exe
    echo.
    echo Current directory: %CD%
    echo Available executables:
    dir /b *.exe 2>nul
    echo.
    pause
    exit /b 1
)

echo Current directory: %CD%
echo Server executable: G:\palworld\PalServer.exe
echo.
echo Launching server process...

REM Start the server with START command (launches in new window and exits this script)
REM This allows PalKeeper to detect when the startup script completes
start "Palworld Server" "G:\palworld\PalServer.exe" -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS

echo.
echo Server launch command issued!
echo The server is starting in a new window...
echo This script will now exit.
echo ========================================

REM Exit the script so PalKeeper knows startup is complete
exit /b 0
