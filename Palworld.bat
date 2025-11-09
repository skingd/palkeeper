@echo off
REM Palworld Server Update Script
REM This uses the existing SteamCMD installation at G:\steamcmd

echo ========================================
echo Palworld Server Update
echo ========================================
echo.

echo Using SteamCMD from: G:\steamcmd\steamcmd.exe
echo Target installation: G:\Palworld
echo.

REM Call the existing steamcmd.exe with full path
"G:\steamcmd\steamcmd.exe" +login anonymous +force_install_dir "G:\Palworld" +app_update 2394010 validate +quit

set UPDATE_EXIT_CODE=%ERRORLEVEL%

echo.
echo ========================================
echo Update complete with exit code: %UPDATE_EXIT_CODE%
echo ========================================

exit /b %UPDATE_EXIT_CODE%
