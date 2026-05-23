@echo off
setlocal enabledelayedexpansion

REM PowerShell Gorrilla Launcher
REM Local-first command centre for Windows

set SCRIPT_DIR=%~dp0
set LAUNCHER_PS1=%SCRIPT_DIR%Start-CommandUnitGorrilla.ps1

if not exist "!LAUNCHER_PS1!" (
    echo Error: Start-CommandUnitGorrilla.ps1 not found in %SCRIPT_DIR%
    exit /b 1
)

REM Launch PowerShell with the starter script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "!LAUNCHER_PS1!" %*

exit /b %errorlevel%
