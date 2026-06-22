@echo off
REM ============================================================================
REM Revert @playwright/mcp - Restore original files.js from backup
REM ============================================================================

setlocal enabledelayedexpansion

echo.
echo ============================================================
echo  Reverting @playwright/mcp File Upload Fix
echo ============================================================
echo.

for /f "tokens=*" %%i in ('npm root -g') do set NPM_GLOBAL=%%i

set FILES_JS=%NPM_GLOBAL%\@playwright\mcp\node_modules\playwright\lib\mcp\browser\tools\files.js
set BACKUP_JS=%NPM_GLOBAL%\@playwright\mcp\node_modules\playwright\lib\mcp\browser\tools\files.js.backup

if not exist "%BACKUP_JS%" (
    echo No backup found at %BACKUP_JS%
    echo Nothing to revert.
    pause
    exit /b 1
)

echo Restoring original files.js from backup...
copy /Y "%BACKUP_JS%" "%FILES_JS%"
if errorlevel 1 (
    echo ERROR: Could not restore backup. Try running as Administrator.
    pause
    exit /b 1
)

echo.
echo Original files.js restored successfully!
echo Backup kept at: %BACKUP_JS%
echo.
pause
