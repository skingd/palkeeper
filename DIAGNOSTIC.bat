@echo off
REM Diagnostic Script for Palworld Server Setup
REM Run this on the server to verify all paths are correct

echo ========================================
echo Palworld Server Diagnostic Check
echo ========================================
echo.

echo [1] Checking Palworld installation directory...
echo.
echo     Checking G:\Palworld (SteamCMD install location):
if exist "G:\Palworld" (
    echo     ✓ G:\Palworld exists
    cd /d "G:\Palworld"
    echo     Server executables found:
    dir /b *.exe 2>nul
    echo.
) else (
    echo     ✗ G:\Palworld NOT FOUND
)

echo     Checking G:\palworld (Actual server location):
if exist "G:\palworld" (
    echo     ✓ G:\palworld exists
    cd /d "G:\palworld"
    echo     Server executables found:
    dir /b *.exe 2>nul
    echo.
) else (
    echo     ✗ G:\palworld NOT FOUND
)
echo.
echo [2] Checking SteamCMD installation...
if exist "G:\steamcmd\steamcmd.exe" (
    echo     ✓ G:\steamcmd\steamcmd.exe exists
) else (
    echo     ✗ G:\steamcmd\steamcmd.exe NOT FOUND
)

echo.
echo [3] Checking for startup script...
if exist "G:\steamcmd\palworld.bat" (
    echo     ✓ G:\steamcmd\palworld.bat exists
) else (
    echo     ✗ G:\steamcmd\palworld.bat NOT FOUND
)

echo.
echo [4] Checking for save files...
if exist "G:\palworld\Pal\Saved\SaveGames" (
    echo     ✓ G:\palworld\Pal\Saved\SaveGames exists
    echo.
    echo     Save directories:
    dir /b /s "G:\palworld\Pal\Saved\SaveGames" 2>nul | findstr /R "^.*\\[0-9A-F]"
) else (
    echo     ✗ G:\palworld\Pal\Saved\SaveGames NOT FOUND
)

echo.
echo [5] Checking if server is currently running...
echo.
echo     Checking for PalServer.exe:
tasklist /FI "IMAGENAME eq PalServer.exe" 2>NUL | find /I /N "PalServer.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo     ✓ PalServer.exe IS RUNNING
    tasklist /FI "IMAGENAME eq PalServer.exe"
) else (
    echo     ✗ PalServer.exe is NOT running
)

echo.
echo     Checking for PalServer-Win64-Shipping-Cmd.exe:
tasklist /FI "IMAGENAME eq PalServer-Win64-Shipping-Cmd.exe" 2>NUL | find /I /N "PalServer-Win64-Shipping-Cmd.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo     ✓ PalServer-Win64-Shipping-Cmd.exe IS RUNNING
    tasklist /FI "IMAGENAME eq PalServer-Win64-Shipping-Cmd.exe"
) else (
    echo     ✗ PalServer-Win64-Shipping-Cmd.exe is NOT running
)

echo.
echo     All Palworld-related processes:
tasklist | findstr /I "Pal"

echo.
echo [6] Checking backup directory...
if exist "G:\Backups\Palworld" (
    echo     ✓ G:\Backups\Palworld exists
) else (
    echo     ⚠ G:\Backups\Palworld does not exist (will be created automatically)
)

echo.
echo ========================================
echo Diagnostic check complete!
echo ========================================
echo.

pause
