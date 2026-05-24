#!/usr/bin/env pwsh
<#
    Power Gorilla launcher
    Starts the local dashboard with PowerShell-generated state.
#>

[CmdletBinding()]
param(
    [string]$Root,
    [int]$Port = 8765,
    [switch]$NoBrowser,
    [switch]$Refresh,
    [switch]$ExtractIcons,
    [switch]$AppMode
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

if ([string]::IsNullOrEmpty($Root)) {
    $Root = $PSScriptRoot
}
if ([string]::IsNullOrEmpty($Root)) {
    $Root = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$moduleManifest = Join-Path $rootPath 'modules\PowerGorilla\PowerGorilla.psd1'
$statePath = Join-Path $rootPath 'data\processed\dashboard-state.json'

Import-Module $moduleManifest -Force
Initialize-PGProject -Root $rootPath | Out-Null

if ($Refresh -or -not (Test-Path -LiteralPath $statePath)) {
    Write-Progress -Activity 'Power Gorilla launch' -Status 'Refreshing dashboard state' -PercentComplete 35
    Invoke-PGRefreshData -Root $rootPath -ExtractIcons:$ExtractIcons | Out-Null
}

Write-Progress -Activity 'Power Gorilla launch' -Status 'Starting local dashboard' -PercentComplete 80
Start-PGDashboardServer -Root $rootPath -Port $Port -OpenBrowser:(!$NoBrowser) -AppMode:$AppMode
Write-Progress -Activity 'Power Gorilla launch' -Completed
