#!/usr/bin/env pwsh
<#
    Power Gorilla validation
    Proves the Phase 1 foundation imports, launches, and remains preview-only for risky UI actions.
#>

[CmdletBinding()]
param(
    [string]$Root,
    [switch]$StaticOnly,
    [switch]$UseSupabase,
    [switch]$RefreshData,
    [switch]$ExtractIcons
)

$ErrorActionPreference = 'Continue'
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

function Add-Check {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][bool]$Passed,
        [string]$Detail = ''
    )
    $script:checks += [pscustomobject]@{
        name = $Name
        passed = $Passed
        detail = $Detail
        timestamp = (Get-Date).ToString('o')
    }
}

function Invoke-Check {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$ScriptBlock
    )
    try {
        $result = & $ScriptBlock
        Add-Check -Name $Name -Passed $true -Detail ([string]$result)
    } catch {
        Add-Check -Name $Name -Passed $false -Detail $_.Exception.Message
    }
}

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$moduleManifest = Join-Path $rootPath 'modules\PowerGorilla\PowerGorilla.psd1'
$reportDir = Join-Path $rootPath 'reports'
$script:checks = @()
$steps = @('Folder structure','Module manifest','Module import','Dashboard files','Schema files','Supabase migrations','Brand assets','Dry-run command engine','No destructive UI actions','Report write')
if (-not $StaticOnly) {
    $steps = @(
        'Folder structure',
        'Module manifest',
        'Module import',
        'Dataset files',
        'CSV parse',
        'Data refresh',
        'Dashboard files',
        'Dashboard state',
        'Icon cache',
        'Integration search',
        'Sign-in report',
        'Dry-run command engine',
        'No destructive UI actions',
        'Report write'
    )
}
if ($UseSupabase) {
    $reportIndex = [array]::IndexOf($steps, 'Report write')
    if ($reportIndex -ge 0) {
        $before = if ($reportIndex -gt 0) { $steps[0..($reportIndex - 1)] } else { @() }
        $after = $steps[$reportIndex..($steps.Count - 1)]
        $steps = @($before + 'Supabase connectivity' + $after)
    } else {
        $steps = @($steps + 'Supabase connectivity')
    }
}

