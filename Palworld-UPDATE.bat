@echo off
REM Palworld Server Update Script - CORRECTED VERSION
REM Deploy this to G:\steamcmd\Palworld.bat on the server
REM This replaces the broken version that called "steamcmd" without the .exe extension

echo ========================================
echo Palworld Server Update
echo ========================================
echo.

REM Change to the steamcmd directory where steamcmd.exe is located
cd /d "%~dp0"

echo Current directory: %CD%
echo Running SteamCMD update...
echo.

REM Run SteamCMD to update Palworld
REM FIXED: Changed "steamcmd" to "steamcmd.exe"
steamcmd.exe +login anonymous +force_install_dir G:\Palworld +app_update 2394010 validate +quit

set UPDATE_EXIT_CODE=%ERRORLEVEL%

echo.
echo ========================================
echo Update complete with exit code: %UPDATE_EXIT_CODE%
echo ========================================

exit /b %UPDATE_EXIT_CODE%
