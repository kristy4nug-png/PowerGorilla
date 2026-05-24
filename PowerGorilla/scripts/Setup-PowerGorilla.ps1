#!/usr/bin/env pwsh
<#
    Phat Gorrilla setup
    PowerShell-first setup, dataset import, dashboard state refresh, and optional desktop shortcut management.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Root,
    [switch]$ExtractIcons,
    [switch]$SkipDataRefresh,
    [switch]$CreateDesktopIcon,
    [switch]$RepairDesktopIcon,
    [switch]$RemoveDesktopIcon
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

if ([string]::IsNullOrEmpty($Root)) {
    if ($PSScriptRoot) {
        $Root = Split-Path -Parent $PSScriptRoot
    } else {
        $scriptPath = $MyInvocation.MyCommand.Path
        if ($scriptPath) {
            $Root = Split-Path -Parent (Split-Path -Parent $scriptPath)
        } else {
            $Root = (Get-Location).Path
        }
    }
}

function Write-SetupStep {
    param(
        [int]$Step,
        [int]$Total,
        [string]$Message
    )
    $percent = [int](($Step / [Math]::Max($Total, 1)) * 100)
    Write-Progress -Activity 'Phat Gorrilla setup' -Status $Message -PercentComplete $percent
    Write-Host ("[{0}/{1}] {2}" -f $Step, $Total, $Message) -ForegroundColor Cyan
}

function Copy-DatasetIfMissing {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Target
    )
    if (-not (Test-Path -LiteralPath $Source)) { return $false }
    if (Test-Path -LiteralPath $Target) { return $false }
    Copy-Item -LiteralPath $Source -Destination $Target
    return $true
}

function Expand-CsvZipIfMissing {
    param(
        [Parameter(Mandatory)][string]$SourceZip,
        [Parameter(Mandatory)][string]$TargetCsv
    )
    if (-not (Test-Path -LiteralPath $SourceZip)) { return $false }
    if (Test-Path -LiteralPath $TargetCsv) { return $false }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($SourceZip)
    try {
        $entry = $archive.Entries | Where-Object { $_.FullName -like '*.csv' } | Select-Object -First 1
        if (-not $entry) { throw "No CSV entry found in $SourceZip" }
        $entryStream = $entry.Open()
        try {
            $fileStream = [System.IO.File]::Create($TargetCsv)
            try {
                $entryStream.CopyTo($fileStream)
            } finally {
                $fileStream.Dispose()
            }
        } finally {
            $entryStream.Dispose()
        }
    } finally {
        $archive.Dispose()
    }
    return $true
}

function Get-PGDesktopShortcutPath {
    $desktop = [Environment]::GetFolderPath('DesktopDirectory')
    return Join-Path $desktop 'Phat Gorrilla.lnk'
}

function Get-PGPreferredShell {
    $pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if ($pwsh) { return $pwsh.Source }

    $powershell = Get-Command powershell.exe -ErrorAction SilentlyContinue
    if ($powershell) { return $powershell.Source }

    throw 'No PowerShell host found on PATH.'
}

function Set-PGDesktopShortcut {
    param([Parameter(Mandatory)][string]$RootPath)

    $shortcutPath = Get-PGDesktopShortcutPath
    $launcher = Join-Path $RootPath 'Start-PowerGorilla.ps1'
    if (-not (Test-Path -LiteralPath $launcher)) {
        throw "Launcher not found: $launcher"
    }
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = Get-PGPreferredShell
    $shortcut.Arguments = ('-NoProfile -ExecutionPolicy Bypass -File "{0}" -AppMode' -f $launcher)
    $shortcut.WorkingDirectory = $RootPath
    $icon = Join-Path $RootPath 'data\icons\fallback-app.svg'
    $ico = Join-Path $RootPath 'assets\gorrilla-launcher.ico'
    if (Test-Path -LiteralPath $ico) { $shortcut.IconLocation = $ico }
    elseif (Test-Path -LiteralPath $icon) { $shortcut.IconLocation = $icon }
    $shortcut.Description = 'Phat Gorrilla local Windows command centre'
    $shortcut.Save()
    return $shortcutPath
}

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$moduleManifest = Join-Path $rootPath 'modules\PowerGorilla\PowerGorilla.psd1'
$importDir = Join-Path $rootPath 'data\imports'
$reportDir = Join-Path $rootPath 'reports'

$totalSteps = 7
$report = [ordered]@{
    timestamp = (Get-Date).ToString('o')
    task = 'Setup Phat Gorrilla'
    projectPath = $rootPath
    actionsPerformed = @()
    actionsSkipped = @()
    warnings = @()
    errors = @()
    finalStatus = 'Started'
}

