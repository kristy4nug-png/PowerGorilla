$script:PGDatasetSpecs = @(
    [pscustomobject]@{ Type = 'Apps';  Size = 1; ExpectedName = 'Proper_Apps_Shortlist.csv' },
    [pscustomobject]@{ Type = 'Two';   Size = 2; ExpectedName = 'Two_App_20K_Free_OpenSource_Combinations.csv' },
    [pscustomobject]@{ Type = 'Three'; Size = 3; ExpectedName = 'Three_App_200K_Free_OpenSource_Integrations.csv' },
    [pscustomobject]@{ Type = 'Four';  Size = 4; ExpectedName = 'Four_App_400K_Free_OpenSource_Integrations.csv' }
)

function Get-PGRoot {
    param([string]$Root)

    if ($Root) {
        return (Resolve-Path -LiteralPath $Root).Path
    }

    return (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
}

function Join-PGPath {
    param(
        [string]$Root,
        [Parameter(Mandatory)][string[]]$Child
    )

    $path = Get-PGRoot -Root $Root
    foreach ($part in $Child) {
        $path = Join-Path -Path $path -ChildPath $part
    }
    return $path
}

function New-PGDirectory {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function ConvertTo-PGJson {
    param(
        [Parameter(ValueFromPipeline)]$InputObject,
        [int]$Depth = 10
    )
    process {
        $InputObject | ConvertTo-Json -Depth $Depth
    }
}

function ConvertTo-PGSafeLogText {
    param([AllowNull()][object]$Value)

    $text = if ($null -eq $Value) { '' } else { [string]$Value }
    $patterns = @(
        '(?i)(password|passwd|pwd)\s*[:=]\s*[^,;\s]+',
        '(?i)(token|secret|apikey|api_key|cookie|session|authorization)\s*[:=]\s*[^,;\s]+',
        '(?i)Bearer\s+[A-Za-z0-9\._\-]+'
    )
    foreach ($pattern in $patterns) {
        $text = [regex]::Replace($text, $pattern, '$1=[REDACTED]')
    }
    return $text
}

function Write-PGLog {
    [CmdletBinding()]
    param(
        [string]$Root,
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO','WARN','ERROR','SKIP','CONFIRMED','DRYRUN')]
        [string]$Level = 'INFO',
        [string]$Area = 'General',
        [AllowNull()][object]$Data
    )

    $rootPath = Get-PGRoot -Root $Root
    $logDir = Join-Path $rootPath 'logs'
    New-PGDirectory -Path $logDir
    $logPath = Join-Path $logDir ("PowerGorilla-{0}.jsonl" -f (Get-Date -Format 'yyyyMMdd'))

    $record = [ordered]@{
        timestamp = (Get-Date).ToString('o')
        level = $Level
        area = $Area
        message = ConvertTo-PGSafeLogText $Message
        data = if ($null -eq $Data) { $null } else { ConvertTo-PGSafeLogText (($Data | ConvertTo-Json -Depth 8 -Compress)) }
    }

    ($record | ConvertTo-Json -Compress -Depth 8) | Add-Content -LiteralPath $logPath -Encoding UTF8
}

function Initialize-PGProject {
    [CmdletBinding()]
    param([string]$Root)

    $rootPath = Get-PGRoot -Root $Root
    foreach ($dir in @(
        'app','data','data\imports','data\processed','data\icons','logs','modules',
        'modules\PowerGorilla','reports','scripts','ui','ui\assets','backups','docs'
    )) {
        New-PGDirectory -Path (Join-Path $rootPath $dir)
    }

    $settingsPath = Join-Path $rootPath 'data\processed\settings.json'
    if (-not (Test-Path -LiteralPath $settingsPath)) {
        $settings = [ordered]@{
            safetyMode = 'Strict Safe Mode'
            adminMode = $false
            experimentalMode = $false
            allowDestructiveActions = $false
            allowCredentialStorage = $false
            created = (Get-Date).ToString('o')
        }
        $settings | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $settingsPath -Encoding UTF8
    }

    $fallbackSvg = @'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96" role="img" aria-label="Fallback app icon">
  <defs>
    <linearGradient id="g" x1="0" x2="1" y1="0" y2="1">
      <stop offset="0" stop-color="#1f7a6d"/>
      <stop offset="0.55" stop-color="#2459a8"/>
      <stop offset="1" stop-color="#7b3f98"/>
    </linearGradient>
  </defs>
  <rect x="10" y="10" width="76" height="76" rx="18" fill="url(#g)"/>
  <rect x="25" y="25" width="18" height="18" rx="5" fill="#ffffff" opacity=".92"/>
  <rect x="53" y="25" width="18" height="18" rx="5" fill="#ffffff" opacity=".72"/>
  <rect x="25" y="53" width="18" height="18" rx="5" fill="#ffffff" opacity=".72"/>
  <rect x="53" y="53" width="18" height="18" rx="5" fill="#ffffff" opacity=".92"/>
</svg>
'@
    $fallbackPaths = @(
        (Join-Path $rootPath 'data\icons\fallback-app.svg'),
        (Join-Path $rootPath 'ui\assets\fallback-app.svg')
    )
    foreach ($path in $fallbackPaths) {
        if (-not (Test-Path -LiteralPath $path)) {
            $fallbackSvg | Set-Content -LiteralPath $path -Encoding UTF8
        }
    }

    Write-PGLog -Root $rootPath -Area 'Setup' -Message 'Project structure initialized.'
    return [pscustomobject]@{
        Root = $rootPath
        Imports = Join-Path $rootPath 'data\imports'
        Processed = Join-Path $rootPath 'data\processed'
        Icons = Join-Path $rootPath 'data\icons'
        Logs = Join-Path $rootPath 'logs'
    }
}

function Get-PGDatasetStatus {
    [CmdletBinding()]
    param([string]$Root)

    $rootPath = Get-PGRoot -Root $Root
    $importDir = Join-Path $rootPath 'data\imports'
    foreach ($spec in $script:PGDatasetSpecs) {
        $path = Join-Path $importDir $spec.ExpectedName
        [pscustomobject]@{
            Type = $spec.Type
            CombinationSize = $spec.Size
            ExpectedName = $spec.ExpectedName
            Path = $path
            Exists = Test-Path -LiteralPath $path
            Length = if (Test-Path -LiteralPath $path) { (Get-Item -LiteralPath $path).Length } else { 0 }
            LastWriteTime = if (Test-Path -LiteralPath $path) { (Get-Item -LiteralPath $path).LastWriteTime } else { $null }
        }
    }
}

function Normalize-PGAppName {
    param([AllowNull()][string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return '' }
    $value = $Name.ToLowerInvariant()
    $value = [regex]::Replace($value, '\([^\)]*\)', ' ')
    $value = [regex]::Replace($value, '[^a-z0-9]+', ' ')
    $value = [regex]::Replace($value, '\b(inc|llc|ltd|desktop|app|application|version|x64|x86|64 bit|32 bit)\b', ' ')
    $value = [regex]::Replace($value, '\s+', ' ').Trim()
    return $value
}

function New-PGId {
    param([AllowNull()][string]$Name)
    $normalized = Normalize-PGAppName $Name
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return ([guid]::NewGuid().ToString('n'))
    }
    $id = [regex]::Replace($normalized, '[^a-z0-9]+', '-').Trim('-')
    if ([string]::IsNullOrWhiteSpace($id)) { $id = [guid]::NewGuid().ToString('n') }
    return $id
}

function Get-PGPropertyValue {
    param(
        [Parameter(Mandatory)]$Row,
        [Parameter(Mandatory)][string[]]$Candidates
    )

    $properties = @($Row.PSObject.Properties)
    foreach ($candidate in $Candidates) {
        $candidateKey = [regex]::Replace($candidate.ToLowerInvariant(), '[^a-z0-9]', '')
        foreach ($property in $properties) {
            $propertyKey = [regex]::Replace(([string]$property.Name).ToLowerInvariant(), '[^a-z0-9]', '')
            if ($propertyKey -eq $candidateKey -and -not [string]::IsNullOrWhiteSpace([string]$property.Value)) {
                return [string]$property.Value
            }
        }
    }

    foreach ($candidate in $Candidates) {
        $candidateKey = [regex]::Replace($candidate.ToLowerInvariant(), '[^a-z0-9]', '')
        foreach ($property in $properties) {
            $propertyKey = [regex]::Replace(([string]$property.Name).ToLowerInvariant(), '[^a-z0-9]', '')
            if ($propertyKey.Contains($candidateKey) -and -not [string]::IsNullOrWhiteSpace([string]$property.Value)) {
                return [string]$property.Value
            }
        }
    }

    return $null
}

function Get-PGLicenseProfile {
    param([AllowNull()][string]$Name, [AllowNull()][string]$RawLicense, [AllowNull()][string]$Tags)

    $haystack = ('{0} {1} {2}' -f $Name, $RawLicense, $Tags).ToLowerInvariant()
    $openSource = $false
    $free = $false
    $mode = 'Unknown'

    if ($haystack -match 'open.?source|oss|gpl|mit|apache|bsd|mozilla public|mpl') {
        $openSource = $true
        $free = $true
        $mode = 'Open-source'
    } elseif ($haystack -match 'built.?in|windows|microsoft store included') {
        $free = $true
        $mode = 'Built-in'
    } elseif ($haystack -match 'free.?tier|freemium') {
        $free = $true
        $mode = 'Free-tier'
    } elseif ($haystack -match '\bfree\b|no cost|gratis') {
        $free = $true
        $mode = 'Free'
    } elseif ($haystack -match 'paid|subscription|trial|commercial') {
        $mode = 'Paid or trial'
    }

    [pscustomobject]@{
        LicenceMode = $mode
        IsOpenSource = $openSource
        IsFreeOrFreeTier = $free
    }
}

function Get-PGSignInClassification {
    param(
        [AllowNull()][string]$Name,
        [AllowNull()][string]$Category,
        [AllowNull()][string]$Raw
    )

    $text = ('{0} {1} {2}' -f $Name, $Category, $Raw).ToLowerInvariant()
    $localPatterns = 'powershell|terminal|cmd|ollama|git|python|node|7-zip|7zip|vlc|ffmpeg|obs|gimp|inkscape|krita|blender|audacity|notepad\+\+|notepad|visual studio code|vs code|libreoffice|everything|paint\.net|winscp|putty|rufus|calibre'
    $cloudRequired = 'google drive|gmail|slack|teams|onedrive|dropbox|notion|trello|asana|spotify|discord|zoom|canva|figma|github desktop|outlook|office|adobe creative cloud'
    $cloudOptional = 'chrome|edge|firefox|brave|vscode|visual studio|github|steam|epic games|obsidian|bitwarden'

    if ($text -match $localPatterns) {
        return [pscustomobject]@{
            SignInMode = 'No sign-in needed'
            LocalMode = 'Local mode available'
            RequiredSignIns = @()
        }
    }
    if ($text -match $cloudRequired) {
        return [pscustomobject]@{
            SignInMode = 'Sign-in required for cloud features'
            LocalMode = 'Local mode may be limited'
            RequiredSignIns = @($Name)
        }
    }
    if ($text -match $cloudOptional) {
        return [pscustomobject]@{
            SignInMode = 'Optional sign-in'
            LocalMode = 'Local mode available'
            RequiredSignIns = @()
        }
    }

    return [pscustomobject]@{
        SignInMode = 'Unknown'
        LocalMode = 'Unknown'
        RequiredSignIns = @()
    }
}

function Resolve-PGIconSourcePath {
    param([AllowNull()][string]$RawPath)

    if ([string]::IsNullOrWhiteSpace($RawPath)) { return $null }
    $value = [Environment]::ExpandEnvironmentVariables($RawPath.Trim())
    $value = $value.Trim('"')

    if ($value -match '^(.+?)(,\-?\d+)$') {
        $candidate = $matches[1].Trim('"')
        if (Test-Path -LiteralPath $candidate) { return (Resolve-Path -LiteralPath $candidate).Path }
    }

    if (Test-Path -LiteralPath $value) {
        return (Resolve-Path -LiteralPath $value).Path
    }

    $first = ($value -split ',')[0].Trim('"')
    if (Test-Path -LiteralPath $first) {
        return (Resolve-Path -LiteralPath $first).Path
    }

    return $null
}

function Get-PGShortcutInfo {
    param([Parameter(Mandatory)][string]$Path)

    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($Path)
        [pscustomobject]@{
            Name = [IO.Path]::GetFileNameWithoutExtension($Path)
            ShortcutPath = $Path
            TargetPath = $shortcut.TargetPath
            IconLocation = $shortcut.IconLocation
            WorkingDirectory = $shortcut.WorkingDirectory
        }
    } catch {
        [pscustomobject]@{
            Name = [IO.Path]::GetFileNameWithoutExtension($Path)
            ShortcutPath = $Path
            TargetPath = $null
            IconLocation = $null
            WorkingDirectory = $null
        }
    }
}

function Get-PGDetectedApps {
    [CmdletBinding()]
    param([string]$Root)

    $rows = New-Object System.Collections.Generic.List[object]

    $registryPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($path in $registryPaths) {
        try {
            foreach ($item in Get-ItemProperty -Path $path -ErrorAction SilentlyContinue) {
                if ([string]::IsNullOrWhiteSpace([string]$item.DisplayName)) { continue }
                $icon = Resolve-PGIconSourcePath $item.DisplayIcon
                $exe = $icon
                $rows.Add([pscustomobject]@{
                    Name = [string]$item.DisplayName
                    NormalizedName = Normalize-PGAppName $item.DisplayName
                    Source = 'Registry'
                    Status = 'Installed'
                    InstallPath = [string]$item.InstallLocation
                    ExecutablePath = $exe
                    ShortcutPath = $null
                    IconSourcePath = $icon
                    Publisher = [string]$item.Publisher
                    Version = [string]$item.DisplayVersion
                })
            }
        } catch {
            Write-PGLog -Root $Root -Level 'WARN' -Area 'Inventory' -Message "Registry scan skipped for $path" -Data $_.Exception.Message
        }
    }

    $shortcutRoots = @(
        [Environment]::GetFolderPath('Programs'),
        [Environment]::GetFolderPath('CommonPrograms'),
        [Environment]::GetFolderPath('Desktop'),
        [Environment]::GetFolderPath('CommonDesktopDirectory')
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) } | Select-Object -Unique

    foreach ($shortcutRoot in $shortcutRoots) {
        foreach ($lnk in Get-ChildItem -LiteralPath $shortcutRoot -Recurse -File -Filter '*.lnk' -ErrorAction SilentlyContinue) {
            $info = Get-PGShortcutInfo -Path $lnk.FullName
            $target = Resolve-PGIconSourcePath $info.TargetPath
            $icon = Resolve-PGIconSourcePath $info.IconLocation
            if (-not $icon) { $icon = $target }
            $status = if ($target) { 'Installed' } else { 'Shortcut only' }
            $rows.Add([pscustomobject]@{
                Name = $info.Name
                NormalizedName = Normalize-PGAppName $info.Name
                Source = 'Shortcut'
                Status = $status
                InstallPath = $info.WorkingDirectory
                ExecutablePath = $target
                ShortcutPath = $info.ShortcutPath
                IconSourcePath = $icon
                Publisher = $null
                Version = $null
            })
        }
    }

    try {
        if (Get-Command Get-StartApps -ErrorAction SilentlyContinue) {
            foreach ($app in Get-StartApps -ErrorAction SilentlyContinue) {
                if ([string]::IsNullOrWhiteSpace([string]$app.Name)) { continue }
                $rows.Add([pscustomobject]@{
                    Name = [string]$app.Name
                    NormalizedName = Normalize-PGAppName $app.Name
                    Source = 'StartApps'
                    Status = 'Store app'
                    InstallPath = $null
                    ExecutablePath = $null
                    ShortcutPath = $app.AppID
                    IconSourcePath = $null
                    Publisher = $null
                    Version = $null
                })
            }
        }
    } catch {
        Write-PGLog -Root $Root -Level 'WARN' -Area 'Inventory' -Message 'Get-StartApps scan skipped.' -Data $_.Exception.Message
    }

    $best = [ordered]@{}
    foreach ($row in $rows) {
        if ([string]::IsNullOrWhiteSpace($row.NormalizedName)) { continue }
        $key = $row.NormalizedName
        if (-not $best.Contains($key)) {
            $best[$key] = $row
            continue
        }

        $current = $best[$key]
        if (($current.Source -ne 'Registry' -and $row.Source -eq 'Registry') -or
            ([string]::IsNullOrWhiteSpace($current.ExecutablePath) -and -not [string]::IsNullOrWhiteSpace($row.ExecutablePath)) -or
            ([string]::IsNullOrWhiteSpace($current.IconSourcePath) -and -not [string]::IsNullOrWhiteSpace($row.IconSourcePath))) {
            $best[$key] = $row
        }
    }

    return @($best.Values)
}