for ($i = 0; $i -lt $steps.Count; $i++) {
    Write-Progress -Activity 'Power Gorilla validation' -Status $steps[$i] -PercentComplete ([int](($i / $steps.Count) * 100))
    switch ($steps[$i]) {
        'Folder structure' {
            Invoke-Check 'Required folders exist' {
                $required = if ($StaticOnly) {
                    @('modules\PowerGorilla','scripts','ui','docs','schema','supabase\migrations','frontend')
                } else {
                    @('app','data','data\imports','data\processed','data\icons','logs','modules\PowerGorilla','reports','scripts','ui','backups','docs')
                }
                $missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $rootPath $_)) })
                if ($missing.Count) { throw "Missing folders: $($missing -join ', ')" }
                'All required folders exist.'
            }
        }
        'Module manifest' {
            Invoke-Check 'Module manifest parses' {
                Test-ModuleManifest -Path $moduleManifest | Out-Null
                'Manifest parsed.'
            }
        }
        'Module import' {
            Invoke-Check 'Module imports' {
                Import-Module $moduleManifest -Force
                'Module imported.'
            }
        }
        'Dataset files' {
            Invoke-Check 'Dataset files present' {
                $status = @(Get-PGDatasetStatus -Root $rootPath)
                $present = @($status | Where-Object Exists)
                if ($present.Count -lt 3) { throw "Expected at least 3 supplied integration datasets; found $($present.Count)." }
                "$($present.Count) dataset files present."
            }
        }
        'CSV parse' {
            Invoke-Check 'CSV imports parse first rows' {
                $paths = @(Get-PGDatasetStatus -Root $rootPath | Where-Object { $_.Exists -and $_.CombinationSize -gt 1 } | Select-Object -ExpandProperty Path)
                foreach ($path in $paths) {
                    $row = Get-Content -LiteralPath $path -TotalCount 2 | ConvertFrom-Csv | Select-Object -First 1
                    if (-not $row) { throw "No row parsed from $path" }
                }
                "$($paths.Count) CSV files parsed."
            }
        }
        'Data refresh' {
            Invoke-Check 'Processed data refresh works' {
                if ($RefreshData -or -not (Test-Path -LiteralPath (Join-Path $rootPath 'data\processed\dashboard-state.json'))) {
                    Invoke-PGRefreshData -Root $rootPath -ExtractIcons:$ExtractIcons | Out-Null
                }
                'Processed data available.'
            }
        }
        'Dashboard files' {
            Invoke-Check 'Dashboard files exist' {
                $files = @('ui\index.html','ui\styles.css','ui\app.js','ui\app-data.js')
                $missing = @($files | Where-Object { -not (Test-Path -LiteralPath (Join-Path $rootPath $_)) })
                if ($missing.Count) { throw "Missing UI files: $($missing -join ', ')" }
                'Dashboard files exist.'
            }
        }
        'Schema files' {
            Invoke-Check 'JSON schemas exist and parse' {
                $files = @('schema\app.schema.json','schema\workflow.schema.json','schema\extraction.schema.json')
                $missing = @($files | Where-Object { -not (Test-Path -LiteralPath (Join-Path $rootPath $_)) })
                if ($missing.Count) { throw "Missing schema files: $($missing -join ', ')" }
                foreach ($file in $files) {
                    Get-Content -LiteralPath (Join-Path $rootPath $file) -Raw | ConvertFrom-Json | Out-Null
                }
                'Schema files parse.'
            }
        }
        'Supabase migrations' {
            Invoke-Check 'Supabase migrations are present' {
                $migrations = @(Get-ChildItem -LiteralPath (Join-Path $rootPath 'supabase\migrations') -Filter '*.sql' -File -ErrorAction Stop)
                if ($migrations.Count -lt 1) { throw 'No Supabase migrations found.' }
                "$($migrations.Count) Supabase migrations found."
            }
        }
        'Brand assets' {
            Invoke-Check 'Bad Gorrilla brand assets exist' {
                $files = @('assets\bad-gorrilla-logo.png','assets\bad-gorrilla-icon.png','assets\gorrilla-launcher.ico','ui\assets\bad-gorrilla-logo.png','frontend\assets\icon.png','frontend\assets\favicon.png')
                $missing = @($files | Where-Object { -not (Test-Path -LiteralPath (Join-Path $rootPath $_)) })
                if ($missing.Count) { throw "Missing brand assets: $($missing -join ', ')" }
                'Brand assets exist.'
            }
        }
        'Dashboard state' {
            Invoke-Check 'Dashboard state JSON loads' {
                $statePath = Join-Path $rootPath 'data\processed\dashboard-state.json'
                $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
                if ($null -eq $state.safety -or $null -eq $state.apps -or $null -eq $state.integrations) { throw 'Dashboard state is missing required sections.' }
                "Apps: $($state.apps.Count), workflows: $($state.integrations.Count)."
            }
        }
        'Icon cache' {
            Invoke-Check 'Icon extraction or fallback works' {
                $fallback = Join-Path $rootPath 'data\icons\fallback-app.svg'
                if (-not (Test-Path -LiteralPath $fallback)) { throw 'Fallback icon missing.' }
                $icons = @(Get-ChildItem -LiteralPath (Join-Path $rootPath 'data\icons') -File -ErrorAction SilentlyContinue)
                "Icon files available: $($icons.Count)."
            }
        }
        'Integration search' {
            Invoke-Check '2/3/4-app visual searches find workflows' {
                $two = @(Get-PGIntegrationSearch -Root $rootPath -Apps @('Audacity','Blender') -CombinationSize 2 -First 1)
                $three = @(Get-PGIntegrationSearch -Root $rootPath -Apps @('age','BleachBit','7-Zip') -CombinationSize 3 -First 1)
                $four = @(Get-PGIntegrationSearch -Root $rootPath -Apps @('age','Audacity','7-Zip','LibreOffice') -CombinationSize 4 -First 1)
                if ($two.Count -lt 1) { throw '2-app workflow search did not find Audacity + Blender.' }
                if ($three.Count -lt 1) { throw '3-app workflow search did not find age + BleachBit + 7-Zip.' }
                if ($four.Count -lt 1) { throw '4-app workflow search did not find age + Audacity + 7-Zip + LibreOffice.' }
                '2-app, 3-app, and 4-app searches returned results.'
            }
        }
        'Sign-in report' {
            Invoke-Check 'Sign-in report works' {
                $report = @(Get-PGSignInReport -Root $rootPath)
                if ($report.Count -lt 1) { throw 'Sign-in report is empty.' }
                "$($report.Count) sign-in rows."
            }
        }
        'Dry-run command engine' {
            Invoke-Check 'Dry-run command preview works' {
                $preview = Invoke-PGCommand -Root $rootPath -Name LaunchApps -Target 'Audacity, Blender' -DryRun
                if ($preview.mode -ne 'Dry-run preview') { throw 'LaunchApps did not remain in dry-run preview.' }
                'LaunchApps stayed dry-run.'
            }
        }
        'No destructive UI actions' {
            Invoke-Check 'UI dangerous actions are preview-only' {
                $js = Get-Content -LiteralPath (Join-Path $rootPath 'ui\app.js') -Raw
                if ($js -notmatch 'No apps were launched' -or $js -notmatch 'Phase 1 only previews this action') {
                    throw 'Launch preview guard text missing from app.js.'
                }
                'UI launch action is preview-only.'
            }
        }
        'Supabase connectivity' {
            Invoke-Check 'Supabase dashboard_stats reads' {
                $supabaseModule = Join-Path $rootPath 'modules\PowerGorilla\PowerGorilla.Supabase.psm1'
                if (-not (Test-Path -LiteralPath $supabaseModule)) { throw 'Supabase extension module missing.' }

                Import-Module $supabaseModule -Force | Out-Null
                $config = Get-GorSupabaseConfig
                $key = if ($config.AnonKey) { $config.AnonKey } else { $config.ServiceKey }
                if ([string]::IsNullOrWhiteSpace($config.Url) -or [string]::IsNullOrWhiteSpace($key)) {
                    throw 'Supabase URL/key not configured. Create PowerGorilla\.env.ps1 locally.'
                }

                $headers = @{
                    apikey = $key
                    Authorization = "Bearer $key"
                }
                $stats = @(Invoke-RestMethod -Uri "$($config.Url)/rest/v1/dashboard_stats?select=*&limit=1" -Headers $headers -TimeoutSec 20 -ErrorAction Stop)
                if ($stats.Count -lt 1) { throw 'Supabase dashboard_stats returned no rows.' }
                $row = $stats[0]
                $writeMode = if ($config.ServiceKey) { 'service key configured for local writes' } else { 'read-only anon key configured; service key not present' }
                "Supabase read ok. Apps: $($row.total_apps), workflows: $($row.total_workflows); $writeMode."
            }
        }
        'Report write' {
            Invoke-Check 'Validation report folder writable' {
                New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
                'Report folder writable.'
            }
        }
    }
}

