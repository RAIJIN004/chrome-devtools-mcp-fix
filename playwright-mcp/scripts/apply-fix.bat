@echo off
REM ============================================================================
REM @playwright/mcp - File Upload Fix for Facebook Marketplace
REM Windows Installation Script
REM ============================================================================
REM
REM This script patches the @playwright/mcp package to fix file upload
REM issues on Facebook Marketplace and similar sites where the page
REM blocks the native file chooser from opening.
REM
REM It replaces the browser_file_upload handler with a patched version
REM that falls back to setInputFiles when no file chooser is available.
REM ============================================================================

setlocal enabledelayedexpansion

echo.
echo ============================================================
echo  @playwright/mcp - File Upload Fix
echo ============================================================
echo.

REM Get npm global path
for /f "tokens=*" %%i in ('npm root -g') do set NPM_GLOBAL=%%i
echo NPM global path: %NPM_GLOBAL%

set MCP_PATH=%NPM_GLOBAL%\@playwright\mcp
set FILES_JS=%MCP_PATH%\node_modules\playwright\lib\mcp\browser\tools\files.js
set BACKUP_JS=%MCP_PATH%\node_modules\playwright\lib\mcp\browser\tools\files.js.backup

echo.
echo Checking for @playwright/mcp installation...

if not exist "%MCP_PATH%" (
    echo ERROR: @playwright/mcp not found at %MCP_PATH%
    echo Please install it first: npm install -g @playwright/mcp
    pause
    exit /b 1
)

if not exist "%FILES_JS%" (
    echo ERROR: files.js not found at %FILES_JS%
    pause
    exit /b 1
)

echo Found @playwright/mcp at: %MCP_PATH%
echo Found files.js at: %FILES_JS%
echo.

REM Create backup
echo Creating backup of original file...
if exist "%BACKUP_JS%" (
    echo Backup already exists at %BACKUP_JS%
) else (
    copy "%FILES_JS%" "%BACKUP_JS%"
    if errorlevel 1 (
        echo ERROR: Could not create backup. Try running as Administrator.
        pause
        exit /b 1
    )
    echo Backup created successfully.
)

REM Locate the patched file
set PATCHED_JS=%~dp0..\fix\files-patched.js
if not exist "%PATCHED_JS%" (
    echo ERROR: Patched file not found at %PATCHED_JS%
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  APPLYING PATCH
echo ============================================================
echo.

echo Copying patched files.js to MCP installation...
copy /Y "%PATCHED_JS%" "%FILES_JS%"
if errorlevel 1 (
    echo ERROR: Could not copy patched file. Try running as Administrator.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  PATCH APPLIED SUCCESSFULLY!
echo ============================================================
echo.
echo Changes made to: %FILES_JS%
echo Backup at:       %BACKUP_JS%
echo.
echo Next steps:
echo 1. Restart opencode (or your MCP client)
echo 2. Navigate to Facebook Marketplace
echo 3. Try browser_file_upload - it should now work with setInputFiles fallback
echo.
echo To revert: copy "%BACKUP_JS%" "%FILES_JS%"
echo.
pause
