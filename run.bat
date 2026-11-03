@echo off
setlocal
cd /d "%~dp0"
echo ============================================================
echo   Desktop Beautify - one-click installer
echo ============================================================
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
set "rc=%ERRORLEVEL%"
if not "%rc%"=="0" (
    echo.
    echo [ERROR] install.ps1 exited with code %rc%
    pause
)
endlocal & exit /b %rc%