try {
    Write-SetupStep 1 $totalSteps 'Preparing folder structure'
    Import-Module $moduleManifest -Force
    Initialize-PGProject -Root $rootPath | Out-Null
    $report.actionsPerformed += 'Verified PowerGorilla folder structure.'

    Write-SetupStep 2 $totalSteps 'Importing supplied datasets when missing'
    $desktop = [Environment]::GetFolderPath('DesktopDirectory')
    $imports = @(
        @{
            Source = Join-Path $desktop 'Two_App_20K_Free_OpenSource_Combinations.csv'
            Target = Join-Path $importDir 'Two_App_20K_Free_OpenSource_Combinations.csv'
            Kind = 'copy'
        },
        @{
            Source = Join-Path $desktop 'Three_App_200K_Free_OpenSource_Integrations_CSV.zip'
            Target = Join-Path $importDir 'Three_App_200K_Free_OpenSource_Integrations.csv'
            Kind = 'zip'
        },
        @{
            Source = Join-Path $desktop 'Four_App_400K_Free_OpenSource_Integrations_CSV.zip'
            Target = Join-Path $importDir 'Four_App_400K_Free_OpenSource_Integrations.csv'
            Kind = 'zip'
        }
    )
    foreach ($item in $imports) {
        if ($item.Kind -eq 'copy') {
            if (Copy-DatasetIfMissing -Source $item.Source -Target $item.Target) {
                $report.actionsPerformed += "Copied dataset: $($item.Target)"
            } elseif (Test-Path -LiteralPath $item.Target) {
                $report.actionsSkipped += "Dataset already present: $($item.Target)"
            } else {
                $report.warnings += "Dataset source not found: $($item.Source)"
            }
        } else {
            if (Expand-CsvZipIfMissing -SourceZip $item.Source -TargetCsv $item.Target) {
                $report.actionsPerformed += "Extracted dataset: $($item.Target)"
            } elseif (Test-Path -LiteralPath $item.Target) {
                $report.actionsSkipped += "Dataset already present: $($item.Target)"
            } else {
                $report.warnings += "Dataset zip not found: $($item.Source)"
            }
        }
    }

    Write-SetupStep 3 $totalSteps 'Checking dataset status'
    $datasetStatus = @(Get-PGDatasetStatus -Root $rootPath)
    $report.datasetStatus = @($datasetStatus)
    if (-not (($datasetStatus | Where-Object Type -eq 'Apps').Exists)) {
        $report.warnings += 'Proper_Apps_Shortlist.csv is not present. App candidates will be derived from integration datasets.'
    }

    Write-SetupStep 4 $totalSteps 'Refreshing processed dashboard data'
    if ($SkipDataRefresh) {
        $report.actionsSkipped += 'Skipped data refresh by request.'
    } else {
        $refresh = Invoke-PGRefreshData -Root $rootPath -ExtractIcons:$ExtractIcons
        $report.actionsPerformed += "Refreshed data. Apps: $($refresh.Apps). Workflows indexed for dashboard: $($refresh.Integrations). Icons: $($refresh.IconsExtracted)."
    }

    Write-SetupStep 5 $totalSteps 'Managing desktop icon option'
    if ($RemoveDesktopIcon) {
        $shortcutPath = Get-PGDesktopShortcutPath
        if (Test-Path -LiteralPath $shortcutPath) {
            if ($PSCmdlet.ShouldProcess($shortcutPath, 'Remove Phat Gorrilla desktop shortcut')) {
                Remove-Item -LiteralPath $shortcutPath
                $report.actionsPerformed += "Removed desktop icon: $shortcutPath"
            }
        } else {
            $report.actionsSkipped += 'Desktop icon was not present.'
        }
    } elseif ($CreateDesktopIcon -or $RepairDesktopIcon) {
        $shortcutPath = Set-PGDesktopShortcut -RootPath $rootPath
        $report.actionsPerformed += "Created or repaired desktop icon: $shortcutPath"
    } else {
        $report.actionsSkipped += 'Desktop icon unchanged. Use -CreateDesktopIcon, -RepairDesktopIcon, or -RemoveDesktopIcon.'
    }

    Write-SetupStep 6 $totalSteps 'Writing setup report'
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    $report.finalStatus = 'Completed'
    $reportPath = Join-Path $reportDir ("Setup-Report-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $report.reportPath = $reportPath
    $report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $reportPath -Encoding UTF8
    Write-PGLog -Root $rootPath -Area 'Setup' -Message 'Setup completed.' -Data @{ Report = $reportPath }

    Write-SetupStep 7 $totalSteps 'Complete'
    Write-Progress -Activity 'Phat Gorrilla setup' -Completed
    Write-Host "Setup report: $reportPath" -ForegroundColor Green
    $report
} catch {
    $report.finalStatus = 'Failed Safely'
    $report.errors += $_.Exception.Message
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    $reportPath = Join-Path $reportDir ("Setup-Report-Failed-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $report.reportPath = $reportPath
    $report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $reportPath -Encoding UTF8
    Write-Progress -Activity 'Phat Gorrilla setup' -Completed
    Write-Error "Phat Gorrilla setup failed safely. Report: $reportPath. Error: $($_.Exception.Message)"
    exit 1
}