function Import-PGProperApps {
    [CmdletBinding()]
    param([string]$Root)

    $dataset = Get-PGDatasetStatus -Root $Root | Where-Object Type -eq 'Apps' | Select-Object -First 1
    if (-not $dataset -or -not $dataset.Exists) {
        return @(Get-PGAppCandidatesFromIntegrationDatasets -Root $Root)
    }

    $rows = Import-Csv -LiteralPath $dataset.Path
    $out = New-Object System.Collections.Generic.List[object]
    foreach ($row in $rows) {
        $name = Get-PGPropertyValue -Row $row -Candidates @('Name','App','App Name','AppName','Application','Application Name','Proper App','Tool','Software')
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        $category = Get-PGPropertyValue -Row $row -Candidates @('Category','Type','Group','Domain','Workflow Category')
        $license = Get-PGPropertyValue -Row $row -Candidates @('License','Licence','License Mode','Licence Mode','Free Open Source Status','Cost','Pricing')
        $tags = Get-PGPropertyValue -Row $row -Candidates @('Tags','Notes','Status','Open Source','Free')
        $profile = Get-PGLicenseProfile -Name $name -RawLicense $license -Tags $tags
        $signIn = Get-PGSignInClassification -Name $name -Category $category -Raw $tags
        $out.Add([pscustomobject]@{
            Name = $name.Trim()
            NormalizedName = Normalize-PGAppName $name
            Category = if ($category) { $category } else { 'Unknown' }
            LicenceMode = $profile.LicenceMode
            IsOpenSource = $profile.IsOpenSource
            IsFreeOrFreeTier = $profile.IsFreeOrFreeTier
            SignInMode = $signIn.SignInMode
            LocalMode = $signIn.LocalMode
            Source = 'Proper_Apps_Shortlist.csv'
            Raw = $row
        })
    }
    return @($out)
}

