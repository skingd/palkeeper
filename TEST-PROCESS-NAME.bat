@echo off
REM Test script to identify the actual Palworld server process
REM Run this, then check Task Manager to see what processes are running

echo ========================================
echo Palworld Process Test
echo ========================================
echo.

echo Starting Palworld server...
cd /d "G:\palworld"

echo.
echo BEFORE starting server:
echo Current Palworld processes:
tasklist | findstr /I "Pal"
echo.

echo Starting server in 5 seconds...
timeout /t 5

echo Launching PalServer.exe...
start "Palworld Server" "G:\palworld\PalServer.exe"

echo.
echo Waiting 15 seconds for server to initialize...
timeout /t 15

echo.
echo AFTER starting server:
echo Current Palworld processes:
tasklist | findstr /I "Pal"
echo.

echo ========================================
echo Check the output above to see:
echo 1. What process name appears (PalServer.exe vs PalServer-Win64-Shipping-Cmd.exe)
echo 2. Update config.json with the correct serverExecutable name
echo ========================================
echo.

pause
