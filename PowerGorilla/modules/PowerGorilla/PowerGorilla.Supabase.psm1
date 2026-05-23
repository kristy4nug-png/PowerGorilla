# PowerGorilla.Supabase.psm1
# Supabase + Ollama extensions for PowerShell Gorilla
# Adds: gorjson, gorextract, gorpush, gorembed, gorsearch (semantic)
#
# Usage:
#   gorjson                    - emit app inventory as schema-valid JSON
#   gorextract -Path file.csv  - batch-extract CSV rows via Ollama
#   gorpush    -Type apps      - push local JSON to Supabase
#   gorembed                   - generate Ollama embeddings for all rows
#   gorsearch "query text"     - semantic vector search

Set-StrictMode -Version 2.0

# ─── Config (loaded from .env.ps1 next to this file) ──────────────────────────
$script:SupabaseConfig = $null

function Get-GorSupabaseConfig {
    if ($script:SupabaseConfig) { return $script:SupabaseConfig }

    $envFile = Join-Path $PSScriptRoot '.env.ps1'
    if (Test-Path -LiteralPath $envFile) {
        . $envFile
    }

    $url      = $env:GORILLA_SUPABASE_URL
    $svcKey   = $env:GORILLA_SUPABASE_SERVICE_KEY
    $anonKey  = $env:GORILLA_SUPABASE_ANON_KEY
    $ollamaUrl = if ($env:GORILLA_OLLAMA_URL) { $env:GORILLA_OLLAMA_URL } else { 'http://localhost:11434' }
    $embedModel = if ($env:GORILLA_EMBED_MODEL) { $env:GORILLA_EMBED_MODEL } else { 'nomic-embed-text' }
    $extractModel = if ($env:GORILLA_EXTRACT_MODEL) { $env:GORILLA_EXTRACT_MODEL } else { 'llama3.2' }

    if ([string]::IsNullOrWhiteSpace($url) -or [string]::IsNullOrWhiteSpace($svcKey)) {
        throw "Missing Supabase config. Create '$envFile' with GORILLA_SUPABASE_URL and GORILLA_SUPABASE_SERVICE_KEY, or set environment variables."
    }

    $script:SupabaseConfig = [pscustomobject]@{
        Url          = $url.TrimEnd('/')
        ServiceKey   = $svcKey
        AnonKey      = $anonKey
        OllamaUrl    = $ollamaUrl.TrimEnd('/')
        EmbedModel   = $embedModel
        ExtractModel = $extractModel
    }
    return $script:SupabaseConfig
}

# ─── HTTP helpers ──────────────────────────────────────────────────────────────
function Invoke-SupabaseRest {
    param(
        [Parameter(Mandatory)][string]$Endpoint,
        [string]$Method = 'GET',
        $Body = $null,
        [switch]$UseServiceKey,
        [hashtable]$ExtraHeaders = @{}
    )
    $config = Get-GorSupabaseConfig
    $key = if ($UseServiceKey) { $config.ServiceKey } else { $config.AnonKey }
    $headers = @{
        'apikey'        = $key
        'Authorization' = "Bearer $key"
        'Content-Type'  = 'application/json'
        'Prefer'        = 'return=minimal'
    }
    foreach ($k in $ExtraHeaders.Keys) { $headers[$k] = $ExtraHeaders[$k] }

    $uri = "$($config.Url)/rest/v1/$Endpoint"
    $params = @{ Uri = $uri; Method = $Method; Headers = $headers; ErrorAction = 'Stop' }
    if ($Body) { $params.Body = ($Body | ConvertTo-Json -Depth 12 -Compress) }

    try {
        $response = Invoke-RestMethod @params
        return $response
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        Write-Warning "Supabase REST error [$status] $Endpoint :: $($_.Exception.Message)"
        throw
    }
}

function Invoke-OllamaGenerate {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [string]$Model = '',
        [switch]$ForceJson
    )
    $config = Get-GorSupabaseConfig
    if ([string]::IsNullOrWhiteSpace($Model)) { $Model = $config.ExtractModel }
    $body = @{
        model   = $Model
        prompt  = $Prompt
        stream  = $false
        options = @{ temperature = 0; num_predict = 2048 }
    }
    if ($ForceJson) { $body.format = 'json' }
    $response = Invoke-RestMethod -Uri "$($config.OllamaUrl)/api/generate" `
        -Method POST -Body ($body | ConvertTo-Json -Depth 8) `
        -ContentType 'application/json' -ErrorAction Stop
    return $response.response
}

