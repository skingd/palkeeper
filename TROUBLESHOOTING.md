# Troubleshooting: Server Failed to Start

## Issue Summary
Based on your logs, the server startup script executes, but `PalServer-Win64-Shipping-Cmd.exe` doesn't start within 60 seconds.

```
[2025-11-09 12:07:36] [ERROR] Server failed to start within 60 seconds
```

## Root Causes & Solutions

### 1. **Increased Startup Wait Time**
✅ **FIXED**: Changed `startupWaitTime` from 60 to 120 seconds in `config.json`

The server might just need more time to initialize. Now it will wait 2 minutes instead of 1 minute.

### 2. **Wrong Executable Name in Startup Script**
⚠️ **LIKELY ISSUE**: Your startup script might be launching the wrong executable.

**Current Config**: Looking for `PalServer-Win64-Shipping-Cmd.exe`
**Common Names**:
- `PalServer-Win64-Shipping-Cmd.exe` (Dedicated server, command-line)
- `PalServer.exe` (May be a wrapper)
- `PalServer-Win64-Shipping.exe` (Alternative name)

**Action Required**:
1. Run `DIAGNOSTIC.bat` on the server to see which executables exist
2. Update `G:\steamcmd\palworld.bat` to use the correct executable name

### 3. **Startup Script Doesn't Exit**
⚠️ **POTENTIAL ISSUE**: If the startup script waits for the server to finish, PalKeeper thinks it's still "starting"

**Solution**: Use the new `palworld-START-FIXED.bat` which:
- Uses `start` command to launch server in new window
- Exits immediately after launch
- Includes diagnostic output

### 4. **Server Paths Are Wrong**
⚠️ **CHECK THIS**: The server might be installed in a different location

**Expected Paths**:
- Server: `G:\Palworld\PalServer-Win64-Shipping-Cmd.exe`
- Saves: `G:\palworld\Pal\Saved\SaveGames\0\4256E675445C0C2720B5FEAE386BFF63`
- SteamCMD: `G:\steamcmd\steamcmd.exe`

## Diagnostic Steps

### Step 1: Run Diagnostic Script
Copy `DIAGNOSTIC.bat` to the server and run it:
```powershell
Copy-Item "C:\Users\sking\OneDrive\Documents\repos\Palkeeper\DIAGNOSTIC.bat" `
          -Destination "\\nephalim\g$\DIAGNOSTIC.bat"

# Then on the server:
G:\DIAGNOSTIC.bat
```

This will show you:
- ✓ Which executables exist in `G:\Palworld\`
- ✓ If the server is already running
- ✓ If all required paths exist

### Step 2: Update Startup Script
Based on diagnostic results, deploy the correct startup script:

**If using `PalServer-Win64-Shipping-Cmd.exe`**:
```powershell
Copy-Item "C:\Users\sking\OneDrive\Documents\repos\Palkeeper\palworld-START-FIXED.bat" `
          -Destination "\\nephalim\g$\steamcmd\palworld.bat" `
          -Force
```

**If executable has a different name**, edit `palworld-START-FIXED.bat` first, then copy.

### Step 3: Update Config If Needed
If the executable has a different name, update `config.json`:

```json
{
  "basicSettings": {
    "serverExecutable": "PalServer.exe",  // ← Change to actual name
    "startupWaitTime": 120
  }
}
```

### Step 4: Test Manually
On the server, test the startup script manually:
```batch
cd G:\steamcmd
palworld.bat
```

Then check if the process started:
```powershell
Get-Process -Name "PalServer*"
```

## Common Issues & Fixes

### Issue: "Server executable not found"
**Cause**: Wrong path or name
**Fix**: 
1. Check `G:\Palworld\` for actual executable name
2. Update startup script with correct name
3. Update `config.json` `serverExecutable` setting

### Issue: "Server is already running"
**Cause**: Server didn't shut down properly
**Fix**:
```powershell
# Kill existing server process
Stop-Process -Name "PalServer*" -Force

# Then restart PalKeeper
```

### Issue: "Access denied" or permission errors
**Cause**: Insufficient permissions
**Fix**: Run PalKeeper as Administrator

### Issue: Server starts but immediately crashes
**Cause**: Configuration error in Palworld settings
**Fix**: 
1. Check `G:\Palworld\Pal\Saved\Config\WindowsServer\PalWorldSettings.ini`
2. Review server logs in `G:\Palworld\Pal\Saved\Logs\`

## Updated Files

### 1. `config.json`
- Increased `startupWaitTime` from 60 to 120 seconds
- Increased `updateTimeout` from 300 to 1800 seconds (from previous fix)

### 2. `palworld-START-FIXED.bat` (NEW)
- Launches correct executable: `PalServer-Win64-Shipping-Cmd.exe`
- Uses `start` command to launch in new window and exit
- Includes diagnostic output showing available executables
- Exits with code 0 so PalKeeper knows it completed

### 3. `DIAGNOSTIC.bat` (NEW)
- Checks all required paths
- Lists available executables
- Shows if server is running
- Helps identify configuration issues

## Next Steps

1. **Run DIAGNOSTIC.bat** on the server
2. **Check the output** to see which executable exists
3. **Deploy the correct startup script** to `G:\steamcmd\palworld.bat`
4. **Update config.json** if the executable name is different
5. **Test manually** before running PalKeeper
6. **Run PalKeeper** with updated configuration

## Expected Log Output After Fix

```
[TIMESTAMP] ========================================
[TIMESTAMP] Starting Palworld server...
[TIMESTAMP] Startup script: G:\steamcmd\palworld.bat
[TIMESTAMP] ========================================
[TIMESTAMP] Executing via cmd.exe from directory: G:\steamcmd
[TIMESTAMP] Startup script process launched (PID: XXXXX)
[TIMESTAMP] Server startup command executed (Total restarts: 1)
[TIMESTAMP] Waiting for server to start (max 120 seconds)...
[TIMESTAMP] Server started successfully!
```

---

**Key Actions Required**:
1. ✅ Run DIAGNOSTIC.bat to identify the correct executable name
2. ✅ Deploy palworld-START-FIXED.bat to G:\steamcmd\palworld.bat
3. ✅ Verify server starts manually before testing PalKeeper
