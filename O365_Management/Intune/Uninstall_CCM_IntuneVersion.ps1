# ============================
# Uninstall ConfigMgr Client - Intune Version
# ============================

# Log folder & file
$LogFolder = "C:\ProgramData\IntuneScripts"
$LogFile   = Join-Path $LogFolder "Uninstall_SCCM_Client.log"

# Ensure log folder exists
if (-not (Test-Path $LogFolder)) {
    New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
}

function Write-Log {
    param(
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp`t$Message"
    Add-Content -Path $LogFile -Value $entry
}

Write-Log "=== Script start ==="

try {
    # 1. Uninstall SCCM Client
    $UninstallPath = "C:\Windows\ccmsetup"
    $UninstallerName = "ccmsetup.exe"
    $UninstallerArguments = "/Uninstall"

    $ccmSetupFullPath = Join-Path $UninstallPath $UninstallerName

    if (Test-Path $ccmSetupFullPath) {
        Write-Log "Found ConfigMgr client at $ccmSetupFullPath. Starting uninstall..."
        $process = Start-Process -FilePath $ccmSetupFullPath -ArgumentList $UninstallerArguments -Wait -PassThru

        Write-Log "Uninstall process exited with code: $($process.ExitCode)"

        # Treat common success codes as OK (0, 3010 = success, reboot required)
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Log "ConfigMgr client uninstall completed successfully."
        }
        else {
            Write-Log "WARNING: Uninstall returned non-success exit code $($process.ExitCode)."
        }
    }
    else {
        Write-Log "ConfigMgr client not found at $ccmSetupFullPath. Nothing to do."
    }

    Write-Log "=== Script end (success path) ==="
    exit 0   # Explicit success for Intune
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    Write-Log "=== Script end (error) ==="

    # Depending on your strategy, you can either:
    exit 1   # Let Intune show as failed
}
