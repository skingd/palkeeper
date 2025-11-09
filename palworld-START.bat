@echo off
REM Palworld Server Start Script - CORRECTED VERSION
REM This script starts the Palworld dedicated server
REM Deploy this to G:\steamcmd\palworld.bat on the server

echo ========================================
echo Starting Palworld Dedicated Server
echo ========================================
echo.

REM Change to the Palworld installation directory
cd /d "G:\Palworld"

echo Current directory: %CD%
echo Server executable: G:\Palworld\PalServer.exe
echo.

REM Start the server (adjust parameters as needed)
start "Palworld Server" "G:\Palworld\PalServer.exe" -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS

echo.
echo Server process started!
echo ========================================
