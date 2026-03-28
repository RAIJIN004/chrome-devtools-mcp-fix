@echo off
REM ============================================================================
REM Chrome DevTools MCP - File Upload Fix for Facebook Marketplace
REM Windows Installation Script
REM ============================================================================
REM
REM This script patches the chrome-devtools-mcp package to fix file upload
REM issues on Facebook Marketplace and similar sites.
REM
REM Run this script as Administrator if you get permission errors.
REM ============================================================================

setlocal enabledelayedexpansion

echo.
echo ============================================================
echo  Chrome DevTools MCP - File Upload Fix
echo ============================================================
echo.

REM Get npm global path
for /f "tokens=*" %%i in ('npm root -g') do set NPM_GLOBAL=%%i
echo NPM global path: %NPM_GLOBAL%

set MCP_PATH=%NPM_GLOBAL%\chrome-devtools-mcp
set INPUT_JS=%MCP_PATH%\build\src\tools\input.js
set BACKUP_JS=%MCP_PATH%\build\src\tools\input.js.backup

echo.
echo Checking for chrome-devtools-mcp installation...

if not exist "%MCP_PATH%" (
    echo ERROR: chrome-devtools-mcp not found at %MCP_PATH%
    echo Please install it first: npm install -g chrome-devtools-mcp
    pause
    exit /b 1
)

if not exist "%INPUT_JS%" (
    echo ERROR: input.js not found at %INPUT_JS%
    pause
    exit /b 1
)

echo Found chrome-devtools-mcp at: %MCP_PATH%
echo.

REM Create backup
echo Creating backup of original file...
if exist "%BACKUP_JS%" (
    echo Backup already exists at %BACKUP_JS%
) else (
    copy "%INPUT_JS%" "%BACKUP_JS%"
    if errorlevel 1 (
        echo ERROR: Could not create backup. Try running as Administrator.
        pause
        exit /b 1
    )
    echo Backup created successfully.
)

echo.
echo ============================================================
echo  MANUAL INSTALLATION REQUIRED
echo ============================================================
echo.
echo Due to Windows file permissions, please manually replace the
echo uploadFile handler in input.js:
echo.
echo 1. Open: %INPUT_JS%
echo.
echo 2. Find lines 297-342 (the uploadFile handler)
echo.
echo 3. Replace with the patched version from:
echo    %~dp0..\fix\input-file-patched-handler.js
echo.
echo 4. Restart your MCP connection (restart opencode)
echo.
echo ============================================================
echo.
echo Original file backed up to: %BACKUP_JS%
echo.
pause
