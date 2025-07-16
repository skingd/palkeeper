# PalKeeper - Palworld Server Monitor

A PowerShell application that automatically monitors your Palworld server and restarts it if it goes down.

## Features

- Monitors the `PalServer-Win64-Shipping-Cmd.exe` process
- Automatically restarts the server if it's not running
- Configurable monitoring intervals
- Detailed logging with timestamps
- Graceful startup waiting
- Easy configuration through config file

## Files

- `PalKeeper.ps1` - Main monitoring script
- `StartPalKeeper.bat` - Convenient batch file to run the monitor
- `config.ps1` - Configuration file for customizing settings
- `PalKeeper.log` - Log file (created automatically)

## Quick Start

1. **Edit the configuration** (if needed):
   - Open `config.ps1` in a text editor
   - Modify the path to your Palworld startup script
   - Adjust monitoring intervals as desired

2. **Run the monitor**:
   - Double-click `StartPalKeeper.bat`, or
   - Run `PalKeeper.ps1` directly in PowerShell

# PalKeeper - Palworld Server Monitor

A PowerShell application that automatically monitors your Palworld server and restarts it if it goes down.

## Features

- Monitors the `PalServer-Win64-Shipping-Cmd.exe` process
- Automatically restarts the server if it's not running
- **JSON-based configuration** for easy setup and maintenance
- Configurable monitoring intervals and restart behavior
- Detailed logging with timestamps and color coding
- Email notifications for server events
- Graceful startup waiting and intelligent restart logic
- Multiple configuration profiles support

## Files

- `PalKeeper.ps1` - Basic monitoring script (uses PowerShell config)
- `PalKeeperAdvanced.ps1` - **Enhanced monitoring script (uses JSON config)**
- `config.json` - **Main JSON configuration file**
- `production-config.json` - Sample production configuration
- `StartPalKeeper.bat` - Launcher for basic version
- `StartPalKeeperAdvanced.bat` - Launcher for advanced version
- `StartPalKeeperCustomConfig.bat` - Launcher with custom config file support
- `PalKeeper.log` - Log file (created automatically)

## Quick Start

1. **Run with default settings**:
   - Double-click `StartPalKeeperAdvanced.bat`
   - If `config.json` doesn't exist, a default one will be created

2. **Customize configuration**:
   - Edit `config.json` with your preferred settings
   - Restart the application

3. **Use custom configuration**:
   - Create your own config file (e.g., `my-config.json`)
   - Run: `StartPalKeeperCustomConfig.bat my-config.json`

## JSON Configuration Structure

```json
{
  "basicSettings": {
    "checkInterval": 30,
    "serverExecutable": "PalServer-Win64-Shipping-Cmd.exe",
    "startupScript": "G:\\steamcmd\\palworld.bat",
    "startupWaitTime": 60
  },
  "advancedSettings": {
    "maxRestartAttempts": 3,
    "restartCooldown": 300
  },
  "emailNotifications": {
    "enabled": false,
    "smtpServer": "smtp.gmail.com",
    "emailFrom": "your-email@gmail.com",
    "emailTo": "admin@yourcompany.com",
    "useSSL": true,
    "smtpPort": 587
  },
  "logging": {
    "logFile": "PalKeeper.log",
    "statusReportInterval": 10,
    "enableConsoleColors": true
  }
}
```

## Configuration Options

### Basic Settings
- `checkInterval` - How often to check if server is running (seconds)
- `serverExecutable` - Name of the server process to monitor
- `startupScript` - Path to your Palworld server startup script
- `startupWaitTime` - How long to wait for server to start (seconds)

### Advanced Settings
- `maxRestartAttempts` - Maximum consecutive restart attempts before cooldown
- `restartCooldown` - Cooldown period between restart attempts (seconds)

### Email Notifications
- `enabled` - Enable/disable email notifications
- `smtpServer` - SMTP server address (e.g., "smtp.gmail.com")
- `emailFrom` - Email address to send from
- `emailTo` - Email address to send notifications to
- `useSSL` - Use SSL/TLS encryption for email
- `smtpPort` - SMTP server port (usually 587 or 25)

### Logging
- `logFile` - Path to log file (relative or absolute)
- `statusReportInterval` - How often to show detailed status (check cycles)
- `enableConsoleColors` - Enable colored console output

## Usage Examples

### Run with default configuration:
```powershell
.\PalKeeperAdvanced.ps1
```

### Run with custom configuration file:
```powershell
.\PalKeeperAdvanced.ps1 -ConfigFile "production-config.json"
```

### Run with email password:
```powershell
$securePassword = ConvertTo-SecureString "your-email-password" -AsPlainText -Force
.\PalKeeperAdvanced.ps1 -EmailPassword $securePassword
```

### Using batch files:
```batch
# Default configuration
StartPalKeeperAdvanced.bat

# Custom configuration
StartPalKeeperCustomConfig.bat production-config.json
```

## How It Works

1. **Initial Check**: Checks if the server is already running
2. **Start Server**: If not running, executes the startup script
3. **Wait for Startup**: Waits for the server process to appear
4. **Monitor Loop**: Continuously monitors the server every X seconds
5. **Auto Restart**: If server stops, automatically restarts it

## Logging

The application creates a `PalKeeper.log` file in the same directory with timestamped entries for:
- Server status checks
- Startup attempts
- Errors and warnings
- Start/stop events

## Stopping the Monitor

- Press `Ctrl+C` in the PowerShell window
- Close the command window
- The monitor will log its shutdown gracefully

## Troubleshooting

### Server won't start
- Verify the path in `$StartupScript` is correct
- Make sure the startup batch file exists and is executable
- Check the log file for error details

### Process not detected
- Verify the exact name of your server executable
- The script looks for `PalServer-Win64-Shipping-Cmd.exe` by default
- You can customize this in `config.ps1`

### Permission issues
- Run PowerShell as Administrator if needed
- Make sure the startup script has proper permissions

## Requirements

- Windows PowerShell 5.1 or PowerShell Core 7.x
- Read/write access to the script directory (for logging)
- Execute permissions for the Palworld startup script
