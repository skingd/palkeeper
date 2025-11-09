# PalKeeper Deployment Guide

## Overview
PalKeeper is now configured to:
1. ✅ Create a backup BEFORE updates
2. ✅ Run updates every time on startup using **local Palworld.bat**
3. ✅ Use existing SteamCMD installation at `G:\steamcmd\steamcmd.exe`
4. ✅ Monitor and auto-restart the Palworld server
5. ✅ Rotate backups (keep last 10)

## Files to Deploy

Copy the following files to your server (e.g., `G:\PalKeeper\`):

### Required Files
- `PalKeeperAdvanced.ps1` - Main monitoring script
- `config.json` - Configuration file
- `Palworld.bat` - Local update script (uses G:\steamcmd\steamcmd.exe)
- `StartPalKeeperAdvanced.bat` - Quick launcher

### Optional Files
- `README.md` - Full documentation
- `production-config.json` - Sample production config
- `StartPalKeeperCustomConfig.bat` - Launcher for custom configs

## Key Configuration Settings

### config.json
```json
{
  "basicSettings": {
    "checkInterval": 30,
    "serverExecutable": "PalServer-Win64-Shipping-Cmd.exe",
    "startupScript": "G:\\steamcmd\\palworld.bat",
    "startupWaitTime": 60
  },
  "updateSettings": {
    "runUpdatesOnStart": true,
    "updateScript": "Palworld.bat",  // ← RELATIVE PATH (resolves to PalKeeper directory)
    "updateTimeout": 300
  },
  "backupSettings": {
    "enableBackup": true,
    "backupOnStart": true,
    "saveFilePath": "G:\\palworld\\Pal\\Saved\\SaveGames\\0\\4256E675445C0C2720B5FEAE386BFF63",
    "backupDestination": "G:\\Backups\\Palworld",
    "maxBackups": 10,
    "backupBeforeUpdate": true  // ← BACKUP BEFORE UPDATE
  }
}
```

## How It Works

### Startup Sequence
1. **Backup**: Creates timestamped backup to `G:\Backups\Palworld\`
2. **Update**: Runs `Palworld.bat` (located in PalKeeper directory)
   - Calls `G:\steamcmd\steamcmd.exe` (existing installation)
   - Updates Palworld server at `G:\Palworld`
3. **Start**: Launches server using `G:\steamcmd\palworld.bat`
4. **Monitor**: Checks every 30 seconds, restarts if crashed

### Palworld.bat (Local Update Script)
```batch
"G:\steamcmd\steamcmd.exe" +login anonymous +force_install_dir "G:\Palworld" +app_update 2394010 validate +quit
```

This uses your **existing SteamCMD installation** instead of creating a new one.

## Deployment Steps

1. **Copy files to server**:
   ```powershell
   Copy-Item -Path "C:\Users\sking\OneDrive\Documents\repos\Palkeeper\*" `
             -Destination "\\nephalim\g$\PalKeeper\" `
             -Include @("PalKeeperAdvanced.ps1", "config.json", "Palworld.bat", "*.bat") `
             -Force
   ```

2. **Verify paths on server**:
   - SteamCMD: `G:\steamcmd\steamcmd.exe` ✅
   - Server install: `G:\Palworld` ✅
   - Startup script: `G:\steamcmd\palworld.bat` ✅
   - Save files: `G:\palworld\Pal\Saved\SaveGames\0\4256E675445C0C2720B5FEAE386BFF63` ✅
   - Backups: `G:\Backups\Palworld` (will be created automatically)

3. **Test on server**:
   ```powershell
   cd G:\PalKeeper
   .\PalKeeperAdvanced.ps1
   ```

4. **Expected output**:
   ```
   [2025-01-XX XX:XX:XX] ========================================
   [2025-01-XX XX:XX:XX] PalKeeper Advanced - Starting...
   [2025-01-XX XX:XX:XX] ========================================
   [2025-01-XX XX:XX:XX] Creating startup backup...
   [2025-01-XX XX:XX:XX] Backup created successfully: Backup_Startup_2025-01-XX_XX-XX-XX
   [2025-01-XX XX:XX:XX] ========================================
   [2025-01-XX XX:XX:XX] Starting server update process...
   [2025-01-XX XX:XX:XX] Update script: G:\PalKeeper\Palworld.bat
   [2025-01-XX XX:XX:XX] ========================================
   [2025-01-XX XX:XX:XX] Creating pre-update backup...
   [2025-01-XX XX:XX:XX] UPDATE: Using SteamCMD from: G:\steamcmd\steamcmd.exe
   [2025-01-XX XX:XX:XX] UPDATE: Connecting to Steam servers...
   ```

## Troubleshooting

### If update script not found:
- Verify `Palworld.bat` is in the same directory as `PalKeeperAdvanced.ps1`
- Check log: `G:\PalKeeper\PalKeeper.log`

### If SteamCMD fails:
- Verify `G:\steamcmd\steamcmd.exe` exists
- Check SteamCMD is working: `G:\steamcmd\steamcmd.exe +quit`

### If backups fail:
- Verify save file path: `G:\palworld\Pal\Saved\SaveGames\0\4256E675445C0C2720B5FEAE386BFF63`
- Check backup destination permissions: `G:\Backups\Palworld`

## Important Notes

- ✅ Updates run **EVERY TIME** on startup
- ✅ Backup is created **BEFORE** every update
- ✅ Uses **EXISTING** SteamCMD installation (no duplicate install)
- ✅ Relative path support (Palworld.bat resolves to PalKeeper directory)
- ✅ Keeps last 10 backups (configurable in `maxBackups`)
- ✅ All logs in `PalKeeper.log` with color-coded console output

## Next Steps

1. Deploy files to `G:\PalKeeper\` on nephalim server
2. Test the complete startup sequence
3. Verify backups are created in `G:\Backups\Palworld\`
4. Monitor `PalKeeper.log` for any issues
5. Optional: Set up email notifications in `config.json`

---

**Ready for deployment!** 🚀