function Get-PGAppCandidatesFromIntegrationDatasets {
    [CmdletBinding()]
    param(
        [string]$Root,
        [int]$MaxRowsPerDataset = 0
    )

    $rootPath = Get-PGRoot -Root $Root
    $cachePath = Join-Path $rootPath 'data\processed\app-candidates-from-integrations.json'
    if ((Test-Path -LiteralPath $cachePath) -and $MaxRowsPerDataset -eq 0) {
        try { return @(Get-Content -LiteralPath $cachePath -Raw | ConvertFrom-Json) } catch { }
    }

    $datasets = @(Get-PGDatasetStatus -Root $rootPath | Where-Object { $_.CombinationSize -gt 1 -and $_.Exists })
    $map = @{}

    foreach ($dataset in $datasets) {
        $rowIndex = 0
        foreach ($row in Import-Csv -LiteralPath $dataset.Path) {
            $rowIndex++
            if ($MaxRowsPerDataset -gt 0 -and $rowIndex -gt $MaxRowsPerDataset) { break }

            $apps = @(Get-PGIntegrationApps -Row $row -Size $dataset.CombinationSize)
            for ($i = 0; $i -lt $apps.Count; $i++) {
                $name = $apps[$i]
                if ([string]::IsNullOrWhiteSpace($name)) { continue }
                $normalized = Normalize-PGAppName $name
                if ([string]::IsNullOrWhiteSpace($normalized)) { continue }

                if (-not $map.ContainsKey($normalized)) {
                    $map[$normalized] = [ordered]@{
                        Name = $name.Trim()
                        NormalizedName = $normalized
                        Category = 'Imported integration app'
                        LicenceMode = 'Unknown'
                        IsOpenSource = $false
                        IsFreeOrFreeTier = $false
                        SignInMode = 'Unknown'
                        LocalMode = 'Unknown'
                        Source = 'Derived from integration CSVs'
                        SeenInWorkflows = 0
                    }
                }

                $categoryCandidates = @(
                    "App $([char](65 + $i)) Category",
                    "App$($i + 1) Category",
                    "Application $($i + 1) Category"
                )
                $category = Get-PGPropertyValue -Row $row -Candidates $categoryCandidates
                if ($category -and $map[$normalized].Category -eq 'Imported integration app') {
                    $map[$normalized].Category = $category
                }

                $licenceText = Get-PGPropertyValue -Row $row -Candidates @('Free/Open-Source Use Mode','Free/Open-Source Mode','Open Source Involved','Open Source Included','Open-Source Count','Open Source Count')
                $profile = Get-PGLicenseProfile -Name $name -RawLicense $licenceText -Tags $licenceText
                if ($profile.IsOpenSource) { $map[$normalized].IsOpenSource = $true }
                if ($profile.IsFreeOrFreeTier) { $map[$normalized].IsFreeOrFreeTier = $true }
                if ($profile.LicenceMode -ne 'Unknown') { $map[$normalized].LicenceMode = $profile.LicenceMode }

                $signin = Get-PGSignInClassification -Name $name -Category $map[$normalized].Category -Raw $licenceText
                if ($map[$normalized].SignInMode -eq 'Unknown' -or $signin.SignInMode -ne 'Unknown') {
                    $map[$normalized].SignInMode = $signin.SignInMode
                    $map[$normalized].LocalMode = $signin.LocalMode
                }

                $map[$normalized].SeenInWorkflows++
            }
        }
    }

    $result = @($map.Values | ForEach-Object { [pscustomobject]$_ } | Sort-Object Name)
    if ($MaxRowsPerDataset -eq 0) {
        $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $cachePath -Encoding UTF8
        Write-PGLog -Root $rootPath -Area 'Imports' -Message 'Derived app shortlist from integration datasets because Proper_Apps_Shortlist.csv is not present.' -Data @{ Count = $result.Count }
    }

    return $result
}

function Resolve-PGDetectedApp {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][object[]]$DetectedApps
    )

    $normalized = Normalize-PGAppName $Name
    if ([string]::IsNullOrWhiteSpace($normalized)) { return $null }

    $exact = @($DetectedApps | Where-Object { $_.NormalizedName -eq $normalized } | Select-Object -First 1)
    if ($exact.Count -gt 0) { return $exact[0] }

    $contains = @($DetectedApps | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_.NormalizedName) -and
        ($_.NormalizedName.Contains($normalized) -or $normalized.Contains($_.NormalizedName))
    } | Sort-Object @{Expression = { [Math]::Abs($_.NormalizedName.Length - $normalized.Length) }} | Select-Object -First 1)
    if ($contains.Count -gt 0) { return $contains[0] }

    return $null
}

function Get-PGAppInventory {
    [CmdletBinding()]
    param(
        [string]$Root,
        [switch]$Refresh,
        [switch]$ExtractIcons
    )

    $rootPath = Get-PGRoot -Root $Root
    Initialize-PGProject -Root $rootPath | Out-Null
    $processedPath = Join-Path $rootPath 'data\processed\app-inventory.json'
    if (-not $Refresh -and (Test-Path -LiteralPath $processedPath)) {
        return @(Get-Content -LiteralPath $processedPath -Raw | ConvertFrom-Json)
    }

    $detected = @(Get-PGDetectedApps -Root $rootPath)
    $proper = @(Import-PGProperApps -Root $rootPath)
    $inventory = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    if ($proper.Count -gt 0) {
        foreach ($app in $proper) {
            $match = Resolve-PGDetectedApp -Name $app.Name -DetectedApps $detected
            $status = if ($match) { $match.Status } else { 'Missing' }
            $key = $app.NormalizedName
            if ($seen.ContainsKey($key)) { continue }
            $seen[$key] = $true
            $inventory.Add([pscustomobject]@{
                Id = New-PGId $app.Name
                Name = $app.Name
                NormalizedName = $app.NormalizedName
                Category = $app.Category
                LicenceMode = $app.LicenceMode
                IsOpenSource = [bool]$app.IsOpenSource
                IsFreeOrFreeTier = [bool]$app.IsFreeOrFreeTier
                SignInMode = $app.SignInMode
                LocalMode = $app.LocalMode
                Status = $status
                Installed = [bool]$match
                InstallPath = if ($match) { $match.InstallPath } else { $null }
                ExecutablePath = if ($match) { $match.ExecutablePath } else { $null }
                ShortcutPath = if ($match) { $match.ShortcutPath } else { $null }
                IconSourcePath = if ($match) { $match.IconSourcePath } else { $null }
                IconFile = 'fallback-app.svg'
                IconUrl = '../data/icons/fallback-app.svg'
                Source = $app.Source
                DetectedSource = if ($match) { $match.Source } else { $null }
                Publisher = if ($match) { $match.Publisher } else { $null }
                Version = if ($match) { $match.Version } else { $null }
                LastScanned = (Get-Date).ToString('o')
            })
        }
    }

    foreach ($app in $detected) {
        $key = $app.NormalizedName
        if ([string]::IsNullOrWhiteSpace($key) -or $seen.ContainsKey($key)) { continue }
        $seen[$key] = $true
        $profile = Get-PGLicenseProfile -Name $app.Name -RawLicense '' -Tags $app.Source
        $signIn = Get-PGSignInClassification -Name $app.Name -Category 'Detected installed app' -Raw $app.Source
        $status = if ($app.Status) { $app.Status } else { 'Installed' }
        if ($app.ExecutablePath -and ($app.ExecutablePath -match '\\AppData\\|\\Portable\\|\\scoop\\|\\tools\\')) {
            $status = 'Portable'
        }
        $inventory.Add([pscustomobject]@{
            Id = New-PGId $app.Name
            Name = $app.Name
            NormalizedName = $app.NormalizedName
            Category = 'Detected installed app'
            LicenceMode = $profile.LicenceMode
            IsOpenSource = [bool]$profile.IsOpenSource
            IsFreeOrFreeTier = [bool]$profile.IsFreeOrFreeTier
            SignInMode = $signIn.SignInMode
            LocalMode = $signIn.LocalMode
            Status = $status
            Installed = $true
            InstallPath = $app.InstallPath
            ExecutablePath = $app.ExecutablePath
            ShortcutPath = $app.ShortcutPath
            IconSourcePath = $app.IconSourcePath
            IconFile = 'fallback-app.svg'
            IconUrl = '../data/icons/fallback-app.svg'
            Source = 'Detected laptop inventory'
            DetectedSource = $app.Source
            Publisher = $app.Publisher
            Version = $app.Version
            LastScanned = (Get-Date).ToString('o')
        })
    }

    $result = @($inventory | Sort-Object Name)
    if ($ExtractIcons) {
        $result = @(Update-PGIconCache -Root $rootPath -Apps $result)
    }

    $result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $processedPath -Encoding UTF8
    Write-PGLog -Root $rootPath -Area 'Inventory' -Message 'App inventory refreshed.' -Data @{ Count = $result.Count; ProperDatasetPresent = ($proper.Count -gt 0) }
    return $result
}

