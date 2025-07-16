@echo off
title PalKeeper - Palworld Server Monitor
echo Starting PalKeeper...
echo.

REM Change to the script directory
cd /d "%~dp0"

REM Run the PowerShell script with execution policy bypass
powershell.exe -ExecutionPolicy Bypass -File "PalKeeper.ps1"

echo.
echo PalKeeper has stopped.
pause
