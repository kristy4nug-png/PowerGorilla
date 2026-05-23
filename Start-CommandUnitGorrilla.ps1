#!/usr/bin/env powershell
<#
  PowerShell Gorrilla Launcher
  Starts the local-first command centre dashboard
#>

param(
    [switch]$Dashboard,
    [string]$Mode = 'visual'
)

if (-not $PSBoundParameters.ContainsKey('Dashboard')) {
    $Dashboard = $true
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not (Test-Path -LiteralPath $scriptRoot)) {
    $scriptRoot = (Get-Location).Path
}
$logDir = Join-Path $scriptRoot 'logs'
if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
$logPath = Join-Path $logDir ("PowerShell-Gorrilla-Launch-{0}.log" -f (Get-Date -Format 'yyyyMMdd'))

function Write-LaunchLog {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [string]$Level = 'INFO'
    )
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
}

try {
    Write-Progress -Activity 'PowerShell Gorrilla launch' -Status 'Preparing' -PercentComplete 10
    
    Write-Host "PowerShell Gorrilla" -ForegroundColor Cyan
    Write-Host "Loading command centre..." -ForegroundColor Gray
    Write-LaunchLog "Launcher started from $scriptRoot"
    
    $manifestPath = Join-Path $scriptRoot 'CommandUnitGorrilla.psd1'
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "Module manifest not found: $manifestPath"
    }
    Write-Progress -Activity 'PowerShell Gorrilla launch' -Status 'Importing module' -PercentComplete 35
    Import-Module $manifestPath -Force -WarningAction SilentlyContinue
    Write-LaunchLog "Module imported: $manifestPath"
    
    if ($Dashboard) {
        Write-Progress -Activity 'PowerShell Gorrilla launch' -Status 'Starting dashboard' -PercentComplete 70
        Write-Host "Starting dashboard..." -ForegroundColor Green
        if (-not (Get-Command gorvisual -ErrorAction SilentlyContinue)) {
            throw "gorvisual command was not exported by the module."
        }
        $dashboardPath = gorvisual
        if ($dashboardPath -and (Test-Path -LiteralPath $dashboardPath)) {
            Write-Host "Dashboard opened: $dashboardPath" -ForegroundColor Green
            Write-LaunchLog "Dashboard opened: $dashboardPath"
            Start-Sleep -Milliseconds 500
            Invoke-Item -LiteralPath $dashboardPath -ErrorAction SilentlyContinue
        }
        elseif ($dashboardPath) {
            Write-Host "Dashboard launch returned: $dashboardPath" -ForegroundColor Yellow
            Write-LaunchLog "Dashboard returned non-file target: $dashboardPath" 'WARN'
        }
        else {
            throw "Dashboard command returned no launch target."
        }
    }
    else {
        Write-Host "Command centre ready. Use 'gorrilla', 'gorvisual', 'gordo', or other commands." -ForegroundColor Green
        Write-LaunchLog 'Command centre loaded without dashboard.'
    }
    
    $host.UI.RawUI.WindowTitle = "PowerShell Gorrilla - Local Command Centre"
    Write-Progress -Activity 'PowerShell Gorrilla launch' -Completed
}
catch {
    Write-Progress -Activity 'PowerShell Gorrilla launch' -Completed
    Write-LaunchLog $_.Exception.Message 'ERROR'
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.Exception.StackTrace -ForegroundColor DarkRed
    Write-Host "Launch log: $logPath" -ForegroundColor Yellow
    exit 1
}
