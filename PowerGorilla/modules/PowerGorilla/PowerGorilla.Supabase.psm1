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

# Config loaded from PowerGorilla\.env.ps1.
$script:SupabaseConfig = $null

function Get-GorProjectRoot {
    return (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
}

function Get-GorValue {
    param(
        [AllowNull()]$Object,
        [Parameter(Mandatory)][string[]]$Names,
        [AllowNull()]$Default = $null
    )

    if ($null -eq $Object) { return $Default }
    foreach ($name in $Names) {
        $property = $Object.PSObject.Properties[$name]
        if ($property -and $null -ne $property.Value) {
            return $property.Value
        }
    }
    return $Default
}

function Split-GorChunk {
    param(
        [Parameter(Mandatory)][object[]]$Items,
        [ValidateRange(1, [int]::MaxValue)][int]$Size
    )

    for ($index = 0; $index -lt $Items.Count; $index += $Size) {
        $last = [Math]::Min($index + $Size - 1, $Items.Count - 1)
        ,@($Items[$index..$last])
    }
}

function Get-GorSupabaseConfig {
    if ($script:SupabaseConfig) { return $script:SupabaseConfig }

    $envFile = Join-Path (Get-GorProjectRoot) '.env.ps1'
    if (Test-Path -LiteralPath $envFile) {
        . $envFile
    }

    $url      = $env:GORILLA_SUPABASE_URL
    $svcKey   = $env:GORILLA_SUPABASE_SERVICE_KEY
    $anonKey  = $env:GORILLA_SUPABASE_ANON_KEY
    $ollamaUrl = if ($env:GORILLA_OLLAMA_URL) { $env:GORILLA_OLLAMA_URL } else { 'http://localhost:11434' }
    $embedModel = if ($env:GORILLA_EMBED_MODEL) { $env:GORILLA_EMBED_MODEL } else { 'nomic-embed-text' }
    $extractModel = if ($env:GORILLA_EXTRACT_MODEL) { $env:GORILLA_EXTRACT_MODEL } else { 'llama3.2' }

    $script:SupabaseConfig = [pscustomobject]@{
        Url          = if ($url) { $url.TrimEnd('/') } else { '' }
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
    $key = if ($UseServiceKey -and $config.ServiceKey) { $config.ServiceKey } else { $config.AnonKey }
    if ([string]::IsNullOrWhiteSpace($config.Url) -or [string]::IsNullOrWhiteSpace($key)) {
        throw 'Optional Supabase free-tier sync is not configured. Local dashboard and local Ollama processing can still run without it.'
    }
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
    $projectRoot = Get-GorProjectRoot
    $pgModule = Join-Path $PSScriptRoot 'PowerGorilla.psm1'
    if (Test-Path -LiteralPath $pgModule) {
        Import-Module $pgModule -Force -ErrorAction SilentlyContinue
    }

    $apps = @()
    if (Get-Command Get-PGAppInventory -ErrorAction SilentlyContinue) {
        $pgRoot = if ($Root) { $Root } else { $projectRoot }
        $apps = @(Get-PGAppInventory -Root $pgRoot -Refresh:$Refresh)
    } else {
        Write-Warning 'gorjson: PowerGorilla module not found. Using empty app list.'
    }

    $valid   = [System.Collections.Generic.List[object]]::new()
    $invalid = [System.Collections.Generic.List[object]]::new()

    foreach ($app in $apps) {
        # Map PG fields to schema fields
        $record = [ordered]@{
            id               = [string](Get-GorValue $app @('Id','id') '')
            name             = [string](Get-GorValue $app @('Name','name') '')
            normalizedName   = [string](Get-GorValue $app @('NormalizedName','normalizedName') '')
            category         = [string](Get-GorValue $app @('Category','category') 'Unknown')
            licenceMode      = [string](Get-GorValue $app @('LicenceMode','licenceMode') 'Unknown')
            isOpenSource     = [bool](Get-GorValue $app @('IsOpenSource','isOpenSource') $false)
            isFreeOrFreeTier = [bool](Get-GorValue $app @('IsFreeOrFreeTier','isFreeOrFreeTier') $false)
            signInMode       = [string](Get-GorValue $app @('SignInMode','signInMode') 'Unknown')
            localMode        = [string](Get-GorValue $app @('LocalMode','localMode') 'Unknown')
            status           = [string](Get-GorValue $app @('Status','status') 'Missing')
            installed        = [bool](Get-GorValue $app @('Installed','installed') $false)
            installPath      = if ($app.InstallPath) { [string]$app.InstallPath } else { $null }
            executablePath   = if ($app.ExecutablePath) { [string]$app.ExecutablePath } else { $null }
            shortcutPath     = if ($app.ShortcutPath) { [string]$app.ShortcutPath } else { $null }
            iconUrl          = if ($app.IconUrl) { [string]$app.IconUrl } else { $null }
            publisher        = if ($app.Publisher) { [string]$app.Publisher } else { $null }
            version          = if ($app.Version) { [string]$app.Version } else { $null }
            lastScanned      = if ($app.LastScanned) { [string]$app.LastScanned } else { (Get-Date).ToString('o') }
            source           = [string](Get-GorValue $app @('Source','source') 'Unknown')
            detectedSource   = if ($app.DetectedSource) { [string]$app.DetectedSource } else { $null }
            seenInWorkflows  = if ($app.SeenInWorkflows) { [int]$app.SeenInWorkflows } else { $null }
            costAllowed      = [bool](Get-GorValue $app @('CostAllowed','costAllowed') $true)
            costPolicy       = [string](Get-GorValue $app @('CostPolicy','costPolicy') 'Local-first; no paid subscriptions; free-tier only when a cloud service is unavoidable.')
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
        Get-Content (Join-Path (Get-GorProjectRoot) 'schema\app.schema.json') -Raw
    } else {
        Get-Content (Join-Path (Get-GorProjectRoot) 'schema\workflow.schema.json') -Raw
    }

    $allResults = [System.Collections.Generic.List[object]]::new()
    $batches    = Split-GorChunk -Items $rows -Size $BatchSize
    $batchNum   = 0

    foreach ($batch in $batches) {
        $batchNum++
        if ($MaxBatches -gt 0 -and $batchNum -gt $MaxBatches) { break }

        $rowsJson = $batch | ConvertTo-Json -Depth 6 -Compress
        $prompt = ""
        if ($Type -eq 'app') {
            $prompt = @"
You are a strict Data Quality Architect specializing in verifying software compliance with open-source and free-tier policy constraints. Your priority is to flag and block paid, trial, commercial, or subscription software.

TARGET JSON SCHEMA:
$schemaJson

INPUT CSV ROWS (JSON array):
$rowsJson

INSTRUCTIONS:
For each input row, extract an application record into a JSON object matching the TARGET JSON SCHEMA exactly. Return a JSON array.

STRICT COST POLICY ENFORCEMENT:
- licenceMode MUST be one of: "Open-source", "Free", "Free-tier", "Built-in", "Paid or trial", "Unknown".
- Scan name, tags, description, source, and pricing information carefully.
- If there is ANY indication of paid licensing, commercial usage, trials, premiums, or subscriptions (e.g. "trial", "paid", "subscription", "commercial", "premium", "m365", "adobe", "license key", "credit card"), you MUST classify licenceMode as "Paid or trial" and set costAllowed to false.
- Set costAllowed to true ONLY for completely open-source, free-tier, built-in, or free software.
- The costPolicy MUST be exactly set to: "Local-first; no paid subscriptions; free-tier only when a cloud service is unavoidable."
- Ensure status is one of: "Installed", "Missing", "Portable", "Store app", "Shortcut only".
- Generate a slug id from the name (lowercase, alphanumeric, hyphens, no spaces).
- Set ollamaEnriched to true.
- Set lastScanned to the current ISO timestamp.

OUTPUT FORMAT:
Return ONLY a valid JSON array of objects. Do not include markdown formatting, backticks (e.g. ```json), or explanatory text.
"@
        } else {
            $prompt = @"
You are a strict visual workflow planner. Your job is to construct multi-app integrations that strictly rely on free-tier, free-subscription, or open-source local-first apps.

TARGET JSON SCHEMA:
$schemaJson

INPUT CSV ROWS (JSON array):
$rowsJson

INSTRUCTIONS:
For each input row, extract a workflow record into a JSON object matching the TARGET JSON SCHEMA exactly. Return a JSON array.

STRICT COST & SECURITY POLICY:
- If the workflow depends on ANY application that is paid, trial, commercial, premium, or subscription-based, you MUST set costAllowed to false.
- Set costAllowed to true ONLY if all apps in the workflow are free-tier, free-subscription, open-source, or built-in.
- The costPolicy MUST be exactly set to: "Local-first; no paid subscriptions; free-tier only when a cloud service is unavoidable."
- Analyze difficulty, setting it strictly to: "Easy", "Medium", "Hard", or "Unknown".
- Evaluate riskLevel (based on whether the workflow initiates OS modifications or system writes), setting it strictly to: "Low", "Medium", or "High".
- Set combinationSize strictly to the integer size of appNames (between 2 and 4).
- Generate a clean slug id from the workflowName.
- Set ollamaEnriched to true.

OUTPUT FORMAT:
Return ONLY a valid JSON array of objects. Do not include markdown formatting, backticks (e.g. ```json), or explanatory text.
"@
        }

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
    $chunks = Split-GorChunk -Items $Records -Size $BatchSize

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
                    cost_allowed    = if ($null -ne $r.costAllowed) { $r.costAllowed } else { $true }
                    cost_policy     = if ($r.costPolicy) { $r.costPolicy } else { 'Local-first; no paid subscriptions; free-tier only when a cloud service is unavoidable.' }
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
                    cost_allowed         = if ($null -ne $r.costAllowed) { $r.costAllowed } else { $true }
                    cost_policy          = if ($r.costPolicy) { $r.costPolicy } else { 'Local-first; no paid subscriptions; free-tier only when a cloud service is unavoidable.' }
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