function Update-PGIconCache {
    [CmdletBinding()]
    param(
        [string]$Root,
        [Parameter(Mandatory)][object[]]$Apps,
        [switch]$Force
    )

    $rootPath = Get-PGRoot -Root $Root
    $iconDir = Join-Path $rootPath 'data\icons'
    New-PGDirectory -Path $iconDir
    $fallback = Join-Path $iconDir 'fallback-app.svg'
    if (-not (Test-Path -LiteralPath $fallback)) {
        Initialize-PGProject -Root $rootPath | Out-Null
    }

    Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue

    foreach ($app in $Apps) {
        $app.IconFile = 'fallback-app.svg'
        $app.IconUrl = '../data/icons/fallback-app.svg'
        $source = Resolve-PGIconSourcePath $app.IconSourcePath
        if (-not $source -and $app.ExecutablePath) { $source = Resolve-PGIconSourcePath $app.ExecutablePath }
        if (-not $source -and $app.ShortcutPath -and (Test-Path -LiteralPath $app.ShortcutPath) -and $app.ShortcutPath -like '*.lnk') {
            $shortcut = Get-PGShortcutInfo -Path $app.ShortcutPath
            $source = Resolve-PGIconSourcePath $shortcut.IconLocation
            if (-not $source) { $source = Resolve-PGIconSourcePath $shortcut.TargetPath }
        }
        if (-not $source) { continue }

        $safeId = New-PGId $app.Name
        $outFile = Join-Path $iconDir ("{0}.png" -f $safeId)
        if ((Test-Path -LiteralPath $outFile) -and -not $Force) {
            $app.IconFile = [IO.Path]::GetFileName($outFile)
            $app.IconUrl = '../data/icons/' + $app.IconFile
            continue
        }

        try {
            $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($source)
            if ($null -ne $icon) {
                $bitmap = $icon.ToBitmap()
                $bitmap.Save($outFile, [System.Drawing.Imaging.ImageFormat]::Png)
                $bitmap.Dispose()
                $icon.Dispose()
                $app.IconFile = [IO.Path]::GetFileName($outFile)
                $app.IconUrl = '../data/icons/' + $app.IconFile
                $app.IconExtracted = $true
                $app.IconExtractedFrom = $source
            }
        } catch {
            $app.IconExtracted = $false
            $app.IconExtractionError = $_.Exception.Message
        }
    }

    return $Apps
}

function Get-PGIntegrationApps {
    param(
        [Parameter(Mandatory)]$Row,
        [int]$Size
    )

    $apps = New-Object System.Collections.Generic.List[string]
    $ordinalCandidates = @(
        @('App1','App 1','Application1','Application 1','Tool1','Tool 1','Software1','Software 1','First App','App A','Tool A'),
        @('App2','App 2','Application2','Application 2','Tool2','Tool 2','Software2','Software 2','Second App','App B','Tool B'),
        @('App3','App 3','Application3','Application 3','Tool3','Tool 3','Software3','Software 3','Third App','App C','Tool C'),
        @('App4','App 4','Application4','Application 4','Tool4','Tool 4','Software4','Software 4','Fourth App','App D','Tool D')
    )

    for ($i = 0; $i -lt $Size; $i++) {
        $value = Get-PGPropertyValue -Row $Row -Candidates $ordinalCandidates[$i]
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $apps.Add($value.Trim())
        }
    }

    if ($apps.Count -lt $Size) {
        $combined = Get-PGPropertyValue -Row $Row -Candidates @('Apps','App Combination','Combination','Tools','Applications','Stack','Workflow Apps')
        if ($combined) {
            foreach ($part in ([regex]::Split($combined, '\s*\+\s*|\s*\|\s*|\s*;\s*|\s*,\s*|\s+ and \s+'))) {
                if (-not [string]::IsNullOrWhiteSpace($part) -and $apps.Count -lt $Size) {
                    $apps.Add($part.Trim())
                }
            }
        }
    }

    if ($apps.Count -lt $Size) {
        foreach ($property in $Row.PSObject.Properties) {
            $key = [regex]::Replace(([string]$property.Name).ToLowerInvariant(), '[^a-z0-9]', '')
            if ($key -match '^(app|tool|software|application)[a-z0-9]*$' -and -not [string]::IsNullOrWhiteSpace([string]$property.Value)) {
                $candidate = [string]$property.Value
                if (-not ($apps -contains $candidate) -and $apps.Count -lt $Size) {
                    $apps.Add($candidate.Trim())
                }
            }
        }
    }

    return @($apps | Select-Object -First $Size)
}

function Get-PGRiskLevel {
    param([AllowNull()][string]$Risk, [AllowNull()][string]$Text)
    $value = ('{0} {1}' -f $Risk, $Text).ToLowerInvariant()
    if ($value -match 'high|registry|delete|format|driver|uninstall|wipe|credential|token|password|admin required') { return 'High' }
    if ($value -match 'medium|update|install|repair|dism|sfc|service|startup|system') { return 'Medium' }
    if ($value -match 'low|read.?only|preview|scan|report|launch') { return 'Low' }
    return 'Low'
}

function Get-PGDifficulty {
    param([AllowNull()][string]$Difficulty, [AllowNull()][string]$Text)
    $value = ('{0} {1}' -f $Difficulty, $Text).ToLowerInvariant()
    if ($value -match 'advanced|hard|complex|expert') { return 'Advanced' }
    if ($value -match 'medium|moderate') { return 'Medium' }
    if ($value -match 'easy|simple|beginner') { return 'Easy' }
    return 'Medium'
}

function Get-PGAutomationReadiness {
    param([AllowNull()][string]$Value, [AllowNull()][string]$Text)
    $haystack = ('{0} {1}' -f $Value, $Text).ToLowerInvariant()
    if ($haystack -match 'ready|powershell|cli|command|script|automate|automation|local file|scan|report') { return 'Automation-ready' }
    if ($haystack -match 'manual|sign.?in|browser only|cloud only') { return 'Manual gate needed' }
    return 'Partially automatable'
}

function Get-PGInventoryMap {
    param([object[]]$Inventory)
    $map = @{}
    foreach ($app in $Inventory) {
        if (-not [string]::IsNullOrWhiteSpace($app.NormalizedName) -and -not $map.ContainsKey($app.NormalizedName)) {
            $map[$app.NormalizedName] = $app
        }
    }
    return $map
}

function Resolve-PGInventoryApp {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$InventoryMap
    )
    $normalized = Normalize-PGAppName $Name
    if ($InventoryMap.ContainsKey($normalized)) { return $InventoryMap[$normalized] }
    foreach ($key in $InventoryMap.Keys) {
        if ($key.Contains($normalized) -or $normalized.Contains($key)) {
            return $InventoryMap[$key]
        }
    }
    return $null
}

