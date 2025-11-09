# PalKeeper Advanced - Enhanced Palworld Server Monitor
# Advanced version with additional features

param(
    [string]$ConfigFile = "config.json",
    [SecureString]$EmailPassword,
    [switch]$OverrideConfig  # Allow command line parameters to override config file
)

# Function to load JSON configuration
function Get-Configuration {
    param([string]$ConfigPath)
    
    $configFile = if (Test-Path $ConfigPath) {
        $ConfigPath
    } else {
        Join-Path $PSScriptRoot $ConfigPath
    }
    
    if (-not (Test-Path $configFile)) {
        Write-Host "Configuration file not found: $configFile" -ForegroundColor Red
        Write-Host "Creating default configuration file..."
        
        # Create default configuration
        $defaultConfig = @{
            basicSettings = @{
                checkInterval = 30
                serverExecutable = "PalServer-Win64-Shipping-Cmd.exe"
                startupScript = "G:\steamcmd\palworld.bat"
                startupWaitTime = 60
            }
            advancedSettings = @{
                maxRestartAttempts = 3
                restartCooldown = 300
            }
            updateSettings = @{
                runUpdatesOnStart = $true
                updateScript = "G:\steamcmd\Palworld.bat"
                updateTimeout = 300
            }
            backupSettings = @{
                enableBackup = $true
                backupOnStart = $true
                saveFilePath = "G:\steamcmd\steamapps\common\PalServer\Pal\Saved"
                backupDestination = "G:\Backups\Palworld"
                maxBackups = 10
                backupBeforeUpdate = $true
            }
            emailNotifications = @{
                enabled = $false
                smtpServer = ""
                emailFrom = ""
                emailTo = ""
                useSSL = $true
                smtpPort = 587
            }
            logging = @{
                logFile = "PalKeeper.log"
                statusReportInterval = 10
                enableConsoleColors = $true
            }
        }
        
        $defaultConfig | ConvertTo-Json -Depth 3 | Out-File -FilePath $configFile -Encoding UTF8
        Write-Host "Default configuration created at: $configFile" -ForegroundColor Green
        Write-Host "Please edit the configuration file and restart the application." -ForegroundColor Yellow
        exit 1
    }
    
    try {
        $config = Get-Content -Path $configFile -Raw | ConvertFrom-Json
        Write-Host "Configuration loaded from: $configFile" -ForegroundColor Green
        return $config
    }
    catch {
        Write-Host "Error reading configuration file: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Load configuration from JSON
$config = Get-Configuration -ConfigPath $ConfigFile

# Extract configuration values with validation
try {
    # Basic Settings (required)
    $CheckInterval = $config.basicSettings.checkInterval
    $ServerExecutable = $config.basicSettings.serverExecutable
    $StartupScript = $config.basicSettings.startupScript
    $StartupWaitTime = $config.basicSettings.startupWaitTime
    
    # Advanced Settings (required)
    $MaxRestartAttempts = $config.advancedSettings.maxRestartAttempts
    $RestartCooldown = $config.advancedSettings.restartCooldown
    
    # Email Notifications (optional, defaults applied)
    $EnableEmailNotifications = if ($null -ne $config.emailNotifications.enabled) { $config.emailNotifications.enabled } else { $false }
    $SmtpServer = if ($config.emailNotifications.smtpServer) { $config.emailNotifications.smtpServer } else { "" }
    $EmailFrom = if ($config.emailNotifications.emailFrom) { $config.emailNotifications.emailFrom } else { "" }
    $EmailTo = if ($config.emailNotifications.emailTo) { $config.emailNotifications.emailTo } else { "" }
    $SmtpPort = if ($config.emailNotifications.smtpPort) { $config.emailNotifications.smtpPort } else { 587 }
    $UseSSL = if ($null -ne $config.emailNotifications.useSSL) { $config.emailNotifications.useSSL } else { $true }
    
    # Logging (optional, defaults applied)
    $LogFile = if ($config.logging.logFile) { $config.logging.logFile } else { "PalKeeper.log" }
    $StatusReportInterval = if ($config.logging.statusReportInterval) { $config.logging.statusReportInterval } else { 10 }
    $EnableConsoleColors = if ($null -ne $config.logging.enableConsoleColors) { $config.logging.enableConsoleColors } else { $true }
    
    # Update Settings (optional, defaults applied)
    $RunUpdatesOnStart = if ($null -ne $config.updateSettings.runUpdatesOnStart) { $config.updateSettings.runUpdatesOnStart } else { $true }
    $UpdateScript = if ($config.updateSettings.updateScript) { $config.updateSettings.updateScript } else { "G:\steamcmd\Palworld.bat" }
    $UpdateTimeout = if ($config.updateSettings.updateTimeout) { $config.updateSettings.updateTimeout } else { 300 }
    
    # Backup Settings (optional, defaults applied)
    $EnableBackup = if ($null -ne $config.backupSettings.enableBackup) { $config.backupSettings.enableBackup } else { $true }
    $BackupOnStart = if ($null -ne $config.backupSettings.backupOnStart) { $config.backupSettings.backupOnStart } else { $true }
    $SaveFilePath = if ($config.backupSettings.saveFilePath) { $config.backupSettings.saveFilePath } else { "" }
    $BackupDestination = if ($config.backupSettings.backupDestination) { $config.backupSettings.backupDestination } else { "" }
    $MaxBackups = if ($config.backupSettings.maxBackups) { $config.backupSettings.maxBackups } else { 10 }
    $BackupBeforeUpdate = if ($null -ne $config.backupSettings.backupBeforeUpdate) { $config.backupSettings.backupBeforeUpdate } else { $true }
    
    # Validate required settings
    if (-not $CheckInterval -or $CheckInterval -le 0) {
        throw "Invalid checkInterval: must be a positive number"
    }
    if (-not $ServerExecutable) {
        throw "serverExecutable is required"
    }
    if (-not $StartupScript) {
        throw "startupScript is required"
    }
    if (-not $StartupWaitTime -or $StartupWaitTime -le 0) {
        throw "Invalid startupWaitTime: must be a positive number"
    }
    if (-not $MaxRestartAttempts -or $MaxRestartAttempts -le 0) {
        throw "Invalid maxRestartAttempts: must be a positive number"
    }
    if (-not $RestartCooldown -or $RestartCooldown -lt 0) {
        throw "Invalid restartCooldown: must be a non-negative number"
    }
}
catch {
    Write-Host "Configuration validation error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check your config.json file for missing or invalid values." -ForegroundColor Yellow
    exit 1
}

# Global variables for restart tracking
$script:ConsecutiveFailures = 0
$script:LastRestartTime = [DateTime]::MinValue
$script:TotalRestarts = 0

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Color coding for console output (if enabled)
    if ($EnableConsoleColors) {
        switch ($Level) {
            "ERROR" { Write-Host $logMessage -ForegroundColor Red }
            "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
            "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
            default { Write-Host $logMessage }
        }
    } else {
        Write-Host $logMessage
    }
    
    # Write to log file
    try {
        $logFilePath = if ([System.IO.Path]::IsPathRooted($LogFile)) {
            $LogFile
        } else {
            Join-Path $PSScriptRoot $LogFile
        }
        
        # Ensure directory exists
        $logDir = Split-Path -Path $logFilePath -Parent
        if ($logDir -and -not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        
        $logMessage | Out-File -FilePath $logFilePath -Append -Encoding UTF8
    }
    catch {
        Write-Host "Warning: Failed to write to log file: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Invoke-SaveBackup {
    param([string]$Reason = "Scheduled")
    
    if (-not $EnableBackup -or -not $SaveFilePath -or -not $BackupDestination) {
        Write-Log "Backup skipped: not configured or disabled"
        return $false
    }
    
    if (-not (Test-Path $SaveFilePath)) {
        Write-Log "Save file path not found: $SaveFilePath" "WARNING"
        return $false
    }
    
    try {
        Write-Log "Starting backup of save files... (Reason: $Reason)" "SUCCESS"
        
        # Create backup destination if it doesn't exist
        if (-not (Test-Path $BackupDestination)) {
            New-Item -Path $BackupDestination -ItemType Directory -Force | Out-Null
            Write-Log "Created backup destination: $BackupDestination"
        }
        
        # Create timestamped backup folder
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $backupFolder = Join-Path $BackupDestination "Backup_$timestamp"
        
        Write-Log "Copying save files to: $backupFolder"
        Copy-Item -Path $SaveFilePath -Destination $backupFolder -Recurse -Force
        
        Write-Log "Backup completed successfully!" "SUCCESS"
        
        # Clean up old backups
        Invoke-BackupCleanup
        
        Send-EmailNotification "PalKeeper: Backup Completed" "Save files have been backed up successfully to $backupFolder`n`nReason: $Reason"
        return $true
    }
    catch {
        Write-Log "Backup failed: $($_.Exception.Message)" "ERROR"
        Send-EmailNotification "PalKeeper: Backup Failed" "Failed to backup save files: $($_.Exception.Message)"
        return $false
    }
}

function Invoke-BackupCleanup {
    if ($MaxBackups -le 0) {
        return
    }
    
    try {
        $backups = Get-ChildItem -Path $BackupDestination -Directory | 
                   Where-Object { $_.Name -like "Backup_*" } | 
                   Sort-Object CreationTime -Descending
        
        if ($backups.Count -gt $MaxBackups) {
            $toDelete = $backups | Select-Object -Skip $MaxBackups
            foreach ($backup in $toDelete) {
                Write-Log "Removing old backup: $($backup.Name)"
                Remove-Item -Path $backup.FullName -Recurse -Force
            }
            Write-Log "Cleaned up $($toDelete.Count) old backup(s)"
        }
    }
    catch {
        Write-Log "Backup cleanup failed: $($_.Exception.Message)" "WARNING"
    }
}

function Invoke-ServerUpdate {
    if (-not $RunUpdatesOnStart -or -not $UpdateScript) {
        Write-Log "Updates skipped: not configured or disabled"
        return $true
    }
    
    if (-not (Test-Path $UpdateScript)) {
        Write-Log "Update script not found: $UpdateScript" "WARNING"
        return $false
    }
    
    try {
        Write-Log "Running server updates..." "SUCCESS"
        Write-Log "Update script: $UpdateScript"
        
        # Backup before update if configured
        if ($BackupBeforeUpdate -and $EnableBackup) {
            Write-Log "Creating pre-update backup..."
            Invoke-SaveBackup -Reason "Pre-Update"
        }
        
        # Run the update script and wait for completion
        Write-Log "Executing update script (timeout: $UpdateTimeout seconds)..."
        $process = Start-Process -FilePath $UpdateScript -WindowStyle Normal -PassThru
        
        $completed = $process.WaitForExit($UpdateTimeout * 1000)
        
        if ($completed) {
            if ($process.ExitCode -eq 0) {
                Write-Log "Server updates completed successfully!" "SUCCESS"
                Send-EmailNotification "PalKeeper: Updates Completed" "Server updates have been applied successfully."
                return $true
            } else {
                Write-Log "Update script exited with code: $($process.ExitCode)" "WARNING"
                return $true  # Continue anyway
            }
        } else {
            Write-Log "Update script timeout after $UpdateTimeout seconds" "WARNING"
            $process.Kill()
            return $true  # Continue anyway
        }
    }
    catch {
        Write-Log "Update failed: $($_.Exception.Message)" "ERROR"
        Send-EmailNotification "PalKeeper: Update Failed" "Server update failed: $($_.Exception.Message)"
        return $false
    }
}

function Send-EmailNotification {
    param([string]$Subject, [string]$Body)
    
    if (-not $EnableEmailNotifications -or -not $SmtpServer -or -not $EmailFrom -or -not $EmailTo) {
        return
    }
    
    # If email notifications are enabled but no password is provided, skip silently
    if (-not $EmailPassword) {
        Write-Log "Email notifications enabled but no password provided. Skipping email." "WARNING"
        return
    }
    
    try {
        $credential = New-Object System.Management.Automation.PSCredential($EmailFrom, $EmailPassword)
        
        $mailParams = @{
            SmtpServer = $SmtpServer
            Port = $SmtpPort
            From = $EmailFrom
            To = $EmailTo
            Subject = $Subject
            Body = $Body
            Credential = $credential
        }
        
        if ($UseSSL) {
            $mailParams.UseSsl = $true
        }
        
        Send-MailMessage @mailParams
        Write-Log "Email notification sent: $Subject"
    }
    catch {
        Write-Log "Failed to send email notification: $($_.Exception.Message)" "ERROR"
    }
}

function Test-ServerRunning {
    param([string]$ProcessName)
    
    try {
        $processes = Get-Process -Name $ProcessName.Replace(".exe", "") -ErrorAction SilentlyContinue
        if ($processes.Count -gt 0) {
            # Reset failure counter on successful detection
            $script:ConsecutiveFailures = 0
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

function Test-RestartCooldown {
    # If this is the first restart attempt, always allow it
    if ($script:LastRestartTime -eq [DateTime]::MinValue) {
        return $true
    }
    
    $timeSinceLastRestart = (Get-Date) - $script:LastRestartTime
    return $timeSinceLastRestart.TotalSeconds -ge $RestartCooldown
}

function Start-Server {
    param([string]$StartupScript)
    
    # Check if we're in cooldown period
    if (-not (Test-RestartCooldown)) {
        $remainingCooldown = $RestartCooldown - ((Get-Date) - $script:LastRestartTime).TotalSeconds
        Write-Log "Restart cooldown active. $([math]::Round($remainingCooldown)) seconds remaining." "WARNING"
        return $false
    }
    
    # Check consecutive failure limit
    if ($script:ConsecutiveFailures -ge $MaxRestartAttempts) {
        Write-Log "Maximum restart attempts ($MaxRestartAttempts) reached. Waiting for cooldown period." "ERROR"
        Send-EmailNotification "PalKeeper: Max Restart Attempts Reached" "The Palworld server has failed to start $MaxRestartAttempts consecutive times. Manual intervention may be required."
        
        # Reset after cooldown
        $script:ConsecutiveFailures = 0
        $script:LastRestartTime = Get-Date
        return $false
    }
    
    Write-Log "Attempting to start server (Attempt $($script:ConsecutiveFailures + 1)/$MaxRestartAttempts)"
    
    try {
        if (-not (Test-Path $StartupScript)) {
            Write-Log "Startup script not found: $StartupScript" "ERROR"
            $script:ConsecutiveFailures++
            return $false
        }
        
        Start-Process -FilePath $StartupScript -WindowStyle Normal
        $script:LastRestartTime = Get-Date
        $script:TotalRestarts++
        
        Write-Log "Server startup command executed (Total restarts: $($script:TotalRestarts))" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Failed to start server: $($_.Exception.Message)" "ERROR"
        $script:ConsecutiveFailures++
        return $false
    }
}

function Wait-ForServerStart {
    param([string]$ProcessName, [int]$MaxWaitTime)
    
    Write-Log "Waiting for server to start (max $MaxWaitTime seconds)..."
    $elapsed = 0
    $checkInterval = 5
    
    while ($elapsed -lt $MaxWaitTime) {
        if (Test-ServerRunning -ProcessName $ProcessName) {
            Write-Log "Server started successfully!" "SUCCESS"
            Send-EmailNotification "PalKeeper: Server Restarted" "The Palworld server has been successfully restarted at $(Get-Date)."
            return $true
        }
        
        Start-Sleep -Seconds $checkInterval
        $elapsed += $checkInterval
        Write-Log "Waiting... ($elapsed/$MaxWaitTime seconds)"
    }
    
    Write-Log "Server failed to start within $MaxWaitTime seconds" "ERROR"
    $script:ConsecutiveFailures++
    return $false
}

function Get-ServerUptime {
    try {
        $process = Get-Process -Name $ServerExecutable.Replace(".exe", "") -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($process) {
            $uptime = (Get-Date) - $process.StartTime
            return $uptime
        }
    }
    catch {
        return $null
    }
    return $null
}

function Show-Status {
    $uptime = Get-ServerUptime
    if ($uptime) {
        $uptimeStr = "{0:dd}d {0:hh}h {0:mm}m {0:ss}s" -f $uptime
        Write-Log "Server Status: RUNNING (Uptime: $uptimeStr, Total Restarts: $script:TotalRestarts)"
    } else {
        Write-Log "Server Status: NOT RUNNING (Total Restarts: $script:TotalRestarts)"
    }
}

function Start-Monitoring {
    Write-Log "=== PalKeeper Advanced Started ===" "SUCCESS"
    Write-Log "Configuration File: $ConfigFile"
    Write-Log "Process: $ServerExecutable"
    Write-Log "Startup Script: $StartupScript"
    Write-Log "Check Interval: $CheckInterval seconds"
    Write-Log "Max Restart Attempts: $MaxRestartAttempts"
    Write-Log "Restart Cooldown: $RestartCooldown seconds"
    Write-Log "Email Notifications: $EnableEmailNotifications"
    Write-Log "Backup Enabled: $EnableBackup"
    Write-Log "Updates on Start: $RunUpdatesOnStart"
    Write-Log "Log File: $LogFile"
    Write-Log "===================================="
    
    # Send startup notification
    Send-EmailNotification "PalKeeper: Monitoring Started" "PalKeeper has started monitoring the Palworld server at $(Get-Date).`n`nConfiguration:`n- Check Interval: $CheckInterval seconds`n- Server Executable: $ServerExecutable`n- Startup Script: $StartupScript`n- Backup Enabled: $EnableBackup`n- Updates on Start: $RunUpdatesOnStart"
    
    # Run initial backup if configured
    if ($BackupOnStart) {
        Write-Log "Performing initial backup..."
        Invoke-SaveBackup -Reason "Initial Startup"
    }
    
    # Run updates if configured
    if ($RunUpdatesOnStart) {
        Write-Log "Running server updates..."
        Invoke-ServerUpdate
    }
    
    # Initial check and status
    if (Test-ServerRunning -ProcessName $ServerExecutable) {
        Show-Status
    } else {
        Write-Log "Server is not running, starting it now..."
        if (Start-Server -StartupScript $StartupScript) {
            Wait-ForServerStart -ProcessName $ServerExecutable -MaxWaitTime $StartupWaitTime
        }
    }
    
    # Main monitoring loop
    $checkCount = 0
    
    while ($true) {
        try {
            Start-Sleep -Seconds $CheckInterval
            $checkCount++
            
            if (-not (Test-ServerRunning -ProcessName $ServerExecutable)) {
                Write-Log "Server is DOWN! Initiating restart sequence..." "ERROR"
                
                if (Start-Server -StartupScript $StartupScript) {
                    Wait-ForServerStart -ProcessName $ServerExecutable -MaxWaitTime $StartupWaitTime
                }
            } else {
                # Show detailed status periodically
                if ($checkCount -ge $StatusReportInterval) {
                    Show-Status
                    $checkCount = 0
                } else {
                    Write-Log "Server is running normally"
                }
            }
        }
        catch {
            Write-Log "Error in monitoring loop: $($_.Exception.Message)" "ERROR"
            Start-Sleep -Seconds $CheckInterval
        }
    }
}

# Validate startup script
if (-not (Test-Path $StartupScript)) {
    Write-Log "Error: Startup script not found at: $StartupScript" "ERROR"
    Write-Log "Please verify the path in config.json and try again."
    exit 1
}

# Graceful shutdown - Note: Use try/finally instead of Register-EngineEvent for proper cleanup
try {
    # Start monitoring
    Start-Monitoring
}
catch {
    Write-Log "Fatal error: $($_.Exception.Message)" "ERROR"
    Send-EmailNotification "PalKeeper: Fatal Error" "PalKeeper encountered a fatal error: $($_.Exception.Message)"
    exit 1
}
finally {
    Write-Log "=== PalKeeper Advanced Stopped ===" "WARNING"
    Send-EmailNotification "PalKeeper: Monitoring Stopped" "PalKeeper monitoring has been stopped at $(Get-Date). Total server restarts during this session: $script:TotalRestarts"
}
