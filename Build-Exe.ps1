<#
.SYNOPSIS
Builds the PowerShell Gorrilla launcher as a standalone EXE.

.DESCRIPTION
This script uses PS2EXE if available locally, otherwise it falls back to Windows IExpress
so you can generate a real executable without needing external download support.
#>

Set-StrictMode -Version 2.0

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputDir = Join-Path $scriptRoot 'dist'
$exeName = 'CommandUnitGorrilla.exe'
$finalExePath = Join-Path $outputDir $exeName
$tempExePath = Join-Path $env:TEMP $exeName
$ps2exePath = Join-Path $scriptRoot 'ps2exe.ps1'
$iexpressPath = Join-Path $env:windir 'System32\iexpress.exe'

New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
if (Test-Path -LiteralPath $tempExePath) {
    Remove-Item -LiteralPath $tempExePath -Force -ErrorAction SilentlyContinue
}

function Write-Status {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Write-ErrorAndExit {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}

function New-Shortcut {
    param(
        [string]$LinkPath,
        [string]$TargetPath,
        [string]$WorkingDirectory,
        [string]$Description,
        [string]$IconLocation
    )
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($LinkPath)
    $shortcut.TargetPath = $TargetPath
    $shortcut.WorkingDirectory = $WorkingDirectory
    $shortcut.Description = $Description
    if (Test-Path -LiteralPath $IconLocation) {
        $shortcut.IconLocation = $IconLocation
    }
    $shortcut.Save()
}

function Create-ShortcutsForExe {
    param([string]$TargetExe)
    $desktop = [Environment]::GetFolderPath('Desktop')
    $startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
    $iconPath = Join-Path $scriptRoot 'assets\gorrilla-launcher.ico'

    New-Shortcut -LinkPath (Join-Path $desktop 'PowerShell Gorrilla.lnk') -TargetPath $TargetExe -WorkingDirectory (Split-Path -Parent $TargetExe) -Description 'PowerShell Gorrilla - Local command centre' -IconLocation $iconPath
    New-Shortcut -LinkPath (Join-Path $startMenu 'PowerShell Gorrilla.lnk') -TargetPath $TargetExe -WorkingDirectory (Split-Path -Parent $TargetExe) -Description 'PowerShell Gorrilla - Local command centre' -IconLocation $iconPath
    Write-Host "Created desktop shortcut: $desktop\PowerShell Gorrilla.lnk"
    Write-Host "Created Start Menu shortcut: $startMenu\PowerShell Gorrilla.lnk"
}

if (Test-Path -LiteralPath $ps2exePath) {
    Write-Status "PS2EXE found locally: $ps2exePath"
    Write-Status "Building $exeName with PS2EXE..."
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ps2exePath -inputFile (Join-Path $scriptRoot 'Start-CommandUnitGorrilla.ps1') -outputFile $finalExePath -title 'PowerShell Gorrilla' -description 'Local-first command centre for Windows' -iconFile (Join-Path $scriptRoot 'assets\gorrilla-launcher.ico') -requireAdmin
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $finalExePath)) {
        Write-ErrorAndExit "PS2EXE failed to build $exeName."
    }
}
else {
    if (-not (Test-Path -LiteralPath $iexpressPath)) {
        Write-ErrorAndExit "PS2EXE is not available and IExpress could not be found at $iexpressPath."
    }
    Write-Status "PS2EXE not found. Falling back to IExpress to build a standalone EXE."

    $sedPath = Join-Path $scriptRoot 'Build-Exe.sed'
    $targetName = $tempExePath

    $sedText = @"
[Version]
Class=IEXPRESS
SEDVersion=3

[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=0
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
RebootMode=NoRestart
InstallPrompt=
DisplayLicense=
FinishMessage=PowerShell Gorrilla is ready.
TargetName=$targetName
FriendlyName=PowerShell Gorrilla
AppLaunched=powershell.exe -NoProfile -ExecutionPolicy Bypass -File Start-CommandUnitGorrilla.ps1
PostInstallCmd=
AdminInstall=0
UsePrompt=0
[Strings]

[SourceFiles]
SourceFiles0=.
SourceFiles1=assets

[SourceFiles0]
Start-CommandUnitGorrilla.ps1=
CommandUnitGorrilla.psd1=
CommandUnitGorrilla.psm1=
CommandUnitGorrilla.cmd=
Create-Shortcuts.cmd=

[SourceFiles1]
gorrilla-launcher.ico=
"@

    Set-Content -LiteralPath $sedPath -Value $sedText -Encoding ASCII
    Write-Status "Building $exeName with IExpress from $sedPath..."
    & $iexpressPath /N $sedPath
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorAndExit "IExpress build failed with exit code $LASTEXITCODE."
    }
    if (-not (Test-Path -LiteralPath $tempExePath)) {
        Write-ErrorAndExit "IExpress finished but did not produce $tempExePath."
    }
    Move-Item -Path $tempExePath -Destination $finalExePath -Force
    Remove-Item -LiteralPath $sedPath -Force -ErrorAction SilentlyContinue
}

if (Test-Path -LiteralPath $finalExePath) {
    Write-Status "Success! EXE created at $finalExePath"
    Create-ShortcutsForExe -TargetExe $finalExePath
    Write-Host "\nYour desktop launcher is ready. Double-click the EXE or the desktop shortcut to start PowerShell Gorrilla."
    exit 0
}

Write-ErrorAndExit "Build completed but $finalExePath was not found."
