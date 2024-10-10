Add-Type -AssemblyName System.Windows.Forms

# Function to log errors
function Log-Error {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - ERROR: $Message"
    Add-Content -Path ".\error.log" -Value $logMessage
}

# Read commands from the text file
try {
    $commands = Get-Content -Path ".\commands.txt"
} catch {
    Log-Error "Failed to read commands from file: $_"
    throw "Cannot proceed without command file."
}

# Track recent errors to suppress repeats
$recentErrors = @{}

foreach ($command in $commands) {
    # Ignore empty lines and lines that start with REM
    if (-not $command.Trim() -or $command.Trim().StartsWith("REM")) {
        continue
    }

    try {
        # Normalize the command for easier processing
        $normalizedCommand = $command.Trim()

        # Handle specific key combinations
        if ($normalizedCommand -eq "WINDOWS R" -or $normalizedCommand -eq "GUI R") {
            [System.Windows.Forms.SendKeys]::SendWait("^{ESC}r")  # Send WIN + R directly
            Start-Sleep -Milliseconds 100  # Short delay to ensure the dialog is open
            [System.Windows.Forms.SendKeys]::SendWait("{BACKSPACE}")  # Press Backspace

        } elseif ($normalizedCommand -eq "ALT ENTER") {
            [System.Windows.Forms.SendKeys]::SendWait("%{ENTER}")

        } elseif ($normalizedCommand -eq "CTRL HOME") {
            [System.Windows.Forms.SendKeys]::SendWait("^{HOME}")

        } elseif ($normalizedCommand -eq "ALT F4") {
            [System.Windows.Forms.SendKeys]::SendWait("%{F4}")  # Send ALT + F4

        # Handle STRING commands
        } elseif ($normalizedCommand -match "^STRING (.+)$") {
            $text = $matches[1] -replace "SPACE", " "  # Replace "SPACE" with actual space
            [System.Windows.Forms.SendKeys]::SendWait($text)

        # Handle STRINGLN commands (string followed by ENTER)
        } elseif ($normalizedCommand -match "^STRINGLN (.+)$") {
            $text = $matches[1] -replace "SPACE", " "
            [System.Windows.Forms.SendKeys]::SendWait($text + "{ENTER}")

        # Handle SPACE as a standalone command
        } elseif ($normalizedCommand -eq "SPACE") {
            [System.Windows.Forms.SendKeys]::SendWait(" ")  # Send literal space

        # Handle DELAY commands
        } elseif ($normalizedCommand -match "^DELAY (\d+)$") {
            $delayTime = [int]$matches[1]
            Start-Sleep -Milliseconds $delayTime

        # Handle INJECT_MOD commands
        } elseif ($normalizedCommand -match "^INJECT_MOD (.+)$") {
            $key = $matches[1]
            if ($key -eq "WINDOWS") {
                $key = "LWIN"
            }
            [System.Windows.Forms.SendKeys]::SendWait("{" + $key + "}")

        # Handle navigation keys and common keys
        } elseif ($normalizedCommand -match "^(UP|DOWN|LEFT|RIGHT|PAGEUP|PAGEDOWN|HOME|END|INSERT|DELETE|DEL|BACKSPACE|TAB|ESC|SPACE)$") {
            [System.Windows.Forms.SendKeys]::SendWait("{" + $normalizedCommand + "}")

        # Handle function and modifier keys
        } elseif ($normalizedCommand -match "^(ENTER|PAUSE|BREAK|PRINTSCREEN|MENU|APP|F1|F2|F3|F4|F5|F6|F7|F8|F9|F10|F11|F12|SHIFT|ALT|CONTROL|CTRL|WINDOWS|GUI|COMMAND)$") {
            [System.Windows.Forms.SendKeys]::SendWait("{" + $normalizedCommand + "}")

        # Handle combinations like SHIFT + TAB or CTRL + f
        } elseif ($normalizedCommand -match "^(SHIFT|CTRL|ALT) (.+)$") {
            $modKey = $matches[1]
            $key = $matches[2]
            # Send the modifier key down, the key press, then the modifier key up
            [System.Windows.Forms.SendKeys]::SendWait("{" + $modKey + " down}{" + $key + "}{"+ $modKey + " up}")

        # Handle lock keys
        } elseif ($normalizedCommand -match "^(CAPSLOCK|NUMLOCK|SCROLLOCK)$") {
            [System.Windows.Forms.SendKeys]::SendWait("{" + $normalizedCommand + "}")

        } else {
            # Handle unknown commands
            if (-not $recentErrors.ContainsKey($normalizedCommand) -or ((Get-Date) - $recentErrors[$normalizedCommand]).TotalSeconds -gt 10) {
                Log-Error "Unknown command: $normalizedCommand"
                $recentErrors[$normalizedCommand] = Get-Date
            }
        }
    } catch {
        Log-Error "Failed to process command '$command': $_"
    }
}
