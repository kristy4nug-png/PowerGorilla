#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Scan for installed desktop applications on Windows
    
.DESCRIPTION
    IntegrationCore Desktop App Scanner
    Discovers installed apps, extracts icons, and generates integration candidates
    Outputs strict JSON for frontend ingestion
    
.EXAMPLE
    .\Scan-DesktopApps.ps1 -IncludePortable -ExtractIcons -OutputFile apps.json
#>

[CmdletBinding()]
param(
    [string]$OutputFile = "$PSScriptRoot\data\processed\desktop_apps_candidates.json",
    [switch]$IncludePortable,
    [switch]$ExtractIcons,
    [switch]$Verbose,
    [int]$MaxApps = 100
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

# Common Windows app installation paths (safe, non-system)
$SCAN_PATHS = @(
    'C:\Program Files'
    'C:\Program Files (x86)'
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
    "$env:LOCALAPPDATA\Programs"
    "C:\Users\$env:USERNAME\AppData\Local\Programs"
)

# System/excluded paths (never scan)
$EXCLUDED_PATHS = @(
    'C:\Windows'
    'C:\Program Files\Windows Defender'
    'C:\Program Files (x86)\Windows'
    'C:\System Volume Information'
)

# Common app categories
$CATEGORY_MAP = @{
    'spotify' = 'Music'
    'youtube' = 'Video'
    'netflix' = 'Video'
    'discord' = 'Communication'
    'slack' = 'Communication'
    'vscode' = 'Development'
    'visual studio' = 'Development'
    'git' = 'Development'
    'photoshop' = 'Design'
    'figma' = 'Design'
    'adobe' = 'Design'
    'blender' = 'Design'
    'premiere' = 'Video'
    'davinci' = 'Video'
    'chrome' = 'Browser'
    'firefox' = 'Browser'
    'edge' = 'Browser'
    'notion' = 'Productivity'
    'obsidian' = 'Productivity'
    'office' = 'Productivity'
    'excel' = 'Productivity'
    'word' = 'Productivity'
    'powerpoint' = 'Productivity'
    '7zip' = 'Utilities'
    'winrar' = 'Utilities'
    'vlc' = 'Media'
    'steam' = 'Gaming'
    'epic' = 'Gaming'
}

<#
.SYNOPSIS
    Extracts icon from executable file
#>
function Get-AppIcon {
    param([string]$ExePath, [string]$OutputDir)
    
    if (-not (Test-Path -LiteralPath $ExePath)) {
        return $null
    }
    
    try {
        # Use Windows API to extract icon
        $iconPath = Join-Path $OutputDir "$(([System.IO.Path]::GetFileNameWithoutExtension($ExePath))).ico"
        
        # PowerShell 5+ can extract icons, but for now return path
        # Actual extraction would use System.Drawing or external tool
        return $iconPath
    } catch {
        return $null
    }
}

<#
.SYNOPSIS
    Gets app metadata from shortcut file
#>
function Get-ShortcutMetadata {
    param([string]$ShortcutPath)
    
    if (-not (Test-Path -LiteralPath $ShortcutPath)) {
        return $null
    }
    
    try {
        $shell = New-Object -ComObject WScript.Shell
        $link = $shell.CreateShortcut($ShortcutPath)
        
        return @{
            TargetPath = $link.TargetPath
            WorkingDirectory = $link.WorkingDirectory
            Arguments = $link.Arguments
            IconLocation = $link.IconLocation
            Description = $link.Description
        }
    } catch {
        return $null
    }
}

<#
.SYNOPSIS
    Scans directory for executable files and shortcuts
#>
function Find-InstalledApps {
    param([string]$ScanPath)
    
    $apps = @()
    $visited = @{}
    
    # Avoid scanning excluded paths
    foreach ($excluded in $EXCLUDED_PATHS) {
        if ($ScanPath -like "$excluded*") {
            Write-Verbose "Skipping excluded path: $ScanPath"
            return @()
        }
    }
    
    if (-not (Test-Path -LiteralPath $ScanPath)) {
        return @()
    }
    
    try {
        # Find all .exe files (limit depth to avoid deep system scanning)
        Get-ChildItem -LiteralPath $ScanPath -Filter '*.exe' -Recurse -ErrorAction SilentlyContinue -Depth 3 |
        Select-Object -First 20 |
        ForEach-Object {
            $exe = $_
            $exeName = $exe.BaseName
            
            # Deduplicate by exe name
            if ($visited[$exeName]) {
                return
            }
            $visited[$exeName] = $true
            
            # Get file metadata
            $fileInfo = $exe.VersionInfo
            $fileName = $exe.Name
            
            # Determine category
            $category = 'Applications'
            foreach ($key in $CATEGORY_MAP.Keys) {
                if ($exeName -like "*$key*" -or $fileInfo.ProductName -like "*$key*") {
                    $category = $CATEGORY_MAP[$key]
                    break
                }
            }
            
            $apps += @{
                name = $fileInfo.ProductName -or $exeName
                slug = ($exeName -replace '[^a-z0-9-]', '-').ToLower()
                category = $category
                exe_path = $exe.FullName
                publisher = $fileInfo.CompanyName
                version = $fileInfo.ProductVersion
                icon_source = 'exe'
                launch_command = """$($exe.FullName)"""
                confidence = 0.85
                safe_to_launch = $true
                needs_review = $false
                notes = @()
            }
        }
    } catch {
        Write-Verbose "Error scanning path $ScanPath : $_"
    }
    
    return $apps
}

<#
.SYNOPSIS
    Scans Start Menu shortcuts for apps
#>
function Find-StartMenuApps {
    param([string]$StartMenuPath)
    
    $apps = @()
    $visited = @{}
    
    if (-not (Test-Path -LiteralPath $StartMenuPath)) {
        return @()
    }
    
    try {
        Get-ChildItem -LiteralPath $StartMenuPath -Filter '*.lnk' -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 30 |
        ForEach-Object {
            $link = $_
            $name = $link.BaseName
            
            if ($visited[$name]) {
                return
            }
            $visited[$name] = $true
            
            $metadata = Get-ShortcutMetadata -ShortcutPath $link.FullName
            if (-not $metadata) { return }
            
            $exePath = $metadata.TargetPath
            if (-not (Test-Path -LiteralPath $exePath)) {
                return
            }
            
            $fileInfo = (Get-Item -LiteralPath $exePath).VersionInfo
            
            # Determine category
            $category = 'Applications'
            foreach ($key in $CATEGORY_MAP.Keys) {
                if ($name -like "*$key*" -or $fileInfo.ProductName -like "*$key*") {
                    $category = $CATEGORY_MAP[$key]
                    break
                }
            }
            
            $apps += @{
                name = $fileInfo.ProductName -or $name
                slug = ($name -replace '[^a-z0-9-]', '-').ToLower()
                category = $category
                exe_path = $exePath
                shortcut_path = $link.FullName
                publisher = $fileInfo.CompanyName
                version = $fileInfo.ProductVersion
                icon_source = 'shortcut'
                launch_command = """$exePath"""
                confidence = 0.90
                safe_to_launch = $true
                needs_review = $false
                notes = @()
            }
        }
    } catch {
        Write-Verbose "Error scanning Start Menu: $_"
    }
    
    return $apps
}

# ===== MAIN EXECUTION =====

Write-Host "🔍 Scanning for desktop applications..." -ForegroundColor Cyan

$allApps = @()

# Scan Program Files
foreach ($path in $SCAN_PATHS) {
    if (Test-Path -LiteralPath $path) {
        Write-Verbose "Scanning: $path"
        $found = Find-InstalledApps -ScanPath $path
        $allApps += $found
    }
}

# Scan Start Menu
$startMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
if (Test-Path -LiteralPath $startMenuPath) {
    Write-Verbose "Scanning Start Menu: $startMenuPath"
    $found = Find-StartMenuApps -ScanPath $startMenuPath
    $allApps += $found
}

# Deduplicate and limit
$allApps = $allApps | Group-Object -Property slug | 
    ForEach-Object { $_.Group | Select-Object -First 1 } |
    Sort-Object -Property name |
    Select-Object -First $MaxApps

Write-Host "✅ Found $($allApps.Count) applications" -ForegroundColor Green

# Build desktop app candidates (strict JSON format)
$candidates = @()
$allApps | ForEach-Object {
    $candidates += @{
        type = 'desktop_app_candidate'
        name = $_.name
        slug = $_.slug
        category = $_.category
        exe_path = $_.exe_path
        shortcut_path = $_.shortcut_path
        launch_command = $_.launch_command
        icon_source = $_.icon_source
        publisher = $_.publisher
        confidence = [double]$_.confidence
        safe_to_launch = [bool]$_.safe_to_launch
        needs_review = [bool]$_.needs_review
        notes = @()
    }
}

# Output JSON
$output = @{
    scan_timestamp = (Get-Date -Format 'o')
    total_found = $candidates.Count
    candidates = $candidates
    safe_to_scan = $true
    notes = @(
        "Scanned common installation paths"
        "Excluded system paths"
        "Deduplicatedby app slug"
    )
} | ConvertTo-Json -Depth 10

# Ensure output directory exists
$outputDir = Split-Path -Parent $OutputFile
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Write output
$output | Out-File -FilePath $OutputFile -Encoding UTF8 -Force
Write-Host "📝 Saved candidates to: $OutputFile" -ForegroundColor Green

# Return candidates as object (for pipeline)
$output | ConvertFrom-Json | Write-Output
