@echo off
title PalKeeper Advanced - Custom Config
echo Starting PalKeeper Advanced with custom configuration...
echo.

REM Change to the script directory
cd /d "%~dp0"

REM Check if a config file was provided as parameter
if "%1"=="" (
    echo Usage: %0 [config-file]
    echo Example: %0 production-config.json
    echo.
    echo Using default config.json...
    set CONFIG_FILE=config.json
) else (
    set CONFIG_FILE=%1
    echo Using configuration file: %CONFIG_FILE%
)

REM Check if the specified config file exists
if not exist "%CONFIG_FILE%" (
    echo Configuration file not found: %CONFIG_FILE%
    echo A default configuration will be created.
    echo.
)

REM Run the advanced PowerShell script with custom config
powershell.exe -ExecutionPolicy Bypass -File "PalKeeperAdvanced.ps1" -ConfigFile "%CONFIG_FILE%"

echo.
echo PalKeeper Advanced has stopped.
pause
