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

# Extract configuration values
$CheckInterval = $config.basicSettings.checkInterval
$ServerExecutable = $config.basicSettings.serverExecutable
$StartupScript = $config.basicSettings.startupScript
$StartupWaitTime = $config.basicSettings.startupWaitTime
$MaxRestartAttempts = $config.advancedSettings.maxRestartAttempts
$RestartCooldown = $config.advancedSettings.restartCooldown
$EnableEmailNotifications = $config.emailNotifications.enabled
$SmtpServer = $config.emailNotifications.smtpServer
$EmailFrom = $config.emailNotifications.emailFrom
$EmailTo = $config.emailNotifications.emailTo
$SmtpPort = $config.emailNotifications.smtpPort
$UseSSL = $config.emailNotifications.useSSL
$LogFile = $config.logging.logFile
$StatusReportInterval = $config.logging.statusReportInterval
$EnableConsoleColors = $config.logging.enableConsoleColors

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
    $logFilePath = if ([System.IO.Path]::IsPathRooted($LogFile)) {
        $LogFile
    } else {
        Join-Path $PSScriptRoot $LogFile
    }
    $logMessage | Out-File -FilePath $logFilePath -Append -Encoding UTF8
}

function Send-EmailNotification {
    param([string]$Subject, [string]$Body)
    
    if (-not $EnableEmailNotifications -or -not $SmtpServer -or -not $EmailFrom -or -not $EmailTo) {
        return
    }
    
    try {
        $credential = if ($EmailPassword) {
            New-Object System.Management.Automation.PSCredential($EmailFrom, $EmailPassword)
        } else {
            Get-Credential -Message "Enter email credentials for notifications" -UserName $EmailFrom
        }
        
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
    Write-Log "Log File: $LogFile"
    Write-Log "===================================="
    
    # Send startup notification
    Send-EmailNotification "PalKeeper: Monitoring Started" "PalKeeper has started monitoring the Palworld server at $(Get-Date).`n`nConfiguration:`n- Check Interval: $CheckInterval seconds`n- Server Executable: $ServerExecutable`n- Startup Script: $StartupScript"
    
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

# Graceful shutdown
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Write-Log "=== PalKeeper Advanced Stopped ===" "WARNING"
    Send-EmailNotification "PalKeeper: Monitoring Stopped" "PalKeeper monitoring has been stopped at $(Get-Date). Total server restarts during this session: $script:TotalRestarts"
}

# Validate startup script
if (-not (Test-Path $StartupScript)) {
    Write-Log "Error: Startup script not found at: $StartupScript" "ERROR"
    Write-Log "Please verify the path in config.ps1 and try again."
    exit 1
}

# Start monitoring
try {
    Start-Monitoring
}
catch {
    Write-Log "Fatal error: $($_.Exception.Message)" "ERROR"
    Send-EmailNotification "PalKeeper: Fatal Error" "PalKeeper encountered a fatal error: $($_.Exception.Message)"
    exit 1
}