function Invoke-OllamaEmbed {
    param(
        [Parameter(Mandatory)][string]$Text,
        [string]$Model = ''
    )
    $config = Get-GorSupabaseConfig
    if ([string]::IsNullOrWhiteSpace($Model)) { $Model = $config.EmbedModel }
    $body = @{ model = $Model; input = $Text }
    $response = Invoke-RestMethod -Uri "$($config.OllamaUrl)/api/embed" `
        -Method POST -Body ($body | ConvertTo-Json -Depth 4) `
        -ContentType 'application/json' -ErrorAction Stop
    return $response.embeddings[0]   # float[]
}

# ─── Schema validation (lightweight, no external module needed) ────────────────
function Test-GorAppSchema {
    param([Parameter(Mandatory)]$Record)
    $errors = @()
    foreach ($field in @('id','name','status','category','installed','lastScanned')) {
        if ($null -eq $Record.$field -or [string]::IsNullOrWhiteSpace([string]$Record.$field)) {
            $errors += "Required field missing: $field"
        }
    }
    $validStatuses = @('Installed','Missing','Portable','Store app','Shortcut only')
    if ($Record.status -and $validStatuses -notcontains $Record.status) {
        $errors += "Invalid status: $($Record.status)"
    }
    $validLicences = @('Open-source','Free','Free-tier','Built-in','Paid or trial','Unknown')
    if ($Record.licenceMode -and $validLicences -notcontains $Record.licenceMode) {
        $errors += "Invalid licenceMode: $($Record.licenceMode)"
    }
    return $errors
}

function Test-GorWorkflowSchema {
    param([Parameter(Mandatory)]$Record)
    $errors = @()
    foreach ($field in @('id','workflowName','appNames','combinationSize')) {
        if ($null -eq $Record.$field) { $errors += "Required field missing: $field" }
    }
    if ($Record.combinationSize -and ($Record.combinationSize -lt 2 -or $Record.combinationSize -gt 4)) {
        $errors += "combinationSize must be 2-4"
    }
    if ($Record.appNames -and @($Record.appNames).Count -lt 2) {
        $errors += "appNames must have at least 2 entries"
    }
    $validDiff = @('Easy','Medium','Hard','Unknown')
    if ($Record.difficulty -and $validDiff -notcontains $Record.difficulty) {
        $errors += "Invalid difficulty: $($Record.difficulty)"
    }
    return $errors
}

