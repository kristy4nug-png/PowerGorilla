@echo off
setlocal

REM PowerShell Gorrilla EXE Builder
REM Builds the launcher as a standalone EXE using PS2EXE or native IExpress fallback.

set SCRIPT_DIR=%~dp0
set BUILD_SCRIPT=%SCRIPT_DIR%Build-Exe.ps1

if not exist "%BUILD_SCRIPT%" (
    echo Error: Build-Exe.ps1 missing from %SCRIPT_DIR%
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BUILD_SCRIPT%"
exit /b %errorlevel%
