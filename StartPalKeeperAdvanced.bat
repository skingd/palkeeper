@echo off
title PalKeeper Advanced - Palworld Server Monitor
echo Starting PalKeeper Advanced with JSON configuration...
echo.

REM Change to the script directory
cd /d "%~dp0"

REM Check if config.json exists, if not, the script will create a default one
if not exist "config.json" (
    echo Configuration file not found. A default config.json will be created.
    echo Please edit the configuration file after creation and restart.
    echo.
)

REM Run the advanced PowerShell script with execution policy bypass
powershell.exe -ExecutionPolicy Bypass -File "PalKeeperAdvanced.ps1"

echo.
echo PalKeeper Advanced has stopped.
pause