# ─── gorjson: emit app inventory as schema-valid JSON ─────────────────────────
function Invoke-GorJson {
    [CmdletBinding()]
    param(
        [string]$Root = '',
        [string]$OutFile = '',
        [switch]$Refresh
    )
    Write-Host 'gorjson: Loading app inventory...' -ForegroundColor Cyan

    # Load PowerGorilla module if available
    $pgModule = Join-Path $PSScriptRoot 'modules\PowerGorilla\PowerGorilla.psm1'
    if (Test-Path -LiteralPath $pgModule) {
        Import-Module $pgModule -Force -ErrorAction SilentlyContinue
    }

    $apps = @()
    if (Get-Command Get-PGAppInventory -ErrorAction SilentlyContinue) {
        $pgRoot = if ($Root) { $Root } else { $PSScriptRoot }
        $apps = @(Get-PGAppInventory -Root $pgRoot -Refresh:$Refresh)
    } else {
        Write-Warning 'gorjson: PowerGorilla module not found. Using empty app list.'
    }

    $valid   = [System.Collections.Generic.List[object]]::new()
    $invalid = [System.Collections.Generic.List[object]]::new()

    foreach ($app in $apps) {
        # Map PG fields to schema fields
        $record = [ordered]@{
            id               = [string]($app.Id ?? $app.id ?? '')
            name             = [string]($app.Name ?? $app.name ?? '')
            normalizedName   = [string]($app.NormalizedName ?? $app.normalizedName ?? '')
            category         = [string]($app.Category ?? $app.category ?? 'Unknown')
            licenceMode      = [string]($app.LicenceMode ?? $app.licenceMode ?? 'Unknown')
            isOpenSource     = [bool]($app.IsOpenSource ?? $app.isOpenSource ?? $false)
            isFreeOrFreeTier = [bool]($app.IsFreeOrFreeTier ?? $app.isFreeOrFreeTier ?? $false)
            signInMode       = [string]($app.SignInMode ?? $app.signInMode ?? 'Unknown')
            localMode        = [string]($app.LocalMode ?? $app.localMode ?? 'Unknown')
            status           = [string]($app.Status ?? $app.status ?? 'Missing')
            installed        = [bool]($app.Installed ?? $app.installed ?? $false)
            installPath      = if ($app.InstallPath) { [string]$app.InstallPath } else { $null }
            executablePath   = if ($app.ExecutablePath) { [string]$app.ExecutablePath } else { $null }
            shortcutPath     = if ($app.ShortcutPath) { [string]$app.ShortcutPath } else { $null }
            iconUrl          = if ($app.IconUrl) { [string]$app.IconUrl } else { $null }
            publisher        = if ($app.Publisher) { [string]$app.Publisher } else { $null }
            version          = if ($app.Version) { [string]$app.Version } else { $null }
            lastScanned      = if ($app.LastScanned) { [string]$app.LastScanned } else { (Get-Date).ToString('o') }
            source           = [string]($app.Source ?? $app.source ?? 'Unknown')
            detectedSource   = if ($app.DetectedSource) { [string]$app.DetectedSource } else { $null }
            seenInWorkflows  = if ($app.SeenInWorkflows) { [int]$app.SeenInWorkflows } else { $null }
            ollamaEnriched   = $false
            embeddingModel   = $null
        }

        $errors = Test-GorAppSchema -Record ([pscustomobject]$record)
        if ($errors.Count -eq 0) {
            $valid.Add([pscustomobject]$record)
        } else {
            $invalid.Add([pscustomobject]@{ record = $record; errors = $errors })
        }
    }

    Write-Host "gorjson: $($valid.Count) valid, $($invalid.Count) invalid records" -ForegroundColor $(if ($invalid.Count -gt 0) { 'Yellow' } else { 'Green' })

    if ($invalid.Count -gt 0) {
        Write-Warning "gorjson: $($invalid.Count) records failed schema validation. First error: $($invalid[0].errors[0])"
    }

    $output = [pscustomobject]@{
        schema       = 'gorilla/app/v1'
        generatedAt  = (Get-Date).ToString('o')
        totalRecords = $valid.Count
        invalidCount = $invalid.Count
        apps         = $valid
    }

    if ($OutFile) {
        $output | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $OutFile -Encoding UTF8
        Write-Host "gorjson: Written to $OutFile" -ForegroundColor Green
    } else {
        return $output
    }
}
Set-Alias gorjson Invoke-GorJson