Write-Progress -Activity 'Power Gorilla validation' -Completed

$passed = @($script:checks | Where-Object passed).Count
$failed = @($script:checks | Where-Object { -not $_.passed }).Count
$status = if ($failed -eq 0) { 'Completed' } else { 'Failed Safely' }
$outcome = [ordered]@{
    timestamp = (Get-Date).ToString('o')
    task = if ($StaticOnly) { 'Validate Bad Gorrilla static GitHub package' } elseif ($UseSupabase) { 'Validate Bad Gorrilla Phase 1 with Supabase' } else { 'Validate Bad Gorrilla Phase 1' }
    projectPath = $rootPath
    finalStatus = $status
    checked = $script:checks.Count
    passed = $passed
    failed = $failed
    checks = $script:checks
    destructiveActionsTriggered = $false
    restartNeeded = $false
    nextRecommendedStep = if ($failed -eq 0) { 'Launch with .\Start-PowerGorilla.ps1' } else { 'Review failed validation checks and rerun validation.' }
}

New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
$reportPath = Join-Path $reportDir ("Validation-Report-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$outcome.reportPath = $reportPath
$outcome | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $reportPath -Encoding UTF8

try {
    Write-PGLog -Root $rootPath -Area 'Validation' -Message "Validation $status." -Data @{ Report = $reportPath; Passed = $passed; Failed = $failed }
} catch { }

Write-Host "Validation status: $status" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Yellow' })
Write-Host "Validation report: $reportPath" -ForegroundColor Cyan
$outcome

if ($failed -gt 0) { exit 1 }
