# PalKeeper - Palworld Server Monitor
# Monitors PalServer-Win64-Shipping-Cmd.exe and restarts it if not running

param(
    [int]$CheckInterval,
    [string]$ServerExecutable,
    [string]$StartupScript,
    [int]$StartupWaitTime
)

# Load configuration file if it exists, otherwise use defaults
$configFile = Join-Path $PSScriptRoot "config.ps1"
if (Test-Path $configFile) {
    Write-Host "Loading configuration from: $configFile"
    . $configFile
}

# Set defaults if not provided via parameters or config file
if (-not $CheckInterval) { $CheckInterval = 30 }
if (-not $ServerExecutable) { $ServerExecutable = "PalServer-Win64-Shipping-Cmd.exe" }
if (-not $StartupScript) { $StartupScript = "G:\steamcmd\palworld.bat" }
if (-not $StartupWaitTime) { $StartupWaitTime = 60 }

# Function to write timestamped log messages
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    
    # Also write to log file
    try {
        $logFile = Join-Path $PSScriptRoot "PalKeeper.log"
        $logDir = Split-Path -Path $logFile -Parent
        if ($logDir -and -not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        $logMessage | Out-File -FilePath $logFile -Append -Encoding UTF8
    }
    catch {
        Write-Host "Warning: Failed to write to log file: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Function to check if the server process is running
function Test-ServerRunning {
    param([string]$ProcessName)
    
    try {
        $processes = Get-Process -Name $ProcessName.Replace(".exe", "") -ErrorAction SilentlyContinue
        return ($processes.Count -gt 0)
    }
    catch {
        return $false
    }
}

# Function to start the server
function Start-Server {
    param([string]$StartupScript)
    
    Write-Log "Starting Palworld server using: $StartupScript"
    
    try {
        if (-not (Test-Path $StartupScript)) {
            Write-Log "Startup script not found: $StartupScript" "ERROR"
            return $false
        }
        
        # Start the batch file and don't wait for it to complete
        Start-Process -FilePath $StartupScript -WindowStyle Normal
        Write-Log "Server startup command executed successfully"
        return $true
    }
    catch {
        Write-Log "Failed to start server: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to wait for server to start
function Wait-ForServerStart {
    param([string]$ProcessName, [int]$MaxWaitTime)
    
    Write-Log "Waiting for server to start (max $MaxWaitTime seconds)..."
    $elapsed = 0
    $checkInterval = 5  # Check every 5 seconds
    
    while ($elapsed -lt $MaxWaitTime) {
        if (Test-ServerRunning -ProcessName $ProcessName) {
            Write-Log "Server is now running!"
            return $true
        }
        
        Start-Sleep -Seconds $checkInterval
        $elapsed += $checkInterval
        Write-Log "Still waiting for server to start... ($elapsed/$MaxWaitTime seconds)"
    }
    
    Write-Log "Server did not start within $MaxWaitTime seconds" "WARNING"
    return $false
}

# Main monitoring loop
function Start-Monitoring {
    Write-Log "=== PalKeeper Started ==="
    Write-Log "Monitoring process: $ServerExecutable"
    Write-Log "Startup script: $StartupScript"
    Write-Log "Check interval: $CheckInterval seconds"
    Write-Log "Startup wait time: $StartupWaitTime seconds"
    Write-Log "=========================="
    
    # Initial check
    if (Test-ServerRunning -ProcessName $ServerExecutable) {
        Write-Log "Server is already running"
    } else {
        Write-Log "Server is not running, starting it now..."
        if (Start-Server -StartupScript $StartupScript) {
            Wait-ForServerStart -ProcessName $ServerExecutable -MaxWaitTime $StartupWaitTime
        }
    }
    
    # Main monitoring loop
    while ($true) {
        try {
            Start-Sleep -Seconds $CheckInterval
            
            if (-not (Test-ServerRunning -ProcessName $ServerExecutable)) {
                Write-Log "Server is not running! Attempting to restart..." "WARNING"
                
                if (Start-Server -StartupScript $StartupScript) {
                    Wait-ForServerStart -ProcessName $ServerExecutable -MaxWaitTime $StartupWaitTime
                } else {
                    Write-Log "Failed to start server, will try again in $CheckInterval seconds" "ERROR"
                }
            } else {
                Write-Log "Server is running normally"
            }
        }
        catch {
            Write-Log "Error in monitoring loop: $($_.Exception.Message)" "ERROR"
            Start-Sleep -Seconds $CheckInterval
        }
    }
}

# Handle Ctrl+C gracefully
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Write-Log "=== PalKeeper Stopped ==="
}

# Validate parameters
if (-not (Test-Path $StartupScript)) {
    Write-Log "Error: Startup script not found at: $StartupScript" "ERROR"
    Write-Log "Please verify the path and try again."
    exit 1
}

# Start monitoring
try {
    Start-Monitoring
}
catch {
    Write-Log "Fatal error: $($_.Exception.Message)" "ERROR"
    exit 1
}