# ─── gorextract: batch-extract CSV rows via Ollama ────────────────────────────
function Invoke-GorExtract {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [ValidateSet('app','workflow')][string]$Type = 'app',
        [int]$BatchSize = 30,
        [int]$MaxBatches = 0,
        [string]$Model = '',
        [string]$OutDir = ''
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "gorextract: File not found: $Path"
    }

    $config   = Get-GorSupabaseConfig
    $model    = if ($Model) { $Model } else { $config.ExtractModel }
    $rows     = @(Import-Csv -LiteralPath $Path)
    $schemaId = if ($Type -eq 'app') { 'gorilla/app/v1' } else { 'gorilla/workflow/v1' }

    Write-Host "gorextract: $($rows.Count) rows from $(Split-Path -Leaf $Path) in batches of $BatchSize using $model" -ForegroundColor Cyan

    $schemaJson = if ($Type -eq 'app') {
        Get-Content (Join-Path $PSScriptRoot 'schema\app.schema.json') -Raw
    } else {
        Get-Content (Join-Path $PSScriptRoot 'schema\workflow.schema.json') -Raw
    }

    $allResults = [System.Collections.Generic.List[object]]::new()
    $batches    = [System.Linq.Enumerable]::Chunk($rows, $BatchSize)
    $batchNum   = 0

    foreach ($batch in $batches) {
        $batchNum++
        if ($MaxBatches -gt 0 -and $batchNum -gt $MaxBatches) { break }

        $rowsJson = $batch | ConvertTo-Json -Depth 6 -Compress
        $prompt = @"
You are a data extraction assistant. Extract structured data from these CSV rows.

TARGET JSON SCHEMA:
$schemaJson

CSV ROWS (JSON array):
$rowsJson

Return a JSON array of objects that match the schema exactly. One object per input row.
Rules:
- Use null for missing optional fields
- licenceMode must be one of: Open-source, Free, Free-tier, Built-in, Paid or trial, Unknown
- status must be one of: Installed, Missing, Portable, Store app, Shortcut only
- combinationSize must be an integer 2-4
- difficulty must be: Easy, Medium, Hard, or Unknown
- riskLevel must be: Low, Medium, or High
- Generate a slug id from the name (lowercase, hyphens, no spaces)
- Set ollamaEnriched to true
- Set lastScanned to current ISO timestamp

Return ONLY the JSON array. No explanation. No markdown. No code blocks.
"@

        Write-Host "  Batch $batchNum / $(if ($MaxBatches -gt 0) { $MaxBatches } else { [Math]::Ceiling($rows.Count / $BatchSize) })..." -ForegroundColor Gray

        try {
            $raw = Invoke-OllamaGenerate -Prompt $prompt -Model $model -ForceJson
            $parsed = $raw | ConvertFrom-Json -ErrorAction Stop

            foreach ($item in $parsed) {
                $errors = if ($Type -eq 'app') {
                    Test-GorAppSchema -Record $item
                } else {
                    Test-GorWorkflowSchema -Record $item
                }

                $extraction = [pscustomobject]@{
                    extractionId    = [guid]::NewGuid().ToString('n')
                    sourceType      = 'csv-chunk'
                    sourceRef       = "$Path :: batch $batchNum"
                    extractedAt     = (Get-Date).ToString('o')
                    model           = $model
                    prompt          = $prompt.Substring(0, [Math]::Min(500, $prompt.Length))
                    result          = $item
                    targetSchema    = $schemaId
                    confidence      = 1.0
                    schemaValid     = ($errors.Count -eq 0)
                    validationErrors = $errors
                }
                $allResults.Add($extraction)
            }
        } catch {
            Write-Warning "  Batch $batchNum failed: $($_.Exception.Message)"
        }

        Start-Sleep -Milliseconds 200  # gentle on Ollama
    }

    $valid = @($allResults | Where-Object { $_.schemaValid })
    Write-Host "gorextract: $($allResults.Count) extracted, $($valid.Count) schema-valid" -ForegroundColor $(if ($valid.Count -eq 0) { 'Red' } else { 'Green' })

    if ($OutDir) {
        $outFile = Join-Path $OutDir "extraction-$(Split-Path -LeafBase $Path)-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $allResults | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $outFile -Encoding UTF8
        Write-Host "gorextract: Results written to $outFile" -ForegroundColor Cyan
    }

    return $allResults
}
Set-Alias gorextract Invoke-GorExtract

