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
REM Patches applied:
REM   1. tool.js - Allows tools with clearsModalState to run even when
REM      the expected modal state is not present.
REM   2. files.js - Falls back to setInputFiles when no fileChooser
REM      modal is available.
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
set TOOLS_DIR=%MCP_PATH%\node_modules\playwright\lib\mcp\browser\tools
set FILES_JS=%TOOLS_DIR%\files.js
set TOOL_JS=%TOOLS_DIR%\tool.js
set BACKUP_FILES_JS=%TOOLS_DIR%\files.js.backup
set BACKUP_TOOL_JS=%TOOLS_DIR%\tool.js.backup

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

if not exist "%TOOL_JS%" (
    echo ERROR: tool.js not found at %TOOL_JS%
    pause
    exit /b 1
)

echo Found @playwright/mcp at: %MCP_PATH%
echo.

REM ============================================================================
REM Patch 1: tool.js
REM ============================================================================
echo [1/2] Patching tool.js...
if exist "%BACKUP_TOOL_JS%" (
    echo   Backup already exists at %BACKUP_TOOL_JS%
) else (
    copy "%TOOL_JS%" "%BACKUP_TOOL_JS%"
    if errorlevel 1 (
        echo   ERROR: Could not create backup. Try running as Administrator.
        pause
        exit /b 1
    )
    echo   Backup created.
)

set PATCHED_TOOL_JS=%~dp0..\fix\tool-patched.js
if not exist "%PATCHED_TOOL_JS%" (
    echo   ERROR: Patched tool.js not found at %PATCHED_TOOL_JS%
    pause
    exit /b 1
)

copy /Y "%PATCHED_TOOL_JS%" "%TOOL_JS%"
if errorlevel 1 (
    echo   ERROR: Could not copy patched tool.js. Try running as Administrator.
    pause
    exit /b 1
)
echo   Done.

REM ============================================================================
REM Patch 2: files.js
REM ============================================================================
echo [2/2] Patching files.js...
if exist "%BACKUP_FILES_JS%" (
    echo   Backup already exists at %BACKUP_FILES_JS%
) else (
    copy "%FILES_JS%" "%BACKUP_FILES_JS%"
    if errorlevel 1 (
        echo   ERROR: Could not create backup. Try running as Administrator.
        pause
        exit /b 1
    )
    echo   Backup created.
)

set PATCHED_FILES_JS=%~dp0..\fix\files-patched.js
if not exist "%PATCHED_FILES_JS%" (
    echo   ERROR: Patched files.js not found at %PATCHED_FILES_JS%
    pause
    exit /b 1
)

copy /Y "%PATCHED_FILES_JS%" "%FILES_JS%"
if errorlevel 1 (
    echo   ERROR: Could not copy patched files.js. Try running as Administrator.
    pause
    exit /b 1
)
echo   Done.

echo.
echo ============================================================
echo  PATCH APPLIED SUCCESSFULLY!
echo ============================================================
echo.
echo Changes made:
echo   %TOOL_JS%
echo   %FILES_JS%
echo.
echo Backups:
echo   %BACKUP_TOOL_JS%
echo   %BACKUP_FILES_JS%
echo.
echo Next steps:
echo 1. Restart opencode (or your MCP client)
echo 2. Navigate to Facebook Marketplace
echo 3. Use browser_file_upload tool to upload images
echo.
echo To revert: run revert-fix.bat or restore backups manually
echo.
pause
