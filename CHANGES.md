# Recent Changes - Event-Based Update System

## Changes Made

### 1. Event-Based Update Process (Fixed 60-Second Timeout)
**Problem**: Update script was timing out after 60 seconds even though SteamCMD updates can take much longer.

**Solution**: Implemented event-based process monitoring:
- Added `Exited` event handler to detect when batch file completes
- Changed from fixed timeout to continuous monitoring with timeout safety
- Process now waits for **actual completion** rather than arbitrary timeout
- Shows progress updates every 30 seconds during long updates
- Increased default timeout from 300 to 1800 seconds (30 minutes)

**How it works**:
```powershell
# Register exit event handler
$exitEvent = Register-ObjectEvent -InputObject $process -EventName Exited -Action $exitEventHandler

# Enable event raising
$process.EnableRaisingEvents = $true

# Wait for process to actually exit
while (-not $process.HasExited) {
    Start-Sleep -Seconds 2
    # Check timeout as safety measure
    # Show progress every 30 seconds
}
```

### 2. Improved Server Startup Diagnostics
**Problem**: Server startup was failing silently without detailed error information.

**Solution**: Enhanced `Start-Server` function with:
- Better error messages showing exact paths being used
- Process ID tracking for launched processes
- Detailed error output including exception details
- Clear log messages showing execution method (cmd.exe vs direct)
- Added `-PassThru` to get process info and verify launch

**New output**:
```
[TIMESTAMP] ========================================
[TIMESTAMP] Starting Palworld server...
[TIMESTAMP] Startup script: G:\steamcmd\palworld.bat
[TIMESTAMP] ========================================
[TIMESTAMP] Executing via cmd.exe from directory: G:\steamcmd
[TIMESTAMP] Startup script process launched (PID: 12345)
[TIMESTAMP] Server startup command executed (Total restarts: 1)
```

### 3. Configuration Updates

Updated `config.json`:
```json
"updateSettings": {
  "runUpdatesOnStart": true,
  "updateScript": "Palworld.bat",
  "updateTimeout": 1800  // ← Increased from 300 to 1800 (30 minutes)
}
```

## What This Fixes

✅ **No more premature timeout**: Update process waits for actual completion
✅ **Better visibility**: Progress updates every 30 seconds during long updates
✅ **Accurate timing**: Shows actual duration of update process
✅ **Safety timeout**: Still has 30-minute maximum to prevent infinite hangs
✅ **Better debugging**: Detailed startup error messages help diagnose server launch issues

## Testing the Changes

1. **Test update process**:
   ```powershell
   cd C:\Users\sking\OneDrive\Documents\repos\Palkeeper
   .\PalKeeperAdvanced.ps1
   ```

2. **Watch for new log messages**:
   - "UPDATE: Process exited with code 0" (when update completes)
   - "Update process completed in X.X seconds" (shows actual duration)
   - "Still updating... (X seconds elapsed)" (progress updates)
   - "Startup script process launched (PID: XXXXX)" (server startup)

3. **Expected behavior**:
   - Update will run to completion (even if > 5 minutes)
   - Progress shown every 30 seconds
   - Server startup shows detailed path and PID info
   - Any errors show full exception details

## Troubleshooting

### If updates still timeout:
- Check the timeout value in config.json (default is now 1800 seconds = 30 minutes)
- Increase if needed for slow internet connections
- Check log for "Still updating..." messages to see progress

### If server fails to start:
- Look for "Startup script not found" error with exact path
- Check for "Failed to start server" with detailed exception
- Verify PID is shown in "Startup script process launched" message
- Ensure G:\steamcmd\palworld.bat exists and is executable

### If you see "UNC paths not supported":
- The pushd/popd mechanism should handle this
- Check log for "Executing via cmd.exe from directory:" message

## Next Steps

1. Deploy updated files to server
2. Run a test to verify updates complete successfully
3. Monitor the log file for detailed progress information
4. Verify server starts successfully after update

---

**Key Improvement**: The update process now **listens for the batch file to finish** rather than guessing with a timeout! 🎉
