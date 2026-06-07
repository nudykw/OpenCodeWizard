@echo off
:: ============================================================================
:: OpenCodeWizard.cmd
:: ----------------------------------------------------------------------------
:: Convenience wrapper for Windows users. Self-elevates to Administrator via
:: UAC (one prompt) and forwards every argument to OpenCodeWizard.ps1.
::
:: Placement: this file MUST live next to OpenCodeWizard.ps1 in the repo root.
:: Usage:     double-click in File Explorer, or run from any terminal:
::               OpenCodeWizard.cmd
::               OpenCodeWizard.cmd -Silent
::               OpenCodeWizard.cmd -DryRun -Lang uk
::               OpenCodeWizard.cmd -ListBackups
::
:: Behavior:
::   * If the current session is not elevated, relaunches itself with UAC.
::   * The elevated process sets its working directory to this file's folder
::     (UAC resets the working dir to C:\Windows\System32 by default).
::   * Then invokes powershell.exe with -NoProfile and -ExecutionPolicy Bypass,
::     so no manual `Set-ExecutionPolicy` is required.
:: ============================================================================

setlocal EnableExtensions EnableDelayedExpansion

:: --- 1. Self-elevation -----------------------------------------------------
:: `net session` succeeds only inside an elevated (admin) token.
net session >nul 2>&1
if "%errorlevel%"=="0" goto :elevated

:: Not elevated: ask UAC to relaunch this very script with full args.
:: The `""%~f0"` trick keeps `%~f0` quoted even when the path contains
:: spaces, and lets `%*` follow as separate arguments.
powershell -NoProfile -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/c \"\"%~f0\" %*\"' -Verb RunAs"
set RC=%errorlevel%
endlocal & exit /b %RC%

:elevated
:: --- 2. Restore the working directory --------------------------------------
:: UAC-launched processes start in System32; the wizard expects its own folder.
cd /d "%~dp0"

:: --- 3. Run the PowerShell wizard ------------------------------------------
echo.
echo [OpenCodeWizard] Launching PowerShell wizard (Administrator)...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0OpenCodeWizard.ps1" %*
set RC=%errorlevel%

:: --- 4. Pause only when launched from Explorer (no args = interactive) -----
:: When run from a terminal the user already sees the output; pause would be
:: noise. When double-clicked, closing immediately would hide errors.
if "%~1"=="" (
    echo.
    echo [OpenCodeWizard] Finished with exit code %RC%. Press any key to close.
    pause >nul
)

endlocal & exit /b %RC%
