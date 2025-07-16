# PalKeeper Configuration
# Edit these values to customize the monitoring behavior

# Basic Settings
# How often to check if the server is running (in seconds)
$CheckInterval = 30

# Name of the server executable to monitor
$ServerExecutable = "PalServer-Win64-Shipping-Cmd.exe"

# Path to the batch file that starts the server
$StartupScript = "G:\steamcmd\palworld.bat"

# How long to wait for the server to start after executing the startup script (in seconds)
$StartupWaitTime = 60

# Advanced Settings (for PalKeeperAdvanced.ps1)
# Maximum number of consecutive restart attempts before entering cooldown
$MaxRestartAttempts = 3

# Cooldown period between restart attempts (in seconds) - 5 minutes default
$RestartCooldown = 300

# Email Notification Settings (optional)
# Set to $true to enable email notifications
$EnableEmailNotifications = $false

# SMTP server for sending emails (e.g., "smtp.gmail.com" for Gmail)
$SmtpServer = ""

# Email address to send notifications from
$EmailFrom = ""

# Email address to send notifications to
$EmailTo = ""

# Note: For security, email password should be provided as a parameter when running the script
# Example: .\PalKeeperAdvanced.ps1 -EmailPassword (ConvertTo-SecureString "yourpassword" -AsPlainText -Force)
