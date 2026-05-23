@echo off
setlocal enabledelayedexpansion

REM PowerShell Gorrilla - Create Desktop Shortcut
REM Adds the app to Desktop and Start Menu for quick access

set SCRIPT_DIR=%~dp0
set EXE_PATH=%SCRIPT_DIR%dist\CommandUnitGorrilla.exe
set LAUNCHER=%SCRIPT_DIR%CommandUnitGorrilla.cmd
set ICON=%SCRIPT_DIR%assets\gorrilla-launcher.ico
set DESKTOP=%USERPROFILE%\Desktop
set START_MENU=%APPDATA%\Microsoft\Windows\Start Menu\Programs

if exist "!EXE_PATH!" (
    set LAUNCHER=!EXE_PATH!
) else if not exist "!LAUNCHER!" (
    echo Error: No launcher found. Build the EXE or keep CommandUnitGorrilla.cmd in place.
    exit /b 1
)

REM Create VBScript to generate shortcuts
set VBS_TEMP=%TEMP%\create_shortcut.vbs

(
    echo Set objShell = CreateObject("WScript.Shell"^)
    echo.
    echo ' Create Desktop shortcut
    echo Set objDesktopLink = objShell.CreateShortcut("!DESKTOP!\PowerShell Gorrilla.lnk"^)
    echo objDesktopLink.TargetPath = "!LAUNCHER!"
    echo objDesktopLink.WorkingDirectory = "!SCRIPT_DIR!"
    echo objDesktopLink.Description = "PowerShell Gorrilla - Local command centre"
    if exist "!ICON!" (
        echo objDesktopLink.IconLocation = "!ICON!"
    )
    echo objDesktopLink.Save
    echo.
    echo ' Create Start Menu shortcut
    echo Set objMenuLink = objShell.CreateShortcut("!START_MENU!\PowerShell Gorrilla.lnk"^)
    echo objMenuLink.TargetPath = "!LAUNCHER!"
    echo objMenuLink.WorkingDirectory = "!SCRIPT_DIR!"
    echo objMenuLink.Description = "PowerShell Gorrilla - Local command centre"
    if exist "!ICON!" (
        echo objMenuLink.IconLocation = "!ICON!"
    )
    echo objMenuLink.Save
    echo.
    echo WScript.Echo "Shortcuts created successfully"
) > "!VBS_TEMP!"

echo Creating shortcuts...
cscript.exe //nologo "!VBS_TEMP!"

if exist "!VBS_TEMP!" del /q "!VBS_TEMP!"

echo.
echo Desktop shortcut created: !DESKTOP!\PowerShell Gorrilla.lnk
echo Start Menu shortcut created: !START_MENU!\PowerShell Gorrilla.lnk
echo.
pause