function New-PGWorkflowActionPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Workflow,
        [string]$Root
    )

    $apps = @($Workflow.AppNames)
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# Power Gorilla safe action plan')
    $lines.Add('# Strict Safe Mode: preview first, execute only after explicit confirmation.')
    $lines.Add("`$apps = @(" + (($apps | ForEach-Object { "'$($_.Replace("'","''"))'" }) -join ', ') + ')')
    $lines.Add("Invoke-PGCommand -Name 'LaunchApps' -Target (`$apps -join ', ') -WhatIf")
    $lines.Add("Invoke-PGCommand -Name 'ProduceReport' -Target '$($Workflow.Id)' -WhatIf")
    if ($Workflow.RiskLevel -ne 'Low') {
        $lines.Add('# This workflow is not low risk. Review the risk notes before any action.')
    }
    return @($lines)
}

function Import-PGIntegrationDatasets {
    [CmdletBinding()]
    param(
        [string]$Root,
        [switch]$Refresh,
        [int]$SamplePerDataset = 1200
    )

    $rootPath = Get-PGRoot -Root $Root
    Initialize-PGProject -Root $rootPath | Out-Null
    $processedPath = Join-Path $rootPath 'data\processed\integrations.json'
    if (-not $Refresh -and (Test-Path -LiteralPath $processedPath)) {
        return @(Get-Content -LiteralPath $processedPath -Raw | ConvertFrom-Json)
    }

    $inventory = @(Get-PGAppInventory -Root $rootPath -Refresh:$false)
    $inventoryMap = Get-PGInventoryMap -Inventory $inventory
    $items = New-Object System.Collections.Generic.List[object]
    $statuses = @(Get-PGDatasetStatus -Root $rootPath | Where-Object { $_.CombinationSize -gt 1 })

    foreach ($dataset in $statuses) {
        if (-not $dataset.Exists) { continue }
        $rowIndex = 0
        $addedForDataset = 0
        foreach ($row in Import-Csv -LiteralPath $dataset.Path) {
            $rowIndex++
            if ($SamplePerDataset -gt 0 -and $addedForDataset -ge $SamplePerDataset) { break }
            $apps = @(Get-PGIntegrationApps -Row $row -Size $dataset.CombinationSize)
            if ($apps.Count -ne $dataset.CombinationSize) { continue }
            $workflowName = Get-PGPropertyValue -Row $row -Candidates @('Workflow Name','Workflow','Name','Title','Integration','Combination Name','Use Case','Idea')
            $description = Get-PGPropertyValue -Row $row -Candidates @('What it can do','What They Can Do Together','What It Can Do','Description','Outcome','Result','Workflow Idea','Use Case','Best Use','Summary')
            $category = Get-PGPropertyValue -Row $row -Candidates @('Category','Workflow Category','Type','Domain','Area')
            $difficultyRaw = Get-PGPropertyValue -Row $row -Candidates @('Difficulty','Complexity','Ease')
            $riskRaw = Get-PGPropertyValue -Row $row -Candidates @('Risk','Risk Level','Safety')
            $automationRaw = Get-PGPropertyValue -Row $row -Candidates @('Automation','Automation Readiness','PowerShell','Commands')
            if ([string]::IsNullOrWhiteSpace($workflowName)) {
                $workflowName = ($apps -join ' + ')
            }
            if ([string]::IsNullOrWhiteSpace($description)) {
                $description = 'Workflow idea from imported Power Gorilla integration dataset.'
            }
            if ([string]::IsNullOrWhiteSpace($category)) {
                $category = 'Imported workflow'
            }

            $resolvedApps = foreach ($name in $apps) { Resolve-PGInventoryApp -Name $name -InventoryMap $inventoryMap }
            $installedCount = @($resolvedApps | Where-Object { $_ -and $_.Installed }).Count
            $openSourceCount = @($resolvedApps | Where-Object { $_ -and $_.IsOpenSource }).Count
            $freeCount = @($resolvedApps | Where-Object { $_ -and $_.IsFreeOrFreeTier }).Count
            $localCount = @($resolvedApps | Where-Object { $_ -and $_.LocalMode -match 'Local mode available' }).Count
            $signin = @($resolvedApps | Where-Object { $_ -and $_.SignInMode -match 'required|Optional|Unknown' } | ForEach-Object { "$($_.Name): $($_.SignInMode)" })
            $risk = Get-PGRiskLevel -Risk $riskRaw -Text $description
            $difficulty = Get-PGDifficulty -Difficulty $difficultyRaw -Text $description
            $automation = Get-PGAutomationReadiness -Value $automationRaw -Text $description

            $score = 0
            $score += $installedCount * 25
            $score += $openSourceCount * 10
            $score += $freeCount * 8
            $score += $localCount * 12
            if ($risk -eq 'Low') { $score += 20 } elseif ($risk -eq 'Medium') { $score += 5 } else { $score -= 30 }
            if ($automation -eq 'Automation-ready') { $score += 18 }
            if ($difficulty -eq 'Easy') { $score += 10 }

            $workflow = [pscustomobject]@{
                Id = ('{0}-{1:000000}' -f $dataset.Type.ToLowerInvariant(), $rowIndex)
                SourceFile = $dataset.ExpectedName
                CombinationSize = [int]$dataset.CombinationSize
                AppNames = @($apps)
                NormalizedAppNames = @($apps | ForEach-Object { Normalize-PGAppName $_ })
                WorkflowName = $workflowName
                Description = $description
                Category = $category
                Difficulty = $difficulty
                RiskLevel = $risk
                AutomationReadiness = $automation
                InstalledCount = $installedCount
                MissingApps = @($apps | Where-Object { -not (Resolve-PGInventoryApp -Name $_ -InventoryMap $inventoryMap) })
                OpenSourceCount = $openSourceCount
                FreeCount = $freeCount
                LocalCount = $localCount
                FreeOpenSourceStatus = if ($openSourceCount -eq $apps.Count) { 'All open-source' } elseif ($freeCount -eq $apps.Count) { 'All free/free-tier where known' } elseif ($freeCount -gt 0 -or $openSourceCount -gt 0) { 'Mixed free/open-source status' } else { 'Unknown' }
                SignInRequirement = if ($signin.Count -gt 0) { ($signin -join '; ') } else { 'No sign-in needed where known' }
                LocalOnlyAvailability = if ($localCount -eq $apps.Count) { 'Local-only available' } elseif ($localCount -gt 0) { 'Partial local mode' } else { 'Unknown or cloud-assisted' }
                CommandsAvailable = @('Preview Plan','Export Plan','Add to Favourites','Launch Apps -WhatIf','Generate PowerShell Plan')
                SafeNextAction = 'Preview Plan'
                RankScore = $score
                PowerShellPlan = @()
            }
            $workflow.PowerShellPlan = @(New-PGWorkflowActionPlan -Workflow $workflow -Root $rootPath)
            $items.Add($workflow)
            $addedForDataset++
        }
    }

    $result = @($items | Sort-Object RankScore -Descending)
    $result | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $processedPath -Encoding UTF8
    Write-PGLog -Root $rootPath -Area 'Integrations' -Message 'Integration datasets imported.' -Data @{ Count = $result.Count; FilesPresent = @($statuses | Where-Object Exists).Count }
    return $result
}

function Get-PGIntegrationSearch {
    [CmdletBinding()]
    param(
        [string]$Root,
        [string]$Query,
        [string[]]$Apps,
        [ValidateSet(0,2,3,4)][int]$CombinationSize = 0,
        [switch]$InstalledOnly,
        [switch]$OpenSourceOnly,
        [switch]$FreeOnly,
        [switch]$LocalOnly,
        [switch]$EasyOnly,
        [switch]$AutomationReadyOnly,
        [string]$Category,
        [int]$First = 100
    )

    $rootPath = Get-PGRoot -Root $Root
    $selected = @($Apps | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { Normalize-PGAppName $_ })
    $needsSourceScan = $selected.Count -gt 0 -or $Query -or $CombinationSize -gt 0 -or $InstalledOnly -or $OpenSourceOnly -or $FreeOnly -or $LocalOnly -or $EasyOnly -or $AutomationReadyOnly -or $Category

    if (-not $needsSourceScan) {
        return @(Import-PGIntegrationDatasets -Root $rootPath | Sort-Object RankScore -Descending | Select-Object -First $First)
    }

    $inventory = @(Get-PGAppInventory -Root $rootPath)
    $inventoryMap = Get-PGInventoryMap -Inventory $inventory
    $statuses = @(Get-PGDatasetStatus -Root $rootPath | Where-Object { $_.CombinationSize -gt 1 -and $_.Exists })
    $filtered = New-Object System.Collections.Generic.List[object]
    $trimAt = [Math]::Max($First * 8, 500)

    foreach ($dataset in $statuses) {
        if ($CombinationSize -gt 0 -and [int]$dataset.CombinationSize -ne $CombinationSize) { continue }
        $rowIndex = 0
        foreach ($row in Import-Csv -LiteralPath $dataset.Path) {
            $rowIndex++
            if (($rowIndex % 5000) -eq 0) {
                Write-Progress -Activity 'Power Gorilla integration search' -Status ("Scanning {0} row {1}" -f $dataset.ExpectedName, $rowIndex) -PercentComplete -1
            }

            $appsForRow = @(Get-PGIntegrationApps -Row $row -Size $dataset.CombinationSize)
            if ($appsForRow.Count -ne $dataset.CombinationSize) { continue }

            if ($selected.Count -gt 0) {
                $rowNames = @($appsForRow | ForEach-Object { Normalize-PGAppName $_ })
                $allSelected = $true
                foreach ($selectedName in $selected) {
                    if ($rowNames -notcontains $selectedName) {
                        $allSelected = $false
                        break
                    }
                }
                if (-not $allSelected) { continue }
            }

            $workflowName = Get-PGPropertyValue -Row $row -Candidates @('Workflow Name','Workflow','Name','Title','Integration','Combination Name','Use Case','Idea','Integration Family')
            $description = Get-PGPropertyValue -Row $row -Candidates @('What it can do','What They Can Do Together','What It Can Do','Description','Outcome','Result','Workflow Idea','Use Case','Best Use','Summary')
            $categoryValue = Get-PGPropertyValue -Row $row -Candidates @('Category','Workflow Category','Type','Domain','Area','Integration Family','Category Mix')
            $difficultyRaw = Get-PGPropertyValue -Row $row -Candidates @('Difficulty','Complexity','Ease')
            $riskRaw = Get-PGPropertyValue -Row $row -Candidates @('Risk','Risk Level','Safety','Confidence / Caution','Caution')
            $automationRaw = Get-PGPropertyValue -Row $row -Candidates @('Automation','Automation Readiness','Automation Ready','Automation Level','PowerShell','Commands','Integration Method')

            if ([string]::IsNullOrWhiteSpace($workflowName)) { $workflowName = ($appsForRow -join ' + ') }
            if ([string]::IsNullOrWhiteSpace($description)) { $description = 'Workflow idea from imported Power Gorilla integration dataset.' }
            if ([string]::IsNullOrWhiteSpace($categoryValue)) { $categoryValue = 'Imported workflow' }

            if ($Category -and $categoryValue -notlike "*$Category*") { continue }
            if ($Query) {
                $haystack = ('{0} {1} {2} {3}' -f $workflowName, $description, $categoryValue, ($appsForRow -join ' ')).ToLowerInvariant()
                $matched = $true
                foreach ($term in @($Query.ToLowerInvariant() -split '\s+' | Where-Object { $_ })) {
                    if (-not $haystack.Contains($term)) {
                        $matched = $false
                        break
                    }
                }
                if (-not $matched) { continue }
            }

            $resolvedApps = foreach ($name in $appsForRow) { Resolve-PGInventoryApp -Name $name -InventoryMap $inventoryMap }
            $installedCount = @($resolvedApps | Where-Object { $_ -and $_.Installed }).Count
            $openSourceCount = @($resolvedApps | Where-Object { $_ -and $_.IsOpenSource }).Count
            $freeCount = @($resolvedApps | Where-Object { $_ -and $_.IsFreeOrFreeTier }).Count
            $localCount = @($resolvedApps | Where-Object { $_ -and $_.LocalMode -match 'Local mode available' }).Count
            $signin = @($resolvedApps | Where-Object { $_ -and $_.SignInMode -match 'required|Optional|Unknown' } | ForEach-Object { "$($_.Name): $($_.SignInMode)" })
            $risk = Get-PGRiskLevel -Risk $riskRaw -Text $description
            $difficulty = Get-PGDifficulty -Difficulty $difficultyRaw -Text $description
            $automation = Get-PGAutomationReadiness -Value $automationRaw -Text $description

            if ($InstalledOnly -and $installedCount -lt [int]$dataset.CombinationSize) { continue }
            if ($OpenSourceOnly -and $openSourceCount -lt [int]$dataset.CombinationSize) { continue }
            if ($FreeOnly -and $freeCount -lt [int]$dataset.CombinationSize) { continue }
            if ($LocalOnly -and $localCount -lt [int]$dataset.CombinationSize) { continue }
            if ($EasyOnly -and $difficulty -ne 'Easy') { continue }
            if ($AutomationReadyOnly -and $automation -ne 'Automation-ready') { continue }

            $score = 0
            $score += $installedCount * 25
            $score += $openSourceCount * 10
            $score += $freeCount * 8
            $score += $localCount * 12
            if ($risk -eq 'Low') { $score += 20 } elseif ($risk -eq 'Medium') { $score += 5 } else { $score -= 30 }
            if ($automation -eq 'Automation-ready') { $score += 18 }
            if ($difficulty -eq 'Easy') { $score += 10 }

            $workflow = [pscustomobject]@{
                Id = ('{0}-{1:000000}' -f $dataset.Type.ToLowerInvariant(), $rowIndex)
                SourceFile = $dataset.ExpectedName
                CombinationSize = [int]$dataset.CombinationSize
                AppNames = @($appsForRow)
                NormalizedAppNames = @($appsForRow | ForEach-Object { Normalize-PGAppName $_ })
                WorkflowName = $workflowName
                Description = $description
                Category = $categoryValue
                Difficulty = $difficulty
                RiskLevel = $risk
                AutomationReadiness = $automation
                InstalledCount = $installedCount
                MissingApps = @($appsForRow | Where-Object { -not (Resolve-PGInventoryApp -Name $_ -InventoryMap $inventoryMap) })
                OpenSourceCount = $openSourceCount
                FreeCount = $freeCount
                LocalCount = $localCount
                FreeOpenSourceStatus = if ($openSourceCount -eq $appsForRow.Count) { 'All open-source' } elseif ($freeCount -eq $appsForRow.Count) { 'All free/free-tier where known' } elseif ($freeCount -gt 0 -or $openSourceCount -gt 0) { 'Mixed free/open-source status' } else { 'Unknown' }
                SignInRequirement = if ($signin.Count -gt 0) { ($signin -join '; ') } else { 'No sign-in needed where known' }
                LocalOnlyAvailability = if ($localCount -eq $appsForRow.Count) { 'Local-only available' } elseif ($localCount -gt 0) { 'Partial local mode' } else { 'Unknown or cloud-assisted' }
                CommandsAvailable = @('Preview Plan','Export Plan','Add to Favourites','Launch Apps -WhatIf','Generate PowerShell Plan')
                SafeNextAction = 'Preview Plan'
                RankScore = $score
                PowerShellPlan = @()
            }
            $workflow.PowerShellPlan = @(New-PGWorkflowActionPlan -Workflow $workflow -Root $rootPath)
            $filtered.Add($workflow)

            if ($filtered.Count -gt $trimAt) {
                $top = @($filtered | Sort-Object RankScore -Descending | Select-Object -First $First)
                $filtered.Clear()
                foreach ($item in $top) { $filtered.Add($item) }
            }
        }
    }
    Write-Progress -Activity 'Power Gorilla integration search' -Completed

    return @($filtered | Sort-Object RankScore -Descending | Select-Object -First $First)
}

function Get-PGWorkflowSuggestions {
    [CmdletBinding()]
    param(
        [string]$Root,
        [Parameter(Mandatory)][string[]]$SelectedApps,
        [int]$First = 24
    )

    $rootPath = Get-PGRoot -Root $Root
    $selected = @($SelectedApps | ForEach-Object { Normalize-PGAppName $_ })
    $matches = @(Get-PGIntegrationSearch -Root $rootPath -Apps $SelectedApps -First 500)
    $inventory = @(Get-PGAppInventory -Root $rootPath)
    $inventoryMap = Get-PGInventoryMap -Inventory $inventory
    $scores = @{}

    foreach ($workflow in $matches) {
        foreach ($app in $workflow.AppNames) {
            $norm = Normalize-PGAppName $app
            if ($selected -contains $norm) { continue }
            if (-not $scores.ContainsKey($norm)) {
                $resolved = Resolve-PGInventoryApp -Name $app -InventoryMap $inventoryMap
                $scores[$norm] = [ordered]@{
                    Name = $app
                    Score = 0
                    WorkflowCount = 0
                    Installed = if ($resolved) { [bool]$resolved.Installed } else { $false }
                    IsOpenSource = if ($resolved) { [bool]$resolved.IsOpenSource } else { $false }
                    IsFreeOrFreeTier = if ($resolved) { [bool]$resolved.IsFreeOrFreeTier } else { $false }
                    LocalMode = if ($resolved) { $resolved.LocalMode } else { 'Unknown' }
                    IconUrl = if ($resolved) { $resolved.IconUrl } else { '../data/icons/fallback-app.svg' }
                }
            }
            $scores[$norm].Score += [int]$workflow.RankScore
            $scores[$norm].WorkflowCount += 1
            if ($scores[$norm].Installed) { $scores[$norm].Score += 25 }
            if ($scores[$norm].IsOpenSource) { $scores[$norm].Score += 10 }
            if ($scores[$norm].IsFreeOrFreeTier) { $scores[$norm].Score += 8 }
            if ($scores[$norm].LocalMode -match 'Local mode available') { $scores[$norm].Score += 12 }
        }
    }

    return @($scores.Values | ForEach-Object { [pscustomobject]$_ } | Sort-Object Score -Descending | Select-Object -First $First)
}

function Get-PGSignInReport {
    [CmdletBinding()]
    param(
        [string]$Root,
        [switch]$Refresh
    )

    $rootPath = Get-PGRoot -Root $Root
    $processedPath = Join-Path $rootPath 'data\processed\sign-in-report.json'
    if (-not $Refresh -and (Test-Path -LiteralPath $processedPath)) {
        return @(Get-Content -LiteralPath $processedPath -Raw | ConvertFrom-Json)
    }

    $inventory = @(Get-PGAppInventory -Root $rootPath)
    $report = foreach ($app in $inventory) {
        [pscustomobject]@{
            AppName = $app.Name
            Status = $app.Status
            SignInMode = $app.SignInMode
            LocalMode = $app.LocalMode
            Installed = $app.Installed
            Notes = if ($app.SignInMode -match 'required') { 'Use the official app, browser, or CLI sign-in flow. Power Gorilla will not collect credentials.' } elseif ($app.SignInMode -eq 'Unknown') { 'Needs manual review.' } else { 'No credential action needed for local mode.' }
        }
    }
    $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $processedPath -Encoding UTF8
    return @($report)
}

function New-PGDashboardState {
    [CmdletBinding()]
    param([string]$Root)

    $rootPath = Get-PGRoot -Root $Root
    $inventory = @(Get-PGAppInventory -Root $rootPath)
    $integrations = @(Import-PGIntegrationDatasets -Root $rootPath)
    $signIn = @(Get-PGSignInReport -Root $rootPath)
    $datasets = @(Get-PGDatasetStatus -Root $rootPath)
    $favoritesPath = Join-Path $rootPath 'data\processed\favourites.json'
    $favorites = @()
    if (Test-Path -LiteralPath $favoritesPath) {
        try { $favorites = @(Get-Content -LiteralPath $favoritesPath -Raw | ConvertFrom-Json) } catch { $favorites = @() }
    }

    $state = [ordered]@{
        generatedAt = (Get-Date).ToString('o')
        safety = [ordered]@{
            mode = 'Strict Safe Mode'
            destructiveActionsEnabled = $false
            dangerousButtonsPreviewOnly = $true
            credentialsStored = $false
        }
        datasets = @($datasets)
        apps = @($inventory)
        integrations = @($integrations)
        signIn = @($signIn)
        favourites = @($favorites)
        stats = [ordered]@{
            apps = $inventory.Count
            installedApps = @($inventory | Where-Object Installed).Count
            missingApps = @($inventory | Where-Object { -not $_.Installed }).Count
            workflows = $integrations.Count
            twoApp = @($integrations | Where-Object CombinationSize -eq 2).Count
            threeApp = @($integrations | Where-Object CombinationSize -eq 3).Count
            fourApp = @($integrations | Where-Object CombinationSize -eq 4).Count
            iconsExtracted = @($inventory | Where-Object { $_.IconFile -and $_.IconFile -ne 'fallback-app.svg' }).Count
        }
    }

    $statePath = Join-Path $rootPath 'data\processed\dashboard-state.json'
    $state | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $statePath -Encoding UTF8
    $appDataPath = Join-Path $rootPath 'ui\app-data.js'
    ('window.POWER_GORILLA_STATE = ' + ($state | ConvertTo-Json -Depth 14) + ';') | Set-Content -LiteralPath $appDataPath -Encoding UTF8
    return [pscustomobject]$state
}

function Invoke-PGRefreshData {
    [CmdletBinding()]
    param(
        [string]$Root,
        [switch]$ExtractIcons
    )

    $rootPath = Get-PGRoot -Root $Root
    Initialize-PGProject -Root $rootPath | Out-Null
    $inventory = @(Get-PGAppInventory -Root $rootPath -Refresh -ExtractIcons:$ExtractIcons)
    $integrations = @(Import-PGIntegrationDatasets -Root $rootPath -Refresh)
    $signIn = @(Get-PGSignInReport -Root $rootPath -Refresh)
    $state = New-PGDashboardState -Root $rootPath
    Write-PGLog -Root $rootPath -Area 'Refresh' -Message 'Power Gorilla data refreshed.' -Data @{
        Apps = $inventory.Count
        Integrations = $integrations.Count
        SignInRows = $signIn.Count
        IconsExtracted = $state.stats.iconsExtracted
    }

    return [pscustomobject]@{
        Root = $rootPath
        Apps = $inventory.Count
        Integrations = $integrations.Count
        IconsExtracted = $state.stats.iconsExtracted
        DatasetFilesPresent = @((Get-PGDatasetStatus -Root $rootPath) | Where-Object Exists).Count
        DashboardState = Join-Path $rootPath 'data\processed\dashboard-state.json'
        Dashboard = Join-Path $rootPath 'ui\index.html'
    }
}

function Test-PGIsAdmin {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Get-PGSystemHealth {
    [CmdletBinding()]
    param([string]$Root)

    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $computer = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    [pscustomobject]@{
        ComputerName = $env:COMPUTERNAME
        User = $env:USERNAME
        IsAdmin = Test-PGIsAdmin
        OS = if ($os) { $os.Caption } else { 'Unknown' }
        OSVersion = if ($os) { $os.Version } else { 'Unknown' }
        UptimeHours = if ($os) { [Math]::Round(((Get-Date) - $os.LastBootUpTime).TotalHours, 1) } else { $null }
        TotalMemoryGB = if ($computer) { [Math]::Round($computer.TotalPhysicalMemory / 1GB, 2) } else { $null }
        SafetyMode = 'Strict Safe Mode'
        Notes = 'Read-only system snapshot. No repair actions were run.'
    }
}

function Get-PGDiskHealth {
    [CmdletBinding()]
    param([string]$Root)

    try {
        Get-Volume | Where-Object DriveLetter | ForEach-Object {
            [pscustomobject]@{
                Drive = "$($_.DriveLetter):"
                FileSystem = $_.FileSystem
                HealthStatus = $_.HealthStatus
                SizeGB = [Math]::Round($_.Size / 1GB, 2)
                FreeGB = [Math]::Round($_.SizeRemaining / 1GB, 2)
                FreePercent = if ($_.Size -gt 0) { [Math]::Round(($_.SizeRemaining / $_.Size) * 100, 1) } else { $null }
                Action = 'Report only'
            }
        }
    } catch {
        Write-PGLog -Root $Root -Level 'WARN' -Area 'Health' -Message 'Disk health scan failed.' -Data $_.Exception.Message
        @()
    }
}

function Get-PGOllamaModels {
    [CmdletBinding()]
    param([string]$Root)

    $cmd = Get-Command ollama -ErrorAction SilentlyContinue
    if (-not $cmd) {
        return [pscustomobject]@{ Installed = $false; Models = @(); Notes = 'Ollama command was not found on PATH.' }
    }

    try {
        $output = & $cmd.Source list 2>&1
        return [pscustomobject]@{ Installed = $true; Models = @($output); Notes = 'Read-only ollama list scan.' }
    } catch {
        return [pscustomobject]@{ Installed = $true; Models = @(); Notes = $_.Exception.Message }
    }
}

function Get-PGStartupApps {
    [CmdletBinding()]
    param([string]$Root)

    $paths = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'
    )
    foreach ($path in $paths) {
        try {
            $props = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
            if (-not $props) { continue }
            foreach ($prop in $props.PSObject.Properties) {
                if ($prop.Name -like 'PS*') { continue }
                [pscustomobject]@{
                    Name = $prop.Name
                    Command = ConvertTo-PGSafeLogText $prop.Value
                    Source = $path
                    Action = 'Review only'
                }
            }
        } catch {
            Write-PGLog -Root $Root -Level 'WARN' -Area 'Startup' -Message "Startup scan skipped for $path" -Data $_.Exception.Message
        }
    }
}

function Get-PGPorts {
    [CmdletBinding()]
    param([string]$Root)

    try {
        Get-NetTCPConnection -State Listen -ErrorAction Stop | Select-Object -First 200 LocalAddress,LocalPort,OwningProcess,State
    } catch {
        Write-PGLog -Root $Root -Level 'WARN' -Area 'Ports' -Message 'Port scan failed.' -Data $_.Exception.Message
        @()
    }
}

function Invoke-PGCommand {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param(
        [string]$Root,
        [Parameter(Mandatory)]
        [ValidateSet('ScanApps','SearchIntegrations','LaunchApps','CheckSystemHealth','CheckDiskHealth','CheckWindowsUpdates','CheckWingetUpdates','CheckStoreUpdates','CheckOllamaModels','CheckServices','CheckStartupApps','CheckPorts','CheckSuspiciousFailures','ProduceReport','CreateRestorePoint','RunDISM','RunSFC')]
        [string]$Name,
        [string]$Target,
        [switch]$DryRun
    )

    $rootPath = Get-PGRoot -Root $Root
    $alwaysPreview = @('LaunchApps','CreateRestorePoint','RunDISM','RunSFC')
    $preview = $DryRun -or $WhatIfPreference -or ($alwaysPreview -contains $Name)
    $plan = [ordered]@{
        command = $Name
        target = $Target
        mode = if ($preview) { 'Dry-run preview' } else { 'Read-only execution' }
        admin = Test-PGIsAdmin
        safety = 'Strict Safe Mode'
        destructive = $false
        rollback = 'No system-changing action is executed by this Phase 1 command.'
        notes = @()
    }

    switch ($Name) {
        'ScanApps' { $plan.notes += 'Refreshes app inventory and integration indexes. Read-only file writes are limited to PowerGorilla data/processed and logs.' }
        'SearchIntegrations' { $plan.notes += 'Searches imported CSV-derived workflow indexes.' }
        'LaunchApps' { $plan.notes += 'Phase 1 does not launch apps from the dashboard. This preview lists the apps that would be launched after a future confirmation gate.' }
        'CheckSystemHealth' { $plan.notes += 'Reads OS, admin, uptime, and memory status.' }
        'CheckDiskHealth' { $plan.notes += 'Reads volume free-space and health metadata. No cleanup is performed.' }
        'CheckWindowsUpdates' { $plan.notes += 'Planned Phase 2 scan-only feature. No Windows Update action is taken.' }
        'CheckWingetUpdates' { $plan.notes += 'Planned Phase 2 scan-only feature using winget upgrade. No upgrades are installed.' }
        'CheckStoreUpdates' { $plan.notes += 'Store update status is limited by local Microsoft Store visibility. No updates are triggered.' }
        'CheckOllamaModels' { $plan.notes += 'Runs ollama list only when Ollama is installed. No model downloads are started.' }
        'CheckServices' { $plan.notes += 'Planned service health review. No services are started, stopped, or reconfigured.' }
        'CheckStartupApps' { $plan.notes += 'Reads startup entries for review. No startup entries are disabled.' }
        'CheckPorts' { $plan.notes += 'Reads listening TCP ports. No processes are killed.' }
        'CheckSuspiciousFailures' { $plan.notes += 'Planned event-log review. No event logs are cleared.' }
        'ProduceReport' { $plan.notes += 'Writes a report under PowerGorilla reports only.' }
        'CreateRestorePoint' { $plan.notes += 'Restore point creation is not run in Phase 1. Future use will require admin and explicit confirmation.' }
        'RunDISM' { $plan.notes += 'DISM repair is blocked in Phase 1 and requires explicit future confirmation.' }
        'RunSFC' { $plan.notes += 'SFC repair is blocked in Phase 1 and requires explicit future confirmation.' }
    }

    Write-PGLog -Root $rootPath -Level $(if ($preview) { 'DRYRUN' } else { 'INFO' }) -Area 'Command' -Message "Command requested: $Name" -Data $plan

    if ($preview) {
        return [pscustomobject]$plan
    }

    if (-not $PSCmdlet.ShouldProcess($Name, 'Run read-only Power Gorilla command')) {
        return [pscustomobject]$plan
    }

    switch ($Name) {
        'ScanApps' { return Invoke-PGRefreshData -Root $rootPath -ExtractIcons }
        'CheckSystemHealth' { return Get-PGSystemHealth -Root $rootPath }
        'CheckDiskHealth' { return Get-PGDiskHealth -Root $rootPath }
        'CheckOllamaModels' { return Get-PGOllamaModels -Root $rootPath }
        'CheckStartupApps' { return Get-PGStartupApps -Root $rootPath }
        'CheckPorts' { return Get-PGPorts -Root $rootPath }
        default { return [pscustomobject]$plan }
    }
}

function Get-PGContentType {
    param([string]$Path)
    switch ([IO.Path]::GetExtension($Path).ToLowerInvariant()) {
        '.html' { 'text/html; charset=utf-8' }
        '.css'  { 'text/css; charset=utf-8' }
        '.js'   { 'application/javascript; charset=utf-8' }
        '.json' { 'application/json; charset=utf-8' }
        '.svg'  { 'image/svg+xml' }
        '.png'  { 'image/png' }
        '.ico'  { 'image/x-icon' }
        default { 'application/octet-stream' }
    }
}

function Send-PGHttpBytes {
    param(
        [Parameter(Mandatory)]$Context,
        [byte[]]$Bytes,
        [string]$ContentType = 'application/json; charset=utf-8',
        [int]$StatusCode = 200
    )
    $Context.Response.StatusCode = $StatusCode
    $Context.Response.ContentType = $ContentType
    $Context.Response.ContentLength64 = $Bytes.Length
    $Context.Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
    $Context.Response.OutputStream.Close()
}

function Send-PGHttpJson {
    param(
        [Parameter(Mandatory)]$Context,
        [AllowNull()]$Data,
        [int]$StatusCode = 200
    )
    $json = if ($Data -is [string]) { $Data } else { $Data | ConvertTo-Json -Depth 12 }
    Send-PGHttpBytes -Context $Context -Bytes ([Text.Encoding]::UTF8.GetBytes($json)) -ContentType 'application/json; charset=utf-8' -StatusCode $StatusCode
}

function Read-PGHttpBody {
    param($Request)
    $reader = New-Object IO.StreamReader($Request.InputStream, $Request.ContentEncoding)
    try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
}

function Save-PGFavourite {
    param([string]$Root, [string]$Body)
    if ($Body -match '(?i)password|token|secret|cookie|session|authorization') {
        throw 'Favourite payload looked like it might contain sensitive data and was rejected.'
    }
    $rootPath = Get-PGRoot -Root $Root
    $path = Join-Path $rootPath 'data\processed\favourites.json'
    $existing = @()
    if (Test-Path -LiteralPath $path) {
        try { $existing = @(Get-Content -LiteralPath $path -Raw | ConvertFrom-Json) } catch { $existing = @() }
    }
    $item = $Body | ConvertFrom-Json
    $record = [ordered]@{
        id = if ($item.id) { $item.id } else { [guid]::NewGuid().ToString('n') }
        apps = @($item.apps)
        icons = @($item.icons)
        workflowDescription = [string]$item.workflowDescription
        actionPlan = @($item.actionPlan)
        dateSaved = (Get-Date).ToString('o')
        tags = @($item.tags)
    }
    $all = @($existing) + [pscustomobject]$record
    $all | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $path -Encoding UTF8
    Write-PGLog -Root $rootPath -Area 'Favourites' -Message 'Favourite workflow saved.' -Data @{ Apps = $record.apps; Tags = $record.tags }
    return [pscustomobject]$record
}

function Save-PGPlanReport {
    param([string]$Root, [string]$Body)
    if ($Body -match '(?i)password|token|secret|cookie|session|authorization') {
        throw 'Plan payload looked like it might contain sensitive data and was rejected.'
    }
    $rootPath = Get-PGRoot -Root $Root
    $reportDir = Join-Path $rootPath 'reports'
    New-PGDirectory -Path $reportDir
    $path = Join-Path $reportDir ("PowerGorilla-Plan-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $Body | Set-Content -LiteralPath $path -Encoding UTF8
    Write-PGLog -Root $rootPath -Area 'Reports' -Message 'Workflow plan exported.' -Data @{ Path = $path }
    return [pscustomobject]@{ saved = $true; path = $path }
}

function Start-PGDashboardServer {
    [CmdletBinding()]
    param(
        [string]$Root,
        [int]$Port = 8765,
        [switch]$OpenBrowser
    )

    $rootPath = Get-PGRoot -Root $Root
    Initialize-PGProject -Root $rootPath | Out-Null
    $uiDir = Join-Path $rootPath 'ui'
    $iconDir = Join-Path $rootPath 'data\icons'
    $processedDir = Join-Path $rootPath 'data\processed'
    $listener = New-Object System.Net.HttpListener
    $prefix = "http://127.0.0.1:$Port/"
    $listener.Prefixes.Add($prefix)

    try {
        $listener.Start()
    } catch {
        Write-PGLog -Root $rootPath -Level 'WARN' -Area 'Dashboard' -Message 'HTTP dashboard server could not start; opening file mode instead.' -Data $_.Exception.Message
        Invoke-Item -LiteralPath (Join-Path $uiDir 'index.html')
        return
    }

    Write-PGLog -Root $rootPath -Area 'Dashboard' -Message "Dashboard server started at $prefix"
    Write-Host "Power Gorilla dashboard: $prefix" -ForegroundColor Cyan
    Write-Host 'Press Ctrl+C in this PowerShell window to stop the local server.' -ForegroundColor DarkGray
    if ($OpenBrowser) {
        Start-Process $prefix
    }

    try {
        while ($listener.IsListening) {
            $context = $listener.GetContext()
            try {
                $requestPath = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath.TrimStart('/'))
                if ([string]::IsNullOrWhiteSpace($requestPath)) { $requestPath = 'index.html' }

                if ($context.Request.HttpMethod -eq 'GET' -and $requestPath -eq 'api/state') {
                    $statePath = Join-Path $processedDir 'dashboard-state.json'
                    if (-not (Test-Path -LiteralPath $statePath)) { New-PGDashboardState -Root $rootPath | Out-Null }
                    $json = Get-Content -LiteralPath $statePath -Raw
                    Send-PGHttpJson -Context $context -Data $json
                    continue
                }

                if ($context.Request.HttpMethod -eq 'POST' -and $requestPath -eq 'api/favourites') {
                    $saved = Save-PGFavourite -Root $rootPath -Body (Read-PGHttpBody -Request $context.Request)
                    New-PGDashboardState -Root $rootPath | Out-Null
                    Send-PGHttpJson -Context $context -Data @{ ok = $true; favourite = $saved }
                    continue
                }

                if ($context.Request.HttpMethod -eq 'POST' -and $requestPath -eq 'api/export-plan') {
                    $savedReport = Save-PGPlanReport -Root $rootPath -Body (Read-PGHttpBody -Request $context.Request)
                    Send-PGHttpJson -Context $context -Data @{ ok = $true; report = $savedReport }
                    continue
                }

                if ($context.Request.HttpMethod -eq 'POST' -and $requestPath -eq 'api/preview-command') {
                    $body = Read-PGHttpBody -Request $context.Request
                    $payload = $body | ConvertFrom-Json
                    $preview = Invoke-PGCommand -Root $rootPath -Name ([string]$payload.name) -Target ([string]$payload.target) -DryRun
                    Send-PGHttpJson -Context $context -Data @{ ok = $true; preview = $preview }
                    continue
                }

                $filePath = $null
                if ($requestPath -like 'icons/*') {
                    $filePath = Join-Path $iconDir ([IO.Path]::GetFileName($requestPath))
                } elseif ($requestPath -like 'data/icons/*') {
                    $filePath = Join-Path $iconDir ([IO.Path]::GetFileName($requestPath))
                } elseif ($requestPath -like 'assets/*') {
                    $filePath = Join-Path $uiDir $requestPath
                } else {
                    $filePath = Join-Path $uiDir $requestPath
                }

                if (-not (Test-Path -LiteralPath $filePath)) {
                    Send-PGHttpJson -Context $context -StatusCode 404 -Data @{ ok = $false; error = 'Not found' }
                    continue
                }

                $bytes = [IO.File]::ReadAllBytes($filePath)
                Send-PGHttpBytes -Context $context -Bytes $bytes -ContentType (Get-PGContentType -Path $filePath)
            } catch {
                Write-PGLog -Root $rootPath -Level 'ERROR' -Area 'Dashboard' -Message 'Request failed.' -Data $_.Exception.Message
                Send-PGHttpJson -Context $context -StatusCode 500 -Data @{ ok = $false; error = 'Request failed safely.' }
            }
        }
    } finally {
        if ($listener.IsListening) { $listener.Stop() }
        $listener.Close()
        Write-PGLog -Root $rootPath -Area 'Dashboard' -Message 'Dashboard server stopped.'
    }
}

Export-ModuleMember -Function Initialize-PGProject,Invoke-PGRefreshData,Get-PGDatasetStatus,Get-PGAppInventory,Import-PGIntegrationDatasets,Get-PGIntegrationSearch,Get-PGWorkflowSuggestions,Get-PGSignInReport,Update-PGIconCache,Invoke-PGCommand,Get-PGSystemHealth,Get-PGDiskHealth,Get-PGOllamaModels,Get-PGStartupApps,Get-PGPorts,New-PGWorkflowActionPlan,Start-PGDashboardServer,Write-PGLog
