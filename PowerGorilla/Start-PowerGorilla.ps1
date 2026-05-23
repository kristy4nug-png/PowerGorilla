#!/usr/bin/env pwsh
<#
    Power Gorilla launcher
    Starts the local dashboard with PowerShell-generated state.
#>

[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot,
    [int]$Port = 8765,
    [switch]$NoBrowser,
    [switch]$Refresh,
    [switch]$ExtractIcons
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

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
Start-PGDashboardServer -Root $rootPath -Port $Port -OpenBrowser:(!$NoBrowser)
Write-Progress -Activity 'Power Gorilla launch' -Completed