# ─── gorpush: push JSON records to Supabase ───────────────────────────────────
function Invoke-GorPush {
    [CmdletBinding()]
    param(
        [ValidateSet('apps','workflows','extractions')][string]$Type = 'apps',
        [object[]]$Records = @(),
        [string]$JsonFile = '',
        [int]$BatchSize = 100,
        [switch]$DryRun
    )

    if ($JsonFile) {
        $data  = Get-Content -LiteralPath $JsonFile -Raw | ConvertFrom-Json
        $Records = if ($data.apps) { $data.apps } elseif ($data -is [array]) { $data } else { @($data) }
    }

    if ($Records.Count -eq 0) {
        Write-Warning 'gorpush: No records to push.'
        return
    }

    $table = switch ($Type) {
        'apps'        { 'apps' }
        'workflows'   { 'workflows' }
        'extractions' { 'ollama_extractions' }
    }

    Write-Host "gorpush: Pushing $($Records.Count) records to Supabase table '$table'..." -ForegroundColor Cyan
    if ($DryRun) { Write-Host '  DRY RUN — no data will be sent' -ForegroundColor Yellow }

    $pushed = 0
    $failed = 0
    $chunks = [System.Linq.Enumerable]::Chunk($Records, $BatchSize)

    foreach ($chunk in $chunks) {
        if ($DryRun) {
            Write-Host "  [DRY RUN] Would push batch of $($chunk.Count) records" -ForegroundColor Gray
            $pushed += $chunk.Count
            continue
        }

        # Map camelCase schema → snake_case Postgres columns
        $rows = $chunk | ForEach-Object {
            $r = $_
            if ($Type -eq 'apps') {
                [ordered]@{
                    id               = $r.id
                    name             = $r.name
                    normalized_name  = $r.normalizedName
                    category         = $r.category
                    licence_mode     = $r.licenceMode
                    is_open_source   = $r.isOpenSource
                    is_free          = $r.isFreeOrFreeTier
                    sign_in_mode     = $r.signInMode
                    local_mode       = $r.localMode
                    status           = $r.status
                    installed        = $r.installed
                    install_path     = $r.installPath
                    executable_path  = $r.executablePath
                    shortcut_path    = $r.shortcutPath
                    icon_url         = $r.iconUrl
                    publisher        = $r.publisher
                    version          = $r.version
                    source           = $r.source
                    detected_source  = $r.detectedSource
                    seen_in_workflows = $r.seenInWorkflows
                    ollama_enriched  = $r.ollamaEnriched
                    embedding_model  = $r.embeddingModel
                    last_scanned     = $r.lastScanned
                }
            } elseif ($Type -eq 'workflows') {
                [ordered]@{
                    id                   = $r.id
                    workflow_name        = $r.workflowName
                    description          = $r.description
                    category             = $r.category
                    app_names            = $r.appNames
                    combination_size     = $r.combinationSize
                    difficulty           = $r.difficulty
                    risk_level           = $r.riskLevel
                    automation_readiness = $r.automationReadiness
                    free_open_source     = $r.freeOpenSourceStatus
                    rank_score           = $r.rankScore
                    sign_in_requirement  = $r.signInRequirement
                    powershell_plan      = $r.powerShellPlan
                    ollama_enriched      = $r.ollamaEnriched
                    embedding_model      = $r.embeddingModel
                }
            } else {
                [ordered]@{
                    extraction_id     = $r.extractionId
                    source_type       = $r.sourceType
                    source_ref        = $r.sourceRef
                    extracted_at      = $r.extractedAt
                    model             = $r.model
                    prompt            = $r.prompt
                    result            = $r.result
                    target_schema     = $r.targetSchema
                    confidence        = $r.confidence
                    schema_valid      = $r.schemaValid
                    validation_errors = $r.validationErrors
                }
            }
        }

        try {
            Invoke-SupabaseRest -Endpoint $table -Method POST -Body @($rows) -UseServiceKey `
                -ExtraHeaders @{ 'Prefer' = 'resolution=merge-duplicates,return=minimal' }
            $pushed += $chunk.Count
            Write-Host "  Pushed batch of $($chunk.Count) records" -ForegroundColor Green
        } catch {
            $failed += $chunk.Count
            Write-Warning "  Batch failed: $($_.Exception.Message)"
        }

        Start-Sleep -Milliseconds 100
    }

    Write-Host "gorpush: Done — $pushed pushed, $failed failed" -ForegroundColor $(if ($failed -gt 0) { 'Yellow' } else { 'Green' })
    return [pscustomobject]@{ Pushed = $pushed; Failed = $failed; Table = $table }
}
Set-Alias gorpush Invoke-GorPush

# ─── gorembed: generate Ollama embeddings and push to pgvector ────────────────
function Invoke-GorEmbed {
    [CmdletBinding()]
    param(
        [ValidateSet('apps','workflows')][string]$Type = 'apps',
        [int]$Limit = 500,
        [string]$Model = '',
        [switch]$DryRun
    )

    $config = Get-GorSupabaseConfig
    $model  = if ($Model) { $Model } else { $config.EmbedModel }

    Write-Host "gorembed: Fetching $Type without embeddings (limit $Limit)..." -ForegroundColor Cyan

    $table  = if ($Type -eq 'apps') { 'apps' } else { 'workflows' }
    $select = if ($Type -eq 'apps') { 'id,name,category,sign_in_mode,local_mode,licence_mode' } `
              else { 'id,workflow_name,description,category,app_names' }

    $records = @(Invoke-SupabaseRest `
        -Endpoint "$table?select=$select&embedding=is.null&limit=$Limit" `
        -UseServiceKey)

    if ($records.Count -eq 0) {
        Write-Host "gorembed: All $Type already have embeddings." -ForegroundColor Green
        return
    }

    Write-Host "gorembed: Embedding $($records.Count) $Type with $model..." -ForegroundColor Cyan
    $done = 0; $failed = 0

    foreach ($rec in $records) {
        $text = if ($Type -eq 'apps') {
            "$($rec.name) $($rec.category) $($rec.licence_mode) $($rec.sign_in_mode) $($rec.local_mode)"
        } else {
            "$($rec.workflow_name) $($rec.description) $($rec.category) $(($rec.app_names -join ' '))"
        }

        if ($DryRun) {
            Write-Host "  [DRY RUN] Would embed: $($rec.id)" -ForegroundColor Gray
            $done++
            continue
        }

        try {
            $embedding = Invoke-OllamaEmbed -Text $text -Model $model
            $embeddingStr = '[' + ($embedding -join ',') + ']'

            Invoke-SupabaseRest `
                -Endpoint "$table?id=eq.$($rec.id)" `
                -Method PATCH `
                -Body @{ embedding = $embeddingStr; embedding_model = $model } `
                -UseServiceKey | Out-Null

            $done++
            if ($done % 50 -eq 0) { Write-Host "  $done / $($records.Count) embedded..." -ForegroundColor Gray }
        } catch {
            Write-Warning "  Failed to embed $($rec.id): $($_.Exception.Message)"
            $failed++
        }

        Start-Sleep -Milliseconds 50
    }

    Write-Host "gorembed: Done — $done embedded, $failed failed" -ForegroundColor $(if ($failed -gt 0) { 'Yellow' } else { 'Green' })
    return [pscustomobject]@{ Done = $done; Failed = $failed; Model = $model }
}
Set-Alias gorembed Invoke-GorEmbed

# ─── gorsemantic: semantic vector search ──────────────────────────────────────
function Invoke-GorSemanticSearch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Query,
        [ValidateSet('apps','workflows','both')][string]$Type = 'both',
        [int]$Limit = 10,
        [string]$Model = ''
    )

    $config = Get-GorSupabaseConfig
    $model  = if ($Model) { $Model } else { $config.EmbedModel }

    Write-Host "gorsemantic: Embedding query '$Query'..." -ForegroundColor Cyan
    $embedding = Invoke-OllamaEmbed -Text $Query -Model $model
    $embeddingStr = '[' + ($embedding -join ',') + ']'

    if ($Type -eq 'apps' -or $Type -eq 'both') {
        Write-Host 'gorsemantic: Searching apps...' -ForegroundColor Cyan
        $appResults = Invoke-SupabaseRest `
            -Endpoint "rpc/search_apps" -Method POST `
            -Body @{ query_embedding = $embeddingStr; match_count = $Limit } `
            -UseServiceKey

        if ($appResults.Count -gt 0) {
            Write-Host "`nAPPS (top $Limit by similarity):" -ForegroundColor Yellow
            $appResults | Format-Table id, name, category, status, similarity -AutoSize
        }
    }

    if ($Type -eq 'workflows' -or $Type -eq 'both') {
        Write-Host 'gorsemantic: Searching workflows...' -ForegroundColor Cyan
        $wfResults = Invoke-SupabaseRest `
            -Endpoint "rpc/search_workflows" -Method POST `
            -Body @{ query_embedding = $embeddingStr; match_count = $Limit } `
            -UseServiceKey

        if ($wfResults.Count -gt 0) {
            Write-Host "`nWORKFLOWS (top $Limit by similarity):" -ForegroundColor Yellow
            $wfResults | Format-Table id, workflow_name, category, similarity -AutoSize
        }
    }
}
Set-Alias gorsemantic Invoke-GorSemanticSearch

Write-Host 'PowerGorilla Supabase extensions loaded.' -ForegroundColor DarkGray
Write-Host '  gorjson | gorextract | gorpush | gorembed | gorsemantic' -ForegroundColor DarkGray
