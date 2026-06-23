@echo off
REM ============================================================================
REM Revert @playwright/mcp - Restore original files.js and tool.js from backup
REM ============================================================================

setlocal enabledelayedexpansion

echo.
echo ============================================================
echo  Reverting @playwright/mcp File Upload Fix
echo ============================================================
echo.

for /f "tokens=*" %%i in ('npm root -g') do set NPM_GLOBAL=%%i

set TOOLS_DIR=%NPM_GLOBAL%\@playwright\mcp\node_modules\playwright\lib\mcp\browser\tools
set FILES_JS=%TOOLS_DIR%\files.js
set TOOL_JS=%TOOLS_DIR%\tool.js
set BACKUP_FILES_JS=%TOOLS_DIR%\files.js.backup
set BACKUP_TOOL_JS=%TOOLS_DIR%\tool.js.backup

echo [1/2] Restoring tool.js...
if not exist "%BACKUP_TOOL_JS%" (
    echo   No backup found for tool.js. Skipping.
) else (
    copy /Y "%BACKUP_TOOL_JS%" "%TOOL_JS%"
    echo   Done.
)

echo [2/2] Restoring files.js...
if not exist "%BACKUP_FILES_JS%" (
    echo   No backup found for files.js. Skipping.
) else (
    copy /Y "%BACKUP_FILES_JS%" "%FILES_JS%"
    echo   Done.
)

echo.
echo Revert completed!
echo Backups preserved at:
echo   %BACKUP_TOOL_JS%
echo   %BACKUP_FILES_JS%
echo.
pause
