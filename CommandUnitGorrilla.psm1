# CommandUnitGorrilla
# A local-first Windows command centre for app inspection, repair sessions, reports,
# snapshots, FireDesk support, laptop health, and local AI-assisted planning.

Set-StrictMode -Version 2.0

$script:GorVersion = '2.5.0'
$script:GorExpectedCommands = @(
    'gorrilla','gor','gorload','gorstatus','gormap','gorui','gorfinal','gorlauncher','gorbaseline',
    'gorappadd','gorapps','gorappstatus','gorfleet','gorfleetreport',
    'gorengineer','gorplan','gorpatchpreview','gorfix','gorapply','gorbeast','gorreport',
    'gorsessions','gornewsession','gorview','gorapplysafe','gorapplymedium','gorfaildoctor',
    'gorsnap','gorsnaps','gorrestore','gordiff','gorclean',
    'gorhealth','gorports','gorport','gorslow','gorstartup','gorservices','gorevents','gornetwork',
    'gorfiredesk','gorfiredeskfix','gorfiredeskreport','gorbindlocal','gorkill5000',
    'gorindex','gorsearch','gorask','gorselftest',
    'gortest','gorrescue','gorrestore-lastgood','gormodule-rollback','gorprofile-repair','gorprofile-check','gorpanic',
    'gorstate','gorblackbox','gorpatchplan','gorpatchdiff','gorpatchapply','gorpatchundo','gorpatchreport',
    'gormodels','gormodel','goraskfile','goraskproject',
    'gortools','gorprofile','gorserver','goropen','gorapi','gorledger',
    'gorupgrade-check','gorbackup-module','gorrollback-module','gorversion','gorchangelog',
    'gorquality','gordoctor','gorerror','gorcmd','gorwatch','gorschedule',
    'gorsecurity','gorperf','gorpackage','gorvisual','gordesktop','goralerts','goroptions','goradvisor',
    'gorelite','gorstack','gorelite-fix','gorstack-fix','gorelite-report',
    'gordo','goreverything','gorboost','gorai','gorlaunch','gornewweb',
    'gorintegrate','gorfixqueue',
    'gorprompt','gorunderstand','gorworkflow','gorupdate','New-GorDesignBrief','Resolve-GorIntent','Get-GorInstalledApps',
    'Get-GorCreativePipelines','New-GorCreativeProject','New-GorHugeCheck',
    'Get-GorConnectorStatus','Set-GorConnectorPassport','New-GorBookProject','Get-GorProductVision','Get-GorWorldClassWorkflowPacks',
    'Get-GorBackupPosture','Invoke-GorKeepOneBackup','Get-GorDesktopAppInventory','Get-GorPackageBank',
    'gorconnectors','gorbook','gorkeeponebackup','gordesktopapps','gorpackagebank'
)

function Get-GorModuleRoot {
    if ($PSScriptRoot) {
        return $PSScriptRoot
    }
    if ($PSCommandPath) {
        return (Split-Path -Parent $PSCommandPath)
    }
    return (Get-Location).Path
}

function Get-GorUserModuleInstallRoot {
    return (Join-Path (Join-Path (Get-GorDocuments) 'PowerShell\Modules') 'CommandUnitGorrilla')
}

function Resolve-GorLaunchModuleRoot {
    $installed = Get-GorUserModuleInstallRoot
    $installedModule = Join-Path $installed 'CommandUnitGorrilla.psm1'
    $installedManifest = Join-Path $installed 'CommandUnitGorrilla.psd1'
    if ((Test-Path -LiteralPath $installedModule) -and (Test-Path -LiteralPath $installedManifest)) {
        return $installed
    }
    return (Get-GorModuleRoot)
}

function Get-GorDesktop {
    $desktop = [Environment]::GetFolderPath('Desktop')
    if ([string]::IsNullOrWhiteSpace($desktop)) {
        $desktop = Join-Path $HOME 'Desktop'
    }
    return $desktop
}

function Get-GorDocuments {
    $docs = [Environment]::GetFolderPath('MyDocuments')
    if ([string]::IsNullOrWhiteSpace($docs)) {
        $docs = Join-Path $HOME 'Documents'
    }
    return $docs
}

function Get-GorLocalAppData {
    $local = [Environment]::GetFolderPath('LocalApplicationData')
    if ([string]::IsNullOrWhiteSpace($local)) {
        $local = Join-Path $HOME 'AppData\Local'
    }
    return $local
}

function Get-GorPaths {
    $desktop = Get-GorDesktop
    $root = Join-Path (Get-GorLocalAppData) 'CommandUnitGorrilla'
    $launchers = Join-Path $root 'Launchers'
    [pscustomobject]@{
        ModuleRoot = Get-GorModuleRoot
        Desktop = $desktop
        Root = $root
        LegacyDesktopRoot = Join-Path $desktop 'CommandUnitGorrilla'
        Fleet = Join-Path $root 'Fleet'
        AppsJson = Join-Path (Join-Path $root 'Fleet') 'apps.json'
        Sessions = Join-Path $root 'Sessions'
        Snapshots = Join-Path $root 'Snapshots'
        Reports = Join-Path $root 'Reports'
        Vault = Join-Path $root 'Vault'
        VaultIndex = Join-Path (Join-Path $root 'Vault') 'index.json'
        Backups = Join-Path $root 'Backups'
        Launchers = Join-Path $root 'Launchers'
        Assets = Join-Path $root 'Assets'
        Index = Join-Path $root 'Index'
        TestLab = Join-Path $root 'TestLab'
        Rescue = Join-Path $root 'Rescue'
        State = Join-Path $root 'State'
        BlackBox = Join-Path $root 'BlackBox'
        PatchStudio = Join-Path $root 'PatchStudio'
        Config = Join-Path $root 'Config'
        ModelsJson = Join-Path (Join-Path $root 'Config') 'models.json'
        ToolsJson = Join-Path (Join-Path $root 'Config') 'tools.json'
        EliteStackJson = Join-Path (Join-Path $root 'Config') 'elite-stack.json'
        PackageBankJson = Join-Path (Join-Path $root 'Config') 'package-bank.json'
        ConnectorPassportJson = Join-Path (Join-Path $root 'Config') 'connector-passport.json'
        IntegrationRoot = Join-Path $root 'Integrations'
        IntegrationImports = Join-Path (Join-Path $root 'Integrations') 'Imports'
        IntegrationCache = Join-Path (Join-Path $root 'Integrations') 'Cache'
        IntegrationIndexJson = Join-Path (Join-Path (Join-Path $root 'Integrations') 'Cache') 'integration-builder-index.json'
        IntegrationIcons = Join-Path (Join-Path $root 'Dashboard') 'integration-icons'
        Prompts = Join-Path $root 'Prompts'
        IntentPrompt = Join-Path (Join-Path $root 'Prompts') 'intent-router.md'
        SafetyPrompt = Join-Path (Join-Path $root 'Prompts') 'safety-policy.md'
        UpdatePlanJson = Join-Path (Join-Path $root 'State') 'update-plan.json'
        Profiles = Join-Path $root 'Profiles'
        Dashboard = Join-Path $root 'Dashboard'
        Ledger = Join-Path $root 'Ledger'
        LedgerJsonl = Join-Path (Join-Path $root 'Ledger') 'ledger.jsonl'
        Knowledge = Join-Path $root 'Knowledge'
        ErrorsJson = Join-Path (Join-Path $root 'Knowledge') 'errors.json'
        Packages = Join-Path $root 'Packages'
        Schedule = Join-Path $root 'Schedule'
        ServerState = Join-Path (Join-Path $root 'Dashboard') 'server.json'
        AlertsJson = Join-Path (Join-Path $root 'State') 'alerts.json'
        OptionsJson = Join-Path (Join-Path $root 'State') 'options.json'
        CommandsMd = Join-Path $root 'GORRILLA_COMMANDS.md'
        Layout = Join-Path $root 'CommandUnitGorrilla_REAL_LAYOUT.md'
        DesktopCmd = Join-Path $launchers 'CommandUnit Gorrilla.cmd'
        DesktopLnk = Join-Path $desktop 'PowerShell Gorrilla.lnk'
        LauncherIco = Join-Path (Join-Path $root 'Assets') 'gorrilla-launcher.ico'
        RescueCmd = Join-Path $launchers 'CommandUnit Gorrilla Rescue.cmd'
        LauncherPs1 = Join-Path (Join-Path $root 'Launchers') 'Start-CommandUnitGorrilla.ps1'
        RescuePs1 = Join-Path (Join-Path $root 'Launchers') 'Start-CommandUnitGorrilla-Rescue.ps1'
    }
}

function Add-GorSafetyNotice {
    param(
        [Parameter(Mandatory=$true)][string]$Area,
        [Parameter(Mandatory=$true)][string]$Message,
        [AllowNull()][object]$Data = $null
    )
    try {
        $paths = Get-GorPaths
        if (-not (Test-Path -LiteralPath $paths.State)) {
            New-Item -ItemType Directory -Path $paths.State -Force | Out-Null
        }
        $noticePath = Join-Path $paths.State 'safety-notices.json'
        $items = @(Get-GorJson -Path $noticePath -Default @())
        $items += [pscustomobject]@{
            CreatedAt = Get-GorNow
            Area = $Area
            Message = $Message
            Data = $Data
        }
        Set-GorJson -Path $noticePath -Value $items
    }
    catch {
        Write-Warning "PowerShell Gorrilla safety notice could not be written: $($_.Exception.Message)"
    }
}

function Initialize-GorEnvironment {
    $paths = Get-GorPaths
    if ((Test-Path -LiteralPath $paths.LegacyDesktopRoot) -and -not (Test-Path -LiteralPath $paths.Root)) {
        $parent = Split-Path -Parent $paths.Root
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        Add-GorSafetyNotice -Area 'Startup migration' -Message 'Legacy desktop project folder was detected but not moved automatically. Review and move it manually after backup if you still need this migration.' -Data ([pscustomobject]@{ From=$paths.LegacyDesktopRoot; SuggestedDestination=$paths.Root })
    }
    elseif ((Test-Path -LiteralPath $paths.LegacyDesktopRoot) -and (Test-Path -LiteralPath $paths.Root)) {
        $legacyTarget = Join-Path (Get-GorLocalAppData) ('CommandUnitGorrilla-Desktop-Migration-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
        Add-GorSafetyNotice -Area 'Startup migration' -Message 'Legacy desktop project folder was detected while the local app data store already exists. No automatic move was performed.' -Data ([pscustomobject]@{ From=$paths.LegacyDesktopRoot; SuggestedDestination=$legacyTarget })
    }
    $folders = @(
        $paths.Root,
        $paths.Fleet,
        $paths.Sessions,
        $paths.Snapshots,
        $paths.Reports,
        $paths.Vault,
        $paths.Backups,
        $paths.Launchers,
        $paths.Assets,
        $paths.Index,
        $paths.TestLab,
        $paths.Rescue,
        $paths.State,
        $paths.BlackBox,
        $paths.PatchStudio,
        $paths.Config,
        $paths.IntegrationRoot,
        $paths.IntegrationImports,
        $paths.IntegrationCache,
        $paths.IntegrationIcons,
        $paths.Prompts,
        $paths.Profiles,
        $paths.Dashboard,
        $paths.Ledger,
        $paths.Knowledge,
        $paths.Packages,
        $paths.Schedule
    )
    foreach ($folder in $folders) {
        if (-not (Test-Path -LiteralPath $folder)) {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
        }
    }
    foreach ($desktopFileName in @('CommandUnit Gorrilla.cmd','CommandUnit Gorrilla Rescue.cmd')) {
        $desktopFile = Join-Path $paths.Desktop $desktopFileName
        if (Test-Path -LiteralPath $desktopFile) {
            Add-GorSafetyNotice -Area 'Launcher migration' -Message 'Legacy desktop launcher was detected but not moved automatically. It is safe to leave it in place or repair shortcuts through Create-Shortcuts.cmd.' -Data ([pscustomobject]@{ From=$desktopFile; SuggestedDestination=(Join-Path $paths.Launchers $desktopFileName) })
        }
    }
    if ((-not (Test-Path -LiteralPath $paths.AppsJson)) -or ((Get-Item -LiteralPath $paths.AppsJson -ErrorAction SilentlyContinue).Length -eq 0)) {
        $empty = @()
        Set-GorJson -Path $paths.AppsJson -Value $empty
    }
    Initialize-GorSeedFiles -Paths $paths
}

function Get-GorNow {
    return (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
}

function New-GorId {
    param([string]$Prefix = 'gor')
    $stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
    $suffix = [Guid]::NewGuid().ToString('N').Substring(0, 8)
    return "$Prefix-$stamp-$suffix"
}

function ConvertTo-GorJson {
    param([Parameter(Mandatory=$true)]$Value)
    return ($Value | ConvertTo-Json -Depth 12)
}

function Set-GorJson {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)]$Value
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $json = ConvertTo-GorJson -Value $Value
    if ([string]::IsNullOrWhiteSpace($json)) {
        $json = '[]'
    }
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
}

function Get-GorJson {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        $Default = $null
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        return $Default
    }
    try {
        $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return $Default
        }
        return ($raw | ConvertFrom-Json)
    }
    catch {
        Write-Warning "Could not read JSON: $Path :: $($_.Exception.Message)"
        return $Default
    }
}

function ConvertTo-GorArray {
    param($Value)
    if ($null -eq $Value) {
        return @()
    }
    if ($Value -is [System.Array]) {
        return $Value
    }
    if (($Value -is [System.Collections.IEnumerable]) -and -not ($Value -is [string]) -and -not ($Value -is [System.Collections.IDictionary])) {
        foreach ($item in $Value) {
            $item
        }
        return
    }
    return ,$Value
}

function Get-GorRoot {
    return (Get-GorPaths).Root
}

function Get-GorConfigPath {
    param([string]$Name = '')
    $paths = Get-GorPaths
    if ([string]::IsNullOrWhiteSpace($Name)) {
        return $paths.Config
    }
    return (Join-Path $paths.Config $Name)
}

function Read-GorJson {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        $Default = $null
    )
    return (Get-GorJson -Path $Path -Default $Default)
}

function Write-GorJson {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)]$Value
    )
    Set-GorJson -Path $Path -Value $Value
}

function ConvertTo-GorHtmlSafe {
    param([AllowNull()][string]$Text)
    return (Escape-GorHtml -Text $Text)
}

function Test-GorCommand {
    param([Parameter(Mandatory=$true)][string]$Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Name = $Name
        Exists = [bool]$cmd
        Source = if ($cmd) { [string]$cmd.Source } else { '' }
        Path = if ($cmd -and ($cmd.PSObject.Properties.Name -contains 'Path')) { [string]$cmd.Path } else { '' }
    }
}

function Write-GorLedger {
    param(
        [Parameter(Mandatory=$true)][string]$Type,
        [Parameter(Mandatory=$true)][string]$Message,
        $Data = $null
    )
    $paths = Get-GorPaths
    $parent = Split-Path -Parent $paths.LedgerJsonl
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $entry = [pscustomobject]@{
        Time = Get-GorNow
        Type = $Type
        Message = $Message
        User = [Environment]::UserName
        Machine = [Environment]::MachineName
        Data = $Data
    }
    Add-Content -LiteralPath $paths.LedgerJsonl -Value (ConvertTo-GorJson -Value $entry) -Encoding UTF8
    return $entry
}

function Get-GorCommandCatalog {
    $items = @(
        @('gorrilla','Core','Open the command room','LOW','gorrilla'),
        @('gorstatus','Core','Show module and workspace status','LOW','gorstatus'),
        @('gorui','Core','Build/open the local HTML command room','LOW','gorui'),
        @('gortest','Test Lab','Run module, FireDesk, repair, report, or full test suites','LOW','gortest all'),
        @('gorrescue','Rescue','Create and show emergency rescue launcher','LOW','gorrescue'),
        @('gorrestore-lastgood','Rescue','Restore module from last backup after confirmation','HIGH','gorrestore-lastgood'),
        @('gormodule-rollback','Rescue','Roll back module from selected backup after confirmation','HIGH','gormodule-rollback'),
        @('gorprofile-check','Rescue','Check profile autoload safety','LOW','gorprofile-check'),
        @('gorprofile-repair','Rescue','Patch profile autoload after confirmation','MEDIUM','gorprofile-repair'),
        @('gorpanic','Rescue','Print emergency commands','LOW','gorpanic'),
        @('gorstate','Desired State','Export/check/repair/report local desired state','MEDIUM','gorstate check'),
        @('gorblackbox','Black Box','Capture before/after app evidence','LOW','gorblackbox start FireDesk'),
        @('gorpatchplan','Patch Studio','Create a patch plan without applying','LOW','gorpatchplan FireDesk'),
        @('gorpatchdiff','Patch Studio','Show patch plan diff','LOW','gorpatchdiff SESSION'),
        @('gorpatchapply','Patch Studio','Apply plan after backup and confirmation','HIGH','gorpatchapply SESSION'),
        @('gorpatchundo','Patch Studio','Restore from patch backup after confirmation','HIGH','gorpatchundo SESSION'),
        @('gormodel','Model Router','Manage local Ollama model preferences','LOW','gormodel status'),
        @('gormodels','Model Router','List local Ollama models','LOW','gormodels'),
        @('gorask','Model Router','Ask local Ollama using indexed snippets','LOW','gorask QUESTION'),
        @('goraskfile','Model Router','Ask local Ollama about one file','LOW','goraskfile FILE QUESTION'),
        @('goraskproject','Model Router','Ask local Ollama about a project','LOW','goraskproject PATH QUESTION'),
        @('gortools','Tools','Check/update/install local tool dependencies','MEDIUM','gortools check'),
        @('gorprofile','Fleet Profiles','Manage app profiles','MEDIUM','gorprofile FireDesk'),
        @('gorserver','Dashboard','Start local-only dashboard server','LOW','gorserver'),
        @('goropen','Dashboard','Open dashboard','LOW','goropen'),
        @('gorapi','Dashboard','Show local API data','LOW','gorapi status'),
        @('gorledger','Evidence','View/search/report append-only ledger','LOW','gorledger'),
        @('gorupgrade-check','Upgrade','Check active module and backups','LOW','gorupgrade-check'),
        @('gorbackup-module','Upgrade','Backup active module','LOW','gorbackup-module'),
        @('gorrollback-module','Upgrade','Rollback module after confirmation','HIGH','gorrollback-module'),
        @('gorversion','Upgrade','Show active version','LOW','gorversion'),
        @('gorchangelog','Upgrade','Show changelog','LOW','gorchangelog'),
        @('gorquality','Quality','Score an app from 0-100','LOW','gorquality FireDesk'),
        @('gordoctor','Doctor Pro','Inspect project structure and risks','LOW','gordoctor FireDesk'),
        @('gorerror','Knowledge','Search/add/report local error fixes','LOW','gorerror port already in use'),
        @('gorcmd','Command Palette','Search command catalog','LOW','gorcmd search patch'),
        @('gorwatch','Watch','Monitor health without auto-repair','LOW','gorwatch FireDesk'),
        @('gorschedule','Watch','Create/clear schedule only with confirmation','MEDIUM','gorschedule daily'),
        @('gorreport','Reports','Build unified reports','LOW','gorreport all'),
        @('gorsecurity','Security','Defensive local security review','LOW','gorsecurity FireDesk'),
        @('gorperf','Performance','Measure local performance and app weight','LOW','gorperf app FireDesk'),
        @('gorpackage','Release','Create release package after confirmation','HIGH','gorpackage FireDesk'),
        @('gordesktop','Desktop','Preview or apply a tidy desktop organisation plan','MEDIUM','gordesktop tidy'),
        @('goralerts','Advisor','Show what is not working and what needs attention','LOW','goralerts'),
        @('goroptions','Advisor','Show safe next-step options for current alerts','LOW','goroptions'),
        @('goradvisor','Advisor','Run the full local advisor and write alerts/options','LOW','goradvisor'),
        @('gorappdiscover','Discovery','Scan installed Windows apps and shortcuts','LOW','gorappdiscover'),
        @('gorlaptopscan','Assessment','Run a laptop-wide security and performance scan','LOW','gorlaptopscan'),
        @('gorelite','Elite Stack','Show the full installed cockpit/toolchain status','LOW','gorelite'),
        @('gorelite-fix','Elite Stack','Repair safe user-level stack integration such as pnpm and PATH refresh','MEDIUM','gorelite-fix'),
        @('gorelite-report','Elite Stack','Write an HTML evidence report for the elite stack','LOW','gorelite-report'),
        @('gordo','Everything','Run a high-level do-everything workflow by mode','MEDIUM','gordo boost'),
        @('gorboost','Everything','Safe one-command upgrade of reports, stack checks, advisor and dashboard','MEDIUM','gorboost'),
        @('gorai','Everything','Start/check the local AI lab around Ollama and Docker','LOW','gorai'),
        @('gorlaunch','Everything','Launch installed cockpit apps by friendly name','LOW','gorlaunch code'),
        @('gornewweb','Everything','Create a new Next.js workspace with the installed web stack','MEDIUM','gornewweb MyApp'),
        @('gorintegrate','Integration','Show how installed apps work together safely','LOW','gorintegrate'),
        @('gorfixqueue','Integration','Show the prioritized safe fix queue','LOW','gorfixqueue'),
        @('gorconnectors','Integration','Show connector readiness and sign-in truth status','LOW','gorconnectors'),
        @('gordesktopapps','Discovery','Scan Desktop, Start Menu, and Program Files for app readiness','LOW','gordesktopapps'),
        @('gorpackagebank','Package Bank','Show 100+ curated package-manager options checked against this laptop','LOW','gorpackagebank'),
        @('gorbook','Integration','Create a multi-app book production plan','LOW','gorbook "My Book"'),
        @('gorkeeponebackup','Cleanliness','Keep one solid module backup and remove older generated test book packs','MEDIUM','gorkeeponebackup preview'),
        @('gorprompt','Understanding','Open/list local prompt files used by the command brain','LOW','gorprompt list'),
        @('gorunderstand','Understanding','Turn plain English into safe suggested commands','LOW','gorunderstand build a web app'),
        @('gorworkflow','Workflow Hub','List, explain, or run named safe workflows','MEDIUM','gorworkflow list'),
        @('gorupdate','Update Center','Preview/apply/report/rollback local module updates safely','HIGH','gorupdate preview')
    )
    $rows = foreach ($item in $items) {
        [pscustomobject]@{
            Command = $item[0]
            Category = $item[1]
            Description = $item[2]
            Risk = $item[3]
            Example = $item[4]
        }
    }
    return (ConvertTo-GorArray $rows)
}

function Initialize-GorSeedFiles {
    param([Parameter(Mandatory=$true)]$Paths)
    if (-not (Test-Path -LiteralPath $Paths.ModelsJson)) {
        Write-GorJson -Path $Paths.ModelsJson -Value ([pscustomobject]@{ Fast=''; Code=''; Deep=''; Vision=''; UpdatedAt=Get-GorNow })
    }
    if (-not (Test-Path -LiteralPath $Paths.EliteStackJson)) {
        Write-GorJson -Path $Paths.EliteStackJson -Value ([pscustomobject]@{
            Name = 'Elite PowerShell Stack'
            UpdatedAt = Get-GorNow
            RepairMode = 'UserLevelSafe'
            Notes = 'Tracks the developer, AI, security, design, API, database, tunnel, and visual cockpit tools that PowerShell Gorrilla can orchestrate.'
        })
    }
    if (-not (Test-Path -LiteralPath $Paths.IntentPrompt)) {
        $intentPrompt = @(
            '# PowerShell Gorrilla Product Brain and Intent Router',
            '',
            'Purpose:',
            'PowerShell Gorrilla is a local-first command centre for a Windows laptop. It helps the user control apps, diagnose problems, launch tools, manage device/media workflows, use local AI, and bring outcome summaries back into a visual app.',
            '',
            'Behaviour:',
            '- Answer in plain language first.',
            '- Suggest the safest useful next action without asking lots of questions.',
            '- Ask one concise follow-up only when a required detail is missing.',
            '- Never pretend a connector is working if it is only planned or demo-preview.',
            '- Explain what will happen when a user chooses an action.',
            '- Prefer outcome language: Scan, Analyse, Launch, Preview, Connect, Repair, View Result.',
            '',
            'Core routes:',
            '- "status", "what is working", "check laptop" -> gordo now',
            '- "fix", "problem", "broken", "repair" -> gorfixqueue then goradvisor',
            '- "apps", "what can this control", "integrations" -> gorintegrate',
            '- "workflow", "automation", "picture to design to writing" -> gorworkflow list, gorai, gorlaunch figma',
            '- "AI", "Ollama", "local model" -> gorai',
            '- "security", "safe", "scan exposure" -> gorsecurity FireDesk',
            '- "ports", "server", "connection" -> gorports or gornetwork',
            '- "update", "backup", "rollback" -> gorupdate preview then gorbackup-module',
            '- "create web app" -> gornewweb, then gorlaunch code',
            '',
            'Always mention risk. For medium/high risk commands, tell the user PowerShell will require confirmation.'
        )
        Set-Content -LiteralPath $Paths.IntentPrompt -Value $intentPrompt -Encoding UTF8
    }
    if (-not (Test-Path -LiteralPath $Paths.SafetyPrompt)) {
        $safetyPrompt = @(
            '# PowerShell Gorrilla Safety Policy',
            '',
            'The app should feel powerful but controlled.',
            '- Never start cloudflared or ngrok automatically.',
            '- Never delete, overwrite, or move user files without preview, backup, and confirmation.',
            '- Ollama may advise and summarize. PowerShell performs execution.',
            '- Prefer local-only URLs and 127.0.0.1 bindings.',
            '- Every update should support backup or rollback.',
            '- If an action is demo-only, planned, or ready-to-connect, label it truthfully.',
            '- Default to low-risk diagnostic, preview, scan, and explain actions before repair actions.'
        )
        Set-Content -LiteralPath $Paths.SafetyPrompt -Value $safetyPrompt -Encoding UTF8
    }
    $currentIntent = Get-Content -LiteralPath $Paths.IntentPrompt -Raw -ErrorAction SilentlyContinue
    if ($currentIntent -and $currentIntent -notmatch 'Product Brain') {
        Set-Content -LiteralPath $Paths.IntentPrompt -Value @(
            '# PowerShell Gorrilla Product Brain and Intent Router',
            '',
            'PowerShell Gorrilla is a local-first command centre for a Windows laptop. It helps the user control apps, diagnose problems, launch tools, manage device/media workflows, use local AI, and bring outcome summaries back into a visual app.',
            '',
            'Answer in plain language first. Suggest the safest useful next action without asking lots of questions. Ask one concise follow-up only when a required detail is missing.',
            '',
            'Intent routes:',
            '- status/check laptop -> gordo now',
            '- fix/problem/broken -> gorfixqueue then goradvisor',
            '- apps/integrations -> gorintegrate',
            '- workflow/picture/design/writing -> gorworkflow list, gorai, gorlaunch figma',
            '- AI/Ollama/local model -> gorai',
            '- security/safe/exposure -> gorsecurity FireDesk',
            '- ports/server/connection -> gorports or gornetwork',
            '- update/backup/rollback -> gorupdate preview then gorbackup-module',
            '- create web app -> gornewweb then gorlaunch code',
            '',
            'Use outcome labels: Scan, Analyse, Launch, Preview, Connect, Repair, View Result. Never pretend planned connectors are already working.'
        ) -Encoding UTF8
    }
    $currentSafety = Get-Content -LiteralPath $Paths.SafetyPrompt -Raw -ErrorAction SilentlyContinue
    if ($currentSafety -and $currentSafety -notmatch 'powerful but controlled') {
        Add-Content -LiteralPath $Paths.SafetyPrompt -Value @(
            '',
            'Product safety behaviour:',
            '- The app should feel powerful but controlled.',
            '- If an action is demo-only, planned, or ready-to-connect, label it truthfully.',
            '- Default to low-risk diagnostic, preview, scan, and explain actions before repair actions.',
            '- Medium and high risk actions must require explicit confirmation.'
        ) -Encoding UTF8
    }
    $currentIntent = Get-Content -LiteralPath $Paths.IntentPrompt -Raw -ErrorAction SilentlyContinue
    if ($currentIntent -and $currentIntent -notmatch '200000 prompt operator matrix') {
        Add-Content -LiteralPath $Paths.IntentPrompt -Value @(
            '',
            '200000 prompt operator matrix:',
            '- Combine domains, apps/tools, outcomes, and response styles to route requests without storing a huge static file.',
            '- Use the installed app list as truth for available app choices.',
            '- Use laptop context: processes, ports, disks, services, event errors, network checks, reports, models, alerts, and profiles.',
            '- Choose the app that best fits the outcome, then suggest the safest whitelisted command or app launch.',
            '- Prefer observe, explain, and preview before repair, delete, move, or stop actions.'
        ) -Encoding UTF8
    }
    if (-not (Test-Path -LiteralPath $Paths.ErrorsJson)) {
        $errors = @(
            [pscustomobject]@{ Pattern='An empty pipe element is not allowed'; Fix='Assign foreach/if output to a variable first, then pipe the variable to Format-Table or another command.' },
            [pscustomobject]@{ Pattern='command not recognized'; Fix='Check PATH, install the missing tool, or use the full executable path.' },
            [pscustomobject]@{ Pattern='Ollama requires more memory'; Fix='Switch to a smaller local model, close memory-heavy apps, or reduce context size.' },
            [pscustomobject]@{ Pattern='Select-String -Recurse'; Fix='Use Get-ChildItem -Recurse -File piped into Select-String instead of Select-String -Recurse.' },
            [pscustomobject]@{ Pattern='port already in use'; Fix='Run gorport PORT to identify the owner before stopping anything.' },
            [pscustomobject]@{ Pattern='python venv missing'; Fix='Create .venv locally and install requirements with CurrentUser-safe commands.' },
            [pscustomobject]@{ Pattern='npm not recognized'; Fix='Install Node.js or repair PATH, then reopen PowerShell.' }
        )
        Write-GorJson -Path $Paths.ErrorsJson -Value $errors
    }
    if (-not (Test-Path -LiteralPath $Paths.LedgerJsonl)) {
        Set-Content -LiteralPath $Paths.LedgerJsonl -Value @() -Encoding UTF8
    }
    New-GorCommandsFile -Path $Paths.CommandsMd
    Initialize-GorFireDeskProfile -Paths $Paths
}

function New-GorCommandsFile {
    param([Parameter(Mandatory=$true)][string]$Path)
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# PowerShell Gorrilla Commands')
    $lines.Add('')
    $lines.Add('Generated: ' + (Get-GorNow))
    $lines.Add('')
    foreach ($cmd in (Get-GorCommandCatalog | Sort-Object Category, Command)) {
        $lines.Add('- `' + $cmd.Command + '` [' + $cmd.Category + '/' + $cmd.Risk + '] - ' + $cmd.Description + ' Example: `' + $cmd.Example + '`')
    }
    Set-Content -LiteralPath $Path -Value $lines -Encoding UTF8
}

function Initialize-GorFireDeskProfile {
    param([Parameter(Mandatory=$true)]$Paths)
    $fire = Join-Path (Get-GorDesktop) 'FireDeskElite\Dashboard'
    if (-not (Test-Path -LiteralPath $fire)) {
        return
    }
    $profilePath = Join-Path $Paths.Profiles 'FireDesk.json'
    if (Test-Path -LiteralPath $profilePath) {
        return
    }
    $profile = [pscustomobject]@{
        Name = 'FireDesk'
        Path = $fire
        AppType = 'Python'
        StartCommand = '.\.venv\Scripts\python.exe app.py'
        TestCommand = 'python -m compileall .'
        RepairMode = 'Conservative'
        Ports = @(5000)
        ImportantFiles = @('app.py','config.py','requirements.txt')
        LogPaths = @('logs','*.log')
        HealthChecks = @('127.0.0.1:5000','compileall','port-owner','binding')
        ModelPreference = 'code'
        Notes = 'Auto-created first-class FireDesk profile.'
    }
    Write-GorJson -Path $profilePath -Value $profile
    Write-GorLedger -Type 'profile' -Message 'Created FireDesk profile.' -Data $profile | Out-Null
}

function Get-GorGeneratedStores {
    $paths = Get-GorPaths
    return @(
        [pscustomobject]@{ Name='Backups'; Path=$paths.Backups; Kind='Directory'; Keep=20 },
        [pscustomobject]@{ Name='Snapshots'; Path=$paths.Snapshots; Kind='Directory'; Keep=20 },
        [pscustomobject]@{ Name='Sessions'; Path=$paths.Sessions; Kind='Directory'; Keep=30 },
        [pscustomobject]@{ Name='Reports'; Path=$paths.Reports; Kind='File'; Keep=40 },
        [pscustomobject]@{ Name='Index'; Path=$paths.Index; Kind='File'; Keep=10 }
    )
}

function Get-GorCleanupCandidates {
    param([int]$Keep = 20)
    Initialize-GorEnvironment
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($store in Get-GorGeneratedStores) {
        if (-not (Test-Path -LiteralPath $store.Path)) {
            continue
        }
        $effectiveKeep = [Math]::Max(0, $Keep)
        if ($store.Kind -eq 'Directory') {
            $items = @(Get-ChildItem -LiteralPath $store.Path -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
        }
        else {
            $items = @(Get-ChildItem -LiteralPath $store.Path -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
        }
        $oldItems = @($items | Select-Object -Skip $effectiveKeep)
        foreach ($item in $oldItems) {
            $rows.Add([pscustomobject]@{
                Store = $store.Name
                Path = $item.FullName
                LastWriteTime = $item.LastWriteTime
                SizeBytes = if ($item.PSIsContainer) { $null } else { $item.Length }
                Action = 'DELETE_OLD_GENERATED_ITEM'
            })
        }
    }
    return (ConvertTo-GorArray $rows)
}

function Invoke-GorCleanup {
    param(
        [int]$Keep = 20,
        [switch]$Apply,
        [string]$ConfirmText = ''
    )
    $candidates = @(Get-GorCleanupCandidates -Keep $Keep)
    if ($candidates.Count -eq 0) {
        Write-Host "No generated cleanup candidates found. Keeping at least $Keep recent items per store." -ForegroundColor Green
        return @()
    }
    if (-not $Apply) {
        Write-Host "Preview only. Run: gorclean -Apply -Keep $Keep -ConfirmText CLEANGORRILLA" -ForegroundColor Yellow
        Write-GorTable -Rows $candidates
        return (ConvertTo-GorArray $candidates)
    }
    if ($ConfirmText -ne 'CLEANGORRILLA') {
        Write-Warning 'Confirmation did not match. No generated cleanup candidates were deleted. Re-run with -ConfirmText CLEANGORRILLA after reviewing the preview.'
        return [pscustomobject]@{
            Status = 'BLOCKED'
            Detail = 'Cleanup requires explicit confirmation text.'
            PreviewCount = $candidates.Count
            RequiredConfirmText = 'CLEANGORRILLA'
        }
    }
    $deleted = New-Object System.Collections.Generic.List[object]
    foreach ($candidate in $candidates) {
        try {
            if (Test-Path -LiteralPath $candidate.Path) {
                Remove-Item -LiteralPath $candidate.Path -Recurse -Force -ErrorAction Stop
            }
            $deleted.Add([pscustomobject]@{
                Store = $candidate.Store
                Path = $candidate.Path
                Status = 'DELETED'
            })
        }
        catch {
            $deleted.Add([pscustomobject]@{
                Store = $candidate.Store
                Path = $candidate.Path
                Status = 'FAILED'
                Detail = $_.Exception.Message
            })
        }
    }
    Write-GorTable -Rows $deleted
    return (ConvertTo-GorArray $deleted)
}

function Escape-GorHtml {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) {
        return ''
    }
    return [System.Net.WebUtility]::HtmlEncode($Text)
}

function ConvertTo-GorFragment {
    param($Data)
    if ($null -eq $Data) {
        return '<p class="muted">No data.</p>'
    }
    if ($Data -is [string]) {
        return '<pre>' + (Escape-GorHtml $Data) + '</pre>'
    }
    try {
        $fragment = $Data | ConvertTo-Html -Fragment
        $html = ($fragment -join [Environment]::NewLine)
        return $html
    }
    catch {
        return '<pre>' + (Escape-GorHtml ($Data | Out-String)) + '</pre>'
    }
}

function New-GorHtmlReport {
    param(
        [Parameter(Mandatory=$true)][string]$Title,
        [Parameter(Mandatory=$true)]$Sections,
        [string]$Path
    )
    Initialize-GorEnvironment
    if ([string]::IsNullOrWhiteSpace($Path)) {
        $safeTitle = ($Title -replace '[^A-Za-z0-9]+','-').Trim('-')
        if ([string]::IsNullOrWhiteSpace($safeTitle)) {
            $safeTitle = 'report'
        }
        $paths = Get-GorPaths
        $Path = Join-Path $paths.Reports ("$safeTitle.html")
    }
    $css = @(
        '<style>',
        ':root{color-scheme:dark;--bg:#0b0f14;--panel:#111821;--panel2:#151e29;--line:#263241;--text:#e7edf5;--muted:#98a6b5;--ok:#37d67a;--warn:#ffcc66;--bad:#ff6b6b;--accent:#67b7ff;}',
        '*{box-sizing:border-box}body{margin:0;background:#0b0f14;color:var(--text);font-family:Segoe UI,Inter,Arial,sans-serif;line-height:1.5;}',
        'header{padding:28px 34px;border-bottom:1px solid var(--line);background:#0f151d;}',
        'h1{margin:0;font-size:28px;font-weight:750;letter-spacing:0;}h2{margin:0 0 14px 0;font-size:18px;}',
        'main{max-width:1220px;margin:0 auto;padding:24px;}',
        '.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:16px;}',
        '.card{background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:18px;margin:0 0 16px 0;box-shadow:0 14px 40px rgba(0,0,0,.22);}',
        '.muted{color:var(--muted)}.badge{display:inline-block;border:1px solid var(--line);border-radius:999px;padding:3px 10px;margin:2px 5px 2px 0;background:var(--panel2);font-size:12px;color:var(--muted)}',
        '.ok{color:var(--ok)}.warn{color:var(--warn)}.bad{color:var(--bad)}.accent{color:var(--accent)}',
        'table{width:100%;border-collapse:collapse;margin-top:6px;}th,td{border-bottom:1px solid var(--line);padding:8px 9px;text-align:left;vertical-align:top;}th{color:#c9d6e5;background:#121b26;font-size:12px;text-transform:uppercase;}',
        'pre{white-space:pre-wrap;word-break:break-word;background:#081018;border:1px solid var(--line);border-radius:8px;padding:13px;overflow:auto;color:#dbe8f6;}',
        'a{color:var(--accent)}',
        '</style>'
    )
    $sectionHtml = New-Object System.Collections.Generic.List[string]
    foreach ($section in (ConvertTo-GorArray $Sections)) {
        $name = ''
        $body = ''
        if ($section.PSObject.Properties.Name -contains 'Title') {
            $name = [string]$section.Title
        }
        if ($section.PSObject.Properties.Name -contains 'Html') {
            $body = [string]$section.Html
        }
        elseif ($section.PSObject.Properties.Name -contains 'Data') {
            $body = ConvertTo-GorFragment -Data $section.Data
        }
        else {
            $body = ConvertTo-GorFragment -Data $section
        }
        $sectionHtml.Add(('<section class="card"><h2>' + (Escape-GorHtml $name) + '</h2>' + $body + '</section>'))
    }
    $lines = @(
        '<!doctype html>',
        '<html>',
        '<head>',
        '<meta charset="utf-8">',
        '<meta name="viewport" content="width=device-width, initial-scale=1">',
        '<title>' + (Escape-GorHtml $Title) + '</title>',
        ($css -join [Environment]::NewLine),
        '</head>',
        '<body>',
        '<header><h1>' + (Escape-GorHtml $Title) + '</h1><div class="muted">PowerShell Gorrilla · ' + (Escape-GorHtml (Get-GorNow)) + '</div></header>',
        '<main>',
        (@(ConvertTo-GorArray $sectionHtml) -join [Environment]::NewLine),
        '</main>',
        '</body>',
        '</html>'
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Set-Content -LiteralPath $Path -Value $lines -Encoding UTF8
    return $Path
}

function Test-GorParseFile {
    param([Parameter(Mandatory=$true)][string]$Path)
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors) | Out-Null
    $rows = foreach ($errorItem in $errors) {
        [pscustomobject]@{
            Message = $errorItem.Message
            Line = $errorItem.Extent.StartLineNumber
            Column = $errorItem.Extent.StartColumnNumber
        }
    }
    [pscustomobject]@{
        Path = $Path
        Ok = (($errors | Measure-Object).Count -eq 0)
        Errors = @($rows)
    }
}

function Get-GorCommandAvailability {
    $askCmd = Get-Command ask -ErrorAction Ignore
    $ollamaCmd = Get-Command ollama -ErrorAction Ignore
    [pscustomobject]@{
        Ask = [bool]$askCmd
        AskPath = if ($askCmd) { $askCmd.Source } else { $null }
        Ollama = [bool]$ollamaCmd
        OllamaPath = if ($ollamaCmd) { $ollamaCmd.Source } else { $null }
    }
}

function Get-GorEliteStackSpec {
    $items = @(
        @('PowerShell 7','pwsh','--version','Core cockpit','Required'),
        @('Windows Terminal','wt','--version','Core cockpit','Recommended'),
        @('Git','git','--version','Source control','Required'),
        @('GitHub CLI','gh','--version','Source control','Recommended'),
        @('VS Code','code','--version','Editor','Recommended'),
        @('Node.js','node','--version','Web build','Required'),
        @('npm','npm','--version','Web build','Required'),
        @('pnpm','pnpm','--version','Web build','Required'),
        @('Docker','docker','--version','Containers','Recommended'),
        @('Ollama','ollama','--version','Local AI','Recommended'),
        @('Supabase CLI','supabase','--version','Backend','Recommended'),
        @('Playwright','playwright','--version','Testing','Recommended'),
        @('Trivy','trivy','--version','Security','Recommended'),
        @('Gitleaks','gitleaks','version','Security','Recommended'),
        @('Semgrep','semgrep','--version','Security','Recommended'),
        @('pre-commit','pre-commit','--version','Quality','Recommended'),
        @('ripgrep','rg','--version','Search','Required'),
        @('fd','fd','--version','Search','Recommended'),
        @('Caddy','caddy','version','Local server','Recommended'),
        @('cloudflared','cloudflared','--version','Tunnels','Optional'),
        @('ngrok','ngrok','version','Tunnels','Optional'),
        @('Bruno CLI','bru','--version','API','Recommended'),
        @('Lighthouse','lighthouse','--version','Web quality','Recommended'),
        @('Vercel','vercel','--version','Deploy','Optional'),
        @('Netlify CLI','netlify','--version','Deploy','Optional'),
        @('Wrangler','wrangler','--version','Edge deploy','Optional'),
        @('Prisma','prisma','--version','Database','Optional'),
        @('Drizzle Kit','drizzle-kit','--version','Database','Optional')
    )
    foreach ($item in $items) {
        [pscustomobject]@{
            Name = $item[0]
            Command = $item[1]
            Args = $item[2]
            Category = $item[3]
            Importance = $item[4]
        }
    }
}

function Invoke-GorNativeToolVersion {
    param(
        [Parameter(Mandatory=$true)][string]$Command,
        [string]$Args = ''
    )
    $cmd = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $cmd) {
        return [pscustomobject]@{ Exists=$false; Version=''; Source=''; Detail='Command not found on PATH.' }
    }
    if ($cmd.Source -and ($cmd.Source -match '\.(exe|cmd|bat|ps1)$') -and -not (Test-Path -LiteralPath $cmd.Source)) {
        return [pscustomobject]@{ Exists=$false; Version=''; Source=[string]$cmd.Source; Detail='Command shim exists but target file is missing.' }
    }
    if ($cmd.Source -and $cmd.Source -like '*\Microsoft\WinGet\Links\*') {
        return [pscustomobject]@{ Exists=$true; Version='installed'; Source=[string]$cmd.Source; Detail='WinGet command alias detected; version probe skipped.' }
    }
    try {
        $parts = @()
        if (-not [string]::IsNullOrWhiteSpace($Args)) {
            $parts = @($Args -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        }
        $job = Start-Job -ScriptBlock {
            param($source, $arguments)
            & $source @arguments 2>&1 | Select-Object -First 1
        } -ArgumentList $cmd.Source, $parts
        $done = Wait-Job -Job $job -Timeout 4
        if ($done) {
            $output = Receive-Job -Job $job
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        }
        else {
            Stop-Job -Job $job -ErrorAction SilentlyContinue
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
            return [pscustomobject]@{
                Exists = $true
                Version = 'installed'
                Source = [string]$cmd.Source
                Detail = 'Version probe timed out; command exists.'
            }
        }
        return [pscustomobject]@{
            Exists = $true
            Version = ([string]$output).Trim()
            Source = [string]$cmd.Source
            Detail = ''
        }
    }
    catch {
        return [pscustomobject]@{
            Exists = $true
            Version = 'installed'
            Source = [string]$cmd.Source
            Detail = $_.Exception.Message
        }
    }
}

function Get-GorEliteStackSummary {
    $spec = @(Get-GorEliteStackSpec)
    $found = 0
    $missingRequired = 0
    $missingRecommended = 0
    foreach ($tool in $spec) {
        $cmd = Get-Command $tool.Command -ErrorAction SilentlyContinue
        $exists = [bool]$cmd
        if ($exists -and $cmd.Source -and ($cmd.Source -match '\.(exe|cmd|bat|ps1)$') -and -not (Test-Path -LiteralPath $cmd.Source)) {
            $exists = $false
        }
        if ($exists) {
            $found += 1
        }
        elseif ($tool.Importance -eq 'Required') {
            $missingRequired += 1
        }
        elseif ($tool.Importance -eq 'Recommended') {
            $missingRecommended += 1
        }
    }
    [pscustomobject]@{
        Total = $spec.Count
        Found = $found
        MissingRequired = $missingRequired
        MissingRecommended = $missingRecommended
        Ok = ($missingRequired -eq 0)
    }
}

function Get-GorEliteStackRows {
    param([switch]$Quick)
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($tool in Get-GorEliteStackSpec) {
        if ($Quick) {
            $cmd = Get-Command $tool.Command -ErrorAction SilentlyContinue
            $exists = [bool]$cmd
            if ($exists -and $cmd.Source -and ($cmd.Source -match '\.(exe|cmd|bat|ps1)$') -and -not (Test-Path -LiteralPath $cmd.Source)) {
                $exists = $false
            }
            $probe = [pscustomobject]@{
                Exists = $exists
                Version = if ($exists) { 'installed' } else { '' }
                Source = if ($exists) { [string]$cmd.Source } else { '' }
                Detail = if ($exists) { 'Quick probe; run gorelite for versions.' } else { 'Command not found on PATH.' }
            }
        }
        else {
            $probe = Invoke-GorNativeToolVersion -Command $tool.Command -Args $tool.Args
        }
        $status = if ($probe.Exists) { 'OK' } elseif ($tool.Importance -eq 'Required') { 'MISSING' } else { 'OPTIONAL_MISSING' }
        $rows.Add([pscustomobject]@{
            Name = $tool.Name
            Category = $tool.Category
            Command = $tool.Command
            Status = $status
            Importance = $tool.Importance
            Version = $probe.Version
            Source = $probe.Source
            Detail = $probe.Detail
        })
    }
    return (ConvertTo-GorArray $rows)
}

function Get-GorEliteStackIssues {
    param($Rows = $null)
    $rows = if ($null -eq $Rows) { @(Get-GorEliteStackRows) } else { @(ConvertTo-GorArray $Rows) }
    $issues = New-Object System.Collections.Generic.List[object]
    foreach ($row in $rows) {
        if ($row.Status -eq 'MISSING') {
            $fix = switch ($row.Command) {
                'pnpm' { 'Run gorelite-fix, then reopen PowerShell.' }
                'node' { 'Install or repair Node.js LTS, then reopen PowerShell.' }
                default { 'Install the missing tool or repair PATH, then run gorelite again.' }
            }
            $issues.Add([pscustomobject]@{ Severity='HIGH'; Tool=$row.Name; Problem='Required command missing'; Fix=$fix })
        }
        elseif ($row.Status -eq 'OPTIONAL_MISSING' -and $row.Importance -eq 'Recommended') {
            $issues.Add([pscustomobject]@{ Severity='LOW'; Tool=$row.Name; Problem='Recommended command missing'; Fix='Install when you need this capability.' })
        }
    }
    $node = $rows | Where-Object Command -eq 'node' | Select-Object -First 1
    if ($node -and $node.Version -match 'v25\.') {
        $issues.Add([pscustomobject]@{ Severity='MEDIUM'; Tool='Node.js'; Problem='Current Node is not an LTS line'; Fix='Use Node.js LTS for fewer npm engine warnings. Your installer attempted 24.15.0, while this shell saw v25.x.' })
    }
    $corepack = Get-Command corepack -ErrorAction SilentlyContinue
    if (-not $corepack) {
        $issues.Add([pscustomobject]@{ Severity='MEDIUM'; Tool='Corepack'; Problem='Corepack command is not on PATH'; Fix='Run gorelite-fix to install pnpm directly and refresh the current session PATH.' })
    }
    return (ConvertTo-GorArray $issues)
}

function Repair-GorEliteStack {
    Initialize-GorEnvironment
    $results = New-Object System.Collections.Generic.List[object]
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
    $extraPaths = @(
        (Join-Path $HOME '.local\bin'),
        (Join-Path $env:APPDATA 'npm'),
        (Join-Path $env:APPDATA 'Python\Python314\Scripts'),
        (Join-Path $env:APPDATA 'Python\Python312\Scripts')
    )
    foreach ($extra in $extraPaths) {
        if ((Test-Path -LiteralPath $extra) -and ($env:Path -notlike "*$extra*")) {
            $env:Path += ';' + $extra
        }
    }
    $results.Add([pscustomobject]@{ Action='Refresh current PATH'; Status='OK'; Detail='Machine, User, npm, pipx and local bin paths refreshed for this session.' })

    if ((Get-Command npm -ErrorAction SilentlyContinue) -and -not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
        try {
            & npm install -g pnpm 2>&1 | Out-Null
            $results.Add([pscustomobject]@{ Action='Install pnpm'; Status='OK'; Detail='Installed pnpm globally with npm because Corepack was unavailable.' })
        }
        catch {
            $results.Add([pscustomobject]@{ Action='Install pnpm'; Status='FAILED'; Detail=$_.Exception.Message })
        }
    }
    elseif (Get-Command pnpm -ErrorAction SilentlyContinue) {
        $results.Add([pscustomobject]@{ Action='Install pnpm'; Status='SKIPPED'; Detail='pnpm already available.' })
    }
    else {
        $results.Add([pscustomobject]@{ Action='Install pnpm'; Status='SKIPPED'; Detail='npm is not available in this shell.' })
    }

    if ((Get-Command corepack -ErrorAction SilentlyContinue) -and (Get-Command pnpm -ErrorAction SilentlyContinue)) {
        try {
            & corepack prepare pnpm@latest --activate 2>&1 | Out-Null
            $results.Add([pscustomobject]@{ Action='Activate pnpm with Corepack'; Status='OK'; Detail='Corepack activation completed.' })
        }
        catch {
            $results.Add([pscustomobject]@{ Action='Activate pnpm with Corepack'; Status='WARN'; Detail=$_.Exception.Message })
        }
    }
    else {
        $results.Add([pscustomobject]@{ Action='Activate pnpm with Corepack'; Status='SKIPPED'; Detail='Corepack is still unavailable; direct pnpm install is enough for Gorrilla commands.' })
    }

    Write-GorLedger -Type 'elite-stack' -Message 'Elite stack repair pass completed.' -Data $results | Out-Null
    return (ConvertTo-GorArray $results)
}

function New-GorEliteStackReport {
    $rows = Get-GorEliteStackRows
    $issues = Get-GorEliteStackIssues
    $summary = [pscustomobject]@{
        GeneratedAt = Get-GorNow
        Total = @($rows).Count
        OK = @($rows | Where-Object Status -eq 'OK').Count
        Missing = @($rows | Where-Object Status -eq 'MISSING').Count
        OptionalMissing = @($rows | Where-Object Status -eq 'OPTIONAL_MISSING').Count
        Issues = @($issues).Count
    }
    return (New-GorReport -Title 'PowerShell Gorrilla Elite Stack' -Sections @(
        [pscustomobject]@{ Title='Summary'; Data=$summary },
        [pscustomobject]@{ Title='Issues'; Data=$issues },
        [pscustomobject]@{ Title='Tools'; Data=$rows }
    ) -FileName 'elite-stack.html')
}

function New-GorEverythingResult {
    param(
        [Parameter(Mandatory=$true)][string]$Step,
        [Parameter(Mandatory=$true)][string]$Status,
        [string]$Detail = '',
        $Data = $null
    )
    [pscustomobject]@{
        Step = $Step
        Status = $Status
        Detail = $Detail
        Data = $Data
        At = Get-GorNow
    }
}

function Invoke-GorEverythingStep {
    param(
        [Parameter(Mandatory=$true)][string]$Step,
        [Parameter(Mandatory=$true)][scriptblock]$Script
    )
    try {
        $data = & $Script
        return (New-GorEverythingResult -Step $Step -Status 'OK' -Detail 'Completed.' -Data $data)
    }
    catch {
        return (New-GorEverythingResult -Step $Step -Status 'FAILED' -Detail $_.Exception.Message)
    }
}

function Get-GorLaunchCatalog {
    @(
        [pscustomobject]@{ Name='terminal'; Command='wt'; Args=@(); Category='Core' },
        [pscustomobject]@{ Name='code'; Command='code'; Args=@(); Category='Editor' },
        [pscustomobject]@{ Name='vscode'; Command='code'; Args=@(); Category='Editor' },
        [pscustomobject]@{ Name='github'; Command='github'; Args=@(); Category='Source' },
        [pscustomobject]@{ Name='docker'; Command='Docker Desktop'; Args=@(); Category='Containers' },
        [pscustomobject]@{ Name='ollama'; Command='ollama'; Args=@('serve'); Category='AI' },
        [pscustomobject]@{ Name='lmstudio'; Command='LM Studio'; Args=@(); Category='AI' },
        [pscustomobject]@{ Name='bruno'; Command='bruno'; Args=@(); Category='API' },
        [pscustomobject]@{ Name='postman'; Command='Postman'; Args=@(); Category='API' },
        [pscustomobject]@{ Name='insomnia'; Command='Insomnia'; Args=@(); Category='API' },
        [pscustomobject]@{ Name='dbeaver'; Command='dbeaver'; Args=@(); Category='Database' },
        [pscustomobject]@{ Name='obsidian'; Command='Obsidian'; Args=@(); Category='Knowledge' },
        [pscustomobject]@{ Name='notion'; Command='Notion'; Args=@(); Category='Knowledge' },
        [pscustomobject]@{ Name='figma'; Command='Figma'; Args=@(); Category='Design' },
        [pscustomobject]@{ Name='canva'; Command='Canva'; Args=@(); Category='Design' },
        [pscustomobject]@{ Name='sharex'; Command='ShareX'; Args=@(); Category='Capture' },
        [pscustomobject]@{ Name='obs'; Command='obs64'; Args=@(); Category='Capture' },
        [pscustomobject]@{ Name='gimp'; Command='gimp'; Args=@(); Category='Design' },
        [pscustomobject]@{ Name='krita'; Command='krita'; Args=@(); Category='Design' },
        [pscustomobject]@{ Name='inkscape'; Command='inkscape'; Args=@(); Category='Design' },
        [pscustomobject]@{ Name='blender'; Command='blender'; Args=@(); Category='3D' },
        [pscustomobject]@{ Name='everything'; Command='Everything'; Args=@(); Category='Search' }
    )
}

function Get-GorInstalledApps {
    $roots = @()
    $startPrograms = Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'Microsoft\Windows\Start Menu\Programs'
    $commonStartPrograms = Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) 'Microsoft\Windows\Start Menu\Programs'
    $commonDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
    $userDesktop = Get-GorDesktop
    foreach ($path in @($startPrograms, $commonStartPrograms, $commonDesktop, $userDesktop)) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)) {
            $roots += $path
        }
    }
    $apps = New-Object System.Collections.Generic.List[object]
    foreach ($root in $roots | Get-Unique) {
        $shortcuts = Get-ChildItem -LiteralPath $root -Recurse -Include '*.lnk','*.appref-ms' -File -ErrorAction SilentlyContinue
        foreach ($item in $shortcuts) {
            $apps.Add([pscustomobject]@{
                Name = [System.IO.Path]::GetFileNameWithoutExtension($item.Name)
                Path = $item.FullName
                Location = $root
                RelativePath = Get-GorRelativePath -Base $root -Path $item.FullName
                Type = 'Shortcut'
            })
        }
    }
    foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) }) {
        $folders = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | Select-Object -First 40
        foreach ($folder in $folders) {
            $apps.Add([pscustomobject]@{
                Name = $folder.Name
                Path = $folder.FullName
                Location = $root
                RelativePath = $folder.Name
                Type = 'Installed folder'
            })
        }
    }
    return @(ConvertTo-GorArray ($apps | Sort-Object Name -Unique))
}

function Get-GorQuickInstalledApps {
    $roots = @(
        (Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'Microsoft\Windows\Start Menu\Programs'),
        (Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) 'Microsoft\Windows\Start Menu\Programs'),
        ([Environment]::GetFolderPath('CommonDesktopDirectory')),
        (Get-GorDesktop)
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) }
    $apps = New-Object System.Collections.Generic.List[object]
    foreach ($root in $roots | Select-Object -Unique) {
        $shortcuts = @(Get-ChildItem -LiteralPath $root -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\.(lnk|appref-ms)$' } | Select-Object -First 120)
        foreach ($item in $shortcuts) {
            $apps.Add([pscustomobject]@{
                Name = [System.IO.Path]::GetFileNameWithoutExtension($item.Name)
                Path = $item.FullName
                Location = $root
                RelativePath = $item.Name
                Type = 'Shortcut'
            })
        }
    }
    foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) }) {
        foreach ($folder in @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | Select-Object -First 25)) {
            $apps.Add([pscustomobject]@{
                Name = $folder.Name
                Path = $folder.FullName
                Location = $root
                RelativePath = $folder.Name
                Type = 'Installed folder'
            })
        }
    }
    return @(ConvertTo-GorArray ($apps | Sort-Object Name -Unique))
}

function Get-GorDesktopAppInventory {
    param(
        [switch]$Quick,
        [int]$Limit = 300
    )
    Initialize-GorEnvironment
    $rootSpecs = @(
        [pscustomobject]@{ Source='User Desktop'; Path=(Get-GorDesktop); Recurse=$false },
        [pscustomobject]@{ Source='Public Desktop'; Path=([Environment]::GetFolderPath('CommonDesktopDirectory')); Recurse=$false },
        [pscustomobject]@{ Source='User Start Menu'; Path=(Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'Microsoft\Windows\Start Menu\Programs'); Recurse=(-not $Quick) },
        [pscustomobject]@{ Source='Public Start Menu'; Path=(Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) 'Microsoft\Windows\Start Menu\Programs'); Recurse=(-not $Quick) }
    )
    $connectors = @(Get-GorConnectorCatalog)
    $launchCatalog = @(Get-GorLaunchCatalog)
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($spec in $rootSpecs) {
        if ([string]::IsNullOrWhiteSpace($spec.Path) -or -not (Test-Path -LiteralPath $spec.Path)) {
            continue
        }
        $items = if ($spec.Recurse) {
            @(Get-ChildItem -LiteralPath $spec.Path -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\.(lnk|appref-ms|url)$' } | Select-Object -First $Limit)
        }
        else {
            @(Get-ChildItem -LiteralPath $spec.Path -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\.(lnk|appref-ms|url)$' } | Select-Object -First $Limit)
        }
        foreach ($item in $items) {
            $name = [System.IO.Path]::GetFileNameWithoutExtension($item.Name)
            $connector = @($connectors | Where-Object { $name -match $_.Pattern } | Select-Object -First 1)
            $known = @($launchCatalog | Where-Object { $name -match [regex]::Escape($_.Name) -or $_.Name -match [regex]::Escape($name) } | Select-Object -First 1)
            $rows.Add([pscustomobject]@{
                Name = $name
                Source = $spec.Source
                Kind = [IO.Path]::GetExtension($item.FullName).TrimStart('.').ToUpperInvariant()
                Path = $item.FullName
                RelativePath = Get-GorRelativePath -Base $spec.Path -Path $item.FullName
                Launchable = $true
                KnownToGorilla = [bool]($connector -or $known)
                Connector = if ($connector) { [string]$connector.Name } else { '' }
                Category = if ($known) { [string]$known.Category } elseif ($connector) { 'Connector' } else { 'Desktop app' }
                ConnectionState = if ($connector) { 'LAUNCHABLE_NEEDS_SIGN_IN_TRUTH' } else { 'LAUNCHABLE' }
                Action = 'Open visibly, then let Gorilla record the user-confirmed readiness state.'
            })
        }
    }
    foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) }) {
        $take = if ($Quick) { 25 } else { 80 }
        foreach ($folder in @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | Select-Object -First $take)) {
            $connector = @($connectors | Where-Object { $folder.Name -match $_.Pattern } | Select-Object -First 1)
            $known = @($launchCatalog | Where-Object { $folder.Name -match [regex]::Escape($_.Name) -or $_.Name -match [regex]::Escape($folder.Name) } | Select-Object -First 1)
            $rows.Add([pscustomobject]@{
                Name = $folder.Name
                Source = 'Program Files'
                Kind = 'FOLDER'
                Path = $folder.FullName
                RelativePath = $folder.Name
                Launchable = $false
                KnownToGorilla = [bool]($connector -or $known)
                Connector = if ($connector) { [string]$connector.Name } else { '' }
                Category = if ($known) { [string]$known.Category } elseif ($connector) { 'Connector' } else { 'Installed folder' }
                ConnectionState = if ($connector) { 'INSTALLED_NEEDS_LAUNCH_PATH' } else { 'INSTALLED_FOLDER' }
                Action = 'Use as installed evidence; add a shortcut or launch command before automation.'
            })
        }
    }
    return @(ConvertTo-GorArray ($rows | Sort-Object Name, Source -Unique | Select-Object -First $Limit))
}

function New-GorPackageBankSeed {
    $items = New-Object System.Collections.Generic.List[object]
    function Add-GorPackageBankItem {
        param(
            [string]$Name,
            [string]$Id,
            [string]$Manager,
            [string]$Category,
            [string]$Purpose,
            [string]$Command = '',
            [string]$Tags = ''
        )
        $install = switch ($Manager) {
            'winget' { "winget install --id $Id --exact" }
            'npm' { "npm install -g $Id" }
            'pipx' { "pipx install $Id" }
            'pip' { "pip install --user $Id" }
            'psgallery' { "Install-Module $Id -Scope CurrentUser" }
            default { $Id }
        }
        $items.Add([pscustomobject]@{
            Name = $Name
            Id = $Id
            Manager = $Manager
            Category = $Category
            Purpose = $Purpose
            Command = $Command
            InstallCommand = $install
            Quality = 'Curated'
            LaptopFit = 'Check manager/app status on this laptop before install.'
            Tags = @($Tags -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        })
    }

    Add-GorPackageBankItem 'Visual Studio Code' 'Microsoft.VisualStudioCode' 'winget' 'Developer' 'Primary code editor and Gorilla project cockpit.' 'code' 'editor,code'
    Add-GorPackageBankItem 'Git' 'Git.Git' 'winget' 'Developer' 'Source control for app changes, rollback evidence, and releases.' 'git' 'source,code'
    Add-GorPackageBankItem 'GitHub CLI' 'GitHub.cli' 'winget' 'Developer' 'Repository, issue, and pull-request work from the terminal.' 'gh' 'source,github'
    Add-GorPackageBankItem 'PowerShell' 'Microsoft.PowerShell' 'winget' 'Core' 'Modern shell runtime for the Gorilla launcher.' 'pwsh' 'core,shell'
    Add-GorPackageBankItem 'Windows Terminal' 'Microsoft.WindowsTerminal' 'winget' 'Core' 'Reliable tabbed terminal for local operations.' 'wt' 'core,shell'
    Add-GorPackageBankItem 'Node.js LTS' 'OpenJS.NodeJS.LTS' 'winget' 'Developer' 'Stable JavaScript runtime for dashboards and web apps.' 'node' 'web,build'
    Add-GorPackageBankItem 'Python' 'Python.Python.3.12' 'winget' 'Developer' 'Python runtime for scripts, AI helpers, and automation.' 'python' 'python,automation'
    Add-GorPackageBankItem 'Docker Desktop' 'Docker.DockerDesktop' 'winget' 'Containers' 'Local containers for AI, databases, and test services.' 'docker' 'containers,ai'
    Add-GorPackageBankItem 'Ollama' 'Ollama.Ollama' 'winget' 'AI' 'Local model runtime for private planning and drafting.' 'ollama' 'ai,local'
    Add-GorPackageBankItem 'LM Studio' 'ElementLabs.LMStudio' 'winget' 'AI' 'Desktop local-model interface and model management.' 'lms' 'ai,local'
    Add-GorPackageBankItem 'AnythingLLM' 'Mintplex-Labs.AnythingLLM' 'winget' 'AI' 'Local knowledge/chat workspace for documents and context.' '' 'ai,knowledge'
    Add-GorPackageBankItem 'Oh My Posh' 'JanDeDobbeleer.OhMyPosh' 'winget' 'Core' 'Prompt/theme support for a clearer operator terminal.' 'oh-my-posh' 'shell,quality'
    Add-GorPackageBankItem 'Microsoft Word' 'Microsoft.Office' 'winget' 'Writing' 'Long-form manuscript and business document production.' 'winword' 'writing,office'
    Add-GorPackageBankItem 'LibreOffice' 'TheDocumentFoundation.LibreOffice' 'winget' 'Writing' 'Open document fallback for writing and exports.' 'soffice' 'writing,office'
    Add-GorPackageBankItem 'Obsidian' 'Obsidian.Obsidian' 'winget' 'Knowledge' 'Local notes, book plans, and knowledge vaults.' 'obsidian' 'notes,knowledge'
    Add-GorPackageBankItem 'Notion' 'Notion.Notion' 'winget' 'Knowledge' 'Structured planning workspace when web/app session is available.' 'notion' 'notes,planning'
    Add-GorPackageBankItem 'Zotero' 'DigitalScholar.Zotero' 'winget' 'Research' 'Research library and citation management.' 'zotero' 'research,writing'
    Add-GorPackageBankItem 'Calibre' 'KovidGoyal.Calibre' 'winget' 'Publishing' 'Ebook management and conversion workflows.' 'calibre' 'book,publishing'
    Add-GorPackageBankItem 'Pandoc' 'JohnMacFarlane.Pandoc' 'winget' 'Publishing' 'Document conversion for book/report workflows.' 'pandoc' 'book,conversion'
    Add-GorPackageBankItem 'Canva' 'Canva.Canva' 'winget' 'Design' 'Cover, image, and marketing design worker app.' 'canva' 'design,cover'
    Add-GorPackageBankItem 'Figma' 'Figma.Figma' 'winget' 'Design' 'UI, layout, and design-system worker app.' 'figma' 'design,layout'
    Add-GorPackageBankItem 'Adobe Creative Cloud' 'Adobe.CreativeCloud' 'winget' 'Design' 'Adobe launcher for print, layout, and image tools.' 'Creative Cloud' 'design,adobe'
    Add-GorPackageBankItem 'Adobe Acrobat Reader' 'Adobe.Acrobat.Reader.64-bit' 'winget' 'Publishing' 'PDF review and print-check support.' 'AcroRd32' 'pdf,publishing'
    Add-GorPackageBankItem 'GIMP' 'GIMP.GIMP' 'winget' 'Design' 'Image editing and transparent asset work.' 'gimp' 'design,image'
    Add-GorPackageBankItem 'Krita' 'KDE.Krita' 'winget' 'Design' 'Illustration, painting, and book-art workflows.' 'krita' 'design,illustration'
    Add-GorPackageBankItem 'Inkscape' 'Inkscape.Inkscape' 'winget' 'Design' 'Vector artwork, icons, diagrams, and covers.' 'inkscape' 'design,vector'
    Add-GorPackageBankItem 'Blender' 'BlenderFoundation.Blender' 'winget' '3D' '3D assets, renders, scenes, and product visuals.' 'blender' '3d,visual'
    Add-GorPackageBankItem 'ShareX' 'ShareX.ShareX' 'winget' 'Capture' 'Screenshots, captures, OCR, and proof images.' 'ShareX' 'capture,evidence'
    Add-GorPackageBankItem 'OBS Studio' 'OBSProject.OBSStudio' 'winget' 'Capture' 'Screen recording and demo production.' 'obs64' 'video,capture'
    Add-GorPackageBankItem 'VLC' 'VideoLAN.VLC' 'winget' 'Media' 'Media playback and quick asset review.' 'vlc' 'media,review'
    Add-GorPackageBankItem 'Audacity' 'Audacity.Audacity' 'winget' 'Media' 'Audio recording and cleanup.' 'audacity' 'audio,media'
    Add-GorPackageBankItem 'HandBrake' 'HandBrake.HandBrake' 'winget' 'Media' 'Video conversion and compression.' 'HandBrake' 'video,conversion'
    Add-GorPackageBankItem 'FFmpeg' 'Gyan.FFmpeg' 'winget' 'Media' 'Command-line media conversion engine.' 'ffmpeg' 'video,audio'
    Add-GorPackageBankItem 'ImageMagick' 'ImageMagick.ImageMagick' 'winget' 'Media' 'Image conversion, resize, and batch processing.' 'magick' 'image,automation'
    Add-GorPackageBankItem 'Everything' 'voidtools.Everything' 'winget' 'Search' 'Fast local file search for projects and assets.' 'Everything' 'search,files'
    Add-GorPackageBankItem '7-Zip' '7zip.7zip' 'winget' 'Utilities' 'Archive, extract, and package outputs.' '7z' 'archive,utility'
    Add-GorPackageBankItem 'PowerToys' 'Microsoft.PowerToys' 'winget' 'Utilities' 'Window management, OCR, color picker, and productivity tools.' 'PowerToys' 'utility,windows'
    Add-GorPackageBankItem 'KeePassXC' 'KeePassXCTeam.KeePassXC' 'winget' 'Security' 'Local password vault for safer account management.' 'keepassxc' 'security,vault'
    Add-GorPackageBankItem 'Bitwarden' 'Bitwarden.Bitwarden' 'winget' 'Security' 'Password manager for visible sign-in readiness.' 'Bitwarden' 'security,vault'
    Add-GorPackageBankItem 'Microsoft Edge' 'Microsoft.Edge' 'winget' 'Browser' 'Default browser worker for web apps and portals.' 'msedge' 'browser,web'
    Add-GorPackageBankItem 'Google Chrome' 'Google.Chrome' 'winget' 'Browser' 'Browser worker for web apps and account sessions.' 'chrome' 'browser,web'
    Add-GorPackageBankItem 'Mozilla Firefox' 'Mozilla.Firefox' 'winget' 'Browser' 'Browser worker and testing alternative.' 'firefox' 'browser,web'
    Add-GorPackageBankItem 'Brave Browser' 'Brave.Brave' 'winget' 'Browser' 'Privacy-focused browser worker.' 'brave' 'browser,web'
    Add-GorPackageBankItem 'Postman' 'Postman.Postman' 'winget' 'API' 'API testing workspace.' 'Postman' 'api,testing'
    Add-GorPackageBankItem 'Bruno' 'Bruno.Bruno' 'winget' 'API' 'Git-friendly API client.' 'bruno' 'api,testing'
    Add-GorPackageBankItem 'Insomnia' 'Kong.Insomnia' 'winget' 'API' 'API testing and collections.' 'Insomnia' 'api,testing'
    Add-GorPackageBankItem 'DBeaver' 'dbeaver.dbeaver' 'winget' 'Database' 'Database browsing and query workbench.' 'dbeaver' 'database,data'
    Add-GorPackageBankItem 'DB Browser for SQLite' 'DBBrowserForSQLite.DBBrowserForSQLite' 'winget' 'Database' 'SQLite inspection for local apps.' 'DB Browser for SQLite' 'database,sqlite'
    Add-GorPackageBankItem 'Azure Data Studio' 'Microsoft.AzureDataStudio' 'winget' 'Database' 'SQL notebooks and database work.' 'azuredatastudio' 'database,sql'
    Add-GorPackageBankItem 'TablePlus' 'TablePlus.TablePlus' 'winget' 'Database' 'Database GUI for multiple engines.' 'TablePlus' 'database,sql'
    Add-GorPackageBankItem 'pgAdmin' 'PostgreSQL.pgAdmin' 'winget' 'Database' 'PostgreSQL admin UI.' 'pgAdmin4' 'database,postgres'
    Add-GorPackageBankItem 'MySQL Workbench' 'Oracle.MySQLWorkbench' 'winget' 'Database' 'MySQL design and administration.' 'MySQLWorkbench' 'database,mysql'
    Add-GorPackageBankItem 'Caddy' 'CaddyServer.Caddy' 'winget' 'Web Server' 'Simple local/static server and HTTPS tooling.' 'caddy' 'server,web'
    Add-GorPackageBankItem 'Nginx' 'Nginx.Nginx' 'winget' 'Web Server' 'Local reverse-proxy and server experiments.' 'nginx' 'server,web'
    Add-GorPackageBankItem 'Cloudflared' 'Cloudflare.cloudflared' 'winget' 'Network' 'Tunnel tool; Gorilla must never start public tunnels automatically.' 'cloudflared' 'tunnel,network'
    Add-GorPackageBankItem 'ngrok' 'Ngrok.Ngrok' 'winget' 'Network' 'Tunnel tool with explicit human approval only.' 'ngrok' 'tunnel,network'
    Add-GorPackageBankItem 'Wireshark' 'WiresharkFoundation.Wireshark' 'winget' 'Network' 'Network inspection and diagnostics.' 'wireshark' 'network,diagnostics'
    Add-GorPackageBankItem 'Fiddler Everywhere' 'Progress.Fiddler.Everywhere' 'winget' 'Network' 'HTTP debugging and API inspection.' 'Fiddler Everywhere' 'network,http'
    Add-GorPackageBankItem 'WinSCP' 'WinSCP.WinSCP' 'winget' 'File Transfer' 'Secure file transfer when user approves.' 'WinSCP' 'files,transfer'
    Add-GorPackageBankItem 'FileZilla' 'FileZilla.FileZilla.Client' 'winget' 'File Transfer' 'FTP/SFTP transfer client.' 'filezilla' 'files,transfer'
    Add-GorPackageBankItem 'Rclone' 'Rclone.Rclone' 'winget' 'File Transfer' 'Cloud/storage sync with explicit approval gates.' 'rclone' 'files,sync'
    Add-GorPackageBankItem 'Syncthing' 'Syncthing.Syncthing' 'winget' 'File Transfer' 'Private device-to-device sync.' 'syncthing' 'files,sync'
    Add-GorPackageBankItem 'VeraCrypt' 'IDRIX.VeraCrypt' 'winget' 'Security' 'Encrypted containers for sensitive local projects.' 'VeraCrypt' 'security,encryption'
    Add-GorPackageBankItem 'Gitleaks' 'Gitleaks.Gitleaks' 'winget' 'Security' 'Secret scanning for local projects.' 'gitleaks' 'security,code'
    Add-GorPackageBankItem 'Trivy' 'AquaSecurity.Trivy' 'winget' 'Security' 'Container, dependency, and file vulnerability scanning.' 'trivy' 'security,containers'
    Add-GorPackageBankItem 'Semgrep' 'Semgrep.Semgrep' 'winget' 'Security' 'Static analysis for code risks.' 'semgrep' 'security,code'
    Add-GorPackageBankItem 'Snyk CLI' 'Snyk.Snyk' 'winget' 'Security' 'Dependency and container security review.' 'snyk' 'security,dependencies'
    Add-GorPackageBankItem 'LocalSend' 'localsend.localsend_app' 'winget' 'Utilities' 'Local network file sharing.' 'LocalSend' 'files,utility'
    Add-GorPackageBankItem 'Notepad++' 'Notepad++.Notepad++' 'winget' 'Editor' 'Fast text editing and log viewing.' 'notepad++' 'editor,logs'
    Add-GorPackageBankItem 'Sublime Text' 'SublimeHQ.SublimeText.4' 'winget' 'Editor' 'Fast professional code/text editor.' 'subl' 'editor,code'
    Add-GorPackageBankItem 'JetBrains Toolbox' 'JetBrains.Toolbox' 'winget' 'Developer' 'JetBrains app manager for IDEs.' 'jetbrains-toolbox' 'editor,ide'
    Add-GorPackageBankItem 'Cursor' 'Anysphere.Cursor' 'winget' 'Developer' 'AI-assisted coding editor when available.' 'cursor' 'editor,ai'
    Add-GorPackageBankItem 'Windsurf' 'Codeium.Windsurf' 'winget' 'Developer' 'AI-assisted coding editor when available.' 'windsurf' 'editor,ai'
    Add-GorPackageBankItem 'Vercel CLI' 'vercel' 'npm' 'Deploy' 'Frontend deployment CLI with explicit approval.' 'vercel' 'deploy,web'
    Add-GorPackageBankItem 'Netlify CLI' 'netlify-cli' 'npm' 'Deploy' 'Static/frontend deployment CLI with explicit approval.' 'netlify' 'deploy,web'
    Add-GorPackageBankItem 'Wrangler' 'wrangler' 'npm' 'Deploy' 'Cloudflare Workers/pages CLI with explicit approval.' 'wrangler' 'deploy,edge'
    Add-GorPackageBankItem 'pnpm' 'pnpm' 'npm' 'Developer' 'Fast package manager for Node projects.' 'pnpm' 'web,build'
    Add-GorPackageBankItem 'yarn' 'yarn' 'npm' 'Developer' 'Alternative JavaScript package manager.' 'yarn' 'web,build'
    Add-GorPackageBankItem 'TypeScript' 'typescript' 'npm' 'Developer' 'TypeScript compiler and project support.' 'tsc' 'web,code'
    Add-GorPackageBankItem 'tsx' 'tsx' 'npm' 'Developer' 'Fast TypeScript script runner.' 'tsx' 'web,code'
    Add-GorPackageBankItem 'Vite' 'vite' 'npm' 'Developer' 'Fast frontend dev server and builder.' 'vite' 'web,build'
    Add-GorPackageBankItem 'Next.js' 'next' 'npm' 'Developer' 'React app framework support.' 'next' 'web,react'
    Add-GorPackageBankItem 'Playwright' '@playwright/test' 'npm' 'Testing' 'Browser automation and visual QA.' 'playwright' 'testing,browser'
    Add-GorPackageBankItem 'Lighthouse' 'lighthouse' 'npm' 'Testing' 'Web performance and quality audits.' 'lighthouse' 'testing,web'
    Add-GorPackageBankItem 'ESLint' 'eslint' 'npm' 'Quality' 'JavaScript/TypeScript linting.' 'eslint' 'quality,code'
    Add-GorPackageBankItem 'Prettier' 'prettier' 'npm' 'Quality' 'Consistent code formatting.' 'prettier' 'quality,code'
    Add-GorPackageBankItem 'Prisma' 'prisma' 'npm' 'Database' 'Database schema and migrations.' 'prisma' 'database,orm'
    Add-GorPackageBankItem 'Drizzle Kit' 'drizzle-kit' 'npm' 'Database' 'TypeScript database migrations.' 'drizzle-kit' 'database,orm'
    Add-GorPackageBankItem 'Supabase CLI' 'supabase' 'npm' 'Backend' 'Local Supabase dev and project management.' 'supabase' 'backend,database'
    Add-GorPackageBankItem 'Firebase Tools' 'firebase-tools' 'npm' 'Backend' 'Firebase deployment and local tools.' 'firebase' 'backend,deploy'
    Add-GorPackageBankItem 'Electron Builder' 'electron-builder' 'npm' 'Desktop Apps' 'Package desktop apps.' 'electron-builder' 'desktop,build'
    Add-GorPackageBankItem 'OpenAPI Generator CLI' '@openapitools/openapi-generator-cli' 'npm' 'API' 'Generate clients/servers from OpenAPI specs.' 'openapi-generator-cli' 'api,codegen'
    Add-GorPackageBankItem 'Redocly CLI' '@redocly/cli' 'npm' 'API' 'Lint and publish API docs.' 'redocly' 'api,docs'
    Add-GorPackageBankItem 'Mermaid CLI' '@mermaid-js/mermaid-cli' 'npm' 'Documentation' 'Render workflow diagrams.' 'mmdc' 'docs,diagrams'
    Add-GorPackageBankItem 'Sharp CLI' 'sharp-cli' 'npm' 'Media' 'Image conversion and optimization.' 'sharp' 'image,automation'
    Add-GorPackageBankItem 'Biome' '@biomejs/biome' 'npm' 'Quality' 'Fast formatter and linter.' 'biome' 'quality,code'
    Add-GorPackageBankItem 'npm-check-updates' 'npm-check-updates' 'npm' 'Quality' 'Review dependency update options.' 'ncu' 'quality,updates'
    Add-GorPackageBankItem 'serve' 'serve' 'npm' 'Web Server' 'Static local web server.' 'serve' 'server,web'
    Add-GorPackageBankItem 'http-server' 'http-server' 'npm' 'Web Server' 'Simple local static server.' 'http-server' 'server,web'
    Add-GorPackageBankItem 'pipx' 'pipx' 'pip' 'Python' 'Install isolated Python CLIs.' 'pipx' 'python,tools'
    Add-GorPackageBankItem 'ruff' 'ruff' 'pipx' 'Python' 'Fast Python linter and formatter.' 'ruff' 'python,quality'
    Add-GorPackageBankItem 'black' 'black' 'pipx' 'Python' 'Python formatting.' 'black' 'python,quality'
    Add-GorPackageBankItem 'pytest' 'pytest' 'pipx' 'Python' 'Python test runner.' 'pytest' 'python,testing'
    Add-GorPackageBankItem 'poetry' 'poetry' 'pipx' 'Python' 'Python dependency and package manager.' 'poetry' 'python,build'
    Add-GorPackageBankItem 'uv' 'uv' 'pipx' 'Python' 'Fast Python package/project tool.' 'uv' 'python,build'
    Add-GorPackageBankItem 'mkdocs-material' 'mkdocs-material' 'pipx' 'Documentation' 'Project documentation site generator.' 'mkdocs' 'docs,site'
    Add-GorPackageBankItem 'jupyterlab' 'jupyterlab' 'pipx' 'Data' 'Notebooks for analysis and AI experiments.' 'jupyter' 'data,notebook'
    Add-GorPackageBankItem 'datasette' 'datasette' 'pipx' 'Data' 'Explore SQLite/data files locally.' 'datasette' 'data,sqlite'
    Add-GorPackageBankItem 'yt-dlp' 'yt-dlp' 'pipx' 'Media' 'Media download tool only for user-approved lawful uses.' 'yt-dlp' 'media,utility'
    Add-GorPackageBankItem 'cookiecutter' 'cookiecutter' 'pipx' 'Developer' 'Project template generator.' 'cookiecutter' 'project,templates'
    Add-GorPackageBankItem 'pre-commit' 'pre-commit' 'pipx' 'Quality' 'Local quality hooks.' 'pre-commit' 'quality,git'
    Add-GorPackageBankItem 'PowerShellGet' 'PowerShellGet' 'psgallery' 'PowerShell' 'PowerShell module management.' 'PowerShellGet' 'powershell,modules'
    Add-GorPackageBankItem 'PSReadLine' 'PSReadLine' 'psgallery' 'PowerShell' 'Better shell editing and history.' 'PSReadLine' 'powershell,shell'
    Add-GorPackageBankItem 'PSScriptAnalyzer' 'PSScriptAnalyzer' 'psgallery' 'PowerShell' 'PowerShell linting and script quality.' 'Invoke-ScriptAnalyzer' 'powershell,quality'
    Add-GorPackageBankItem 'ImportExcel' 'ImportExcel' 'psgallery' 'PowerShell' 'Excel file automation without Excel dependency.' 'Import-Excel' 'powershell,excel'
    Add-GorPackageBankItem 'Microsoft.Graph' 'Microsoft.Graph' 'psgallery' 'Microsoft 365' 'Microsoft Graph automation after user-approved auth.' 'Connect-MgGraph' 'm365,automation'
    Add-GorPackageBankItem 'Az PowerShell' 'Az' 'psgallery' 'Cloud' 'Azure administration after explicit sign-in.' 'Connect-AzAccount' 'azure,cloud'
    Add-GorPackageBankItem 'dbatools' 'dbatools' 'psgallery' 'Database' 'SQL Server automation and diagnostics.' 'dbatools' 'database,sql'
    Add-GorPackageBankItem 'PSWriteHTML' 'PSWriteHTML' 'psgallery' 'Reports' 'HTML report generation.' 'New-HTML' 'reports,powershell'
    Add-GorPackageBankItem 'Pode' 'Pode' 'psgallery' 'Web Server' 'PowerShell web/API server framework.' 'Pode' 'powershell,server'
    Add-GorPackageBankItem 'Terminal-Icons' 'Terminal-Icons' 'psgallery' 'Core' 'Clearer file icons in terminal.' 'Terminal-Icons' 'powershell,shell'
    return @(ConvertTo-GorArray $items)
}

function Initialize-GorPackageBank {
    param([switch]$Force)
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $existing = @(Read-GorJson -Path $paths.PackageBankJson -Default @())
    if (-not $Force -and $existing.Count -ge 100) {
        return (ConvertTo-GorArray $existing)
    }
    $seed = @(New-GorPackageBankSeed)
    Write-GorJson -Path $paths.PackageBankJson -Value $seed
    Write-GorLedger -Type 'package-bank' -Message 'Package bank seed refreshed.' -Data ([pscustomobject]@{ Count=$seed.Count; Path=$paths.PackageBankJson }) | Out-Null
    return (ConvertTo-GorArray $seed)
}

function Get-GorPackageManagerState {
    $managers = @('winget','npm','pip','pipx','choco')
    $rows = @{}
    foreach ($manager in $managers) {
        $cmd = Get-Command $manager -ErrorAction SilentlyContinue
        $rows[$manager] = [pscustomobject]@{
            Name = $manager
            Available = [bool]$cmd
            Source = if ($cmd) { [string]$cmd.Source } else { '' }
        }
    }
    $rows['psgallery'] = [pscustomobject]@{
        Name = 'psgallery'
        Available = [bool](Get-Command Install-Module -ErrorAction SilentlyContinue)
        Source = 'PowerShellGet'
    }
    return $rows
}

function Get-GorPackageBank {
    param(
        [string]$Search = '',
        [int]$First = 200
    )
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $bank = @(Read-GorJson -Path $paths.PackageBankJson -Default @())
    if ($bank.Count -lt 100) {
        $bank = @(Initialize-GorPackageBank -Force)
    }
    $managerState = Get-GorPackageManagerState
    $installed = @(Get-GorQuickInstalledApps | Where-Object { $_.Name -notmatch 'uninstall|remove' })
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($pkg in $bank) {
        $manager = [string]$pkg.Manager
        $state = if ($managerState.ContainsKey($manager)) { $managerState[$manager] } else { [pscustomobject]@{ Available=$false; Source='' } }
        $commandFound = $false
        if (-not [string]::IsNullOrWhiteSpace([string]$pkg.Command)) {
            $commandFound = [bool](Get-Command -Name ([string]$pkg.Command) -ErrorAction SilentlyContinue)
        }
        $namePattern = [regex]::Escape([string]$pkg.Name)
        $appHit = @($installed | Where-Object { $_.Name -match $namePattern -or [string]$pkg.Name -match [regex]::Escape($_.Name) } | Select-Object -First 1)
        $installedHint = [bool]($commandFound -or $appHit)
        $worksHere = if ($installedHint) { 'INSTALLED_OR_LAUNCHABLE' } elseif ($state.Available) { 'MANAGER_READY' } else { 'NEEDS_MANAGER' }
        $rows.Add([pscustomobject]@{
            Name = [string]$pkg.Name
            Id = [string]$pkg.Id
            Manager = $manager
            Category = [string]$pkg.Category
            Purpose = [string]$pkg.Purpose
            Command = [string]$pkg.Command
            InstallCommand = [string]$pkg.InstallCommand
            ManagerAvailable = [bool]$state.Available
            InstalledHint = [bool]$installedHint
            WorksHere = $worksHere
            Status = if ($installedHint) { 'READY' } elseif ($state.Available) { 'AVAILABLE_TO_INSTALL' } else { 'MANAGER_MISSING' }
            Safety = 'Preview only. Gorilla does not install until the user chooses an explicit install action.'
            Tags = @($pkg.Tags)
        })
    }
    if (-not [string]::IsNullOrWhiteSpace($Search)) {
        $q = $Search.ToLowerInvariant()
        $rows = @($rows | Where-Object {
            $haystack = ([string]$_.Name + ' ' + [string]$_.Category + ' ' + [string]$_.Purpose + ' ' + [string]$_.Tags).ToLowerInvariant()
            $haystack.Contains($q)
        })
    }
    return @(ConvertTo-GorArray ($rows | Sort-Object Category, Name | Select-Object -First $First))
}

function Get-GorQuickLaptopContext {
    $processes = @()
    try {
        $processes = @(Get-Process -ErrorAction SilentlyContinue | Sort-Object CPU -Descending | Select-Object -First 8 | ForEach-Object {
            [pscustomobject]@{ Name=$_.ProcessName; CPU=[math]::Round([double]($_.CPU),2); WorkingSetMB=[math]::Round($_.WorkingSet64 / 1MB,1) }
        })
    }
    catch {}
    [pscustomobject]@{
        Disks = @()
        TopProcesses = $processes
        ListeningPorts = @()
        StoppedAutoServices = @()
        RecentErrors = @()
        Network = @()
        Summary = [pscustomobject]@{
            Disks = 0
            TopProcesses = $processes.Count
            ListeningPorts = 0
            StoppedAutoServices = 0
            RecentErrors = 0
            NetworkChecks = 0
        }
    }
}

function Get-GorPromptMatrix {
    $domains = @(
        'diagnose laptop health','launch an app for the task','inspect running services','inspect ports and local servers',
        'repair a local app safely','build a web app','test a web app','review security exposure','prepare a design workflow',
        'summarise reports and evidence','clean generated clutter','package a release','connect local AI','debug API tools',
        'organise desktop work','create rollback evidence','find files and project context','compare app options','choose the right tool',
        'explain next safest action'
    )
    $tools = @(
        'PowerShell','Ollama','VS Code','Windows Terminal','browser','Bruno','Postman','Figma','Canva','Adobe','Word','Docker',
        'Git','Node','Python','Everything','File Explorer','Windows services','event logs','ports','reports','saved profiles','connector status'
    )
    $outcomes = @(
        'plan','launch','inspect','summarise','repair','test','secure','optimise','package','document',
        'compare','prioritise','triage','explain','route','verify','rollback','scan','monitor','recommend',
        'extract evidence','prepare prompt','write command','show risk','find app'
    )
    $tones = @(
        'concise','step-by-step','expert engineer','non-technical','evidence-first','risk-first','fast path','deep audit',
        'local-only','confirmation-gated','beginner-safe','operator mode','debug mode','release mode','security mode','build mode',
        'design mode','API mode','system mode','cleanup mode'
    )
    $samples = New-Object System.Collections.Generic.List[object]
    foreach ($domain in $domains | Select-Object -First 8) {
        foreach ($outcome in $outcomes | Select-Object -First 5) {
            if ($samples.Count -ge 40) { break }
            $samples.Add([pscustomobject]@{
                Title = "$outcome :: $domain"
                Prompt = "Use local context to $outcome for '$domain'. Pick the safest app/tool, explain why, name the command to run, and ask only if a missing detail blocks progress."
                RiskRule = 'Do not run medium/high-risk actions without explicit typed confirmation.'
            })
        }
        if ($samples.Count -ge 40) { break }
    }
    [pscustomobject]@{
        Count = ($domains.Count * $tools.Count * $outcomes.Count * $tones.Count)
        Domains = $domains
        Tools = $tools
        Outcomes = $outcomes
        Styles = $tones
        Samples = @(ConvertTo-GorArray $samples)
        SystemInstruction = 'You are the local operator brain for PowerShell Gorrilla. Use installed apps, connector truth status, laptop signals, reports, ports, processes, models, and whitelisted commands to choose the best next action. Prefer read-only inspection first. Label risk. Never invent app availability or sign-in state; use the provided app and connector lists.'
    }
}

function Get-GorLaptopContext {
    $disks = @(Get-GorDiskInfo | Select-Object -First 8)
    $processes = @(Get-GorTopProcesses | Select-Object -First 10)
    $ports = @(Get-GorListeningPorts | Select-Object -First 20)
    $services = @(Get-GorStoppedAutoServices | Select-Object -First 12)
    $errors = @(Get-GorRecentErrors | Select-Object -First 10)
    $network = @(Get-GorNetworkDiagnostics | Select-Object -First 8)
    [pscustomobject]@{
        Disks = $disks
        TopProcesses = $processes
        ListeningPorts = $ports
        StoppedAutoServices = $services
        RecentErrors = $errors
        Network = $network
        Summary = [pscustomobject]@{
            Disks = $disks.Count
            TopProcesses = $processes.Count
            ListeningPorts = $ports.Count
            StoppedAutoServices = $services.Count
            RecentErrors = $errors.Count
            NetworkChecks = $network.Count
        }
    }
}

function New-GorDesignBrief {
    param(
        [string]$Goal = 'Design a bold PowerShell Gorrilla poster',
        [string]$App = 'Canva'
    )
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $safeGoal = if ([string]::IsNullOrWhiteSpace($Goal)) { 'Design a bold PowerShell Gorrilla poster' } else { $Goal.Trim() }
    $safeApp = if ([string]::IsNullOrWhiteSpace($App)) { 'Canva' } else { $App.Trim() }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $file = Join-Path $paths.Reports ("design-brief-$stamp.md")
    $lines = @(
        '# PowerShell Gorrilla Design Brief',
        '',
        "Goal: $safeGoal",
        "Recommended app: $safeApp",
        "Created: $(Get-GorNow)",
        '',
        'Plain-English concept:',
        'Create a premium, dark, high-contrast poster that explains PowerShell Gorrilla as a local AI command centre for a Windows laptop.',
        '',
        'Headline:',
        'PowerShell Gorrilla',
        '',
        'Supporting copy:',
        'One local command centre for apps, AI, diagnostics, safe repairs, and real laptop context.',
        '',
        'Visual direction:',
        '- Dark technical background with clean green/blue highlights.',
        '- Use a simple PG mark, not the old large mascot image.',
        '- Show four capability blocks: See the laptop, Choose apps, Ask Ollama, Run safely.',
        '- Keep the layout readable for a normal person, not just developers.',
        '',
        'Suggested workflow:',
        '1. Open the chosen design app from the App Operator.',
        '2. Create a poster or social graphic using the headline and copy above.',
        '3. Use the app dashboard to check laptop/app status while designing.',
        '4. Save/export the design, then keep this brief as evidence.'
    )
    Set-Content -LiteralPath $file -Value $lines -Encoding UTF8
    [pscustomobject]@{
        Status = 'CREATED'
        Goal = $safeGoal
        App = $safeApp
        Path = $file
        Summary = 'Design brief created for a PowerShell Gorrilla poster.'
    }
}

function Get-GorCreativePipelines {
    param($DesignApps = $null)
    $apps = if ($null -eq $DesignApps) { @(Get-GorInstalledApps | Where-Object { $_.Name -match 'Canva|Figma|GIMP|Krita|Inkscape|Blender|OBS|ShareX|Paint|Photo' -and $_.Name -notmatch 'uninstall' }) } else { @(ConvertTo-GorArray $DesignApps) }
    function Find-GorPipelineApp {
        param([string]$Pattern)
        return ($apps | Where-Object { $_.Name -match $Pattern -and $_.Type -eq 'Shortcut' } | Select-Object -First 1)
    }
    $canva = Find-GorPipelineApp -Pattern 'Canva'
    $figma = Find-GorPipelineApp -Pattern 'Figma'
    $gimp = Find-GorPipelineApp -Pattern 'GIMP'
    $krita = Find-GorPipelineApp -Pattern 'Krita'
    $blender = Find-GorPipelineApp -Pattern 'Blender'
    $obs = Find-GorPipelineApp -Pattern 'OBS'
    $sharex = Find-GorPipelineApp -Pattern 'ShareX'
    $pipelines = New-Object System.Collections.Generic.List[object]
    if ($canva -and $gimp -and $sharex) {
        $pipelines.Add([pscustomobject]@{
            Name = 'Poster Launch Kit'
            Outcome = 'Create a polished poster/social graphic, improve source images, and capture/export proof.'
            Apps = @($canva, $gimp, $sharex)
            Steps = @('Draft layout in Canva','Refine image/texture in GIMP','Capture/export and save evidence with ShareX')
            BestFor = 'Posters, announcements, thumbnails, quick brand visuals'
        })
    }
    if ($figma -and $krita -and $obs) {
        $pipelines.Add([pscustomobject]@{
            Name = 'Product Demo Visual'
            Outcome = 'Design a clean UI mockup, create supporting artwork, and record a demo clip.'
            Apps = @($figma, $krita, $obs)
            Steps = @('Compose interface/storyboard in Figma','Paint/edit visual assets in Krita','Record walkthrough with OBS')
            BestFor = 'App demos, feature launches, explainer visuals'
        })
    }
    if ($blender -and ($figma -or $canva) -and $obs) {
        $layout = if ($figma) { $figma } else { $canva }
        $pipelines.Add([pscustomobject]@{
            Name = '3D Showcase'
            Outcome = 'Build a 3D visual, place it into a designed layout, and record/present the result.'
            Apps = @($blender, $layout, $obs)
            Steps = @('Create or render 3D scene in Blender', "Lay out final visual in $($layout.Name)", 'Record or present with OBS')
            BestFor = 'Premium product visuals, hero scenes, dramatic reveals'
        })
    }
    if ($pipelines.Count -eq 0) {
        $fallback = @($apps | Select-Object -First 3)
        if ($fallback.Count -gt 0) {
            $pipelines.Add([pscustomobject]@{
                Name = 'Available Creative Chain'
                Outcome = 'Use the best creative apps currently discovered on the laptop.'
                Apps = $fallback
                Steps = @('Plan the visual','Create or edit the asset','Export or capture the result')
                BestFor = 'General creative work'
            })
        }
    }
    return @(ConvertTo-GorArray $pipelines)
}

function New-GorCreativeProject {
    param(
        [string]$Goal = 'Create something amazing with 2-3 apps',
        [string]$Pipeline = ''
    )
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $pipelines = @(Get-GorCreativePipelines)
    $chosen = if ([string]::IsNullOrWhiteSpace($Pipeline)) { $pipelines | Select-Object -First 1 } else { $pipelines | Where-Object { $_.Name -eq $Pipeline } | Select-Object -First 1 }
    if (-not $chosen) { $chosen = $pipelines | Select-Object -First 1 }
    if (-not $chosen) { throw 'No creative pipeline could be built from discovered apps.' }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $folder = Join-Path $paths.Reports "creative-project-$stamp"
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    $briefPath = Join-Path $folder 'creative-brief.md'
    $appNames = @($chosen.Apps | ForEach-Object { $_.Name })
    $lines = @(
        '# Creative Project Pack',
        '',
        "Goal: $Goal",
        "Pipeline: $($chosen.Name)",
        "Outcome: $($chosen.Outcome)",
        "Apps: $($appNames -join ' -> ')",
        "Created: $(Get-GorNow)",
        '',
        'Steps:'
    )
    $i = 1
    foreach ($step in @($chosen.Steps)) {
        $lines += "$i. $step"
        $i++
    }
    $lines += @(
        '',
        'Prompt for local AI:',
        "Help create '$Goal' using $($appNames -join ', '). Give concise design direction, asset ideas, export checklist, and risks.",
        '',
        'Safety:',
        'This project pack only creates local notes. Apps are opened only when you choose Open.'
    )
    Set-Content -LiteralPath $briefPath -Value $lines -Encoding UTF8
    [pscustomobject]@{
        Status = 'CREATED'
        Goal = $Goal
        Pipeline = $chosen.Name
        Apps = $appNames
        Folder = $folder
        Brief = $briefPath
        Steps = @($chosen.Steps)
    }
}

function Get-GorConnectorCatalog {
    @(
        [pscustomobject]@{ Id='local-ai'; Name='Local AI'; Pattern='Ollama|LM Studio'; Launch='ollama'; Role='Reasoning, drafting, critique, routing'; AuthMode='Local service'; Capabilities=@('Plan','Draft','Critique','Summarise') },
        [pscustomobject]@{ Id='word'; Name='Microsoft Word'; Pattern='Word|Microsoft 365|Office'; Launch='winword'; Role='Long-form manuscript writing and DOCX editing'; AuthMode='Desktop account'; Capabilities=@('Write','Edit','Review','ExportDocx') },
        [pscustomobject]@{ Id='canva'; Name='Canva'; Pattern='Canva'; Launch='canva'; Role='Cover design, interior graphics, marketing visuals'; AuthMode='App or app-window session'; Capabilities=@('DesignCover','CreateImages','ExportArtwork') },
        [pscustomobject]@{ Id='adobe'; Name='Adobe'; Pattern='Adobe|Acrobat|InDesign|Photoshop|Illustrator|Creative Cloud'; Launch='Adobe Creative Cloud'; Role='Print sizing, PDF production, professional layout'; AuthMode='Desktop account'; Capabilities=@('Layout','Preflight','ExportPdf','ImageEdit') },
        [pscustomobject]@{ Id='figma'; Name='Figma'; Pattern='Figma'; Launch='figma'; Role='Structured layouts, templates, design systems'; AuthMode='App or app-window session'; Capabilities=@('Layout','Prototype','DesignSystem') },
        [pscustomobject]@{ Id='web-app-window'; Name='Web App Window'; Pattern='Chrome|Edge|Firefox|Brave'; Launch='msedge'; Role='Chromeless app windows for web apps, research, and publishing portals'; AuthMode='App-window profile'; Capabilities=@('OpenWebApps','Research','Publish') },
        [pscustomobject]@{ Id='gorilla'; Name='Gorilla Launcher'; Pattern='PowerShell Gorrilla|CommandUnit Gorrilla'; Launch='gorvisual'; Role='Always-on control plane and evidence ledger'; AuthMode='Local command centre'; Capabilities=@('Launch','Plan','Verify','Ledger','Report') }
    )
}

function Test-GorLaunchableCommand {
    param([string]$Command)
    if ([string]::IsNullOrWhiteSpace($Command)) { return $false }
    if ($Command -eq 'gorvisual') { return $true }
    if ($Command -in @('msedge','msedge.exe','chrome','chrome.exe')) {
        return [bool](Get-GorAppWindowBrowser)
    }
    return [bool](Get-Command -Name $Command -ErrorAction Ignore)
}

function Get-GorAppWindowBrowser {
    $candidates = New-Object System.Collections.Generic.List[string]
    foreach ($name in @('msedge','msedge.exe','chrome','chrome.exe')) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) {
            if (($cmd.PSObject.Properties.Name -contains 'Source') -and -not [string]::IsNullOrWhiteSpace([string]$cmd.Source)) {
                $candidates.Add([string]$cmd.Source)
            }
            elseif (($cmd.PSObject.Properties.Name -contains 'Path') -and -not [string]::IsNullOrWhiteSpace([string]$cmd.Path)) {
                $candidates.Add([string]$cmd.Path)
            }
        }
    }
    foreach ($candidate in @(
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
        (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe'),
        (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe')
    )) {
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $candidates.Add($candidate)
        }
    }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    return ''
}

function Open-GorAppWindow {
    param([Parameter(Mandatory=$true)][string]$Url)
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $browser = Get-GorAppWindowBrowser
    if ([string]::IsNullOrWhiteSpace($browser)) {
        throw 'No Edge/Chrome app-window runtime was found. Gorilla will not open the dashboard as a normal browser tab.'
    }
    $profile = Join-Path $paths.Dashboard 'AppWindowProfile'
    if (-not (Test-Path -LiteralPath $profile)) {
        New-Item -ItemType Directory -Path $profile -Force | Out-Null
    }
    $args = @(
        "--app=$Url",
        '--new-window',
        '--no-first-run',
        '--no-default-browser-check',
        "--user-data-dir=$profile"
    )
    Start-Process -FilePath $browser -ArgumentList $args -WindowStyle Normal -ErrorAction Stop | Out-Null
    return [pscustomobject]@{
        Url = $Url
        Browser = $browser
        Profile = $profile
        Mode = 'APP_WINDOW_NO_TABS'
    }
}

function Get-GorConnectorAppMatches {
    param([Parameter(Mandatory=$true)][string]$Pattern)
    $roots = @(
        (Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'Microsoft\Windows\Start Menu\Programs'),
        (Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) 'Microsoft\Windows\Start Menu\Programs'),
        ([Environment]::GetFolderPath('CommonDesktopDirectory')),
        (Get-GorDesktop)
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) }
    $appMatches = New-Object System.Collections.ArrayList
    foreach ($root in $roots | Select-Object -Unique) {
        $items = @(Get-ChildItem -LiteralPath $root -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\.(lnk|appref-ms)$' })
        foreach ($item in $items) {
            if ($item.Name -match $Pattern) {
                [void]$appMatches.Add([pscustomobject]@{ Name=[System.IO.Path]::GetFileNameWithoutExtension($item.Name); Path=$item.FullName; Type='Shortcut'; Location=$root })
            }
            if ($appMatches.Count -ge 5) { break }
        }
        if ($appMatches.Count -ge 5) { break }
    }
    return (ConvertTo-GorArray $appMatches)
}

function Get-GorConnectorPassport {
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $passport = Read-GorJson -Path $paths.ConnectorPassportJson -Default $null
    if ($passport -and ($passport.PSObject.Properties.Name -contains 'Connectors')) {
        return $passport
    }
    return [pscustomobject]@{
        UpdatedAt = ''
        Connectors = @()
    }
}

function Set-GorConnectorPassport {
    param(
        [Parameter(Mandatory=$true)][string]$Id,
        [bool]$SignedIn = $true,
        [string]$Note = ''
    )
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $catalog = @(Get-GorConnectorCatalog)
    $connector = $catalog | Where-Object { $_.Id -eq $Id } | Select-Object -First 1
    if (-not $connector) {
        throw "Unknown connector id: $Id"
    }
    $passport = Get-GorConnectorPassport
    $records = @($passport.Connectors | Where-Object { $_.Id -ne $Id })
    $record = [pscustomobject]@{
        Id = $Id
        Name = $connector.Name
        SignedIn = [bool]$SignedIn
        VerifiedAt = Get-GorNow
        Note = if ([string]::IsNullOrWhiteSpace($Note)) { 'User-confirmed visible session state in the Gorilla app.' } else { $Note }
    }
    $records += $record
    $next = [pscustomobject]@{
        UpdatedAt = Get-GorNow
        Connectors = @($records | Sort-Object Id)
    }
    Write-GorJson -Path $paths.ConnectorPassportJson -Value $next
    Write-GorLedger -Type 'connector-passport' -Message "Connector $Id sign-in state updated." -Data $record | Out-Null
    return $record
}

function Get-GorConnectorStatus {
    Initialize-GorEnvironment
    $catalog = @(Get-GorConnectorCatalog)
    $passport = Get-GorConnectorPassport
    $passportRecords = @($passport.Connectors)
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($connector in $catalog) {
        $matches = @(Get-GorConnectorAppMatches -Pattern $connector.Pattern)
        $launchable = (Test-GorLaunchableCommand -Command $connector.Launch) -or ($matches.Count -gt 0)
        $passportRecord = $passportRecords | Where-Object { $_.Id -eq $connector.Id } | Select-Object -First 1
        $signedInConfirmed = [bool]($passportRecord -and $passportRecord.SignedIn -and $launchable)
        $authStatus = switch ($connector.AuthMode) {
            'Local command centre' { 'LOCAL_READY' }
            'Local service' {
                $aiStatus = Get-GorCommandAvailability
                if ($connector.Id -eq 'local-ai' -and $aiStatus.Ollama) { 'LOCAL_READY' } else { 'READY_TO_CONNECT' }
            }
            default {
                if ($signedInConfirmed) { 'SIGNED_IN_CONFIRMED' } elseif ($launchable) { 'AUTH_UNKNOWN' } else { 'NOT_INSTALLED' }
            }
        }
        $status = if ($authStatus -in @('LOCAL_READY','SIGNED_IN_CONFIRMED')) {
            'READY'
        }
        elseif ($launchable) {
            'NEEDS_SIGN_IN_CHECK'
        }
        else {
            'MISSING_OR_WEB_ONLY'
        }
        $rows.Add([pscustomobject]@{
            Id = $connector.Id
            Name = $connector.Name
            Status = $status
            AuthStatus = $authStatus
            Launchable = [bool]$launchable
            AuthMode = $connector.AuthMode
            SignedInConfirmed = [bool]$signedInConfirmed
            VerifiedAt = if ($signedInConfirmed) { [string]$passportRecord.VerifiedAt } else { '' }
            Role = $connector.Role
            Capabilities = @($connector.Capabilities)
            Matches = @($matches | ForEach-Object { $_.Name })
            NextStep = if ($authStatus -eq 'SIGNED_IN_CONFIRMED') { "Visible sign-in confirmed at $($passportRecord.VerifiedAt). Recheck if the app asks you to sign in again." } elseif ($authStatus -eq 'AUTH_UNKNOWN') { 'Open the app once and confirm the visible account/session here. Gorilla records only your approval, never tokens.' } elseif ($authStatus -eq 'READY_TO_CONNECT') { 'Start or connect the local service.' } elseif ($status -eq 'MISSING_OR_WEB_ONLY') { 'Install the app, add a shortcut, or use the app-window version.' } else { 'Ready for local orchestration.' }
        })
    }
    return (ConvertTo-GorArray $rows)
}

function New-GorBookProject {
    param(
        [string]$Title = 'Untitled Book',
        [string]$Goal = 'Write, design, size, illustrate, and package a book using multiple apps.',
        [string]$TrimSize = '6 x 9 in'
    )
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $connectors = @(Get-GorConnectorStatus)
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $safeName = ($Title -replace '[^\w\-. ]','').Trim()
    if ([string]::IsNullOrWhiteSpace($safeName)) { $safeName = 'book-project' }
    $folder = Join-Path $paths.Reports ("book-project-$stamp")
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    $briefPath = Join-Path $folder 'book-orchestration-plan.md'
    $manifestPath = Join-Path $folder 'connector-status.json'
    $steps = @(
        [pscustomobject]@{ Stage='Plan'; App='Local AI + Gorilla'; Output='chapter plan, tone, production checklist'; Requires='local-ai,gorilla' },
        [pscustomobject]@{ Stage='Write'; App='Microsoft Word + Local AI'; Output='manuscript DOCX with AI critique loops'; Requires='word,local-ai' },
        [pscustomobject]@{ Stage='Cover'; App='Canva + Local AI'; Output='front cover concepts and image prompts'; Requires='canva,local-ai' },
        [pscustomobject]@{ Stage='Sizing'; App='Adobe/InDesign/Acrobat'; Output='trim size, bleed, margins, print-ready PDF'; Requires='adobe' },
        [pscustomobject]@{ Stage='Illustrate'; App='Canva/Figma/Adobe'; Output='interior images, diagrams, page assets'; Requires='canva,figma,adobe' },
        [pscustomobject]@{ Stage='Package'; App='Gorilla Launcher'; Output='local evidence folder, reports, final checklist'; Requires='gorilla' }
    )
    $lines = @(
        '# Gorilla Multi-App Book Project',
        '',
        "Title: $Title",
        "Goal: $Goal",
        "Trim size: $TrimSize",
        "Created: $(Get-GorNow)",
        '',
        'Core rule:',
        'Gorilla can orchestrate apps only when each connector has an honest status. It must never claim Word, Canva, Adobe, or an app-window web tool is signed in unless the connector has a user-approved visible-session check.',
        '',
        'Connector truth table:'
    )
    foreach ($c in $connectors) {
        $lines += "- $($c.Name): $($c.Status) / $($c.AuthStatus) / $($c.NextStep)"
    }
    $lines += @('', 'Workflow:')
    $n = 1
    foreach ($step in $steps) {
        $lines += "$n. $($step.Stage) - $($step.App) - $($step.Output)"
        $n++
    }
    $lines += @(
        '',
        'Local AI role:',
        'Local AI can plan, draft, critique, summarise, produce prompts, and decide the next safest app handoff. It should not bypass app accounts, scrape secrets, or pretend to have cloud connector permissions.',
        '',
        'Always connected to Gorilla Launcher:',
        'Every stage routes through the Gorilla dashboard, ledger, reports folder, and connector status table. External apps are workers; Gorilla remains the control plane.'
    )
    Set-Content -LiteralPath $briefPath -Value $lines -Encoding UTF8
    Write-GorJson -Path $manifestPath -Value ([pscustomobject]@{ Title=$Title; Goal=$Goal; TrimSize=$TrimSize; Connectors=$connectors; Steps=$steps })
    [pscustomobject]@{ Status='CREATED'; Title=$Title; Folder=$folder; Brief=$briefPath; Manifest=$manifestPath; ConnectorsReady=(@($connectors | Where-Object Status -eq 'READY')).Count; ConnectorsNeedSignIn=(@($connectors | Where-Object Status -eq 'NEEDS_SIGN_IN_CHECK')).Count; Steps=$steps }
}

function Get-GorProductVision {
    [pscustomobject]@{
        Name = 'Gorilla Command OS'
        OneLine = 'A local-first AI command centre that routes real work across every trusted app on the machine.'
        Direction = 'Build the connector passport first, then ship flagship workflow packs that prove the app can coordinate Word, Canva, Adobe, app-window web tools, local AI, diagnostics, and reports without pretending any connector is ready before it is verified.'
        Principles = @(
            'Truth before automation: show installed, launchable, signed-in, API-connected, missing, or expired.',
            'Gorilla stays the control plane: external apps are workers, the launcher remains the source of status, logs, and next actions.',
            'Local-first by default: use local files, local AI, and visible user approval before cloud/API handoffs.',
            'Only keep useful artifacts: one solid backup, current evidence, and purposeful project packs.',
            'Human approval gates: never publish, email, buy, delete, or upload without a visible checkpoint.'
        )
        NorthStar = 'One request becomes a governed multi-app production line with status, handoffs, outputs, and evidence.'
        Flagship = 'Book Factory: local AI plans and critiques, Word writes, Canva designs covers/images, Adobe sizes and exports, Gorilla tracks the whole chain.'
    }
}

function Get-GorWorldClassWorkflowPacks {
    @(
        [pscustomobject]@{ Name='Book Factory'; Tier='Flagship'; Command='gorbook "My Book"'; Apps='Local AI, Word, Canva, Adobe, Gorilla'; Outcome='Manuscript, cover, images, print-ready checklist, connector manifest, evidence folder'; Risk='LOW'; Detail='The clearest demo of multi-app orchestration and sign-in truth.' },
        [pscustomobject]@{ Name='Business Proposal Studio'; Tier='Business'; Command='gorworkflow list'; Apps='Word, PowerPoint, Excel, app-window web tools, Canva'; Outcome='Client proposal, quote table, visual cover, PDF handoff'; Risk='LOW'; Detail='Turns a client brief into a polished deliverable pack.' },
        [pscustomobject]@{ Name='Marketing Campaign Factory'; Tier='Growth'; Command='gorworkflow list'; Apps='App-window web tools, Canva, local AI, scheduler/email later'; Outcome='Campaign brief, copy variants, creative assets, launch checklist'; Risk='LOW'; Detail='Coordinates ideation, design, copy, and approval gates.' },
        [pscustomobject]@{ Name='Client Report Control Room'; Tier='Operations'; Command='gorintegrate'; Apps='Spreadsheets, documents, charts, PDF, reports'; Outcome='Charts, executive summary, audit trail, delivery folder'; Risk='LOW'; Detail='A business-grade reporting pipeline with evidence.' },
        [pscustomobject]@{ Name='IT Repair and Evidence Desk'; Tier='Reliability'; Command='gordo now'; Apps='PowerShell, logs, ports, services, reports'; Outcome='Diagnostics, safe repair options, before/after evidence'; Risk='LOW'; Detail='Keeps the machine and local apps healthy while avoiding blind fixes.' },
        [pscustomobject]@{ Name='Course and Content Studio'; Tier='Creator'; Command='gorbook "Course Pack"'; Apps='Local AI, Word, Canva, Adobe, app-window web tools'; Outcome='Lessons, worksheets, slides/graphics, export checklist'; Risk='LOW'; Detail='Repurposes the book pipeline into training products.' }
    )
}

function Get-GorBackupPosture {
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $moduleBackups = @(Get-ChildItem -LiteralPath $paths.Backups -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(module-backup|backup)-' } | Sort-Object LastWriteTime -Descending)
    $bookReports = @(Get-ChildItem -LiteralPath $paths.Reports -Directory -Filter 'book-project-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
    $latestBackup = $moduleBackups | Select-Object -First 1
    [pscustomobject]@{
        Status = if ($moduleBackups.Count -le 1 -and $bookReports.Count -le 1) { 'CLEAN' } else { 'NEEDS_TIDY' }
        ModuleBackups = $moduleBackups.Count
        LatestModuleBackup = if ($latestBackup) { $latestBackup.FullName } else { '' }
        ModuleBackupsToRemove = [Math]::Max(0, $moduleBackups.Count - 1)
        BookProjectPacks = $bookReports.Count
        BookProjectPacksToRemove = [Math]::Max(0, $bookReports.Count - 1)
        Rule = 'Keep the newest module backup and newest book project pack; remove older generated copies only.'
    }
}

function Invoke-GorKeepOneBackup {
    param(
        [switch]$Apply,
        [string]$ConfirmText = ''
    )
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $backupRoot = (Resolve-Path -LiteralPath $paths.Backups -ErrorAction Stop).Path
    $reportsRoot = (Resolve-Path -LiteralPath $paths.Reports -ErrorAction Stop).Path
    $moduleBackups = @(Get-ChildItem -LiteralPath $backupRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(module-backup|backup)-' } | Sort-Object LastWriteTime -Descending)
    $bookReports = @(Get-ChildItem -LiteralPath $reportsRoot -Directory -Filter 'book-project-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
    $removeBackups = @($moduleBackups | Select-Object -Skip 1)
    $removeBookReports = @($bookReports | Select-Object -Skip 1)
    $plan = @()
    foreach ($item in $removeBackups) {
        $plan += [pscustomobject]@{ Type='ModuleBackup'; Action='REMOVE'; Path=$item.FullName; LastWriteTime=$item.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') }
    }
    foreach ($item in $removeBookReports) {
        $plan += [pscustomobject]@{ Type='GeneratedBookProject'; Action='REMOVE'; Path=$item.FullName; LastWriteTime=$item.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') }
    }
    if (-not $Apply) {
        return [pscustomobject]@{ Status='PREVIEW'; Rule='Newest module backup and newest book project pack will be kept.'; KeepModuleBackup=if ($moduleBackups.Count) { $moduleBackups[0].FullName } else { '' }; KeepBookProject=if ($bookReports.Count) { $bookReports[0].FullName } else { '' }; Items=$plan }
    }
    if ($ConfirmText -ne 'KEEPONEGORILLA') {
        return [pscustomobject]@{ Status='BLOCKED'; Detail='Pass -ConfirmText KEEPONEGORILLA to remove older generated backups/reports.'; Items=$plan }
    }
    $results = @()
    foreach ($item in $plan) {
        $resolved = (Resolve-Path -LiteralPath $item.Path -ErrorAction SilentlyContinue).Path
        $allowed = $resolved -and ($resolved.StartsWith($backupRoot, [StringComparison]::OrdinalIgnoreCase) -or $resolved.StartsWith($reportsRoot, [StringComparison]::OrdinalIgnoreCase))
        if (-not $allowed) {
            $results += [pscustomobject]@{ Path=$item.Path; Status='SKIPPED'; Detail='Path did not resolve under Gorilla Backups or Reports.' }
            continue
        }
        try {
            Remove-Item -LiteralPath $resolved -Recurse -Force -ErrorAction Stop
            $results += [pscustomobject]@{ Path=$resolved; Status='REMOVED'; Detail=$item.Type }
        }
        catch {
            $results += [pscustomobject]@{ Path=$resolved; Status='FAILED'; Detail=$_.Exception.Message }
        }
    }
    Write-GorLedger -Type 'cleanup' -Message 'Keep-one-backup cleanup applied.' -Data $results | Out-Null
    [pscustomobject]@{ Status='APPLIED'; Results=$results; Posture=(Get-GorBackupPosture) }
}

function New-GorHugeCheck {
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $status = Get-GorStatusObject
    $apps = @(Get-GorInstalledApps | Where-Object { $_.Name -notmatch 'uninstall' })
    $designApps = @($apps | Where-Object { $_.Name -match 'Canva|Figma|GIMP|Krita|Inkscape|Blender|OBS|ShareX|Paint|Photo' })
    $pipelines = @(Get-GorCreativePipelines -DesignApps $designApps)
    $laptop = Get-GorLaptopContext
    $alerts = @(Get-GorAlerts)
    $models = @(Get-GorOllamaModels)
    $matrix = Get-GorPromptMatrix
    $actions = @(Get-GorCommandCatalog)
    $score = 100
    if (-not $status.ParserOk) { $score -= 20 }
    if (-not $status.OllamaAvailable) { $score -= 10 }
    if ($designApps.Count -lt 2) { $score -= 15 }
    if ($pipelines.Count -lt 1) { $score -= 15 }
    if ($alerts.Count -gt 0) { $score -= [Math]::Min(20, $alerts.Count * 4) }
    if ($score -lt 0) { $score = 0 }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $reportPath = Join-Path $paths.Reports "huge-check-$stamp.json"
    $report = [pscustomobject]@{
        Status = if ($score -ge 85) { 'EXCELLENT' } elseif ($score -ge 70) { 'GOOD' } else { 'NEEDS_ATTENTION' }
        Score = $score
        GeneratedAt = Get-GorNow
        App = [pscustomobject]@{ Version=$status.Version; ParserOk=$status.ParserOk; OllamaAvailable=$status.OllamaAvailable; PromptMatrix=$matrix.Count }
        Apps = [pscustomobject]@{ Installed=$apps.Count; Design=$designApps.Count; Pipelines=$pipelines.Count }
        Laptop = $laptop.Summary
        Alerts = $alerts
        Models = $models
        Actions = $actions.Count
        RecommendedUpgrades = @(
            'Use Creative Pipeline to create project packs from 2-3 apps.',
            'Run design brief before opening apps so the work has direction.',
            'Use Laptop Reality before repair decisions.',
            'Keep risky actions confirmation-gated.',
            'Refresh dashboard after installing new creative tools.'
        )
    }
    Write-GorJson -Path $reportPath -Value $report
    [pscustomobject]@{ Status=$report.Status; Score=$score; Path=$reportPath; InstalledApps=$apps.Count; DesignApps=$designApps.Count; Pipelines=$pipelines.Count; PromptMatrix=$matrix.Count }
}

function gorappdiscover {
    $apps = Get-GorInstalledApps
    return $apps
}

function gordesktopapps {
    param(
        [string]$Search = '',
        [switch]$Full
    )
    $rows = if ($Full) { @(Get-GorDesktopAppInventory) } else { @(Get-GorDesktopAppInventory -Quick) }
    if (-not [string]::IsNullOrWhiteSpace($Search)) {
        $q = $Search.ToLowerInvariant()
        $rows = @($rows | Where-Object {
            ([string]$_.Name + ' ' + [string]$_.Source + ' ' + [string]$_.Category + ' ' + [string]$_.ConnectionState).ToLowerInvariant().Contains($q)
        })
    }
    Write-GorTable -Rows ($rows | Select-Object -First 80 Name,Source,Kind,Launchable,KnownToGorilla,Connector,ConnectionState)
    return (ConvertTo-GorArray $rows)
}

function gorpackagebank {
    param(
        [string]$Search = '',
        [int]$First = 80,
        [switch]$Refresh
    )
    if ($Refresh) {
        Initialize-GorPackageBank -Force | Out-Null
    }
    $rows = @(Get-GorPackageBank -Search $Search -First $First)
    Write-GorTable -Rows ($rows | Select-Object Name,Manager,Category,Status,WorksHere,Command,InstallCommand)
    return (ConvertTo-GorArray $rows)
}

function gorconnectors {
    param([Parameter(Position=0)][string]$Action = 'status')
    $rows = Get-GorConnectorStatus
    if ($Action -eq 'report') {
        return (New-GorReport -Title 'Gorilla Connector Status' -Sections @([pscustomobject]@{ Title='Connectors'; Data=$rows }) -FileName 'connector-status.html')
    }
    $summary = @($rows | Select-Object Name,Status,AuthStatus,Launchable,AuthMode,NextStep)
    Write-GorTable -Rows $summary
    return (ConvertTo-GorArray $rows)
}

function gorbook {
    param(
        [Parameter(Position=0)][string]$Title = 'Untitled Book',
        [Parameter(Position=1)][string]$Goal = 'Write, design, size, illustrate, and package a book using multiple apps.',
        [string]$TrimSize = '6 x 9 in'
    )
    $project = New-GorBookProject -Title $Title -Goal $Goal -TrimSize $TrimSize
    Write-GorTable -Rows @($project | Select-Object Status,Title,Brief,Manifest,ConnectorsReady,ConnectorsNeedSignIn)
    return $project
}

function gorkeeponebackup {
    param(
        [Parameter(Position=0)][string]$Action = 'preview',
        [string]$ConfirmText = ''
    )
    if ($Action -eq 'status') {
        $posture = Get-GorBackupPosture
        Write-GorTable -Rows @($posture)
        return $posture
    }
    if ($Action -eq 'apply') {
        $result = Invoke-GorKeepOneBackup -Apply -ConfirmText $ConfirmText
        Write-GorTable -Rows @($result | Select-Object Status)
        if ($result.Results) { Write-GorTable -Rows $result.Results }
        return $result
    }
    $preview = Invoke-GorKeepOneBackup
    Write-GorTable -Rows @($preview | Select-Object Status,Rule,KeepModuleBackup,KeepBookProject)
    if ($preview.Items) { Write-GorTable -Rows $preview.Items }
    return $preview
}

function gorlaptopscan {
    $security = gorsecurity
    $perf = gorperf
    $summary = [pscustomobject]@{
        Check = 'Laptop-wide assessment'
        Status = if (($security.Count + $perf.Count) -gt 0) { 'OK' } else { 'INFO' }
        Detail = "Security findings: $($security.Count); Performance checks: $($perf.Count)"
    }
    Write-GorTable -Rows @($summary)
    return [pscustomobject]@{ Summary = $summary; Security = $security; Performance = $perf }
}

function Start-GorLaunchTarget {
    param([Parameter(Mandatory=$true)][string]$Name)
    $catalog = @(Get-GorLaunchCatalog)
    if ($Name -in @('list','apps','catalog')) {
        return $catalog
    }
    $target = $catalog | Where-Object { $_.Name -eq $Name.ToLowerInvariant() } | Select-Object -First 1
    if (-not $target) {
        throw "Unknown launch target: $Name. Run gorlaunch list."
    }
    $cmd = Get-Command $target.Command -ErrorAction SilentlyContinue
    if ($cmd) {
        Start-Process -FilePath $cmd.Source -ArgumentList $target.Args -WindowStyle Hidden -ErrorAction Stop | Out-Null
        return [pscustomobject]@{ Name=$target.Name; Status='STARTED'; Command=$cmd.Source }
    }
    try {
        Start-Process -FilePath $target.Command -ArgumentList $target.Args -ErrorAction Stop | Out-Null
        return [pscustomobject]@{ Name=$target.Name; Status='STARTED'; Command=$target.Command }
    }
    catch {
        throw "Could not launch $Name. Command not found or app alias unavailable: $($target.Command)"
    }
}

function Invoke-GorAiLab {
    $rows = New-Object System.Collections.Generic.List[object]
    $ollama = Get-Command ollama -ErrorAction SilentlyContinue
    if ($ollama) {
        try {
            $running = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'ollama*' -and $_.CommandLine -like '*serve*' } | Select-Object -First 1
            if (-not $running) {
                Start-Process -FilePath $ollama.Source -ArgumentList 'serve' -WindowStyle Hidden -ErrorAction SilentlyContinue | Out-Null
            }
            $models = & $ollama.Source list 2>$null | Select-Object -Skip 1
            $rows.Add([pscustomobject]@{ Check='Ollama'; Status='OK'; Detail=('Models: ' + @($models).Count) })
        }
        catch {
            $rows.Add([pscustomobject]@{ Check='Ollama'; Status='WARN'; Detail=$_.Exception.Message })
        }
    }
    else {
        $rows.Add([pscustomobject]@{ Check='Ollama'; Status='MISSING'; Detail='Install Ollama or repair PATH.' })
    }
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        docker ps 1>$null 2>$null
        $rows.Add([pscustomobject]@{ Check='Docker'; Status=if ($LASTEXITCODE -eq 0) { 'OK' } else { 'WARN' }; Detail=if ($LASTEXITCODE -eq 0) { 'Docker is running.' } else { 'Docker is installed but not running.' } })
    }
    else {
        $rows.Add([pscustomobject]@{ Check='Docker'; Status='MISSING'; Detail='Docker command not found in this shell.' })
    }
    Write-GorLedger -Type 'ai-lab' -Message 'AI lab checked.' -Data $rows | Out-Null
    return (ConvertTo-GorArray $rows)
}

function New-GorNextWebApp {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [string]$ParentPath = ''
    )
    if ($Name -notmatch '^[a-zA-Z0-9\-_]+$') {
        throw 'Use a simple app name: letters, numbers, dash, underscore only.'
    }
    if ([string]::IsNullOrWhiteSpace($ParentPath)) {
        $ParentPath = Join-Path (Get-GorDocuments) 'GorrillaApps'
    }
    if (-not (Test-Path -LiteralPath $ParentPath)) {
        New-Item -ItemType Directory -Path $ParentPath -Force | Out-Null
    }
    $pnpm = Get-Command pnpm -ErrorAction SilentlyContinue
    if (-not $pnpm) {
        Repair-GorEliteStack | Out-Null
        $pnpm = Get-Command pnpm -ErrorAction SilentlyContinue
    }
    if (-not $pnpm) {
        throw 'pnpm is not available. Run gorelite-fix, reopen PowerShell, then retry.'
    }
    Push-Location $ParentPath
    try {
        & $pnpm.Source create next-app@latest $Name --ts --tailwind --eslint --app --src-dir --use-pnpm --import-alias '@/*'
        $appPath = Join-Path $ParentPath $Name
        if (Test-Path -LiteralPath $appPath) {
            gorappadd $Name $appPath | Out-Null
        }
        Write-GorLedger -Type 'web-app' -Message "Created Next.js app: $Name" -Data ([pscustomobject]@{ Path=$appPath }) | Out-Null
        return [pscustomobject]@{ Name=$Name; Path=$appPath; Status=if (Test-Path -LiteralPath $appPath) { 'CREATED' } else { 'UNKNOWN' } }
    }
    finally {
        Pop-Location
    }
}

function Get-GorIntegrationMap {
    param($EliteRows = $null)
    $elite = if ($null -eq $EliteRows) { @(Get-GorEliteStackRows -Quick) } else { @(ConvertTo-GorArray $EliteRows) }
    $toolStatus = @{}
    foreach ($row in $elite) {
        $toolStatus[$row.Command] = $row.Status
    }
    $flows = @(
        [pscustomobject]@{ Flow='Build web app'; Apps='PowerShell, Node.js, pnpm, VS Code, Git, Playwright'; Command='gordo web MyApp'; Status=if ($toolStatus['node'] -eq 'OK' -and $toolStatus['pnpm'] -eq 'OK' -and $toolStatus['git'] -eq 'OK') { 'READY' } else { 'NEEDS_FIX' }; Safe='Creates a new folder and registers it as a Gorilla app.' },
        [pscustomobject]@{ Flow='Local AI lab'; Apps='PowerShell, Ollama, Docker, Open WebUI'; Command='gordo ai'; Status=if ($toolStatus['ollama'] -eq 'OK') { 'READY' } else { 'NEEDS_FIX' }; Safe='Starts/checks local services only; no tunnel is opened.' },
        [pscustomobject]@{ Flow='Security review'; Apps='Gitleaks, Trivy, Semgrep, pre-commit'; Command='gorsecurity .'; Status=if ($toolStatus['gitleaks'] -eq 'OK' -or $toolStatus['trivy'] -eq 'OK') { 'READY' } else { 'PARTIAL' }; Safe='Read-only scans and report generation.' },
        [pscustomobject]@{ Flow='API and database work'; Apps='Bruno, Postman, Insomnia, DBeaver, Supabase, Prisma, Drizzle'; Command='gorlaunch bruno'; Status=if ($toolStatus['supabase'] -eq 'OK') { 'READY' } else { 'PARTIAL' }; Safe='Launches tools and keeps project state in Gorilla profiles.' },
        [pscustomobject]@{ Flow='Design and capture'; Apps='Figma, Canva, ShareX, OBS, GIMP, Krita, Inkscape, Blender'; Command='gorlaunch figma'; Status='READY'; Safe='Launch-only integration. No files are modified.' },
        [pscustomobject]@{ Flow='Connector truth check'; Apps='Gorilla, Word, Canva, Adobe, app-window web tools, local AI'; Command='gorconnectors'; Status='READY'; Safe='Shows installed/launchable/auth-unknown state without reading secrets or tokens.' },
        [pscustomobject]@{ Flow='Desktop app scan'; Apps='Desktop shortcuts, Start Menu, Program Files, Gorilla launcher'; Command='gordesktopapps'; Status='READY'; Safe='Read-only inventory so the app knows what is actually on this laptop.' },
        [pscustomobject]@{ Flow='Package bank'; Apps='winget, npm, pipx, pip, PowerShell Gallery'; Command='gorpackagebank'; Status='READY'; Safe='Preview-only curated software bank; installs require an explicit future action.' },
        [pscustomobject]@{ Flow='Multi-app book production'; Apps='Gorilla, Local AI, Word, Canva, Adobe, Figma/app-window web tools'; Command='gorbook "My Book"'; Status='READY_TO_PLAN'; Safe='Creates a local orchestration plan and connector manifest; external apps open only by user choice.' },
        [pscustomobject]@{ Flow='Publish preview'; Apps='Caddy, cloudflared, ngrok, Vercel, Netlify, Wrangler'; Command='tunnel-warning'; Status=if ($toolStatus['caddy'] -eq 'OK') { 'READY_SAFE_LOCAL' } else { 'PARTIAL' }; Safe='Gorilla never starts public tunnels automatically.' },
        [pscustomobject]@{ Flow='Evidence cockpit'; Apps='Gorilla dashboard, reports, ledger, test lab'; Command='gordo report'; Status='READY'; Safe='Writes local HTML/JSON evidence only.' }
    )
    return (ConvertTo-GorArray $flows)
}

function Get-GorFixQueue {
    param($EliteIssues = $null)
    $rows = New-Object System.Collections.Generic.List[object]
    $eliteIssues = if ($null -eq $EliteIssues) { @(Get-GorEliteStackIssues -Rows (Get-GorEliteStackRows -Quick)) } else { @(ConvertTo-GorArray $EliteIssues) }
    foreach ($issue in $eliteIssues) {
        $priority = if ($issue.Severity -eq 'HIGH') { 1 } elseif ($issue.Severity -eq 'MEDIUM') { 2 } else { 4 }
        $command = if ($issue.Tool -in @('Corepack','pnpm')) { 'gorelite-fix' } elseif ($issue.Tool -eq 'Node.js') { 'gorelite issues' } else { 'gorelite issues' }
        $rows.Add([pscustomobject]@{ Priority=$priority; Area='Elite Stack'; Item=$issue.Tool; Risk=$issue.Severity; Fix=$issue.Fix; Command=$command })
    }
    $profile = gorprofile-check -Quiet
    if ($profile.Status -ne 'OK') {
        $rows.Add([pscustomobject]@{ Priority=2; Area='Profile'; Item='PowerShell autoload'; Risk='LOW'; Fix=$profile.Detail; Command='gorprofile-repair' })
    }
    $desktopPlan = @(Get-GorDesktopTidyPlan)
    if ($desktopPlan.Count -gt 0) {
        $rows.Add([pscustomobject]@{ Priority=5; Area='Desktop'; Item='Loose desktop items'; Risk='LOW'; Fix=($desktopPlan.Count.ToString() + ' item(s) can be tidied after preview.'); Command='gordesktop tidy' })
    }
    $fire = Get-GorFireDeskStatus
    if ($fire.Exists -and @($fire.BindingRisks).Count -gt 0) {
        $rows.Add([pscustomobject]@{ Priority=2; Area='FireDesk'; Item='Binding risk'; Risk='MEDIUM'; Fix='Patch 0.0.0.0 dashboard binding to 127.0.0.1 after backup and confirmation.'; Command='gorbindlocal FireDesk' })
    }
    if ($rows.Count -eq 0) {
        $rows.Add([pscustomobject]@{ Priority=9; Area='System'; Item='No urgent fixes'; Risk='OK'; Fix='Create a fresh evidence baseline.'; Command='gordo report' })
    }
    return (ConvertTo-GorArray ($rows | Sort-Object Priority, Area, Item))
}

function Get-GorWorkflowCatalog {
    @(
        [pscustomobject]@{ Name='daily'; Title='Daily cockpit check'; Command='gordo now'; Risk='LOW'; Apps='PowerShell, Gorilla dashboard'; Detail='Fast status, stack summary, and launch catalog.' },
        [pscustomobject]@{ Name='boost'; Title='Safe machine boost'; Command='gordo boost'; Risk='MEDIUM'; Apps='PowerShell, pnpm, reports, dashboard'; Detail='Safe repairs, baseline, reports, and visual refresh.' },
        [pscustomobject]@{ Name='full'; Title='Full evidence pass'; Command='gordo full'; Risk='MEDIUM'; Apps='PowerShell, reports, test lab'; Detail='Runs tests and writes a full local report set.' },
        [pscustomobject]@{ Name='web'; Title='Create web project'; Command='gordo web APP_NAME'; Risk='MEDIUM'; Apps='Node.js, pnpm, VS Code, Git, Playwright'; Detail='Creates a Next.js app and registers it with Gorilla.' },
        [pscustomobject]@{ Name='app'; Title='Inspect current app'; Command='gordo app .'; Risk='LOW'; Apps='Security tools, performance checks, reports'; Detail='Doctor, quality, security, performance, and patch preview.' },
        [pscustomobject]@{ Name='discover'; Title='Discover installed apps'; Command='gorappdiscover'; Risk='LOW'; Apps='Start Menu, Desktop, Program Files'; Detail='Identifies installed apps and shortcuts on the laptop.' },
        [pscustomobject]@{ Name='laptop-scan'; Title='Laptop scan'; Command='gorlaptopscan'; Risk='LOW'; Apps='Security, performance'; Detail='Runs a broad local laptop assessment and identifies next fixes.' },
        [pscustomobject]@{ Name='ai'; Title='Local AI lab'; Command='gordo ai'; Risk='LOW'; Apps='Ollama, Docker'; Detail='Starts/checks local AI services without public exposure.' },
        [pscustomobject]@{ Name='security'; Title='Security review'; Command='gorsecurity .'; Risk='LOW'; Apps='Gitleaks, Trivy, Semgrep'; Detail='Read-only local security review.' },
        [pscustomobject]@{ Name='design'; Title='Design station'; Command='gorlaunch figma'; Risk='LOW'; Apps='Figma, Canva, ShareX, OBS'; Detail='Launch-only design/capture workflow.' },
        [pscustomobject]@{ Name='connectors'; Title='Connector truth check'; Command='gorconnectors'; Risk='LOW'; Apps='Gorilla, local AI, Word, Canva, Adobe, app-window web tools'; Detail='Shows which apps are installed, launchable, local-ready, or still need visible sign-in confirmation.' },
        [pscustomobject]@{ Name='desktop-apps'; Title='Desktop app scan'; Command='gordesktopapps'; Risk='LOW'; Apps='Desktop, Start Menu, Program Files'; Detail='Scans real local app launch points so Gorilla can choose tools honestly.' },
        [pscustomobject]@{ Name='package-bank'; Title='Package manager bank'; Command='gorpackagebank'; Risk='LOW'; Apps='winget, npm, pipx, pip, PowerShell Gallery'; Detail='Shows 100+ high-quality software options and what works on this laptop right now.' },
        [pscustomobject]@{ Name='book'; Title='Multi-app book production'; Command='gorbook "My Book"'; Risk='LOW'; Apps='Local AI, Word, Canva, Adobe, Gorilla dashboard'; Detail='Creates a local book-production plan with connector status, handoffs, outputs, and evidence files.' },
        [pscustomobject]@{ Name='api'; Title='API and database station'; Command='gorlaunch bruno'; Risk='LOW'; Apps='Bruno, Postman, Insomnia, DBeaver'; Detail='Launch API/database tools from the catalog.' },
        [pscustomobject]@{ Name='clean'; Title='One solid backup'; Command='gorkeeponebackup preview'; Risk='LOW'; Apps='Gorilla backups, reports, ledger'; Detail='Previews old generated backups and test book packs so only the newest solid copy remains.' },
        [pscustomobject]@{ Name='update'; Title='Safe update center'; Command='gorupdate preview'; Risk='LOW'; Apps='PowerShell, backups, parser'; Detail='Preview update state and next safe commands.' }
    )
}

function Resolve-GorIntent {
    param([Parameter(Mandatory=$true)][string]$Text)
    $q = $Text.ToLowerInvariant()
    $rows = New-Object System.Collections.Generic.List[object]
    if ($q -match 'fix|broken|repair|safe|issue|problem') {
        $rows.Add([pscustomobject]@{ Rank=1; Command='gorfixqueue'; Risk='LOW'; Why='Shows prioritized safe fixes before applying anything.' })
    }
    if ($q -match 'web|next|site|react|tailwind') {
        $rows.Add([pscustomobject]@{ Rank=2; Command='gordo web MyApp'; Risk='MEDIUM'; Why='Creates a new web app using Node.js and pnpm after safe checks.' })
    }
    if ($q -match 'book|manuscript|cover|adobe|word|publish|trim size|isbn') {
        $rows.Add([pscustomobject]@{ Rank=1; Command='gorconnectors'; Risk='LOW'; Why='Checks app and sign-in truth before planning a multi-app production workflow.' })
        $rows.Add([pscustomobject]@{ Rank=2; Command='gorbook "My Book"'; Risk='LOW'; Why='Creates a local book-production orchestration plan across AI, Word, Canva, Adobe, and Gorilla.' })
    }
    if ($q -match 'design|poster|graphic|creative|canva|figma|image|brand|logo') {
        $rows.Add([pscustomobject]@{ Rank=1; Command='gorworkflow list'; Risk='LOW'; Why='Shows the design workflow before opening creative tools.' })
        $rows.Add([pscustomobject]@{ Rank=2; Command='gorlaunch figma'; Risk='LOW'; Why='Opens a design tool from the launch catalog when available.' })
    }
    if ($q -match 'ai|ollama|model|local assistant') {
        $rows.Add([pscustomobject]@{ Rank=2; Command='gorai'; Risk='LOW'; Why='Starts/checks local Ollama and Docker readiness.' })
    }
    if ($q -match 'security|scan|secret|vulnerability') {
        $rows.Add([pscustomobject]@{ Rank=2; Command='gorsecurity .'; Risk='LOW'; Why='Runs read-only local security review.' })
    }
    if ($q -match 'update|upgrade|version') {
        $rows.Add([pscustomobject]@{ Rank=2; Command='gorupdate preview'; Risk='LOW'; Why='Shows update state and rollback options before changing files.' })
    }
    if ($q -match 'cleanup|clean|rubbish|backup|keep one|old test|unused') {
        $rows.Add([pscustomobject]@{ Rank=1; Command='gorkeeponebackup preview'; Risk='LOW'; Why='Previews older generated backups and test packs so only the newest useful copy remains.' })
    }
    if ($q -match 'connect|connector|signed in|sign in|auth|account') {
        $rows.Add([pscustomobject]@{ Rank=1; Command='gorconnectors'; Risk='LOW'; Why='Shows connector readiness and where visible sign-in checks are still needed.' })
    }
    if ($q -match 'desktop apps|desktop scan|start menu|what apps|installed apps|scan apps') {
        $rows.Add([pscustomobject]@{ Rank=1; Command='gordesktopapps'; Risk='LOW'; Why='Scans Desktop, Start Menu, and Program Files so Gorilla knows the local app reality.' })
    }
    if ($q -match 'package|install|software bank|package manager|winget|npm|pipx|tools bank') {
        $rows.Add([pscustomobject]@{ Rank=1; Command='gorpackagebank'; Risk='LOW'; Why='Shows curated software options and whether this laptop has the right manager or app already.' })
    }
    if ($q -match 'integrat|together|workflow|apps|multiapp|multi-app') {
        $rows.Add([pscustomobject]@{ Rank=2; Command='gorintegrate'; Risk='LOW'; Why='Shows how the installed apps work together.' })
    }
    if ($q -match 'launch|open|choose app|installed app|tool') {
        $rows.Add([pscustomobject]@{ Rank=2; Command='gorappdiscover'; Risk='LOW'; Why='Lists discovered apps and shortcuts so the right tool can be chosen.' })
    }
    if ($q -match 'laptop|machine|really going on|process|ports|services|errors') {
        $rows.Add([pscustomobject]@{ Rank=2; Command='gorlaptopscan'; Risk='LOW'; Why='Reads local laptop signals before making repair recommendations.' })
    }
    if ($q -match 'dashboard|visual|ui|app itself') {
        $rows.Add([pscustomobject]@{ Rank=2; Command='gorvisual'; Risk='LOW'; Why='Regenerates and opens the local dashboard.' })
    }
    if ($rows.Count -eq 0) {
        $rows.Add([pscustomobject]@{ Rank=9; Command='gordo now'; Risk='LOW'; Why='Default safe cockpit check.' })
        $rows.Add([pscustomobject]@{ Rank=10; Command='gorworkflow list'; Risk='LOW'; Why='Shows available workflows.' })
    }
    return (ConvertTo-GorArray ($rows | Sort-Object Rank, Command))
}

function Invoke-GorUnderstanding {
    param([Parameter(Mandatory=$true)][string]$Text)
    $paths = Get-GorPaths
    $suggestions = @(Resolve-GorIntent -Text $Text)
    $ollama = $null
    $promptPath = $paths.IntentPrompt
    if (Test-Path -LiteralPath $promptPath) {
        $policy = Get-Content -LiteralPath $promptPath -Raw -ErrorAction SilentlyContinue
        $apps = @(Get-GorInstalledApps | Select-Object -First 80 Name,Type,RelativePath)
        $matrix = Get-GorPromptMatrix
        $laptop = Get-GorLaptopContext
        $context = [pscustomobject]@{
            PromptMatrixCount = $matrix.Count
            InstalledApps = $apps
            LaptopSummary = $laptop.Summary
            TopPorts = @($laptop.ListeningPorts | Select-Object -First 8)
            TopProcesses = @($laptop.TopProcesses | Select-Object -First 8)
        }
        $prompt = $policy + "`n`nUSER REQUEST:`n" + $Text + "`n`nLOCAL CONTEXT:`n" + (($context | ConvertTo-Json -Depth 8) | Out-String) + "`n`nSUGGESTED COMMANDS:`n" + (($suggestions | ConvertTo-Json -Depth 6) | Out-String) + "`nReturn a short safe recommendation. Choose relevant installed apps by name when useful."
        $ollama = Invoke-GorLocalAI -Prompt $prompt -TimeoutSeconds 25
    }
    [pscustomobject]@{
        Request = $Text
        Suggestions = @($suggestions)
        Ollama = if ($ollama) { $ollama } else { 'Ollama did not answer; deterministic PowerShell suggestions are shown.' }
        Safety = 'Suggestions only. Use the command explicitly to run it; medium/high risk actions require confirmation.'
    }
}

function Get-GorUpdatePlan {
    param([string]$SourcePath = '')
    $paths = Get-GorPaths
    $source = if ([string]::IsNullOrWhiteSpace($SourcePath)) { Get-GorModuleRoot } else { (Resolve-Path -LiteralPath $SourcePath -ErrorAction Stop).Path }
    $installedRoot = Get-GorUserModuleInstallRoot
    $sourceModule = Join-Path $source 'CommandUnitGorrilla.psm1'
    $sourceManifest = Join-Path $source 'CommandUnitGorrilla.psd1'
    $installedModule = Join-Path $installedRoot 'CommandUnitGorrilla.psm1'
    $installedManifest = Join-Path $installedRoot 'CommandUnitGorrilla.psd1'
    $parse = if (Test-Path -LiteralPath $sourceModule) { Test-GorParseFile -Path $sourceModule } else { [pscustomobject]@{ Ok=$false; Errors=@('Source module missing') } }
    $candidateVersion = ''
    if (Test-Path -LiteralPath $sourceManifest) {
        try { $candidateVersion = [string](Test-ModuleManifest -Path $sourceManifest -ErrorAction Stop).Version } catch { $candidateVersion = 'Unknown' }
    }
    $installedVersion = ''
    if (Test-Path -LiteralPath $installedManifest) {
        try { $installedVersion = [string](Test-ModuleManifest -Path $installedManifest -ErrorAction Stop).Version } catch { $installedVersion = 'Unknown' }
    }
    $sourceHash = Get-GorFileHashSafe -Path $sourceModule
    $installedHash = Get-GorFileHashSafe -Path $installedModule
    [pscustomobject]@{
        CreatedAt = Get-GorNow
        SourcePath = $source
        SourceModule = $sourceModule
        SourceManifest = $sourceManifest
        InstalledRoot = $installedRoot
        InstalledModule = $installedModule
        InstalledManifest = $installedManifest
        SourceExists = ((Test-Path -LiteralPath $sourceModule) -and (Test-Path -LiteralPath $sourceManifest))
        ParseOk = $parse.Ok
        CurrentVersion = $installedVersion
        CandidateVersion = $candidateVersion
        SourceHash = $sourceHash
        InstalledHash = $installedHash
        NeedsUpdate = [bool]($sourceHash -and ($sourceHash -ne $installedHash))
        BackupCommand = 'gorbackup-module'
        ApplyCommand = "gorupdate apply `"$source`" -ConfirmText UPDATEGORRILLA"
        RollbackCommand = 'gormodule-rollback'
        Risk = 'HIGH when applying; LOW when previewing'
        Action = if ($parse.Ok) { 'Preview only. Apply requires UPDATEGORRILLA.' } else { 'Do not apply until parser errors are fixed.' }
        Notes = 'Backs up the installed module, copies local source into the user module folder, and refreshes the desktop launcher.'
    }
}

function Invoke-GorUpdateApply {
    param(
        [Parameter(Mandatory=$true)][string]$SourcePath,
        [string]$ConfirmText = ''
    )
    if ($ConfirmText -ne 'UPDATEGORRILLA') {
        throw 'Typed confirmation required: UPDATEGORRILLA'
    }
    $plan = Get-GorUpdatePlan -SourcePath $SourcePath
    if (-not $plan.SourceExists) { throw 'Update source is missing required module files.' }
    if (-not $plan.ParseOk) { throw 'Update source failed parser validation.' }
    $installedRoot = [string]$plan.InstalledRoot
    if (-not (Test-Path -LiteralPath $installedRoot)) {
        New-Item -ItemType Directory -Path $installedRoot -Force | Out-Null
    }
    $backup = if (Test-Path -LiteralPath $installedRoot) {
        New-GorBackup -Path $installedRoot -Reason 'module-update'
    } else {
        $null
    }
    if ($backup) {
        Write-GorLedger -Type 'backup' -Message 'Installed module backup created before update.' -Data $backup | Out-Null
    }
    Copy-Item -LiteralPath $plan.SourceModule -Destination $plan.InstalledModule -Force
    Copy-Item -LiteralPath $plan.SourceManifest -Destination $plan.InstalledManifest -Force
    $sourceAssets = Join-Path ([string]$plan.SourcePath) 'assets'
    if (Test-Path -LiteralPath $sourceAssets) {
        $targetAssets = Join-Path $installedRoot 'assets'
        if (-not (Test-Path -LiteralPath $targetAssets)) {
            New-Item -ItemType Directory -Path $targetAssets -Force | Out-Null
        }
        Copy-Item -Path (Join-Path $sourceAssets '*') -Destination $targetAssets -Recurse -Force -ErrorAction SilentlyContinue
    }
    $launcher = New-GorLauncher
    Write-GorJson -Path (Get-GorPaths).UpdatePlanJson -Value $plan
    Write-GorLedger -Type 'update' -Message 'Module update applied from local source.' -Data ([pscustomobject]@{ Plan=$plan; Backup=$backup; Launcher=$launcher }) | Out-Null
    [pscustomobject]@{ Status='APPLIED'; Version=$script:GorVersion; Backup=$backup; InstalledModule=$plan.InstalledModule; LauncherPs1=$launcher.LauncherPs1; DesktopShortcut=$launcher.DesktopShortcut }
}

function Invoke-GorLocalAI {
    param(
        [Parameter(Mandatory=$true)][string]$Prompt,
        [int]$TimeoutSeconds = 45
    )
    $askCmd = Get-Command ask -ErrorAction Ignore
    if ($askCmd) {
        try {
            $job = Start-Job -ScriptBlock {
                param($p)
                & ask $p 2>&1
            } -ArgumentList $Prompt
            $done = Wait-Job -Job $job -Timeout $TimeoutSeconds
            if ($done) {
                $result = Receive-Job -Job $job
                Remove-Job -Job $job -Force
                return ($result | Out-String).Trim()
            }
            Stop-Job -Job $job -ErrorAction SilentlyContinue
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-Verbose "ask failed: $($_.Exception.Message)"
        }
    }

    $ollamaCmd = Get-Command ollama -ErrorAction Ignore
    if ($ollamaCmd) {
        try {
            $modelsRaw = & ollama list 2>$null
            $modelLines = @($modelsRaw | Select-Object -Skip 1)
            $first = $null
            foreach ($line in $modelLines) {
                $trimmed = ([string]$line).Trim()
                if ($trimmed.Length -gt 0) {
                    $first = ($trimmed -split '\s+')[0]
                    break
                }
            }
            if ($first) {
                $job = Start-Job -ScriptBlock {
                    param($modelName, $p)
                    & ollama run $modelName $p 2>&1
                } -ArgumentList $first, $Prompt
                $done = Wait-Job -Job $job -Timeout $TimeoutSeconds
                if ($done) {
                    $result = Receive-Job -Job $job
                    Remove-Job -Job $job -Force
                    return ($result | Out-String).Trim()
                }
                Stop-Job -Job $job -ErrorAction SilentlyContinue
                Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Verbose "ollama failed: $($_.Exception.Message)"
        }
    }
    return $null
}

function Get-GorLegacyModules {
    $modules = Get-Module -ListAvailable -Name 'CommandUnit*' -ErrorAction SilentlyContinue
    $rows = foreach ($module in $modules) {
        if ($module.Name -ne 'CommandUnitGorrilla') {
            [pscustomobject]@{
                Name = $module.Name
                Version = [string]$module.Version
                Path = $module.Path
                Loaded = [bool](Get-Module -Name $module.Name -ErrorAction SilentlyContinue)
            }
        }
    }
    return (ConvertTo-GorArray $rows)
}

function Get-GorSavedApps {
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $apps = Get-GorJson -Path $paths.AppsJson -Default @()
    return @(ConvertTo-GorArray $apps)
}

function Save-GorSavedApps {
    param([Parameter(Mandatory=$true)]$Apps)
    $paths = Get-GorPaths
    Set-GorJson -Path $paths.AppsJson -Value @(ConvertTo-GorArray $Apps)
}

function Resolve-GorTarget {
    param([Parameter(Mandatory=$true)][string]$NameOrPath)
    $expanded = [Environment]::ExpandEnvironmentVariables($NameOrPath)
    if (Test-Path -LiteralPath $expanded) {
        return (Resolve-Path -LiteralPath $expanded).Path
    }
    if ($NameOrPath -match '^(firedesk|firedeskelite)$') {
        $fire = Join-Path (Get-GorDesktop) 'FireDeskElite\Dashboard'
        if (Test-Path -LiteralPath $fire) {
            return (Resolve-Path -LiteralPath $fire).Path
        }
    }
    $apps = Get-GorSavedApps
    foreach ($app in $apps) {
        if ($app.Name -eq $NameOrPath) {
            if (Test-Path -LiteralPath $app.Path) {
                return (Resolve-Path -LiteralPath $app.Path).Path
            }
            return [string]$app.Path
        }
    }
    throw "Target not found as a saved app or path: $NameOrPath"
}

function Get-GorRelativePath {
    param(
        [Parameter(Mandatory=$true)][string]$Base,
        [Parameter(Mandatory=$true)][string]$Path
    )
    try {
        $baseUri = New-Object System.Uri (($Base.TrimEnd('\') + '\'))
        $pathUri = New-Object System.Uri $Path
        return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($pathUri).ToString()).Replace('/', '\')
    }
    catch {
        return $Path
    }
}

function Get-GorFileHashSafe {
    param([Parameter(Mandatory=$true)][string]$Path)
    try {
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            $hash = Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop
            return $hash.Hash
        }
    }
    catch {
        return $null
    }
    return $null
}

function Get-GorAppFiles {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [int]$MaxFiles = 1200
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        return @()
    }
    $skipDirs = @('.git','.hg','.svn','node_modules','.venv','venv','env','__pycache__','bin','obj','target','dist','build','.next','.turbo')
    $allowed = @('.ps1','.psm1','.psd1','.py','.js','.jsx','.ts','.tsx','.json','.toml','.yaml','.yml','.md','.txt','.html','.css','.cs','.rs','.go','.env','.ini','.cfg')
    $all = Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($file in $all) {
        if ($rows.Count -ge $MaxFiles) {
            break
        }
        $full = $file.FullName
        $blocked = $false
        foreach ($skip in $skipDirs) {
            $needle = '\' + $skip + '\'
            if ($full.IndexOf($needle, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $blocked = $true
                break
            }
        }
        if ($blocked) {
            continue
        }
        $ext = $file.Extension.ToLowerInvariant()
        if ($allowed -contains $ext -or $file.Name -in @('Dockerfile','Makefile','Procfile')) {
            $rows.Add([pscustomobject]@{
                Name = $file.Name
                Path = $full
                RelativePath = Get-GorRelativePath -Base $Path -Path $full
                Extension = $file.Extension
                Length = $file.Length
                LastWriteTime = $file.LastWriteTime
                Hash = Get-GorFileHashSafe -Path $full
            })
        }
    }
    return (ConvertTo-GorArray $rows)
}

function Test-GorAnyFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string[]]$Names
    )
    foreach ($name in $Names) {
        $candidate = Join-Path $Path $name
        if (Test-Path -LiteralPath $candidate) {
            return $true
        }
    }
    return $false
}

function Get-GorAppType {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        $Files = $null
    )
    $types = New-Object System.Collections.Generic.List[string]
    $name = Split-Path -Leaf $Path
    if ($name -match 'FireDesk') { $types.Add('FireDesk') }
    if ($name -match 'Zara') { $types.Add('Zara') }
    if ($name -match 'Viewzy') { $types.Add('Viewzy') }
    if ($name -match 'Letterbox') { $types.Add('Letterbox') }
    if (Test-GorAnyFile -Path $Path -Names @('package.json')) {
        $types.Add('Node')
        if (Test-GorAnyFile -Path $Path -Names @('vite.config.js','vite.config.ts')) { $types.Add('Vite') }
    }
    if (Test-GorAnyFile -Path $Path -Names @('requirements.txt','pyproject.toml','Pipfile','setup.py')) {
        $types.Add('Python')
    }
    if (Test-GorAnyFile -Path $Path -Names @('app.py','main.py')) {
        $types.Add('Flask/FastAPI candidate')
    }
    if (Test-GorAnyFile -Path $Path -Names @('*.csproj')) {
        $types.Add('DotNet')
    }
    else {
        $csproj = Get-ChildItem -LiteralPath $Path -Filter '*.csproj' -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($csproj) { $types.Add('DotNet') }
    }
    if (Test-GorAnyFile -Path $Path -Names @('Cargo.toml')) { $types.Add('Rust') }
    if (Test-GorAnyFile -Path $Path -Names @('go.mod')) { $types.Add('Go') }
    $psm = Get-ChildItem -LiteralPath $Path -Filter '*.psm1' -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($psm) { $types.Add('PowerShell module') }
    if ($types.Count -eq 0) { $types.Add('unknown') }
    return (ConvertTo-GorArray $types)
}

function Search-GorTextInFiles {
    param(
        [Parameter(Mandatory=$true)]$Files,
        [Parameter(Mandatory=$true)][string[]]$Patterns
    )
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($file in (ConvertTo-GorArray $Files)) {
        if (-not (Test-Path -LiteralPath $file.Path -PathType Leaf)) {
            continue
        }
        try {
            $matches = Select-String -LiteralPath $file.Path -Pattern $Patterns -SimpleMatch -ErrorAction SilentlyContinue
            foreach ($match in $matches) {
                $rows.Add([pscustomobject]@{
                    RelativePath = $file.RelativePath
                    Path = $file.Path
                    Line = $match.LineNumber
                    Text = $match.Line.Trim()
                    Pattern = $match.Pattern
                })
            }
        }
        catch {
            Write-Verbose "Search failed for $($file.Path): $($_.Exception.Message)"
        }
    }
    return (ConvertTo-GorArray $rows)
}

function Search-GorRegexInFiles {
    param(
        $Files = $null,
        [string]$Path = '',
        [Parameter(Mandatory=$true)][string]$Pattern,
        [string]$Risk = 'LOW',
        [string]$Category = 'Search',
        [int]$MaxFiles = 1200,
        [int]$MaxMatches = 200
    )
    if ($null -eq $Files -and -not [string]::IsNullOrWhiteSpace($Path)) {
        $Files = Get-GorAppFiles -Path $Path -MaxFiles $MaxFiles
    }
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($file in (ConvertTo-GorArray $Files)) {
        if ($rows.Count -ge $MaxMatches) {
            break
        }
        if (-not (Test-Path -LiteralPath $file.Path -PathType Leaf)) {
            continue
        }
        try {
            $matches = Select-String -LiteralPath $file.Path -Pattern $Pattern -ErrorAction SilentlyContinue
            foreach ($match in $matches) {
                $rows.Add([pscustomobject]@{
                    Category = $Category
                    Risk = $Risk
                    RelativePath = $file.RelativePath
                    Path = $file.Path
                    Line = $match.LineNumber
                    Text = $match.Line.Trim()
                })
            }
        }
        catch {
            Write-Verbose "Regex search failed for $($file.Path): $($_.Exception.Message)"
        }
    }
    return (ConvertTo-GorArray $rows)
}

function Get-GorAppIndex {
    param([Parameter(Mandatory=$true)][string]$Path)
    $resolved = Resolve-GorTarget -NameOrPath $Path
    $files = Get-GorAppFiles -Path $resolved
    $types = Get-GorAppType -Path $resolved -Files $files
    $risks = New-Object System.Collections.Generic.List[object]

    $bindMatches = Search-GorTextInFiles -Files $files -Patterns @('0.0.0.0')
    foreach ($item in $bindMatches) {
        $risks.Add([pscustomobject]@{
            Category = 'Network binding'
            Risk = 'MEDIUM'
            RelativePath = $item.RelativePath
            Path = $item.Path
            Line = $item.Line
            Text = $item.Text
            Description = 'Found 0.0.0.0 binding. Prefer 127.0.0.1 for laptop-local dashboards.'
        })
    }

    $debugMatches = Search-GorTextInFiles -Files $files -Patterns @('debug=True','debug = True')
    foreach ($item in $debugMatches) {
        $risks.Add([pscustomobject]@{
            Category = 'Debug mode'
            Risk = 'MEDIUM'
            RelativePath = $item.RelativePath
            Path = $item.Path
            Line = $item.Line
            Text = $item.Text
            Description = 'Python debug mode appears enabled.'
        })
    }

    $secretRegex = '(?i)(password|passwd|secret|token|api[_-]?key)\s*[:=]\s*["''][^"'']{6,}["'']'
    $secretMatches = Search-GorRegexInFiles -Files $files -Pattern $secretRegex -Risk 'HIGH' -Category 'Secret pattern'
    foreach ($item in $secretMatches) {
        $risks.Add([pscustomobject]@{
            Category = $item.Category
            Risk = $item.Risk
            RelativePath = $item.RelativePath
            Path = $item.Path
            Line = $item.Line
            Text = $item.Text
            Description = 'Possible hardcoded credential-like text.'
        })
    }

    $todoMatches = Search-GorTextInFiles -Files $files -Patterns @('TODO','FIXME','BUG','HACK')
    foreach ($item in $todoMatches) {
        $risks.Add([pscustomobject]@{
            Category = 'Code marker'
            Risk = 'LOW'
            RelativePath = $item.RelativePath
            Path = $item.Path
            Line = $item.Line
            Text = $item.Text
            Description = 'Developer marker found.'
        })
    }

    if ($types -contains 'Python') {
        $hasVenv = (Test-Path -LiteralPath (Join-Path $resolved '.venv')) -or (Test-Path -LiteralPath (Join-Path $resolved 'venv'))
        if (-not $hasVenv) {
            $risks.Add([pscustomobject]@{
                Category = 'Python environment'
                Risk = 'MEDIUM'
                RelativePath = ''
                Path = $resolved
                Line = 0
                Text = ''
                Description = 'Python project hints exist but no .venv or venv folder was found.'
            })
        }
        $hasReq = Test-GorAnyFile -Path $resolved -Names @('requirements.txt','pyproject.toml','Pipfile')
        if (-not $hasReq) {
            $pyFiles = $files | Where-Object { $_.Extension -eq '.py' } | Select-Object -First 1
            if ($pyFiles) {
                $risks.Add([pscustomobject]@{
                    Category = 'Python dependencies'
                    Risk = 'LOW'
                    RelativePath = ''
                    Path = $resolved
                    Line = 0
                    Text = ''
                    Description = 'Python files exist but no requirements.txt, pyproject.toml, or Pipfile was found.'
                })
            }
        }
    }

    if ($types -contains 'Node') {
        $hasNodeModules = Test-Path -LiteralPath (Join-Path $resolved 'node_modules')
        if (-not $hasNodeModules) {
            $risks.Add([pscustomobject]@{
                Category = 'Node dependencies'
                Risk = 'LOW'
                RelativePath = ''
                Path = $resolved
                Line = 0
                Text = ''
                Description = 'package.json exists but node_modules was not found.'
            })
        }
    }
    else {
        $jsFile = $files | Where-Object { $_.Extension -in @('.js','.jsx','.ts','.tsx') } | Select-Object -First 1
        if ($jsFile) {
            $risks.Add([pscustomobject]@{
                Category = 'Node dependencies'
                Risk = 'LOW'
                RelativePath = ''
                Path = $resolved
                Line = 0
                Text = ''
                Description = 'JavaScript or TypeScript files exist but no package.json was detected.'
            })
        }
    }

    [pscustomobject]@{
        Path = $resolved
        Name = Split-Path -Leaf $resolved
        IndexedAt = Get-GorNow
        Types = @(ConvertTo-GorArray $types)
        FileCount = @($files).Count
        Files = @($files)
        Risks = @(ConvertTo-GorArray $risks)
    }
}

function New-GorPlanAction {
    param(
        [Parameter(Mandatory=$true)][string]$Id,
        [Parameter(Mandatory=$true)][string]$Category,
        [ValidateSet('LOW','MEDIUM','HIGH')][string]$Risk = 'LOW',
        [Parameter(Mandatory=$true)][string]$Description,
        [Parameter(Mandatory=$true)][string]$Command,
        [bool]$Enabled = $true
    )
    [pscustomobject]@{
        Id = $Id
        Category = $Category
        Risk = $Risk
        Description = $Description
        Command = $Command
        Enabled = $Enabled
        Status = 'PENDING'
    }
}

function New-GorFallbackPlan {
    param(
        [Parameter(Mandatory=$true)]$Index,
        [string]$Goal = 'Inspect and improve this app safely.'
    )
    $actions = New-Object System.Collections.Generic.List[object]
    $actions.Add((New-GorPlanAction -Id 'scan-summary' -Category 'Inspection' -Risk 'LOW' -Description 'Record app type, file count, and detected risk summary.' -Command 'GOR:SCAN'))
    if ($Index.Types -contains 'Python' -or $Index.Types -contains 'Flask/FastAPI candidate' -or $Index.Types -contains 'FireDesk') {
        $actions.Add((New-GorPlanAction -Id 'python-compile' -Category 'Validation' -Risk 'LOW' -Description 'Run Python compile checks against discovered Python files.' -Command 'GOR:PY_COMPILE'))
    }
    if ($Index.Types -contains 'Node' -or $Index.Types -contains 'Vite') {
        $actions.Add((New-GorPlanAction -Id 'node-package-check' -Category 'Validation' -Risk 'LOW' -Description 'Check package.json scripts and dependency metadata.' -Command 'GOR:NODE_PACKAGE_CHECK'))
    }
    $bindRisk = $false
    foreach ($risk in (ConvertTo-GorArray $Index.Risks)) {
        if ($risk.Category -eq 'Network binding') {
            $bindRisk = $true
            break
        }
    }
    if ($bindRisk) {
        $actions.Add((New-GorPlanAction -Id 'bind-local-preview' -Category 'Patch preview' -Risk 'LOW' -Description 'Preview files that would change from 0.0.0.0 to 127.0.0.1.' -Command 'GOR:PATCH_BIND_LOCAL_PREVIEW'))
        $actions.Add((New-GorPlanAction -Id 'bind-local-patch' -Category 'Patch' -Risk 'MEDIUM' -Description 'Backup first, then replace 0.0.0.0 with 127.0.0.1 in app/config files.' -Command 'GOR:PATCH_BIND_LOCAL' -Enabled $false))
    }
    $actions.Add((New-GorPlanAction -Id 'session-report' -Category 'Report' -Risk 'LOW' -Description 'Generate a repair session HTML report.' -Command 'GOR:REPORT'))
    [pscustomobject]@{
        Goal = $Goal
        CreatedAt = Get-GorNow
        Source = 'Gorrilla fallback planner'
        Summary = 'Safe fallback plan generated without requiring paid APIs. Local AI notes may be attached if ask or Ollama is available.'
        Actions = @(ConvertTo-GorArray $actions)
        AiNotes = $null
    }
}

function Add-GorAiNotesToPlan {
    param(
        [Parameter(Mandatory=$true)]$Plan,
        [Parameter(Mandatory=$true)]$Index,
        [string]$Goal = 'Inspect and improve this app safely.'
    )
    $riskLines = foreach ($risk in (ConvertTo-GorArray $Index.Risks | Select-Object -First 40)) {
        "$($risk.Risk) $($risk.Category) $($risk.RelativePath):$($risk.Line) $($risk.Description)"
    }
    $promptLines = @(
        'You are a local Windows app repair engineer. Produce concise engineering notes only.',
        'Do not suggest paid APIs, credential extraction, destructive actions, registry edits, or hidden persistence.',
        "Goal: $Goal",
        "App: $($Index.Name)",
        "Path: $($Index.Path)",
        "Types: $([string]::Join(', ', @($Index.Types)))",
        'Detected risks:',
        ($riskLines -join [Environment]::NewLine),
        'Return: key diagnosis, safe next checks, and backup-first patch ideas.'
    )
    $prompt = $promptLines -join [Environment]::NewLine
    $notes = Invoke-GorLocalAI -Prompt $prompt -TimeoutSeconds 45
    if ($notes) {
        $Plan.AiNotes = $notes
        $Plan.Source = $Plan.Source + ' + local AI notes'
    }
    return $Plan
}

function New-GorSession {
    param(
        [Parameter(Mandatory=$true)][string]$NameOrPath,
        [string]$Goal = 'Inspect and improve this app safely.'
    )
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $target = Resolve-GorTarget -NameOrPath $NameOrPath
    $id = New-GorId -Prefix 'session'
    $folder = Join-Path $paths.Sessions $id
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    $index = Get-GorAppIndex -Path $target
    $plan = New-GorFallbackPlan -Index $index -Goal $Goal
    $plan = Add-GorAiNotesToPlan -Plan $plan -Index $index -Goal $Goal
    $session = [pscustomobject]@{
        Id = $id
        Name = Split-Path -Leaf $target
        TargetPath = $target
        Goal = $Goal
        CreatedAt = Get-GorNow
        UpdatedAt = Get-GorNow
        Folder = $folder
        Status = 'PLANNED'
    }
    Set-GorJson -Path (Join-Path $folder 'session.json') -Value $session
    Set-GorJson -Path (Join-Path $folder 'index.json') -Value $index
    Set-GorJson -Path (Join-Path $folder 'plan.json') -Value $plan
    Set-GorJson -Path (Join-Path $folder 'apply-results.json') -Value @()
    Set-Content -LiteralPath (Join-Path $folder 'apply.log') -Value @("[$(Get-GorNow)] session created") -Encoding UTF8
    New-GorSessionReport -SessionFolder $folder | Out-Null
    return $session
}

function Resolve-GorSessionFolder {
    param([Parameter(Mandatory=$true)][string]$Session)
    $paths = Get-GorPaths
    if (Test-Path -LiteralPath $Session) {
        return (Resolve-Path -LiteralPath $Session).Path
    }
    $candidate = Join-Path $paths.Sessions $Session
    if (Test-Path -LiteralPath $candidate) {
        return (Resolve-Path -LiteralPath $candidate).Path
    }
    $matches = Get-ChildItem -LiteralPath $paths.Sessions -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$Session*" }
    $matchList = @($matches)
    if ($matchList.Count -eq 1) {
        return $matchList[0].FullName
    }
    throw "Session not found or ambiguous: $Session"
}

function Add-GorApplyLog {
    param(
        [Parameter(Mandatory=$true)][string]$SessionFolder,
        [Parameter(Mandatory=$true)][string]$Message
    )
    $log = Join-Path $SessionFolder 'apply.log'
    Add-Content -LiteralPath $log -Value ("[$(Get-GorNow)] $Message") -Encoding UTF8
}

function New-GorBackup {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [string]$Reason = 'backup'
    )
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Cannot backup missing path: $Path"
    }
    $id = New-GorId -Prefix 'backup'
    $name = Split-Path -Leaf $Path
    if ([string]::IsNullOrWhiteSpace($name)) {
        $name = 'root'
    }
    $folder = Join-Path $paths.Backups $id
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    $dest = Join-Path $folder $name
    if (Test-Path -LiteralPath $Path -PathType Container) {
        Copy-Item -LiteralPath $Path -Destination $dest -Recurse -Force
    }
    else {
        Copy-Item -LiteralPath $Path -Destination $dest -Force
    }
    $meta = [pscustomobject]@{
        Id = $id
        Reason = $Reason
        SourcePath = $Path
        BackupPath = $dest
        CreatedAt = Get-GorNow
    }
    Set-GorJson -Path (Join-Path $folder 'backup.json') -Value $meta
    return $meta
}

function Invoke-GorPatchBindLocal {
    param(
        [Parameter(Mandatory=$true)][string]$TargetPath,
        [switch]$Preview
    )
    $files = Get-GorAppFiles -Path $TargetPath
    $candidateFiles = $files | Where-Object { $_.Name -in @('app.py','config.py','main.py','.env') -or $_.Extension -in @('.py','.json','.toml','.ini','.cfg') }
    $matches = Search-GorTextInFiles -Files $candidateFiles -Patterns @('0.0.0.0')
    if ($Preview) {
        return (ConvertTo-GorArray $matches)
    }
    if (@($matches).Count -eq 0) {
        return @([pscustomobject]@{ Path = $TargetPath; Status = 'NOCHANGE'; Message = 'No 0.0.0.0 binding found.' })
    }
    $backup = New-GorBackup -Path $TargetPath -Reason 'bind-local-patch'
    $changed = New-Object System.Collections.Generic.List[object]
    $unique = @($matches | Select-Object -ExpandProperty Path -Unique)
    foreach ($filePath in $unique) {
        try {
            $raw = Get-Content -LiteralPath $filePath -Raw -ErrorAction Stop
            $new = $raw.Replace('0.0.0.0', '127.0.0.1')
            if ($new -ne $raw) {
                Set-Content -LiteralPath $filePath -Value $new -Encoding UTF8
                $changed.Add([pscustomobject]@{
                    Path = $filePath
                    Status = 'PATCHED'
                    BackupId = $backup.Id
                    Message = 'Replaced 0.0.0.0 with 127.0.0.1'
                })
            }
        }
        catch {
            $changed.Add([pscustomobject]@{
                Path = $filePath
                Status = 'FAILED'
                BackupId = $backup.Id
                Message = $_.Exception.Message
            })
        }
    }
    return (ConvertTo-GorArray $changed)
}

function Invoke-GorPythonCompile {
    param([Parameter(Mandatory=$true)][string]$TargetPath)
    $python = Get-Command python -ErrorAction Ignore
    if (-not $python) {
        $python = Get-Command py -ErrorAction Ignore
    }
    if (-not $python) {
        return [pscustomobject]@{ Status='SKIPPED'; Message='python/py was not found on PATH.'; Output='' }
    }
    $files = Get-GorAppFiles -Path $TargetPath
    $pyFiles = @($files | Where-Object { $_.Extension -eq '.py' })
    if ($pyFiles.Count -eq 0) {
        return [pscustomobject]@{ Status='SKIPPED'; Message='No Python files found.'; Output='' }
    }
    $temp = Join-Path ([IO.Path]::GetTempPath()) ('gor-pyfiles-' + [Guid]::NewGuid().ToString('N') + '.txt')
    try {
        $paths = foreach ($f in $pyFiles) { $f.Path }
        Set-Content -LiteralPath $temp -Value $paths -Encoding UTF8
        $script = "import py_compile, pathlib, sys; failed=[]; paths=pathlib.Path(r'$temp').read_text(encoding='utf-8').splitlines();`nfor p in paths:`n    try: py_compile.compile(p, doraise=True)`n    except Exception as e: failed.append(f'{p}: {e}')`nprint('checked', len(paths), 'python files');`n[print(x) for x in failed];`nsys.exit(1 if failed else 0)"
        $output = & $python.Source -c $script 2>&1
        $status = if ($LASTEXITCODE -eq 0) { 'OK' } else { 'FAILED' }
        return [pscustomobject]@{ Status=$status; Message='Python compile check completed.'; Output=($output | Out-String).Trim() }
    }
    catch {
        return [pscustomobject]@{ Status='FAILED'; Message=$_.Exception.Message; Output='' }
    }
    finally {
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-GorNodePackageCheck {
    param([Parameter(Mandatory=$true)][string]$TargetPath)
    $packagePath = Join-Path $TargetPath 'package.json'
    if (-not (Test-Path -LiteralPath $packagePath)) {
        return [pscustomobject]@{ Status='SKIPPED'; Message='No package.json found.'; Scripts=@(); Dependencies=0; DevDependencies=0 }
    }
    try {
        $pkg = Get-GorJson -Path $packagePath -Default $null
        $scripts = @()
        if ($pkg -and ($pkg.PSObject.Properties.Name -contains 'scripts')) {
            $scripts = @($pkg.scripts.PSObject.Properties.Name)
        }
        $depCount = 0
        $devCount = 0
        if ($pkg -and ($pkg.PSObject.Properties.Name -contains 'dependencies')) {
            $depCount = @($pkg.dependencies.PSObject.Properties).Count
        }
        if ($pkg -and ($pkg.PSObject.Properties.Name -contains 'devDependencies')) {
            $devCount = @($pkg.devDependencies.PSObject.Properties).Count
        }
        return [pscustomobject]@{ Status='OK'; Message='package.json inspected.'; Scripts=$scripts; Dependencies=$depCount; DevDependencies=$devCount }
    }
    catch {
        return [pscustomobject]@{ Status='FAILED'; Message=$_.Exception.Message; Scripts=@(); Dependencies=0; DevDependencies=0 }
    }
}

function Invoke-GorPlanAction {
    param(
        [Parameter(Mandatory=$true)][string]$SessionFolder,
        [Parameter(Mandatory=$true)]$Session,
        [Parameter(Mandatory=$true)]$Action
    )
    $target = [string]$Session.TargetPath
    $result = [pscustomobject]@{
        Id = $Action.Id
        Risk = $Action.Risk
        Command = $Action.Command
        StartedAt = Get-GorNow
        FinishedAt = $null
        Status = 'PENDING'
        Output = $null
    }
    try {
        switch ($Action.Command) {
            'GOR:SCAN' {
                $idx = Get-GorAppIndex -Path $target
                Set-GorJson -Path (Join-Path $SessionFolder 'index.json') -Value $idx
                $result.Status = 'OK'
                $result.Output = "Indexed $($idx.FileCount) files and found $(@($idx.Risks).Count) risk notes."
            }
            'GOR:PY_COMPILE' {
                $compile = Invoke-GorPythonCompile -TargetPath $target
                $result.Status = $compile.Status
                $result.Output = ($compile | ConvertTo-Json -Depth 8)
            }
            'GOR:NODE_PACKAGE_CHECK' {
                $node = Invoke-GorNodePackageCheck -TargetPath $target
                $result.Status = $node.Status
                $result.Output = ($node | ConvertTo-Json -Depth 8)
            }
            'GOR:PATCH_BIND_LOCAL_PREVIEW' {
                $preview = Invoke-GorPatchBindLocal -TargetPath $target -Preview
                $result.Status = 'OK'
                $result.Output = (@($preview) | ConvertTo-Json -Depth 8)
            }
            'GOR:PATCH_BIND_LOCAL' {
                $patched = Invoke-GorPatchBindLocal -TargetPath $target
                $failed = @($patched | Where-Object { $_.Status -eq 'FAILED' })
                $result.Status = if ($failed.Count -gt 0) { 'FAILED' } else { 'OK' }
                $result.Output = (@($patched) | ConvertTo-Json -Depth 8)
            }
            'GOR:REPORT' {
                $reportPath = New-GorSessionReport -SessionFolder $SessionFolder
                $result.Status = 'OK'
                $result.Output = $reportPath
            }
            default {
                $result.Status = 'SKIPPED'
                $result.Output = 'Unknown or unsupported Gorrilla plan command.'
            }
        }
    }
    catch {
        $result.Status = 'FAILED'
        $result.Output = $_.Exception.Message
    }
    $result.FinishedAt = Get-GorNow
    return $result
}

function Invoke-GorApplySession {
    param(
        [Parameter(Mandatory=$true)][string]$Session,
        [ValidateSet('LOW','MEDIUM','HIGH')][string]$MaxRisk = 'LOW',
        [switch]$RequireConfirmation
    )
    $folder = Resolve-GorSessionFolder -Session $Session
    $sessionObj = Get-GorJson -Path (Join-Path $folder 'session.json') -Default $null
    $plan = Get-GorJson -Path (Join-Path $folder 'plan.json') -Default $null
    if (-not $sessionObj -or -not $plan) {
        throw "Session is incomplete: $folder"
    }
    if ($RequireConfirmation) {
        $confirmText = if ($MaxRisk -eq 'HIGH') { 'BEASTGORRILLA' } else { 'MEDIUMGORRILLA' }
        $typed = Read-Host "Type $confirmText to apply $MaxRisk actions"
        if ($typed -ne $confirmText) {
            Write-Warning 'Confirmation did not match. No actions were applied.'
            return
        }
    }
    $rank = @{ LOW = 1; MEDIUM = 2; HIGH = 3 }
    $maxRank = $rank[$MaxRisk]
    $enabledActions = New-Object System.Collections.Generic.List[object]
    foreach ($action in (ConvertTo-GorArray $plan.Actions)) {
        $actionRisk = [string]$action.Risk
        if (-not $rank.ContainsKey($actionRisk)) {
            continue
        }
        if ($action.Enabled -and $rank[$actionRisk] -le $maxRank) {
            $enabledActions.Add($action)
        }
    }
    $backup = New-GorBackup -Path $sessionObj.TargetPath -Reason "session-apply-$MaxRisk"
    Add-GorApplyLog -SessionFolder $folder -Message "Created backup $($backup.Id) before apply."
    $results = New-Object System.Collections.Generic.List[object]
    foreach ($action in $enabledActions) {
        Add-GorApplyLog -SessionFolder $folder -Message "Running action $($action.Id) [$($action.Risk)] $($action.Command)"
        $result = Invoke-GorPlanAction -SessionFolder $folder -Session $sessionObj -Action $action
        $results.Add($result)
        $action.Status = $result.Status
        Add-GorApplyLog -SessionFolder $folder -Message "Action $($action.Id) finished: $($result.Status)"
    }
    $sessionObj.UpdatedAt = Get-GorNow
    $sessionObj.Status = if ((@($results | Where-Object { $_.Status -eq 'FAILED' })).Count -gt 0) { 'FAILED' } else { 'APPLIED' }
    Set-GorJson -Path (Join-Path $folder 'session.json') -Value $sessionObj
    Set-GorJson -Path (Join-Path $folder 'plan.json') -Value $plan
    Set-GorJson -Path (Join-Path $folder 'apply-results.json') -Value @(ConvertTo-GorArray $results)
    New-GorSessionReport -SessionFolder $folder | Out-Null
    return (ConvertTo-GorArray $results)
}

function New-GorSessionReport {
    param([Parameter(Mandatory=$true)][string]$SessionFolder)
    $session = Get-GorJson -Path (Join-Path $SessionFolder 'session.json') -Default $null
    $index = Get-GorJson -Path (Join-Path $SessionFolder 'index.json') -Default $null
    $plan = Get-GorJson -Path (Join-Path $SessionFolder 'plan.json') -Default $null
    $results = Get-GorJson -Path (Join-Path $SessionFolder 'apply-results.json') -Default @()
    $logPath = Join-Path $SessionFolder 'apply.log'
    $log = ''
    if (Test-Path -LiteralPath $logPath) {
        $log = Get-Content -LiteralPath $logPath -Raw
    }
    $sections = @(
        [pscustomobject]@{ Title='Session'; Data=$session },
        [pscustomobject]@{ Title='Detected Types'; Html=('<p>' + (Escape-GorHtml ([string]::Join(', ', @($index.Types)))) + '</p>') },
        [pscustomobject]@{ Title='Risks'; Data=@($index.Risks) },
        [pscustomobject]@{ Title='Plan Actions'; Data=@($plan.Actions) },
        [pscustomobject]@{ Title='Local AI Notes'; Html=('<pre>' + (Escape-GorHtml ([string]$plan.AiNotes)) + '</pre>') },
        [pscustomobject]@{ Title='Apply Results'; Data=@($results) },
        [pscustomobject]@{ Title='Apply Log'; Html=('<pre>' + (Escape-GorHtml $log) + '</pre>') }
    )
    $path = Join-Path $SessionFolder 'report.html'
    New-GorHtmlReport -Title "Gorrilla Repair Session - $($session.Id)" -Sections $sections -Path $path | Out-Null
    return $path
}

function Get-GorPortOwner {
    param([Parameter(Mandatory=$true)][int]$Port)
    $conns = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($conn in $conns) {
        $proc = $null
        if ($conn.OwningProcess) {
            $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        }
        $rows.Add([pscustomobject]@{
            LocalAddress = $conn.LocalAddress
            LocalPort = $conn.LocalPort
            State = $conn.State
            OwningProcess = $conn.OwningProcess
            ProcessName = if ($proc) { $proc.ProcessName } else { $null }
            Path = if ($proc) { try { $proc.Path } catch { $null } } else { $null }
        })
    }
    return (ConvertTo-GorArray $rows)
}

function Test-GorHttpLocal {
    param(
        [string]$Uri = 'http://127.0.0.1:5000/',
        [int]$TimeoutSeconds = 4
    )
    $ProgressPreference = 'SilentlyContinue'
    try {
        $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec $TimeoutSeconds -ErrorAction Stop
        return [pscustomobject]@{ Uri=$Uri; Status='OK'; StatusCode=$response.StatusCode; Message='Responded' }
    }
    catch {
        return [pscustomobject]@{ Uri=$Uri; Status='FAILED'; StatusCode=$null; Message=$_.Exception.Message }
    }
}

function Get-GorFireDeskPath {
    $default = Join-Path (Get-GorDesktop) 'FireDeskElite\Dashboard'
    if (Test-Path -LiteralPath $default) {
        return (Resolve-Path -LiteralPath $default).Path
    }
    $apps = Get-GorSavedApps
    foreach ($app in $apps) {
        if ($app.Name -match 'FireDesk') {
            return [string]$app.Path
        }
    }
    return $default
}

function Get-GorFireDeskStatus {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = Get-GorFireDeskPath
    }
    $exists = Test-Path -LiteralPath $Path
    $files = @()
    if ($exists) {
        $files = foreach ($name in @('app.py','config.py','requirements.txt','.venv')) {
            [pscustomobject]@{
                Name = $name
                Path = Join-Path $Path $name
                Exists = Test-Path -LiteralPath (Join-Path $Path $name)
            }
        }
    }
    $port = Get-GorPortOwner -Port 5000
    $http = Test-GorHttpLocal -Uri 'http://127.0.0.1:5000/'
    $binding = @()
    $compile = $null
    if ($exists) {
        $index = Get-GorAppIndex -Path $Path
        $binding = @($index.Risks | Where-Object { $_.Category -eq 'Network binding' })
        $compile = Invoke-GorPythonCompile -TargetPath $Path
    }
    [pscustomobject]@{
        Path = $Path
        Exists = $exists
        Files = @($files)
        Port5000 = @($port)
        LocalHttp = $http
        BindingRisks = @($binding)
        PythonCompile = $compile
        CheckedAt = Get-GorNow
    }
}

function Get-GorDiskInfo {
    $drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
    $rows = foreach ($drive in $drives) {
        [pscustomobject]@{
            Drive = $drive.DeviceID
            SizeGB = [math]::Round($drive.Size / 1GB, 2)
            FreeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
            FreePercent = if ($drive.Size -gt 0) { [math]::Round(($drive.FreeSpace / $drive.Size) * 100, 1) } else { 0 }
        }
    }
    return (ConvertTo-GorArray $rows)
}

function Get-GorTopProcesses {
    $procs = Get-Process -ErrorAction SilentlyContinue
    $rows = foreach ($proc in $procs) {
        $cpuSeconds = 0
        try {
            if ($proc.TotalProcessorTime) {
                $cpuSeconds = [math]::Round($proc.TotalProcessorTime.TotalSeconds, 2)
            }
        }
        catch {
            $cpuSeconds = 0
        }
        [pscustomobject]@{
            Id = $proc.Id
            ProcessName = $proc.ProcessName
            CPUSeconds = $cpuSeconds
            RAMMB = [math]::Round($proc.WorkingSet64 / 1MB, 1)
        }
    }
    $sorted = $rows | Sort-Object -Property CPUSeconds -Descending | Select-Object -First 12
    return (ConvertTo-GorArray $sorted)
}

function Get-GorStartupEntries {
    $rows = New-Object System.Collections.Generic.List[object]
    $cim = Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue
    foreach ($entry in $cim) {
        $rows.Add([pscustomobject]@{
            Name = $entry.Name
            Command = $entry.Command
            Location = $entry.Location
            User = $entry.User
        })
    }
    $startupFolders = @(
        [Environment]::GetFolderPath('Startup'),
        [Environment]::GetFolderPath('CommonStartup')
    )
    foreach ($folder in $startupFolders) {
        if (Test-Path -LiteralPath $folder) {
            $items = Get-ChildItem -LiteralPath $folder -Force -ErrorAction SilentlyContinue
            foreach ($item in $items) {
                $rows.Add([pscustomobject]@{
                    Name = $item.Name
                    Command = $item.FullName
                    Location = $folder
                    User = $env:USERNAME
                })
            }
        }
    }
    return (ConvertTo-GorArray $rows)
}

function Get-GorListeningPorts {
    $conns = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($conn in $conns) {
        $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        $rows.Add([pscustomobject]@{
            LocalAddress = $conn.LocalAddress
            LocalPort = $conn.LocalPort
            OwningProcess = $conn.OwningProcess
            ProcessName = if ($proc) { $proc.ProcessName } else { $null }
        })
    }
    $sorted = @(ConvertTo-GorArray $rows) | Sort-Object LocalPort
    return (ConvertTo-GorArray $sorted)
}

function Get-GorRecentErrors {
    try {
        $events = Get-WinEvent -FilterHashtable @{ LogName='Application'; Level=2; StartTime=(Get-Date).AddDays(-2) } -MaxEvents 25 -ErrorAction Stop
        $rows = foreach ($event in $events) {
            [pscustomobject]@{
                TimeCreated = $event.TimeCreated
                ProviderName = $event.ProviderName
                Id = $event.Id
                Message = (($event.Message -replace '\s+', ' ').Trim())
            }
        }
        return (ConvertTo-GorArray $rows)
    }
    catch {
        return @([pscustomobject]@{ TimeCreated=Get-Date; ProviderName='Get-WinEvent'; Id=0; Message=$_.Exception.Message })
    }
}

function Get-GorStoppedAutoServices {
    $services = Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -ne 'Running' }
    $rows = foreach ($svc in $services) {
        [pscustomobject]@{
            Name = $svc.Name
            DisplayName = $svc.DisplayName
            State = $svc.State
            StartMode = $svc.StartMode
        }
    }
    return (ConvertTo-GorArray $rows)
}

function Get-GorNetworkDiagnostics {
    $rows = New-Object System.Collections.Generic.List[object]
    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }
    foreach ($adapter in $adapters) {
        $rows.Add([pscustomobject]@{
            Check = 'Adapter'
            Name = $adapter.Name
            Status = $adapter.Status
            Detail = $adapter.InterfaceDescription
        })
    }
    foreach ($hostName in @('127.0.0.1','localhost','8.8.8.8')) {
        try {
            $ok = Test-Connection -ComputerName $hostName -Count 1 -Quiet -ErrorAction Stop
            $rows.Add([pscustomobject]@{ Check='Ping'; Name=$hostName; Status=if ($ok) { 'OK' } else { 'FAILED' }; Detail='' })
        }
        catch {
            $rows.Add([pscustomobject]@{ Check='Ping'; Name=$hostName; Status='FAILED'; Detail=$_.Exception.Message })
        }
    }
    return (ConvertTo-GorArray $rows)
}

function New-GorHealthReport {
    $paths = Get-GorPaths
    $sections = @(
        [pscustomobject]@{ Title='Top Processes'; Data=(Get-GorTopProcesses) },
        [pscustomobject]@{ Title='Disk Free Space'; Data=(Get-GorDiskInfo) },
        [pscustomobject]@{ Title='Listening Ports'; Data=(Get-GorListeningPorts) },
        [pscustomobject]@{ Title='Startup Entries'; Data=(Get-GorStartupEntries) },
        [pscustomobject]@{ Title='Stopped Automatic Services'; Data=(Get-GorStoppedAutoServices) },
        [pscustomobject]@{ Title='Recent Application Errors'; Data=(Get-GorRecentErrors) },
        [pscustomobject]@{ Title='Network Diagnostics'; Data=(Get-GorNetworkDiagnostics) }
    )
    $path = Join-Path $paths.Reports 'health.html'
    return (New-GorHtmlReport -Title 'PowerShell Gorrilla Health Report' -Sections $sections -Path $path)
}

function New-GorLayoutFile {
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $apps = Get-GorSavedApps
    $sessions = Get-ChildItem -LiteralPath $paths.Sessions -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    $snapshots = Get-ChildItem -LiteralPath $paths.Snapshots -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    $reports = Get-ChildItem -LiteralPath $paths.Reports -File -Filter '*.html' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    $fire = Get-GorFireDeskStatus
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# CommandUnitGorrilla Real Layout')
    $lines.Add('')
    $lines.Add('Generated: ' + (Get-GorNow))
    $lines.Add('')
    $lines.Add('## Module Paths')
    $lines.Add('- Module root: ' + $paths.ModuleRoot)
    $lines.Add('- Desktop output: ' + $paths.Root)
    $lines.Add('- Fleet store: ' + $paths.AppsJson)
    $lines.Add('- Sessions: ' + $paths.Sessions)
    $lines.Add('- Snapshots: ' + $paths.Snapshots)
    $lines.Add('- Reports: ' + $paths.Reports)
    $lines.Add('- Vault: ' + $paths.Vault)
    $lines.Add('')
    $lines.Add('## Saved Apps')
    if (@($apps).Count -eq 0) {
        $lines.Add('- None saved yet.')
    }
    else {
        foreach ($app in $apps) {
            $lines.Add('- ' + $app.Name + ' :: ' + $app.Path + ' :: ' + ([string]::Join(', ', @($app.TypeHints))))
        }
    }
    $lines.Add('')
    $lines.Add('## Sessions')
    if (@($sessions).Count -eq 0) {
        $lines.Add('- None yet.')
    }
    else {
        foreach ($session in $sessions) {
            $lines.Add('- ' + $session.Name + ' :: ' + $session.FullName)
        }
    }
    $lines.Add('')
    $lines.Add('## Snapshots')
    if (@($snapshots).Count -eq 0) {
        $lines.Add('- None yet.')
    }
    else {
        foreach ($snapshot in $snapshots) {
            $lines.Add('- ' + $snapshot.Name + ' :: ' + $snapshot.FullName)
        }
    }
    $lines.Add('')
    $lines.Add('## Key Commands')
    foreach ($cmd in $script:GorExpectedCommands) {
        $lines.Add('- ' + $cmd)
    }
    $lines.Add('')
    $lines.Add('## FireDesk Status')
    $lines.Add('- Path: ' + $fire.Path)
    $lines.Add('- Exists: ' + $fire.Exists)
    $lines.Add('- Port 5000 owners: ' + (@($fire.Port5000).Count))
    $lines.Add('- 127.0.0.1:5000: ' + $fire.LocalHttp.Status)
    $lines.Add('- 0.0.0.0 findings: ' + (@($fire.BindingRisks).Count))
    $lines.Add('')
    $lines.Add('## Reports')
    if (@($reports).Count -eq 0) {
        $lines.Add('- None yet.')
    }
    else {
        foreach ($report in $reports) {
            $lines.Add('- ' + $report.Name + ' :: ' + $report.FullName)
        }
    }
    Set-Content -LiteralPath $paths.Layout -Value @(ConvertTo-GorArray $lines) -Encoding UTF8
    return $paths.Layout
}

function New-GorLauncher {
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $moduleRootCandidates = @(([string](Resolve-GorLaunchModuleRoot)) -split "(`r`n|`n|`r)" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $launchersDirCandidates = @(([string]$paths.Launchers) -split "(`r`n|`n|`r)" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    [string]$moduleRoot = ([string]$moduleRootCandidates[-1]).Trim()
    [string]$launchersDir = ([string]$launchersDirCandidates[-1]).Trim()
    [string]$launcherPs1 = Join-Path $launchersDir 'Start-CommandUnitGorrilla.ps1'
    [string]$desktopCmd = Join-Path $launchersDir 'CommandUnit Gorrilla.cmd'
    $moduleRootLiteral = $moduleRoot.Replace("'", "''")
    foreach ($assetName in @('gorrilla-launcher.ico')) {
        $sourceAsset = Join-Path (Join-Path $moduleRoot 'assets') $assetName
        if (Test-Path -LiteralPath $sourceAsset) {
            Copy-Item -LiteralPath $sourceAsset -Destination (Join-Path $paths.Assets $assetName) -Force -ErrorAction SilentlyContinue
        }
    }
    $ps1Lines = @(
        '$ErrorActionPreference = "Stop"',
        'Set-StrictMode -Version 2.0',
        "`$module = '$moduleRootLiteral'",
        '$pathsRoot = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "CommandUnitGorrilla"',
        '$logDir = Join-Path $pathsRoot "Logs"',
        'if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }',
        '$logPath = Join-Path $logDir ("launcher-{0}.log" -f (Get-Date -Format "yyyyMMdd"))',
        'function Write-LauncherLog { param([string]$Message,[string]$Level="INFO") Add-Content -LiteralPath $logPath -Value ("[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"),$Level,$Message) -Encoding UTF8 }',
        'try {',
        '    Write-Progress -Activity "PowerShell Gorrilla launch" -Status "Preparing" -PercentComplete 10',
        '    Write-LauncherLog "Launcher started."',
        '    $manifest = Join-Path $module "CommandUnitGorrilla.psd1"',
        '    $moduleFile = Join-Path $module "CommandUnitGorrilla.psm1"',
        '    if (Test-Path -LiteralPath $manifest) {',
        '        Write-Progress -Activity "PowerShell Gorrilla launch" -Status "Importing module" -PercentComplete 35',
        '        Import-Module $manifest -Force -WarningAction SilentlyContinue -ErrorAction Stop',
        '    } elseif (Test-Path -LiteralPath $moduleFile) {',
        '        Write-Progress -Activity "PowerShell Gorrilla launch" -Status "Importing module file" -PercentComplete 35',
        '        Import-Module $moduleFile -Force -WarningAction SilentlyContinue -ErrorAction Stop',
        '    } else {',
        '        throw "PowerShell Gorrilla module not found under $module"',
        '    }',
        '    if (-not (Get-Command gorvisual -ErrorAction SilentlyContinue)) { throw "gorvisual command is unavailable after module import." }',
        '    Write-Progress -Activity "PowerShell Gorrilla launch" -Status "Opening visual dashboard" -PercentComplete 75',
        '    $url = gorvisual',
        '    Write-Progress -Activity "PowerShell Gorrilla launch" -Completed',
        '    Write-LauncherLog "Visual app opened: $url"',
        '    Write-Host ""',
        '    Write-Host "PowerShell Gorrilla visual app opened: $url" -ForegroundColor Cyan',
        '} catch {',
        '    Write-Progress -Activity "PowerShell Gorrilla launch" -Completed',
        '    Write-LauncherLog $_.Exception.Message "ERROR"',
        '    Write-Host "PowerShell Gorrilla launch failed: $($_.Exception.Message)" -ForegroundColor Red',
        '    Write-Host "Launch log: $logPath" -ForegroundColor Yellow',
        '    exit 1',
        '}'
    )
    Set-Content -LiteralPath $launcherPs1 -Value $ps1Lines -Encoding UTF8
    $cmdLines = @(
        '@echo off',
        'setlocal',
        ('set "GOR_PS1={0}"' -f ([string]$launcherPs1)),
        'if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" (',
        '  "%ProgramFiles%\PowerShell\7\pwsh.exe" -NoLogo -NoExit -ExecutionPolicy Bypass -File "%GOR_PS1%"',
        ') else (',
        '  powershell.exe -NoLogo -NoExit -ExecutionPolicy Bypass -File "%GOR_PS1%"',
        ')'
    )
    Set-Content -LiteralPath $desktopCmd -Value $cmdLines -Encoding ASCII
    try {
        if (Test-Path -LiteralPath $desktopCmd) {
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($paths.DesktopLnk)
            $shortcut.TargetPath = $desktopCmd
            $shortcut.Arguments = ''
            $shortcut.WorkingDirectory = $launchersDir
            $shortcut.Description = 'Open the PowerShell Gorrilla visual control center'
            if (Test-Path -LiteralPath $paths.LauncherIco) {
                $shortcut.IconLocation = $paths.LauncherIco
            }
            $shortcut.Save()
        }
    }
    catch {
        Write-Warning "Could not create visual desktop shortcut: $($_.Exception.Message)"
    }
    [pscustomobject]@{
        DesktopCmd = $desktopCmd
        DesktopShortcut = $paths.DesktopLnk
        LauncherIcon = $paths.LauncherIco
        LauncherPs1 = $launcherPs1
    }
}

function New-GorCommandRoom {
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $status = Get-GorStatusObject
    $apps = Get-GorSavedApps
    $legacy = Get-GorLegacyModules
    $fire = Get-GorFireDeskStatus
    $elite = Get-GorEliteStackRows -Quick
    $eliteIssues = Get-GorEliteStackIssues -Rows $elite
    $healthPath = New-GorHealthReport
    $sections = @(
        [pscustomobject]@{ Title='Status'; Data=$status },
        [pscustomobject]@{ Title='Elite Stack'; Data=@($elite) },
        [pscustomobject]@{ Title='Elite Stack Issues'; Data=@($eliteIssues) },
        [pscustomobject]@{ Title='Saved Apps'; Data=@($apps) },
        [pscustomobject]@{ Title='Legacy CommandUnit Modules'; Data=@($legacy) },
        [pscustomobject]@{ Title='FireDesk'; Data=$fire },
        [pscustomobject]@{ Title='Health Report'; Html=('<p><a href="' + (Escape-GorHtml $healthPath) + '">' + (Escape-GorHtml $healthPath) + '</a></p>') },
        [pscustomobject]@{ Title='Main Commands'; Html=('<pre>' + (Escape-GorHtml ([string]::Join([Environment]::NewLine, $script:GorExpectedCommands))) + '</pre>') }
    )
    $path = Join-Path $paths.Reports 'command-room.html'
    New-GorHtmlReport -Title 'PowerShell Gorrilla Command Room' -Sections $sections -Path $path | Out-Null
    return $path
}

function Get-GorStatusObject {
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $modulePath = Join-Path $paths.ModuleRoot 'CommandUnitGorrilla.psm1'
    $parse = if (Test-Path -LiteralPath $modulePath) { Test-GorParseFile -Path $modulePath } else { $null }
    $ai = Get-GorCommandAvailability
    $eliteSummary = Get-GorEliteStackSummary
    [pscustomobject]@{
        Name = 'PowerShell Gorrilla'
        Version = $script:GorVersion
        PowerShell = $PSVersionTable.PSVersion.ToString()
        Edition = $PSVersionTable.PSEdition
        ModuleRoot = $paths.ModuleRoot
        OutputRoot = $paths.Root
        FleetApps = @(Get-GorSavedApps).Count
        Sessions = @(Get-ChildItem -LiteralPath $paths.Sessions -Directory -ErrorAction SilentlyContinue).Count
        Snapshots = @(Get-ChildItem -LiteralPath $paths.Snapshots -Directory -ErrorAction SilentlyContinue).Count
        Reports = @(Get-ChildItem -LiteralPath $paths.Reports -File -Filter '*.html' -ErrorAction SilentlyContinue).Count
        ParserOk = if ($parse) { $parse.Ok } else { $false }
        AskAvailable = $ai.Ask
        OllamaAvailable = $ai.Ollama
        EliteStackOk = $eliteSummary.Ok
        EliteToolsOk = $eliteSummary.Found
        EliteIssues = ($eliteSummary.MissingRequired + $eliteSummary.MissingRecommended)
        LoadedAt = Get-GorNow
    }
}

function Write-GorTable {
    param($Rows)
    $data = @(ConvertTo-GorArray $Rows)
    if ($data.Count -eq 0) {
        Write-Host 'No rows.' -ForegroundColor Yellow
        return
    }
    return
}

function gorrilla {
    gorstatus
    Write-Host ''
    Write-Host 'Command room: gorui  |  Elite stack: gorelite  |  Visual app: gorvisual  |  Health: gorhealth' -ForegroundColor Cyan
}

function gor {
    gorrilla
}

function gorload {
    Initialize-GorEnvironment
    $legacy = Get-GorLegacyModules
    $results = New-Object System.Collections.Generic.List[object]
    foreach ($module in $legacy) {
        $parseOk = $true
        $errors = ''
        if ($module.Path -and (Test-Path -LiteralPath $module.Path -PathType Leaf) -and $module.Path.EndsWith('.psm1', [System.StringComparison]::OrdinalIgnoreCase)) {
            $parse = Test-GorParseFile -Path $module.Path
            $parseOk = $parse.Ok
            if (-not $parseOk) {
                $errors = (@($parse.Errors) | Out-String).Trim()
            }
        }
        if ($parseOk) {
            try {
                Import-Module -Name $module.Name -ErrorAction Stop -Force
                $results.Add([pscustomobject]@{ Name=$module.Name; Status='LOADED'; Path=$module.Path; Detail='' })
            }
            catch {
                $results.Add([pscustomobject]@{ Name=$module.Name; Status='FAILED'; Path=$module.Path; Detail=$_.Exception.Message })
            }
        }
        else {
            $results.Add([pscustomobject]@{ Name=$module.Name; Status='SKIPPED_PARSE_ERROR'; Path=$module.Path; Detail=$errors })
        }
    }
    Write-GorTable -Rows $results
    return (ConvertTo-GorArray $results)
}

function gorstatus {
    $status = Get-GorStatusObject
    Write-GorTable -Rows @($status)
    return $status
}

function gormap {
    $path = New-GorLayoutFile
    Write-Host "Layout written: $path" -ForegroundColor Green
    return $path
}

function gorui {
    $path = New-GorCommandRoom
    Write-Host "Command room written: $path" -ForegroundColor Green
    Invoke-Item -LiteralPath $path -ErrorAction SilentlyContinue
    return $path
}

function gorfinal {
    $test = gorselftest
    $layout = gormap
    $ui = gorui
    [pscustomobject]@{
        SelfTestOk = (($test | Where-Object { $_.Status -ne 'OK' }).Count -eq 0)
        Layout = $layout
        CommandRoom = $ui
    }
}

function gorlauncher {
    $result = New-GorLauncher
    Write-GorTable -Rows @($result)
    return $result
}

function gorbaseline {
    Initialize-GorEnvironment
    $status = Get-GorStatusObject
    $health = New-GorHealthReport
    $layout = New-GorLayoutFile
    $room = New-GorCommandRoom
    [pscustomobject]@{
        Status = $status
        HealthReport = $health
        Layout = $layout
        CommandRoom = $room
    }
}

function gorappadd {
    param(
        [Parameter(Position=0, Mandatory=$true)][string]$Name,
        [Parameter(Position=1, Mandatory=$true)][string]$Path
    )
    Initialize-GorEnvironment
    $resolved = Resolve-Path -LiteralPath $Path -ErrorAction Stop
    $target = $resolved.Path
    $index = Get-GorAppIndex -Path $target
    $apps = New-Object System.Collections.Generic.List[object]
    foreach ($app in (Get-GorSavedApps)) {
        if ($app.Name -ne $Name) {
            $apps.Add($app)
        }
    }
    $entry = [pscustomobject]@{
        Name = $Name
        Path = $target
        TypeHints = @($index.Types)
        AddedDate = Get-GorNow
        LastCheckedDate = Get-GorNow
    }
    $apps.Add($entry)
    Save-GorSavedApps -Apps @(ConvertTo-GorArray $apps)
    Write-GorTable -Rows @($entry)
    return $entry
}

function gorapps {
    $apps = Get-GorSavedApps
    Write-GorTable -Rows $apps
    return (ConvertTo-GorArray $apps)
}

function gorappstatus {
    param([Parameter(Position=0, Mandatory=$true)][string]$Name)
    $target = Resolve-GorTarget -NameOrPath $Name
    $index = Get-GorAppIndex -Path $target
    $apps = New-Object System.Collections.Generic.List[object]
    foreach ($app in (Get-GorSavedApps)) {
        if ($app.Name -eq $Name -or $app.Path -eq $target) {
            $app.LastCheckedDate = Get-GorNow
            $app.TypeHints = @($index.Types)
        }
        $apps.Add($app)
    }
    Save-GorSavedApps -Apps @(ConvertTo-GorArray $apps)
    $summary = [pscustomobject]@{
        Name = $index.Name
        Path = $index.Path
        Types = [string]::Join(', ', @($index.Types))
        FileCount = $index.FileCount
        Risks = @($index.Risks).Count
        CheckedAt = $index.IndexedAt
    }
    Write-GorTable -Rows @($summary)
    return $index
}

function gorfleet {
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($app in (Get-GorSavedApps)) {
        try {
            $index = Get-GorAppIndex -Path $app.Path
            $rows.Add([pscustomobject]@{
                Name = $app.Name
                Path = $app.Path
                Exists = (Test-Path -LiteralPath $app.Path)
                Types = [string]::Join(', ', @($index.Types))
                Risks = @($index.Risks).Count
                LastCheckedDate = Get-GorNow
            })
        }
        catch {
            $rows.Add([pscustomobject]@{
                Name = $app.Name
                Path = $app.Path
                Exists = $false
                Types = ''
                Risks = 0
                LastCheckedDate = Get-GorNow
                Error = $_.Exception.Message
            })
        }
    }
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

function gorfleetreport {
    $paths = Get-GorPaths
    $fleet = gorfleet
    $sections = @(
        [pscustomobject]@{ Title='Fleet'; Data=@($fleet) },
        [pscustomobject]@{ Title='Saved Apps Store'; Html=('<pre>' + (Escape-GorHtml $paths.AppsJson) + '</pre>') }
    )
    $path = Join-Path $paths.Reports 'fleet.html'
    New-GorHtmlReport -Title 'PowerShell Gorrilla Fleet Report' -Sections $sections -Path $path | Out-Null
    Write-Host "Fleet report written: $path" -ForegroundColor Green
    return $path
}

function gornewsession {
    param(
        [Parameter(Position=0, Mandatory=$true)][string]$NameOrPath,
        [Parameter(Position=1)][string]$Goal = 'Inspect and improve this app safely.'
    )
    $session = New-GorSession -NameOrPath $NameOrPath -Goal $Goal
    Write-GorTable -Rows @($session)
    return $session
}

function gorengineer {
    param(
        [Parameter(Position=0, Mandatory=$true)][string]$NameOrPath,
        [Parameter(Position=1, ValueFromRemainingArguments=$true)][string[]]$Goal
    )
    $goalText = ($Goal -join ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($goalText)) {
        $goalText = 'Inspect, plan, and improve this local app safely.'
    }
    $session = New-GorSession -NameOrPath $NameOrPath -Goal $goalText
    $folder = Resolve-GorSessionFolder -Session $session.Id
    $report = Join-Path $folder 'report.html'
    Write-Host "Engineer session: $($session.Id)" -ForegroundColor Green
    Write-Host "Report: $report" -ForegroundColor Green
    return $session
}

function gorplan {
    param([Parameter(Position=0, Mandatory=$true)][string]$NameOrPath)
    $session = New-GorSession -NameOrPath $NameOrPath -Goal 'Create a safe engineering plan.'
    $plan = Get-GorJson -Path (Join-Path $session.Folder 'plan.json') -Default $null
    Write-GorTable -Rows @($plan.Actions)
    return $plan
}

function gorpatchpreview {
    param([Parameter(Position=0, Mandatory=$true)][string]$NameOrPath)
    $target = Resolve-GorTarget -NameOrPath $NameOrPath
    $preview = Invoke-GorPatchBindLocal -TargetPath $target -Preview
    Write-GorTable -Rows $preview
    return (ConvertTo-GorArray $preview)
}

function gorfix {
    param([Parameter(Position=0, Mandatory=$true)][string]$NameOrPath)
    $session = New-GorSession -NameOrPath $NameOrPath -Goal 'Run safe LOW-risk repairs and validation.'
    $results = Invoke-GorApplySession -Session $session.Id -MaxRisk LOW
    Write-GorTable -Rows $results
    return (ConvertTo-GorArray $results)
}

function gorapply {
    param([Parameter(Position=0, Mandatory=$true)][string]$Session)
    $results = Invoke-GorApplySession -Session $Session -MaxRisk LOW
    Write-GorTable -Rows $results
    return (ConvertTo-GorArray $results)
}

function gorapplysafe {
    param([Parameter(Position=0, Mandatory=$true)][string]$Session)
    $results = Invoke-GorApplySession -Session $Session -MaxRisk LOW
    Write-GorTable -Rows $results
    return (ConvertTo-GorArray $results)
}

function gorapplymedium {
    param([Parameter(Position=0, Mandatory=$true)][string]$Session)
    $results = Invoke-GorApplySession -Session $Session -MaxRisk MEDIUM -RequireConfirmation
    Write-GorTable -Rows $results
    return (ConvertTo-GorArray $results)
}

function gorbeast {
    param([Parameter(Position=0, Mandatory=$true)][string]$Session)
    $results = Invoke-GorApplySession -Session $Session -MaxRisk HIGH -RequireConfirmation
    Write-GorTable -Rows $results
    return (ConvertTo-GorArray $results)
}

function gorreport {
    param(
        [Parameter(Position=0)][string]$Kind = 'health',
        [Parameter(Position=1)][string]$NameOrPath = ''
    )
    switch ($Kind.ToLowerInvariant()) {
        'health' { return (gorhealth) }
        'app' {
            if ([string]::IsNullOrWhiteSpace($NameOrPath)) { throw 'Usage: gorreport app NAME_OR_PATH' }
            $doctor = Get-GorDoctorRows -NameOrPath $NameOrPath
            return (New-GorReport -Title 'Gorrilla App Report' -Sections @([pscustomobject]@{ Title='Doctor'; Data=$doctor }, [pscustomobject]@{ Title='Quality'; Data=(Get-GorQualityRows -NameOrPath $NameOrPath) }) -FileName 'app.html')
        }
        'fleet' { return (gorfleetreport) }
        'security' { return (gorsecurity report $NameOrPath) }
        'performance' { return (gorperf report $NameOrPath) }
        'all' {
            gorhealth | Out-Null
            gorfleetreport | Out-Null
            gorsecurity report | Out-Null
            gorperf report | Out-Null
            return (New-GorReport -Title 'Gorrilla Report Studio Index' -Sections @([pscustomobject]@{ Title='Reports'; Data=(Get-ChildItem -LiteralPath (Get-GorPaths).Reports -File -ErrorAction SilentlyContinue) }) -FileName 'report-studio.html')
        }
        default {
            try {
                $folder = Resolve-GorSessionFolder -Session $Kind
                $path = New-GorSessionReport -SessionFolder $folder
                Write-Host "Session report written: $path" -ForegroundColor Green
                Invoke-Item -LiteralPath $path -ErrorAction SilentlyContinue
                return $path
            }
            catch {
                throw "Unknown report kind or session: $Kind"
            }
        }
    }
}

function gorsessions {
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $dirs = Get-ChildItem -LiteralPath $paths.Sessions -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    $rows = foreach ($dir in $dirs) {
        $session = Get-GorJson -Path (Join-Path $dir.FullName 'session.json') -Default $null
        if ($session) {
            [pscustomobject]@{
                Id = $session.Id
                Name = $session.Name
                Status = $session.Status
                TargetPath = $session.TargetPath
                CreatedAt = $session.CreatedAt
                Folder = $dir.FullName
            }
        }
    }
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

function gorview {
    param([Parameter(Position=0, Mandatory=$true)][string]$Session)
    $folder = Resolve-GorSessionFolder -Session $Session
    $sessionObj = Get-GorJson -Path (Join-Path $folder 'session.json') -Default $null
    $plan = Get-GorJson -Path (Join-Path $folder 'plan.json') -Default $null
    Write-GorTable -Rows @($sessionObj)
    Write-GorTable -Rows @($plan.Actions)
    return [pscustomobject]@{ Session=$sessionObj; Plan=$plan; Folder=$folder }
}

function gorfaildoctor {
    param([Parameter(Position=0, Mandatory=$true)][string]$Session)
    $folder = Resolve-GorSessionFolder -Session $Session
    $results = Get-GorJson -Path (Join-Path $folder 'apply-results.json') -Default @()
    $failed = @($results | Where-Object { $_.Status -eq 'FAILED' -or $_.Status -eq 'SKIPPED' })
    if ($failed.Count -eq 0) {
        Write-Host 'No failed or skipped actions found.' -ForegroundColor Green
    }
    else {
        Write-GorTable -Rows $failed
    }
    return (ConvertTo-GorArray $failed)
}

function gorsnap {
    param([Parameter(Position=0, Mandatory=$true)][string]$NameOrPath)
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $target = Resolve-GorTarget -NameOrPath $NameOrPath
    $id = New-GorId -Prefix 'snap'
    $folder = Join-Path $paths.Snapshots $id
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    $name = Split-Path -Leaf $target
    $dest = Join-Path $folder $name
    if (Test-Path -LiteralPath $target -PathType Container) {
        Copy-Item -LiteralPath $target -Destination $dest -Recurse -Force
    }
    else {
        Copy-Item -LiteralPath $target -Destination $dest -Force
    }
    $meta = [pscustomobject]@{
        Id = $id
        SourcePath = $target
        SnapshotPath = $dest
        CreatedAt = Get-GorNow
    }
    Set-GorJson -Path (Join-Path $folder 'snapshot.json') -Value $meta
    Write-GorTable -Rows @($meta)
    return $meta
}

function gorsnaps {
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $dirs = Get-ChildItem -LiteralPath $paths.Snapshots -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    $rows = foreach ($dir in $dirs) {
        $meta = Get-GorJson -Path (Join-Path $dir.FullName 'snapshot.json') -Default $null
        if ($meta) {
            [pscustomobject]@{
                Id = $meta.Id
                SourcePath = $meta.SourcePath
                SnapshotPath = $meta.SnapshotPath
                CreatedAt = $meta.CreatedAt
            }
        }
    }
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

function Resolve-GorSnapshot {
    param([Parameter(Mandatory=$true)][string]$SnapshotId)
    $paths = Get-GorPaths
    $candidate = Join-Path $paths.Snapshots $SnapshotId
    if (Test-Path -LiteralPath $candidate) {
        return (Resolve-Path -LiteralPath $candidate).Path
    }
    $matches = Get-ChildItem -LiteralPath $paths.Snapshots -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$SnapshotId*" }
    $matchList = @($matches)
    if ($matchList.Count -eq 1) {
        return $matchList[0].FullName
    }
    throw "Snapshot not found or ambiguous: $SnapshotId"
}

function gorrestore {
    param([Parameter(Position=0, Mandatory=$true)][string]$SnapshotId)
    $folder = Resolve-GorSnapshot -SnapshotId $SnapshotId
    $meta = Get-GorJson -Path (Join-Path $folder 'snapshot.json') -Default $null
    if (-not $meta) {
        throw "Snapshot metadata missing: $folder"
    }
    $typed = Read-Host 'Type RESTOREGORRILLA to restore this snapshot over the current target'
    if ($typed -ne 'RESTOREGORRILLA') {
        Write-Warning 'Confirmation did not match. Restore cancelled.'
        return
    }
    if (Test-Path -LiteralPath $meta.SourcePath) {
        New-GorBackup -Path $meta.SourcePath -Reason 'pre-restore' | Out-Null
    }
    if (Test-Path -LiteralPath $meta.SnapshotPath -PathType Container) {
        if (-not (Test-Path -LiteralPath $meta.SourcePath)) {
            New-Item -ItemType Directory -Path $meta.SourcePath -Force | Out-Null
        }
        Copy-Item -LiteralPath (Join-Path $meta.SnapshotPath '*') -Destination $meta.SourcePath -Recurse -Force
    }
    else {
        $parent = Split-Path -Parent $meta.SourcePath
        if ($parent -and -not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        Copy-Item -LiteralPath $meta.SnapshotPath -Destination $meta.SourcePath -Force
    }
    [pscustomobject]@{ SnapshotId=$meta.Id; RestoredTo=$meta.SourcePath; RestoredAt=Get-GorNow; Mode='Overlay restore, no silent deletes' }
}

function gordiff {
    param([Parameter(Position=0, Mandatory=$true)][string]$SnapshotId)
    $folder = Resolve-GorSnapshot -SnapshotId $SnapshotId
    $meta = Get-GorJson -Path (Join-Path $folder 'snapshot.json') -Default $null
    if (-not $meta) {
        throw "Snapshot metadata missing: $folder"
    }
    if (-not (Test-Path -LiteralPath $meta.SourcePath) -or -not (Test-Path -LiteralPath $meta.SnapshotPath)) {
        throw 'Snapshot or source path is missing.'
    }
    $sourceFiles = Get-GorAppFiles -Path $meta.SourcePath -MaxFiles 3000
    $snapFiles = Get-GorAppFiles -Path $meta.SnapshotPath -MaxFiles 3000
    $sourceMap = @{}
    foreach ($file in $sourceFiles) { $sourceMap[$file.RelativePath] = $file.Hash }
    $snapMap = @{}
    foreach ($file in $snapFiles) { $snapMap[$file.RelativePath] = $file.Hash }
    $keys = New-Object System.Collections.Generic.HashSet[string]
    foreach ($key in $sourceMap.Keys) { [void]$keys.Add($key) }
    foreach ($key in $snapMap.Keys) { [void]$keys.Add($key) }
    $rows = foreach ($key in $keys) {
        $sourceHash = $sourceMap[$key]
        $snapHash = $snapMap[$key]
        if ($sourceHash -ne $snapHash) {
            [pscustomobject]@{
                RelativePath = $key
                Status = if (-not $sourceHash) { 'REMOVED_FROM_SOURCE' } elseif (-not $snapHash) { 'ADDED_TO_SOURCE' } else { 'CHANGED' }
                SourceHash = $sourceHash
                SnapshotHash = $snapHash
            }
        }
    }
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

function gorclean {
    param(
        [int]$Keep = 20,
        [switch]$Apply,
        [string]$ConfirmText = ''
    )
    Invoke-GorCleanup -Keep $Keep -Apply:$Apply -ConfirmText $ConfirmText
}

function gorhealth {
    $path = New-GorHealthReport
    Write-Host "Health report written: $path" -ForegroundColor Green
    Invoke-Item -LiteralPath $path -ErrorAction SilentlyContinue
    return $path
}

function gorports {
    $rows = Get-GorListeningPorts
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

function gorport {
    param([Parameter(Position=0, Mandatory=$true)][int]$Port)
    $rows = Get-GorPortOwner -Port $Port
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

function gorslow {
    $rows = Get-GorTopProcesses
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

function gorstartup {
    $rows = Get-GorStartupEntries
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

function gorservices {
    $rows = Get-GorStoppedAutoServices
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

function gorevents {
    $rows = Get-GorRecentErrors
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

function gornetwork {
    $rows = Get-GorNetworkDiagnostics
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

function gorfiredesk {
    $status = Get-GorFireDeskStatus
    Write-GorTable -Rows @([pscustomobject]@{
        Path = $status.Path
        Exists = $status.Exists
        Port5000Owners = @($status.Port5000).Count
        LocalHttp = $status.LocalHttp.Status
        BindingRisks = @($status.BindingRisks).Count
        Compile = if ($status.PythonCompile) { $status.PythonCompile.Status } else { 'N/A' }
    })
    return $status
}

function gorfiredeskfix {
    $path = Get-GorFireDeskPath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "FireDesk path not found: $path"
    }
    $preview = Invoke-GorPatchBindLocal -TargetPath $path -Preview
    if (@($preview).Count -eq 0) {
        Write-Host 'No 0.0.0.0 binding found in FireDesk files.' -ForegroundColor Green
        return @()
    }
    Write-GorTable -Rows $preview
    $typed = Read-Host 'Type FIXFIREDESK to backup and patch FireDesk binding to 127.0.0.1'
    if ($typed -ne 'FIXFIREDESK') {
        Write-Warning 'Confirmation did not match. No patch applied.'
        return
    }
    $result = Invoke-GorPatchBindLocal -TargetPath $path
    Write-GorTable -Rows $result
    return (ConvertTo-GorArray $result)
}

function gorbindlocal {
    param(
        [Parameter(Position=0)][string]$NameOrPath = '',
        [string]$ConfirmText = ''
    )
    $target = if ([string]::IsNullOrWhiteSpace($NameOrPath)) { Get-GorFireDeskPath } else { Resolve-GorTarget -NameOrPath $NameOrPath }
    $preview = Invoke-GorPatchBindLocal -TargetPath $target -Preview
    if (@($preview).Count -eq 0) {
        Write-Host 'No 0.0.0.0 binding found.' -ForegroundColor Green
        return @()
    }
    Write-GorTable -Rows $preview
    $typed = $ConfirmText
    if ($typed -ne 'BINDLOCALGORRILLA') {
        $typed = Read-Host 'Type BINDLOCALGORRILLA to backup and replace 0.0.0.0 with 127.0.0.1'
    }
    if ($typed -ne 'BINDLOCALGORRILLA') {
        Write-Warning 'Confirmation did not match. No patch applied.'
        return
    }
    $result = Invoke-GorPatchBindLocal -TargetPath $target
    Write-GorTable -Rows $result
    return (ConvertTo-GorArray $result)
}

function gorkill5000 {
    param([string]$ConfirmText = '')
    $owners = Get-GorPortOwner -Port 5000
    Write-GorTable -Rows $owners
    if (@($owners).Count -eq 0) {
        Write-Host 'Nothing is listening on port 5000.' -ForegroundColor Green
        return
    }
    $typed = $ConfirmText
    if ($typed -ne 'KILL5000') {
        $typed = Read-Host 'Type KILL5000 to stop the process owner(s) of port 5000'
    }
    if ($typed -ne 'KILL5000') {
        Write-Warning 'Confirmation did not match. No process stopped.'
        return
    }
    $results = New-Object System.Collections.Generic.List[object]
    $pids = @($owners | Select-Object -ExpandProperty OwningProcess -Unique)
    foreach ($pidValue in $pids) {
        try {
            Stop-Process -Id $pidValue -Force -ErrorAction Stop
            $results.Add([pscustomobject]@{ ProcessId=$pidValue; Status='STOPPED' })
        }
        catch {
            $results.Add([pscustomobject]@{ ProcessId=$pidValue; Status='FAILED'; Message=$_.Exception.Message })
        }
    }
    Write-GorTable -Rows $results
    return (ConvertTo-GorArray $results)
}

function gorfiredeskreport {
    $paths = Get-GorPaths
    $status = Get-GorFireDeskStatus
    $sections = @(
        [pscustomobject]@{ Title='FireDesk Status'; Data=$status },
        [pscustomobject]@{ Title='Expected Files'; Data=@($status.Files) },
        [pscustomobject]@{ Title='Port 5000'; Data=@($status.Port5000) },
        [pscustomobject]@{ Title='Binding Risks'; Data=@($status.BindingRisks) },
        [pscustomobject]@{ Title='Python Compile'; Data=$status.PythonCompile }
    )
    $path = Join-Path $paths.Reports 'firedesk.html'
    New-GorHtmlReport -Title 'FireDesk Gorrilla Report' -Sections $sections -Path $path | Out-Null
    Write-Host "FireDesk report written: $path" -ForegroundColor Green
    Invoke-Item -LiteralPath $path -ErrorAction SilentlyContinue
    return $path
}

function gorindex {
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $roots = New-Object System.Collections.Generic.List[string]
    foreach ($folder in @($paths.Reports, $paths.Sessions, $paths.Snapshots)) {
        if (Test-Path -LiteralPath $folder) {
            $roots.Add($folder)
        }
    }
    foreach ($app in (Get-GorSavedApps)) {
        if (Test-Path -LiteralPath $app.Path) {
            $roots.Add([string]$app.Path)
        }
    }
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($root in $roots) {
        $files = Get-GorAppFiles -Path $root -MaxFiles 2500
        foreach ($file in $files) {
            $snippet = ''
            try {
                if ($file.Length -lt 300000) {
                    $raw = Get-Content -LiteralPath $file.Path -Raw -ErrorAction Stop
                    $snippet = $raw.Substring(0, [Math]::Min(800, $raw.Length))
                }
            }
            catch {
                $snippet = ''
            }
            $rows.Add([pscustomobject]@{
                Root = $root
                Path = $file.Path
                RelativePath = $file.RelativePath
                Extension = $file.Extension
                Length = $file.Length
                LastWriteTime = $file.LastWriteTime
                Snippet = $snippet
            })
        }
    }
    Set-GorJson -Path $paths.VaultIndex -Value @(ConvertTo-GorArray $rows)
    Write-Host "Vault index written: $($paths.VaultIndex) [$($rows.Count) files]" -ForegroundColor Green
    return (ConvertTo-GorArray $rows)
}

function gorsearch {
    param([Parameter(Position=0, Mandatory=$true, ValueFromRemainingArguments=$true)][string[]]$Text)
    Initialize-GorEnvironment
    $query = ($Text -join ' ').Trim()
    $paths = Get-GorPaths
    if (-not (Test-Path -LiteralPath $paths.VaultIndex)) {
        gorindex | Out-Null
    }
    $index = Get-GorJson -Path $paths.VaultIndex -Default @()
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($item in (ConvertTo-GorArray $index)) {
        $hay = ([string]$item.Path + "`n" + [string]$item.Snippet)
        if ($hay.IndexOf($query, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $rows.Add([pscustomobject]@{
                Path = $item.Path
                RelativePath = $item.RelativePath
                Snippet = ([string]$item.Snippet).Substring(0, [Math]::Min(240, ([string]$item.Snippet).Length))
            })
        }
    }
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

function gorask {
    param([Parameter(Position=0, Mandatory=$true, ValueFromRemainingArguments=$true)][string[]]$Question)
    $questionText = ($Question -join ' ').Trim()
    $matches = gorsearch $questionText
    $snips = foreach ($match in (@($matches) | Select-Object -First 8)) {
        "PATH: $($match.Path)`n$($match.Snippet)"
    }
    $prompt = @(
        'Answer this question using only the local snippets below. If insufficient, say what is missing.',
        "Question: $questionText",
        'Snippets:',
        ($snips -join "`n---`n")
    ) -join [Environment]::NewLine
    $answer = Invoke-GorLocalAI -Prompt $prompt -TimeoutSeconds 45
    if ($answer) {
        Write-Host $answer
        return $answer
    }
    Write-Warning 'Local ask/Ollama was not available or did not answer. Showing matching snippets instead.'
    return (ConvertTo-GorArray $matches)
}

function Invoke-GorAsk {
    param(
        [Parameter(Mandatory=$true)][string]$Prompt,
        [int]$TimeoutSeconds = 60
    )
    return (Invoke-GorLocalAI -Prompt $Prompt -TimeoutSeconds $TimeoutSeconds)
}

function Invoke-GorCapture {
    param([Parameter(Mandatory=$true)][string]$NameOrPath)
    $target = Resolve-GorTarget -NameOrPath $NameOrPath
    $files = @(Get-GorAppFiles -Path $target -MaxFiles 500 | Sort-Object LastWriteTime -Descending | Select-Object -First 60)
    $git = ''
    if ((Test-Path -LiteralPath (Join-Path $target '.git')) -and (Get-Command git -ErrorAction SilentlyContinue)) {
        try {
            $git = (git -C $target status --short 2>$null | Out-String).Trim()
        }
        catch {
            $git = $_.Exception.Message
        }
    }
    $configLines = Search-GorRegexInFiles -Path $target -Pattern '(0\.0\.0\.0|127\.0\.0\.1|debug\s*=\s*true|SECRET|TOKEN|PASSWORD)' -MaxFiles 600 -MaxMatches 80
    [pscustomobject]@{
        CapturedAt = Get-GorNow
        Target = $target
        AppType = Get-GorAppType -Path $target
        Processes = @(Get-GorTopProcesses | Select-Object -First 15)
        ListeningPorts = @(Get-GorListeningPorts)
        Disk = @(Get-GorDiskInfo)
        RecentFiles = $files
        GitStatus = $git
        ConfigLines = @(ConvertTo-GorArray $configLines)
        Sessions = @(gorsessions | Select-Object -First 10)
    }
}

function New-GorReport {
    param(
        [Parameter(Mandatory=$true)][string]$Title,
        [Parameter(Mandatory=$true)]$Sections,
        [string]$FileName = ''
    )
    $paths = Get-GorPaths
    if ([string]::IsNullOrWhiteSpace($FileName)) {
        $FileName = (($Title -replace '[^A-Za-z0-9]+','-').Trim('-') + '.html')
    }
    $path = Join-Path $paths.Reports $FileName
    New-GorHtmlReport -Title $Title -Sections $Sections -Path $path | Out-Null
    Write-GorLedger -Type 'report' -Message "Report written: $Title" -Data ([pscustomobject]@{ Path=$path }) | Out-Null
    Write-Host "Report written: $path" -ForegroundColor Green
    Invoke-Item -LiteralPath $path -ErrorAction SilentlyContinue
    return $path
}

function Get-GorProfilePath {
    param([Parameter(Mandatory=$true)][string]$Name)
    $safe = ($Name -replace '[^A-Za-z0-9_.-]+','-').Trim('-')
    if ([string]::IsNullOrWhiteSpace($safe)) {
        $safe = 'App'
    }
    return (Join-Path (Get-GorPaths).Profiles ($safe + '.json'))
}

function Get-GorProfileObject {
    param([Parameter(Mandatory=$true)][string]$Name)
    $path = Get-GorProfilePath -Name $Name
    return (Read-GorJson -Path $path -Default $null)
}

function Save-GorProfileObject {
    param([Parameter(Mandatory=$true)]$Profile)
    $path = Get-GorProfilePath -Name ([string]$Profile.Name)
    Write-GorJson -Path $path -Value $Profile
    return $path
}

function Get-GorLastGoodModuleBackups {
    $paths = Get-GorPaths
    $rows = @()
    if (Test-Path -LiteralPath $paths.Backups) {
        $dirs = @(Get-ChildItem -LiteralPath $paths.Backups -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
        $rows = foreach ($dir in $dirs) {
            $module = Get-ChildItem -LiteralPath $dir.FullName -Recurse -File -Filter 'CommandUnitGorrilla.psm1' -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($module) {
                [pscustomobject]@{
                    Id = $dir.Name
                    Folder = $dir.FullName
                    ModuleFile = $module.FullName
                    LastWriteTime = $dir.LastWriteTime
                }
            }
        }
    }
    return (ConvertTo-GorArray $rows)
}

function New-GorRescueLauncher {
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $manifest = Join-Path $paths.ModuleRoot 'CommandUnitGorrilla.psd1'
    $ps1 = @(
        '$ErrorActionPreference = "Continue"',
        '$manifest = "' + ($manifest.Replace('"','""')) + '"',
        'Import-Module -Name $manifest -Force',
        'gorpanic',
        'gorstatus'
    )
    Set-Content -LiteralPath $paths.RescuePs1 -Value $ps1 -Encoding UTF8
    $cmd = @(
        '@echo off',
        'setlocal',
        'set "GOR_RESCUE=' + $paths.RescuePs1 + '"',
        'where pwsh.exe >nul 2>nul',
        'if %errorlevel%==0 (',
        '  pwsh.exe -NoProfile -NoLogo -NoExit -ExecutionPolicy Bypass -File "%GOR_RESCUE%"',
        ') else (',
        '  powershell.exe -NoProfile -NoLogo -NoExit -ExecutionPolicy Bypass -File "%GOR_RESCUE%"',
        ')'
    )
    Set-Content -LiteralPath $paths.RescueCmd -Value $cmd -Encoding ASCII
    [pscustomobject]@{ RescueCmd=$paths.RescueCmd; RescuePs1=$paths.RescuePs1 }
}

function Get-GorDesiredState {
    $paths = Get-GorPaths
    $fire = Get-GorFireDeskPath
    [pscustomobject]@{
        ExportedAt = Get-GorNow
        ModuleExists = Test-Path -LiteralPath (Join-Path $paths.ModuleRoot 'CommandUnitGorrilla.psm1')
        DesktopFolderExists = Test-Path -LiteralPath $paths.Root
        FireDeskPath = $fire
        FireDeskExists = Test-Path -LiteralPath $fire
        FireDeskConfigLocal = (@(Search-GorRegexInFiles -Path $fire -Pattern '0\.0\.0\.0' -MaxFiles 300 -MaxMatches 20).Count -eq 0)
        Port5000LanExposure = (@(Get-GorPortOwner -Port 5000 | Where-Object { $_.LocalAddress -eq '0.0.0.0' -or $_.LocalAddress -eq '::' }).Count -gt 0)
        ProfileAutoload = (gorprofile-check -Quiet).Status
        LauncherExists = Test-Path -LiteralPath $paths.DesktopCmd
        ReportsFolderExists = Test-Path -LiteralPath $paths.Reports
        SessionsFolderExists = Test-Path -LiteralPath $paths.Sessions
        SnapshotsFolderExists = Test-Path -LiteralPath $paths.Snapshots
    }
}

function Test-GorDesiredState {
    $state = Get-GorDesiredState
    $rows = @(
        [pscustomobject]@{ Check='Module'; Status=if ($state.ModuleExists) { 'OK' } else { 'FAILED' }; Detail=$state.ModuleExists },
        [pscustomobject]@{ Check='DesktopFolder'; Status=if ($state.DesktopFolderExists) { 'OK' } else { 'FAILED' }; Detail=$state.DesktopFolderExists },
        [pscustomobject]@{ Check='FireDeskPath'; Status=if ($state.FireDeskExists) { 'OK' } else { 'WARN' }; Detail=$state.FireDeskPath },
        [pscustomobject]@{ Check='FireDeskLocalBinding'; Status=if ($state.FireDeskConfigLocal) { 'OK' } else { 'WARN' }; Detail='0.0.0.0 should be reviewed' },
        [pscustomobject]@{ Check='Port5000LanExposure'; Status=if (-not $state.Port5000LanExposure) { 'OK' } else { 'WARN' }; Detail=$state.Port5000LanExposure },
        [pscustomobject]@{ Check='ProfileAutoload'; Status=$state.ProfileAutoload; Detail='' },
        [pscustomobject]@{ Check='Launcher'; Status=if ($state.LauncherExists) { 'OK' } else { 'FAILED' }; Detail=$state.LauncherExists },
        [pscustomobject]@{ Check='Reports'; Status=if ($state.ReportsFolderExists) { 'OK' } else { 'FAILED' }; Detail=$state.ReportsFolderExists },
        [pscustomobject]@{ Check='Sessions'; Status=if ($state.SessionsFolderExists) { 'OK' } else { 'FAILED' }; Detail=$state.SessionsFolderExists },
        [pscustomobject]@{ Check='Snapshots'; Status=if ($state.SnapshotsFolderExists) { 'OK' } else { 'FAILED' }; Detail=$state.SnapshotsFolderExists }
    )
    return (ConvertTo-GorArray $rows)
}

function New-GorPatchPlan {
    param([Parameter(Mandatory=$true)][string]$NameOrPath)
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $target = Resolve-GorTarget -NameOrPath $NameOrPath
    $id = New-GorId -Prefix 'patch'
    $folder = Join-Path $paths.PatchStudio $id
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    $actions = New-Object System.Collections.Generic.List[object]
    $bind = Invoke-GorPatchBindLocal -TargetPath $target -Preview
    foreach ($item in (ConvertTo-GorArray $bind)) {
        $actions.Add([pscustomobject]@{ Id='bind-local'; Risk='MEDIUM'; File=$item.Path; Line=$item.LineNumber; From='0.0.0.0'; To='127.0.0.1'; AutoPatch=$true; Reason='Local dashboard should bind to loopback by default.' })
    }
    $debug = Search-GorRegexInFiles -Path $target -Pattern 'debug\s*=\s*true|DEBUG\s*=\s*True' -MaxFiles 1200 -MaxMatches 80
    foreach ($item in (ConvertTo-GorArray $debug)) {
        $actions.Add([pscustomobject]@{ Id='debug-warning'; Risk='LOW'; File=$item.Path; Line=$item.LineNumber; From=$item.Line; To='Review only'; AutoPatch=$false; Reason='Debug mode should not be enabled for normal local operation.' })
    }
    $todo = Search-GorRegexInFiles -Path $target -Pattern 'TODO|FIXME' -MaxFiles 1200 -MaxMatches 80
    foreach ($item in (ConvertTo-GorArray $todo)) {
        $actions.Add([pscustomobject]@{ Id='todo'; Risk='LOW'; File=$item.Path; Line=$item.LineNumber; From=$item.Line; To='Review only'; AutoPatch=$false; Reason='Outstanding work marker.' })
    }
    $secret = Search-GorRegexInFiles -Path $target -Pattern '(api[_-]?key|secret|token|password)\s*[:=]\s*["''][^"'']{8,}' -MaxFiles 1200 -MaxMatches 80
    foreach ($item in (ConvertTo-GorArray $secret)) {
        $actions.Add([pscustomobject]@{ Id='secret-risk'; Risk='HIGH'; File=$item.Path; Line=$item.LineNumber; From='Secret-like value'; To='Report only'; AutoPatch=$false; Reason='Hardcoded secret-like values must be reviewed manually.' })
    }
    $plan = [pscustomobject]@{
        Id = $id
        Target = $target
        CreatedAt = Get-GorNow
        Folder = $folder
        Actions = @(ConvertTo-GorArray $actions)
        BackupId = ''
    }
    Write-GorJson -Path (Join-Path $folder 'patch-plan.json') -Value $plan
    Write-GorLedger -Type 'patch-plan' -Message "Patch plan created: $id" -Data $plan | Out-Null
    return $plan
}

function Resolve-GorPatchFolder {
    param([Parameter(Mandatory=$true)][string]$Session)
    $paths = Get-GorPaths
    $candidate = Join-Path $paths.PatchStudio $Session
    if (Test-Path -LiteralPath $candidate) {
        return (Resolve-Path -LiteralPath $candidate).Path
    }
    $matches = @(Get-ChildItem -LiteralPath $paths.PatchStudio -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$Session*" })
    if ($matches.Count -eq 1) {
        return $matches[0].FullName
    }
    throw "Patch session not found or ambiguous: $Session"
}

function Get-GorPatchPlan {
    param([Parameter(Mandatory=$true)][string]$Session)
    $folder = Resolve-GorPatchFolder -Session $Session
    $plan = Read-GorJson -Path (Join-Path $folder 'patch-plan.json') -Default $null
    if (-not $plan) {
        throw "Patch plan missing: $folder"
    }
    return $plan
}

function Get-GorOllamaModels {
    $rows = New-Object System.Collections.Generic.List[object]
    $ollama = Get-Command ollama -ErrorAction SilentlyContinue
    if (-not $ollama) {
        return @([pscustomobject]@{ Name='ollama'; Status='MISSING'; Detail='Install Ollama locally to enable model routing.' })
    }
    try {
        $job = Start-Job -ScriptBlock { ollama list 2>$null }
        $done = Wait-Job -Job $job -Timeout 5
        if (-not $done) {
            Stop-Job -Job $job -ErrorAction SilentlyContinue
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
            return @([pscustomobject]@{ Name='ollama'; Status='TIMEOUT'; Detail='ollama list did not answer within 5 seconds.' })
        }
        $list = @(Receive-Job -Job $job)
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        foreach ($line in ($list | Select-Object -Skip 1)) {
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                $parts = @($line -split '\s+')
                $rows.Add([pscustomobject]@{ Name=$parts[0]; Status='INSTALLED'; Detail=$line })
            }
        }
    }
    catch {
        $rows.Add([pscustomobject]@{ Name='ollama'; Status='FAILED'; Detail=$_.Exception.Message })
    }
    return (ConvertTo-GorArray $rows)
}

function Get-GorToolRows {
    $names = @('pwsh','git','python','node','npm','dotnet','ollama','adb','winget')
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($name in $names) {
        $cmd = Test-GorCommand -Name $name
        $rows.Add([pscustomobject]@{ Tool=$name; Status=if ($cmd.Exists) { 'OK' } else { 'MISSING' }; Source=$cmd.Path })
    }
    foreach ($module in @('Pester','Microsoft.PowerShell.SecretManagement','Microsoft.PowerShell.PSResourceGet')) {
        $found = Get-Module -ListAvailable -Name $module -ErrorAction SilentlyContinue | Select-Object -First 1
        $rows.Add([pscustomobject]@{ Tool=$module; Status=if ($found) { 'OK' } else { 'MISSING' }; Source=if ($found) { $found.ModuleBase } else { '' } })
    }
    return (ConvertTo-GorArray $rows)
}

function Get-GorSecurityFindings {
    param([string]$NameOrPath = '')
    $rows = New-Object System.Collections.Generic.List[object]
    $ports = Get-GorListeningPorts
    foreach ($port in (ConvertTo-GorArray $ports)) {
        if ($port.LocalAddress -eq '0.0.0.0' -or $port.LocalAddress -eq '::') {
            $rows.Add([pscustomobject]@{ Check='LAN exposure'; Risk='MEDIUM'; Target=$port.LocalPort; Detail=($port | Out-String).Trim() })
        }
    }
    $profile = gorprofile-check -Quiet
    if ($profile.Status -ne 'OK') {
        $rows.Add([pscustomobject]@{ Check='PowerShell profile'; Risk='LOW'; Target='Profile'; Detail=$profile.Detail })
    }
    if (-not [string]::IsNullOrWhiteSpace($NameOrPath)) {
        $target = Resolve-GorTarget -NameOrPath $NameOrPath
        $secret = Search-GorRegexInFiles -Path $target -Pattern '(api[_-]?key|secret|token|password)\s*[:=]\s*["''][^"'']{8,}' -MaxFiles 1200 -MaxMatches 100
        foreach ($item in (ConvertTo-GorArray $secret)) {
            $rows.Add([pscustomobject]@{ Check='Secret-like string'; Risk='HIGH'; Target=$item.Path; Detail=('Line ' + $item.LineNumber) })
        }
        $debug = Search-GorRegexInFiles -Path $target -Pattern 'debug\s*=\s*true|DEBUG\s*=\s*True|0\.0\.0\.0' -MaxFiles 1200 -MaxMatches 100
        foreach ($item in (ConvertTo-GorArray $debug)) {
            $rows.Add([pscustomobject]@{ Check='Config risk'; Risk='MEDIUM'; Target=$item.Path; Detail=$item.Line })
        }
    }
    return (ConvertTo-GorArray $rows)
}

function New-GorAlert {
    param(
        [string]$Id,
        [string]$Severity,
        [string]$Area,
        [string]$Title,
        [string]$Detail,
        [string]$Command = '',
        [string]$Confirm = '',
        [string]$Status = 'OPEN'
    )
    [pscustomobject]@{
        Id = $Id
        Severity = $Severity
        Area = $Area
        Title = $Title
        Detail = $Detail
        Command = $Command
        Confirm = $Confirm
        Status = $Status
        CreatedAt = Get-GorNow
    }
}

function Get-GorAlerts {
    Initialize-GorEnvironment
    $alerts = New-Object System.Collections.Generic.List[object]
    $paths = Get-GorPaths
    $status = Get-GorStatusObject
    if (-not $status.ParserOk) {
        $alerts.Add((New-GorAlert -Id 'module-parse' -Severity 'HIGH' -Area 'Module' -Title 'Gorrilla module has a parse problem' -Detail 'The installed module did not parse cleanly. Use rescue or rollback before adding more changes.' -Command 'gortest module'))
    }
    $fire = Get-GorFireDeskStatus
    if (-not $fire.Exists) {
        $alerts.Add((New-GorAlert -Id 'firedesk-missing' -Severity 'HIGH' -Area 'FireDesk' -Title 'FireDeskElite Dashboard is missing' -Detail $fire.Path -Command 'gorprofile FireDesk'))
    }
    else {
        foreach ($file in (ConvertTo-GorArray $fire.Files)) {
            if (-not $file.Exists) {
                $alerts.Add((New-GorAlert -Id ('firedesk-file-' + $file.Name) -Severity 'MEDIUM' -Area 'FireDesk' -Title ("Missing FireDesk file: " + $file.Name) -Detail $file.Path -Command 'gordoctor FireDesk'))
            }
        }
        if (@($fire.BindingRisks).Count -gt 0) {
            $alerts.Add((New-GorAlert -Id 'firedesk-bind' -Severity 'MEDIUM' -Area 'FireDesk' -Title 'FireDesk may expose a dashboard binding' -Detail '0.0.0.0 binding risk found. Local dashboards should prefer 127.0.0.1.' -Command 'gorbindlocal FireDesk' -Confirm 'BINDLOCALGORRILLA'))
        }
        $lanOwners = @($fire.Port5000 | Where-Object { $_.LocalAddress -eq '0.0.0.0' -or $_.LocalAddress -eq '::' })
        if ($lanOwners.Count -gt 0) {
            $alerts.Add((New-GorAlert -Id 'port-5000-lan' -Severity 'HIGH' -Area 'Network' -Title 'Port 5000 is listening beyond localhost' -Detail 'A local dashboard port should not be exposed to the LAN by default.' -Command 'gorkill5000' -Confirm 'KILL5000'))
        }
        if (-not $fire.LocalHttp -or $fire.LocalHttp.Status -ne 'OK') {
            $alerts.Add((New-GorAlert -Id 'firedesk-http' -Severity 'MEDIUM' -Area 'FireDesk' -Title 'FireDesk local web check is not healthy' -Detail ([string]$fire.LocalHttp.Message) -Command 'gorfiredeskreport'))
        }
        if ($fire.PythonCompile -and $fire.PythonCompile.Status -eq 'FAILED') {
            $alerts.Add((New-GorAlert -Id 'firedesk-compile' -Severity 'HIGH' -Area 'FireDesk' -Title 'FireDesk Python compile failed' -Detail ([string]$fire.PythonCompile.Output) -Command 'gordoctor FireDesk'))
        }
    }
    $toolRows = Get-GorToolRows
    foreach ($tool in (ConvertTo-GorArray $toolRows)) {
        if ($tool.Status -eq 'MISSING' -and $tool.Tool -in @('pwsh','git','python','node','npm','dotnet','ollama','adb')) {
            $alerts.Add((New-GorAlert -Id ('tool-' + $tool.Tool) -Severity 'LOW' -Area 'Tools' -Title ("Useful tool missing: " + $tool.Tool) -Detail 'Some advanced Gorrilla features may be reduced.' -Command 'gortools check'))
        }
    }
    foreach ($issue in (Get-GorEliteStackIssues -Rows (Get-GorEliteStackRows -Quick))) {
        if ($issue.Severity -in @('HIGH','MEDIUM')) {
            $alerts.Add((New-GorAlert -Id ('elite-' + ($issue.Tool -replace '[^A-Za-z0-9]+','-')) -Severity $issue.Severity -Area 'Elite Stack' -Title ("Elite stack issue: " + $issue.Tool) -Detail ($issue.Problem + ' ' + $issue.Fix) -Command 'gorelite-fix'))
        }
    }
    $profile = gorprofile-check -Quiet
    if ($profile.Status -ne 'OK') {
        $alerts.Add((New-GorAlert -Id 'profile-autoload' -Severity 'LOW' -Area 'Profile' -Title 'Gorrilla profile autoload is not configured' -Detail $profile.Detail -Command 'gorprofile-repair' -Confirm 'REPAIRGORPROFILE'))
    }
    $desktopPlan = @(Get-GorDesktopTidyPlan)
    if ($desktopPlan.Count -gt 0) {
        $alerts.Add((New-GorAlert -Id 'desktop-tidy' -Severity 'LOW' -Area 'Desktop' -Title 'Desktop has loose items that can be organised' -Detail ($desktopPlan.Count.ToString() + ' item(s) can be moved into the numbered folder system.') -Command 'gordesktop tidy'))
    }
    $reportsCount = @(Get-ChildItem -LiteralPath $paths.Reports -File -ErrorAction SilentlyContinue).Count
    if ($reportsCount -eq 0) {
        $alerts.Add((New-GorAlert -Id 'reports-empty' -Severity 'LOW' -Area 'Reports' -Title 'No reports have been generated yet' -Detail 'Generate a baseline so the app has evidence to compare against.' -Command 'gorreport all'))
    }
    if ($alerts.Count -eq 0) {
        $alerts.Add((New-GorAlert -Id 'all-clear' -Severity 'OK' -Area 'System' -Title 'No urgent problems detected' -Detail 'FireDeskElite and Gorrilla look healthy from the current local checks.' -Command 'gortest all' -Status 'CLEAR'))
    }
    Write-GorJson -Path $paths.AlertsJson -Value @(ConvertTo-GorArray $alerts)
    return (ConvertTo-GorArray $alerts)
}

function Get-GorOptions {
    param($Alerts = $null)
    if ($null -eq $Alerts) {
        $Alerts = Get-GorAlerts
    }
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($alert in (ConvertTo-GorArray $Alerts)) {
        if ($alert.Id -eq 'all-clear') {
            $rows.Add([pscustomobject]@{ Priority=1; Option='Keep watch'; Command='gorwatch FireDesk'; Risk='LOW'; Why='Continue monitoring and generate reports only.'; Confirm='' })
            $rows.Add([pscustomobject]@{ Priority=2; Option='Create quality baseline'; Command='gorreport all'; Risk='LOW'; Why='Write a full baseline report while the system is healthy.'; Confirm='' })
            continue
        }
        if (-not [string]::IsNullOrWhiteSpace([string]$alert.Command)) {
            $rows.Add([pscustomobject]@{ Priority=if ($alert.Severity -eq 'HIGH') { 1 } elseif ($alert.Severity -eq 'MEDIUM') { 2 } else { 3 }; Option=$alert.Title; Command=$alert.Command; Risk=$alert.Severity; Why=$alert.Detail; Confirm=$alert.Confirm })
        }
    }
    $rows.Add([pscustomobject]@{ Priority=9; Option='Ask local AI for a repair plan'; Command='goraskproject FireDesk "what should I fix next?"'; Risk='LOW'; Why='Uses local Ollama only, no paid API.'; Confirm='' })
    $paths = Get-GorPaths
    Write-GorJson -Path $paths.OptionsJson -Value @(ConvertTo-GorArray $rows)
    return (ConvertTo-GorArray ($rows | Sort-Object Priority, Option))
}

function Invoke-GorAdvisor {
    $alerts = Get-GorAlerts
    $options = Get-GorOptions -Alerts $alerts
    [pscustomobject]@{
        CheckedAt = Get-GorNow
        Alerts = @(ConvertTo-GorArray $alerts)
        Options = @(ConvertTo-GorArray $options)
        Summary = if (@($alerts | Where-Object Severity -in @('HIGH','MEDIUM')).Count -gt 0) { 'Attention needed' } else { 'Healthy' }
    }
}

function Get-GorQualityRows {
    param([Parameter(Mandatory=$true)][string]$NameOrPath)
    $target = Resolve-GorTarget -NameOrPath $NameOrPath
    $checks = New-Object System.Collections.Generic.List[object]
    $hasReadme = Test-GorAnyFile -Path $target -Names @('README.md','README.txt','readme.md')
    $checks.Add([pscustomobject]@{ Check='README'; Points=10; Passed=$hasReadme })
    $hasDeps = Test-GorAnyFile -Path $target -Names @('requirements.txt','package.json','*.csproj','pyproject.toml')
    $checks.Add([pscustomobject]@{ Check='Dependency file'; Points=10; Passed=$hasDeps })
    $hasEnv = (Test-Path -LiteralPath (Join-Path $target '.venv')) -or (Test-Path -LiteralPath (Join-Path $target 'node_modules'))
    $checks.Add([pscustomobject]@{ Check='Local dependency folder'; Points=8; Passed=$hasEnv })
    $bindRisk = @(Search-GorRegexInFiles -Path $target -Pattern '0\.0\.0\.0' -MaxFiles 1000 -MaxMatches 20).Count -gt 0
    $checks.Add([pscustomobject]@{ Check='No LAN bind risk'; Points=12; Passed=(-not $bindRisk) })
    $secretRisk = @(Search-GorRegexInFiles -Path $target -Pattern '(api[_-]?key|secret|token|password)\s*[:=]\s*["''][^"'']{8,}' -MaxFiles 1000 -MaxMatches 20).Count -gt 0
    $checks.Add([pscustomobject]@{ Check='No obvious secrets'; Points=12; Passed=(-not $secretRisk) })
    $checks.Add([pscustomobject]@{ Check='Logs folder'; Points=6; Passed=(Test-Path -LiteralPath (Join-Path $target 'logs')) })
    $profiles = @(Get-ChildItem -LiteralPath (Get-GorPaths).Profiles -File -Filter '*.json' -ErrorAction SilentlyContinue)
    $profileHit = $false
    foreach ($file in $profiles) {
        $p = Read-GorJson -Path $file.FullName -Default $null
        if ($p -and ([string]$p.Path -eq $target)) {
            $profileHit = $true
        }
    }
    $checks.Add([pscustomobject]@{ Check='Has Gorrilla profile'; Points=10; Passed=$profileHit })
    $snapshots = @(Get-ChildItem -LiteralPath (Get-GorPaths).Snapshots -Directory -ErrorAction SilentlyContinue)
    $checks.Add([pscustomobject]@{ Check='Has snapshot'; Points=8; Passed=($snapshots.Count -gt 0) })
    $checks.Add([pscustomobject]@{ Check='Has report'; Points=8; Passed=(@(Get-ChildItem -LiteralPath (Get-GorPaths).Reports -File -ErrorAction SilentlyContinue).Count -gt 0) })
    $score = 0
    $max = 0
    foreach ($check in $checks) {
        $max += [int]$check.Points
        if ($check.Passed) {
            $score += [int]$check.Points
        }
    }
    [pscustomobject]@{ Target=$target; Score=[int](($score / [Math]::Max(1,$max)) * 100); Checks=@(ConvertTo-GorArray $checks) }
}

function Get-GorDoctorRows {
    param(
        [Parameter(Mandatory=$true)][string]$NameOrPath,
        [switch]$Deep
    )
    $target = Resolve-GorTarget -NameOrPath $NameOrPath
    $files = @(Get-GorAppFiles -Path $target -MaxFiles $(if ($Deep) { 5000 } else { 1200 }))
    $large = @($files | Sort-Object Length -Descending | Select-Object -First 20)
    $todos = Search-GorRegexInFiles -Path $target -Pattern 'TODO|FIXME' -MaxFiles 1500 -MaxMatches 100
    $configs = @($files | Where-Object { $_.Name -match 'config|settings|env|\.json$|\.yaml$|\.toml$' } | Select-Object -First 80)
    [pscustomobject]@{
        Target = $target
        AppType = Get-GorAppType -Path $target
        FileCount = $files.Count
        DependencyStatus = Get-GorAppIndex -Path $target
        KeyFiles = @($files | Where-Object { $_.Name -in @('README.md','app.py','config.py','requirements.txt','package.json','main.py') })
        LargeFiles = $large
        ConfigFiles = $configs
        Todos = @(ConvertTo-GorArray $todos)
        Security = @(Get-GorSecurityFindings -NameOrPath $target)
        Performance = @(Get-GorPerfRows -NameOrPath $target)
    }
}

function Get-GorPerfRows {
    param([string]$NameOrPath = '')
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($proc in (Get-GorTopProcesses | Select-Object -First 10)) {
        $rows.Add([pscustomobject]@{ Area='Process'; Name=$proc.ProcessName; Value=$proc.CPU; Detail=('RAM MB ' + $proc.WorkingSetMB) })
    }
    foreach ($disk in (Get-GorDiskInfo)) {
        $rows.Add([pscustomobject]@{ Area='Disk'; Name=$disk.Name; Value=$disk.FreeGB; Detail=('Free GB of ' + $disk.SizeGB) })
    }
    if (-not [string]::IsNullOrWhiteSpace($NameOrPath)) {
        $target = Resolve-GorTarget -NameOrPath $NameOrPath
        $files = @(Get-GorAppFiles -Path $target -MaxFiles 5000)
        $size = ($files | Measure-Object Length -Sum).Sum
        $rows.Add([pscustomobject]@{ Area='App'; Name=$target; Value=[math]::Round(($size / 1MB),2); Detail='Folder MB sampled from project files' })
        $large = @($files | Sort-Object Length -Descending | Select-Object -First 10)
        foreach ($file in $large) {
            $rows.Add([pscustomobject]@{ Area='LargeFile'; Name=$file.RelativePath; Value=[math]::Round(($file.Length / 1MB),2); Detail='MB' })
        }
    }
    return (ConvertTo-GorArray $rows)
}

function Normalize-GorIntegrationName {
    param([AllowNull()][string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) {
        return ''
    }
    $clean = $Name.Trim()
    $clean = $clean -replace '\.lnk$', ''
    $clean = $clean -replace '\s+\(\d+\)$', ''
    $clean = $clean -replace '\s+', ' '
    return $clean.ToLowerInvariant()
}

function Get-GorIntegrationCsvValue {
    param(
        [Parameter(Mandatory=$true)]$Row,
        [Parameter(Mandatory=$true)][string[]]$Names
    )
    foreach ($name in $Names) {
        $prop = $Row.PSObject.Properties[$name]
        if ($prop -and $null -ne $prop.Value) {
            return ([string]$prop.Value).Trim()
        }
    }
    return ''
}

function Copy-GorIntegrationImportIfMissing {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Destination
    )
    if ((-not (Test-Path -LiteralPath $Source)) -or (Test-Path -LiteralPath $Destination)) {
        return $false
    }
    $parent = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Copy-Item -LiteralPath $Source -Destination $Destination -ErrorAction Stop
    Write-GorLedger -Type 'integration-import' -Message 'Copied integration dataset into the local PowerShell Gorrilla import cache.' -Data ([pscustomobject]@{ Source=$Source; Destination=$Destination }) | Out-Null
    return $true
}

function Sync-GorIntegrationImports {
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $moduleRoot = Get-GorModuleRoot
    $desktop = Get-GorDesktop
    $legacyImportRoot = Join-Path $moduleRoot 'PowerGorilla\data\imports'
    $expected = @(
        [pscustomobject]@{ Size=2; File='Two_App_20K_Free_OpenSource_Combinations.csv'; Zip='' },
        [pscustomobject]@{ Size=3; File='Three_App_200K_Free_OpenSource_Integrations.csv'; Zip='Three_App_200K_Free_OpenSource_Integrations_CSV.zip' },
        [pscustomobject]@{ Size=4; File='Four_App_400K_Free_OpenSource_Integrations.csv'; Zip='Four_App_400K_Free_OpenSource_Integrations_CSV.zip' }
    )
    $copied = New-Object System.Collections.Generic.List[object]
    $step = 0
    foreach ($item in $expected) {
        $step++
        Write-Progress -Activity 'PowerShell Gorrilla integration imports' -Status ('Preparing ' + $item.File) -PercentComplete (($step / $expected.Count) * 100)
        $destination = Join-Path $paths.IntegrationImports $item.File
        if (Test-Path -LiteralPath $destination) {
            continue
        }
        $csvCandidates = @(
            (Join-Path $legacyImportRoot $item.File),
            (Join-Path $desktop $item.File)
        )
        foreach ($candidate in $csvCandidates) {
            if (Copy-GorIntegrationImportIfMissing -Source $candidate -Destination $destination) {
                $copied.Add([pscustomobject]@{ Source=$candidate; Destination=$destination; Mode='Copy' })
                break
            }
        }
        if ((Test-Path -LiteralPath $destination) -or [string]::IsNullOrWhiteSpace($item.Zip)) {
            continue
        }
        $zipCandidates = @(
            (Join-Path $desktop $item.Zip),
            (Join-Path $moduleRoot $item.Zip)
        )
        foreach ($zip in $zipCandidates) {
            if (-not (Test-Path -LiteralPath $zip)) {
                continue
            }
            try {
                $extractRoot = Join-Path $paths.IntegrationCache ([IO.Path]::GetFileNameWithoutExtension($zip))
                if (-not (Test-Path -LiteralPath $extractRoot)) {
                    New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null
                    Expand-Archive -LiteralPath $zip -DestinationPath $extractRoot -Force -ErrorAction Stop
                }
                $csv = Get-ChildItem -LiteralPath $extractRoot -Recurse -File -Filter $item.File -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($csv -and (Copy-GorIntegrationImportIfMissing -Source $csv.FullName -Destination $destination)) {
                    $copied.Add([pscustomobject]@{ Source=$zip; Destination=$destination; Mode='Extract' })
                    break
                }
            }
            catch {
                Add-GorSafetyNotice -Area 'Integration import' -Message 'A zipped integration dataset could not be extracted into the local cache.' -Data ([pscustomobject]@{ Zip=$zip; Error=$_.Exception.Message })
            }
        }
    }
    Write-Progress -Activity 'PowerShell Gorrilla integration imports' -Completed
    return (ConvertTo-GorArray $copied)
}

function Get-GorIntegrationDatasetSources {
    $paths = Get-GorPaths
    Sync-GorIntegrationImports | Out-Null
    $specs = @(
        [pscustomobject]@{ Size=2; Kind='2-App'; File='Two_App_20K_Free_OpenSource_Combinations.csv' },
        [pscustomobject]@{ Size=3; Kind='3-App'; File='Three_App_200K_Free_OpenSource_Integrations.csv' },
        [pscustomobject]@{ Size=4; Kind='4-App'; File='Four_App_400K_Free_OpenSource_Integrations.csv' }
    )
    foreach ($spec in $specs) {
        $path = Join-Path $paths.IntegrationImports $spec.File
        if (Test-Path -LiteralPath $path) {
            $file = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
            [pscustomobject]@{
                Size = $spec.Size
                Kind = $spec.Kind
                Path = $path
                Status = 'READY'
                RowsSampled = 0
                LengthMB = if ($file) { [math]::Round($file.Length / 1MB, 2) } else { 0 }
                Message = 'Local cached CSV import is ready.'
            }
        }
        else {
            [pscustomobject]@{
                Size = $spec.Size
                Kind = $spec.Kind
                Path = $path
                Status = 'MISSING'
                RowsSampled = 0
                LengthMB = 0
                Message = 'Dataset was not found. Place the CSV in the PowerShell Gorrilla integration imports folder.'
            }
        }
    }
}

function Get-GorIntegrationAppNamesFromRow {
    param(
        [Parameter(Mandatory=$true)]$Row,
        [Parameter(Mandatory=$true)][int]$Size
    )
    $names = New-Object System.Collections.Generic.List[string]
    foreach ($column in @('App A','App B','App C','App D')) {
        if ($names.Count -ge $Size) {
            break
        }
        $value = Get-GorIntegrationCsvValue -Row $Row -Names @($column)
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $names.Add($value)
        }
    }
    return @($names)
}

function ConvertTo-GorIntegrationWorkflow {
    param(
        [Parameter(Mandatory=$true)]$Row,
        [Parameter(Mandatory=$true)]$Source
    )
    $apps = @(Get-GorIntegrationAppNamesFromRow -Row $Row -Size $Source.Size)
    if ($apps.Count -lt 2) {
        return $null
    }
    $what = Get-GorIntegrationCsvValue -Row $Row -Names @('What They Can Do Together','What It Can Do','Power Uses')
    $category = Get-GorIntegrationCsvValue -Row $Row -Names @('Workflow Category','Integration Family','Category Mix')
    $pattern = Get-GorIntegrationCsvValue -Row $Row -Names @('Integration Pattern','Action Chain','Workflow Chain')
    $useMode = Get-GorIntegrationCsvValue -Row $Row -Names @('Free/Open-Source Use Mode','Free/Open-Source Mode','Free/Open-Source Mode')
    $difficulty = Get-GorIntegrationCsvValue -Row $Row -Names @('Difficulty')
    $automation = Get-GorIntegrationCsvValue -Row $Row -Names @('Automation Level','Automation Ready')
    $internetNeed = Get-GorIntegrationCsvValue -Row $Row -Names @('Internet / API Need')
    $caution = Get-GorIntegrationCsvValue -Row $Row -Names @('Confidence / Caution','Desktop Use')
    $openSource = Get-GorIntegrationCsvValue -Row $Row -Names @('Open Source Involved','Open Source Included','Open-Source Count','Open Source Count')
    $method = Get-GorIntegrationCsvValue -Row $Row -Names @('Integration Method')
    $riskText = ($internetNeed + ' ' + $caution + ' ' + $method + ' ' + $what).ToLowerInvariant()
    $risk = if ($riskText -match 'paid api|driver|registry|delete|destructive|credential|token') { 'HIGH' } elseif ($riskText -match 'internet|api|sign.?in|cloud|account|subscription') { 'MEDIUM' } else { 'LOW' }
    $signIn = if (($internetNeed -match 'mostly local|offline|No paid API') -or ($useMode -match 'local|open-source|free')) { 'No sign-in needed' } elseif ($riskText -match 'cloud|account|sign.?in') { 'Sign-in required for cloud features' } else { 'Unknown' }
    $localOnly = if (($internetNeed -match 'mostly local|offline|No paid API') -or ($useMode -match 'local')) { $true } else { $false }
    $autoReady = if (($automation -match 'High|Semi|Auto') -or ($pattern -match 'Automate|Report|Process')) { 'Preview-ready' } else { 'Manual plan' }
    [pscustomobject]@{
        Id = (Get-GorIntegrationCsvValue -Row $Row -Names @('Combo ID','Option ID','Pair ID'))
        Size = $Source.Size
        Kind = $Source.Kind
        Apps = $apps
        AppKey = (@($apps | ForEach-Object { Normalize-GorIntegrationName $_ } | Sort-Object) -join '|')
        WorkflowName = if (-not [string]::IsNullOrWhiteSpace($category)) { $category } else { ($apps -join ' + ') }
        WhatCanDo = $what
        BestUse = Get-GorIntegrationCsvValue -Row $Row -Names @('Example Use Cases','Example Project Ideas','Desktop Use')
        Category = $category
        Pattern = $pattern
        FreeOpenSourceStatus = $useMode
        OpenSourceStatus = $openSource
        Difficulty = if ($difficulty) { $difficulty } else { 'Unknown' }
        RiskLevel = $risk
        AutomationReadiness = $autoReady
        AutomationSource = $automation
        SignInRequirement = $signIn
        LocalOnly = $localOnly
        CommandsAvailable = @('Preview Plan','Export Plan','Add to Favourites','Generate PowerShell Plan')
        SafeNextAction = 'Preview the PowerShell plan. No destructive action runs from this card.'
        ActionPlan = @(
            'Confirm the selected apps are installed or available locally.',
            'Open or launch apps only when the user chooses Launch Apps.',
            'Use file handoff, clipboard, or exported folders before any automation.',
            'Run only preview commands first; require confirmation for any system-changing action.'
        )
        SourceFile = Split-Path -Leaf $Source.Path
    }
}

function Get-GorShortcutTargetPath {
    param([AllowNull()][string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path) -or ([IO.Path]::GetExtension($Path) -ne '.lnk')) {
        return $Path
    }
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($Path)
        if ($shortcut -and -not [string]::IsNullOrWhiteSpace($shortcut.TargetPath)) {
            return $shortcut.TargetPath
        }
    }
    catch {
        return $Path
    }
    return $Path
}

function ConvertTo-GorIconFileName {
    param([Parameter(Mandatory=$true)][string]$Name)
    $safe = (Normalize-GorIntegrationName $Name) -replace '[^a-z0-9]+', '-'
    $safe = $safe.Trim('-')
    if ([string]::IsNullOrWhiteSpace($safe)) {
        $safe = 'app'
    }
    return ($safe + '.png')
}

function Get-GorIntegrationIconUrl {
    param(
        [Parameter(Mandatory=$true)][string]$AppName,
        [AllowNull()]$InventoryItem = $null
    )
    $paths = Get-GorPaths
    $fallback = 'gorrilla-launcher.ico'
    if ($null -eq $InventoryItem -or [string]::IsNullOrWhiteSpace($InventoryItem.Path)) {
        return $fallback
    }
    try {
        if (-not (Test-Path -LiteralPath $paths.IntegrationIcons)) {
            New-Item -ItemType Directory -Path $paths.IntegrationIcons -Force | Out-Null
        }
        $iconFile = Join-Path $paths.IntegrationIcons (ConvertTo-GorIconFileName -Name $AppName)
        if (Test-Path -LiteralPath $iconFile) {
            return ('integration-icons/' + (Split-Path -Leaf $iconFile))
        }
        $targetPath = Get-GorShortcutTargetPath -Path ([string]$InventoryItem.Path)
        if ([string]::IsNullOrWhiteSpace($targetPath) -or -not (Test-Path -LiteralPath $targetPath)) {
            return $fallback
        }
        if ([IO.Directory]::Exists($targetPath)) {
            return $fallback
        }
        $extension = [IO.Path]::GetExtension($targetPath)
        if ($extension -notin @('.exe','.dll','.ico')) {
            return $fallback
        }
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        if ($extension -eq '.ico') {
            Copy-Item -LiteralPath $targetPath -Destination $iconFile -ErrorAction Stop
            return ('integration-icons/' + (Split-Path -Leaf $iconFile))
        }
        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($targetPath)
        if ($null -eq $icon) {
            return $fallback
        }
        try {
            $bitmap = $icon.ToBitmap()
            $bitmap.Save($iconFile, [System.Drawing.Imaging.ImageFormat]::Png)
            return ('integration-icons/' + (Split-Path -Leaf $iconFile))
        }
        finally {
            if ($bitmap) { $bitmap.Dispose() }
            if ($icon) { $icon.Dispose() }
        }
    }
    catch {
        return $fallback
    }
}

function Get-GorIntegrationBuilderData {
    param(
        [int]$RowsPerDataset = 700,
        [switch]$Refresh
    )
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    if ((-not $Refresh) -and (Test-Path -LiteralPath $paths.IntegrationIndexJson)) {
        $cached = Get-GorJson -Path $paths.IntegrationIndexJson -Default $null
        if ($cached -and $cached.SchemaVersion -eq 1) {
            return $cached
        }
    }

    $sources = @(Get-GorIntegrationDatasetSources)
    $workflows = New-Object System.Collections.Generic.List[object]
    $appMeta = @{}
    $sourceIndex = 0
    foreach ($source in $sources) {
        $sourceIndex++
        if ($source.Status -ne 'READY') {
            continue
        }
        Write-Progress -Activity 'PowerShell Gorrilla integration brain' -Status ('Indexing ' + $source.Kind) -PercentComplete (($sourceIndex / [math]::Max(1,$sources.Count)) * 100)
        try {
            $lines = @(Get-Content -LiteralPath $source.Path -TotalCount ($RowsPerDataset + 1) -ErrorAction Stop)
            $rows = @($lines | ConvertFrom-Csv)
            $source.RowsSampled = $rows.Count
            foreach ($row in $rows) {
                $workflow = ConvertTo-GorIntegrationWorkflow -Row $row -Source $source
                if ($null -eq $workflow) {
                    continue
                }
                $workflows.Add($workflow)
                foreach ($app in $workflow.Apps) {
                    $key = Normalize-GorIntegrationName $app
                    if ([string]::IsNullOrWhiteSpace($key)) {
                        continue
                    }
                    if (-not $appMeta.ContainsKey($key)) {
                        $appMeta[$key] = [ordered]@{
                            Name = $app
                            Normalized = $key
                            WorkflowCount = 0
                            Categories = New-Object System.Collections.Generic.List[string]
                            FreeOpenSource = $false
                            LocalFriendly = $false
                        }
                    }
                    $appMeta[$key].WorkflowCount++
                    if (-not [string]::IsNullOrWhiteSpace($workflow.Category)) {
                        $appMeta[$key].Categories.Add($workflow.Category)
                    }
                    if (($workflow.FreeOpenSourceStatus -match 'open-source|free') -or ($workflow.OpenSourceStatus -match 'Yes|Both|[1-4]')) {
                        $appMeta[$key].FreeOpenSource = $true
                    }
                    if ($workflow.LocalOnly -or ($workflow.FreeOpenSourceStatus -match 'local')) {
                        $appMeta[$key].LocalFriendly = $true
                    }
                }
            }
        }
        catch {
            Add-GorSafetyNotice -Area 'Integration brain' -Message 'An integration CSV could not be indexed for the visual builder.' -Data ([pscustomobject]@{ Path=$source.Path; Error=$_.Exception.Message })
        }
    }
    Write-Progress -Activity 'PowerShell Gorrilla integration brain' -Completed

    $desktopInventory = @(Get-GorDesktopAppInventory -Quick | Where-Object { $_.Name -and $_.Name -notmatch '^(Uninstall|Uninstaller)|uninstall|remove' })
    $inventoryByName = @{}
    foreach ($item in $desktopInventory) {
        $key = Normalize-GorIntegrationName $item.Name
        if (-not [string]::IsNullOrWhiteSpace($key) -and -not $inventoryByName.ContainsKey($key)) {
            $inventoryByName[$key] = $item
        }
        if (-not [string]::IsNullOrWhiteSpace($key) -and -not $appMeta.ContainsKey($key)) {
            $appMeta[$key] = [ordered]@{
                Name = $item.Name
                Normalized = $key
                WorkflowCount = 0
                Categories = New-Object System.Collections.Generic.List[string]
                FreeOpenSource = $false
                LocalFriendly = $true
            }
        }
    }

    $apps = New-Object System.Collections.Generic.List[object]
    foreach ($key in ($appMeta.Keys | Sort-Object)) {
        $meta = $appMeta[$key]
        $inventory = $null
        if ($inventoryByName.ContainsKey($key)) {
            $inventory = $inventoryByName[$key]
        }
        $categories = @($meta.Categories | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique | Select-Object -First 3)
        $status = if ($inventory) {
            if ($inventory.Kind -eq 'LNK') { 'Shortcut only' } elseif ($inventory.Kind -eq 'FOLDER') { 'Installed' } else { 'Installed' }
        }
        else {
            'Missing'
        }
        $signin = if ($meta.LocalFriendly) { 'Local mode available' } elseif ($meta.FreeOpenSource) { 'No sign-in needed' } else { 'Unknown' }
        $apps.Add([pscustomobject]@{
            Name = $meta.Name
            Normalized = $meta.Normalized
            Category = if ($categories.Count -gt 0) { ($categories -join ', ') } elseif ($inventory) { $inventory.Category } else { 'Unknown' }
            LicenseMode = if ($meta.FreeOpenSource) { 'Free/open-source/free-tier' } elseif ($meta.LocalFriendly) { 'Local/free-tier likely' } else { 'Unknown' }
            Status = $status
            Installed = [bool]$inventory
            Kind = if ($inventory) { $inventory.Kind } else { 'Unknown' }
            Path = if ($inventory) { $inventory.Path } else { '' }
            Launchable = if ($inventory) { [bool]$inventory.Launchable } else { $false }
            LocalAvailability = if ($meta.LocalFriendly) { 'Local mode available' } else { 'Unknown' }
            SignInRequirement = $signin
            WorkflowCount = $meta.WorkflowCount
            IconUrl = Get-GorIntegrationIconUrl -AppName $meta.Name -InventoryItem $inventory
        })
    }

    $appsOut = @($apps | Sort-Object @{Expression='Installed';Descending=$true}, @{Expression='WorkflowCount';Descending=$true}, Name | Select-Object -First 420)
    $workflowsOut = @($workflows | Sort-Object @{Expression='RiskLevel';Ascending=$true}, @{Expression='LocalOnly';Descending=$true}, @{Expression='AutomationReadiness';Descending=$true} | Select-Object -First 1800)
    $validation = [pscustomobject]@{
        TwoApp = @($workflowsOut | Where-Object Size -eq 2 | Select-Object -First 1 -ExpandProperty Apps)
        ThreeApp = @($workflowsOut | Where-Object Size -eq 3 | Select-Object -First 1 -ExpandProperty Apps)
        FourApp = @($workflowsOut | Where-Object Size -eq 4 | Select-Object -First 1 -ExpandProperty Apps)
    }
    $data = [pscustomobject]@{
        SchemaVersion = 1
        GeneratedAt = Get-GorNow
        Sources = @(ConvertTo-GorArray $sources)
        Apps = @(ConvertTo-GorArray $appsOut)
        Workflows = @(ConvertTo-GorArray $workflowsOut)
        ValidationCombos = $validation
        Stats = [pscustomobject]@{
            AppCount = $appsOut.Count
            WorkflowCount = $workflowsOut.Count
            TwoAppWorkflows = @($workflowsOut | Where-Object Size -eq 2).Count
            ThreeAppWorkflows = @($workflowsOut | Where-Object Size -eq 3).Count
            FourAppWorkflows = @($workflowsOut | Where-Object Size -eq 4).Count
            IconCount = @(Get-ChildItem -LiteralPath $paths.IntegrationIcons -File -ErrorAction SilentlyContinue).Count
            FallbackIcon = 'gorrilla-launcher.ico'
            DestructiveActionsEnabled = $false
        }
        Safety = [pscustomobject]@{
            Mode = 'Read-only visual builder'
            InternetDownloads = $false
            ExecutesUnknownAppsForIcons = $false
            DangerousButtonsRunDirectly = $false
            Notes = 'The icon builder reads local metadata/icons only and generates preview/export plans. System-changing actions remain confirmation-gated through the command engine.'
        }
    }
    Write-GorJson -Path $paths.IntegrationIndexJson -Value $data
    return $data
}

function Get-GorVisualAppData {
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $status = Get-GorStatusObject
    $fire = Get-GorFireDeskStatus
    $state = Test-GorDesiredState
    $alerts = Get-GorAlerts
    $options = Get-GorOptions -Alerts $alerts
    $models = Get-GorOllamaModels
    $tools = Get-GorToolRows
    $elite = Get-GorEliteStackRows -Quick
    $eliteIssues = Get-GorEliteStackIssues -Rows $elite
    $launchCatalog = Get-GorLaunchCatalog
    $integrationMap = Get-GorIntegrationMap -EliteRows $elite
    $integrationBuilder = Get-GorIntegrationBuilderData
    $fixQueue = Get-GorFixQueue -EliteIssues $eliteIssues
    $workflows = Get-GorWorkflowCatalog
    $updatePlan = Get-GorUpdatePlan
    $promptFiles = @(
        [pscustomobject]@{ Name='Intent Router'; Path=$paths.IntentPrompt; Purpose='Turns natural language into safe Gorilla command suggestions.' },
        [pscustomobject]@{ Name='Safety Policy'; Path=$paths.SafetyPrompt; Purpose='Documents local-first execution rules and confirmation boundaries.' }
    )
    $reports = foreach ($file in @(Get-ChildItem -LiteralPath $paths.Reports -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 30)) {
        [pscustomobject]@{ Name=$file.Name; Path=$file.FullName; SizeKB=[math]::Round($file.Length / 1KB, 1); LastWriteTime=$file.LastWriteTime.ToString('yyyy-MM-dd HH:mm') }
    }
    $tests = foreach ($file in @(Get-ChildItem -LiteralPath $paths.TestLab -File -Filter '*.json' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 12)) {
        [pscustomobject]@{ Name=$file.Name; Path=$file.FullName; LastWriteTime=$file.LastWriteTime.ToString('yyyy-MM-dd HH:mm') }
    }
    $profiles = foreach ($file in @(Get-ChildItem -LiteralPath $paths.Profiles -File -Filter '*.json' -ErrorAction SilentlyContinue | Sort-Object Name)) {
        $profile = Read-GorJson -Path $file.FullName -Default $null
        if ($profile) {
            [pscustomobject]@{ Name=$profile.Name; Path=$profile.Path; AppType=$profile.AppType; Ports=$profile.Ports; File=$file.FullName }
        }
    }
    $black = foreach ($dir in @(Get-ChildItem -LiteralPath $paths.BlackBox -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 12)) {
        [pscustomobject]@{ Name=$dir.Name; Path=$dir.FullName; LastWriteTime=$dir.LastWriteTime.ToString('yyyy-MM-dd HH:mm') }
    }
    $ledger = @(Get-Content -LiteralPath $paths.LedgerJsonl -Tail 20 -ErrorAction SilentlyContinue)
    $actions = @(
        [pscustomobject]@{ Title='Full Reliability Test'; Command='gortest all'; Risk='LOW'; Area='Test Lab'; Detail='Runs module, FireDesk, repair and report smoke checks.' },
        [pscustomobject]@{ Title='Advisor Scan'; Command='goradvisor'; Risk='LOW'; Area='Advisor'; Detail='Finds what is not working and refreshes recommended options.' },
        [pscustomobject]@{ Title='Show Alerts'; Command='goralerts'; Risk='LOW'; Area='Advisor'; Detail='Shows current alerts in plain English.' },
        [pscustomobject]@{ Title='Show Fix Options'; Command='goroptions'; Risk='LOW'; Area='Advisor'; Detail='Shows safe next-step choices for current alerts.' },
        [pscustomobject]@{ Title='Open Visual App'; Command='gorvisual'; Risk='LOW'; Area='Visual'; Detail='Regenerates and opens this dashboard.' },
        [pscustomobject]@{ Title='Elite Stack Status'; Command='gorelite'; Risk='LOW'; Area='Elite Stack'; Detail='Shows the full installed PowerShell, web, AI, security and deploy cockpit.' },
        [pscustomobject]@{ Title='Elite Stack Repair'; Command='gorelite-fix'; Risk='MEDIUM'; Area='Elite Stack'; Detail='Repairs safe user-level integration gaps such as missing pnpm in the current shell.' },
        [pscustomobject]@{ Title='Elite Stack Report'; Command='gorelite-report'; Risk='LOW'; Area='Elite Stack'; Detail='Writes an HTML report of all elite stack tools and issues.' },
        [pscustomobject]@{ Title='Do Everything Now'; Command='gordo now'; Risk='LOW'; Area='Everything'; Detail='Runs status, stack issues and advisor in one command.' },
        [pscustomobject]@{ Title='Boost This Machine'; Command='gordo boost'; Risk='MEDIUM'; Area='Everything'; Detail='Runs safe repairs, baseline reports and opens the visual dashboard.' },
        [pscustomobject]@{ Title='Full Evidence Pass'; Command='gordo full'; Risk='MEDIUM'; Area='Everything'; Detail='Runs tests, reports, stack evidence and dashboard refresh.' },
        [pscustomobject]@{ Title='AI Lab'; Command='gordo ai'; Risk='LOW'; Area='Everything'; Detail='Starts/checks local Ollama and Docker readiness.' },
        [pscustomobject]@{ Title='Integration Map'; Command='gorintegrate'; Risk='LOW'; Area='Integration'; Detail='Shows how your installed apps are wired into safe workflows.' },
        [pscustomobject]@{ Title='Fix Queue'; Command='gorfixqueue'; Risk='LOW'; Area='Integration'; Detail='Shows prioritized fixes without applying them.' },
        [pscustomobject]@{ Title='Connector Passport'; Command='gorconnectors'; Risk='LOW'; Area='Integration'; Detail='Shows each app connector truth status: installed, launchable, local-ready, or needing visible sign-in confirmation.' },
        [pscustomobject]@{ Title='Scan Desktop Apps'; Command='gordesktopapps'; Risk='LOW'; Area='Discovery'; Detail='Scans Desktop, Start Menu, and Program Files so Gorilla knows what local apps are available.' },
        [pscustomobject]@{ Title='Package Bank'; Command='gorpackagebank'; Risk='LOW'; Area='Package Bank'; Detail='Shows 100+ curated install options and labels what is already installed, manager-ready, or missing on this laptop.' },
        [pscustomobject]@{ Title='Book Factory'; Command='gorbook "My Book"'; Risk='LOW'; Area='Workflow Packs'; Detail='Creates the flagship multi-app book plan across local AI, Word, Canva, Adobe, and Gorilla evidence.' },
        [pscustomobject]@{ Title='One Solid Backup Preview'; Command='gorkeeponebackup preview'; Risk='LOW'; Area='Cleanliness'; Detail='Previews older generated backups and test book packs that can be removed while keeping the newest solid copy.' },
        [pscustomobject]@{ Title='Prompt Library'; Command='gorprompt list'; Risk='LOW'; Area='Understanding'; Detail='Shows the local prompt files that teach Gorilla how to route requests safely.' },
        [pscustomobject]@{ Title='Understand Request'; Command='gorunderstand fix my machine'; Risk='LOW'; Area='Understanding'; Detail='Uses rules and Ollama when available to suggest safe commands without executing repairs.' },
        [pscustomobject]@{ Title='Workflow Catalog'; Command='gorworkflow list'; Risk='LOW'; Area='Workflows'; Detail='Shows reusable daily, boost, AI, security, API and update workflows.' },
        [pscustomobject]@{ Title='Discover installed apps'; Command='gorappdiscover'; Risk='LOW'; Area='Discovery'; Detail='Scans known Windows start menu and desktop launchers on your laptop.' },
        [pscustomobject]@{ Title='Laptop-wide assessment'; Command='gorlaptopscan'; Risk='LOW'; Area='Assessment'; Detail='Runs full laptop security and performance review tasks.' },
        [pscustomobject]@{ Title='Update Preview'; Command='gorupdate preview'; Risk='LOW'; Area='Update Center'; Detail='Shows what an app/module update would do before anything is applied.' },
        [pscustomobject]@{ Title='Launch VS Code'; Command='gorlaunch code'; Risk='LOW'; Area='Launch'; Detail='Opens VS Code through the Gorilla launch catalog.' },
        [pscustomobject]@{ Title='Launch Bruno'; Command='gorlaunch bruno'; Risk='LOW'; Area='Launch'; Detail='Opens Bruno for API work.' },
        [pscustomobject]@{ Title='Launch Figma'; Command='gorlaunch figma'; Risk='LOW'; Area='Launch'; Detail='Opens Figma for design work.' },
        [pscustomobject]@{ Title='FireDesk Status'; Command='gorfiredesk'; Risk='LOW'; Area='FireDesk'; Detail='Checks files, port 5000, local HTTP, binding risks and compile status.' },
        [pscustomobject]@{ Title='FireDesk Report'; Command='gorfiredeskreport'; Risk='LOW'; Area='FireDesk'; Detail='Builds a clean HTML report for FireDesk.' },
        [pscustomobject]@{ Title='Desired State Check'; Command='gorstate check'; Risk='LOW'; Area='State'; Detail='Compares your machine to the Gorrilla desired state.' },
        [pscustomobject]@{ Title='Project Doctor'; Command='gordoctor FireDesk'; Risk='LOW'; Area='Doctor'; Detail='Inspects files, risks, dependency state and performance notes.' },
        [pscustomobject]@{ Title='Quality Score'; Command='gorquality FireDesk'; Risk='LOW'; Area='Quality'; Detail='Scores the app against professional reliability signals.' },
        [pscustomobject]@{ Title='Security Review'; Command='gorsecurity FireDesk'; Risk='LOW'; Area='Security'; Detail='Reviews ports, bind addresses, debug mode and secret-like strings.' },
        [pscustomobject]@{ Title='Performance Lab'; Command='gorperf app FireDesk'; Risk='LOW'; Area='Performance'; Detail='Measures local load, folder weight and large files.' },
        [pscustomobject]@{ Title='Patch Plan'; Command='gorpatchplan FireDesk'; Risk='LOW'; Area='Patch Studio'; Detail='Creates a patch plan. It does not apply changes.' },
        [pscustomobject]@{ Title='Tidy Desktop Preview'; Command='gordesktop tidy'; Risk='LOW'; Area='Desktop'; Detail='Shows a safe organisation plan for loose desktop items.' },
        [pscustomobject]@{ Title='Backup Module'; Command='gorbackup-module'; Risk='LOW'; Area='Rescue'; Detail='Backs up the current Gorrilla module before upgrades.' },
        [pscustomobject]@{ Title='Rescue Console'; Command='gorrescue'; Risk='LOW'; Area='Rescue'; Detail='Creates an emergency no-profile launcher.' },
        [pscustomobject]@{ Title='Bind Local Fix'; Command='gorbindlocal FireDesk'; Risk='MEDIUM'; Area='Safety'; Detail='Requires typed confirmation and backup before changing 0.0.0.0.' },
        [pscustomobject]@{ Title='Stop Port 5000 Owner'; Command='gorkill5000'; Risk='HIGH'; Area='Safety'; Detail='Requires typed confirmation before stopping any process.' }
    )
    $installedApps = @(Get-GorQuickInstalledApps | Where-Object { $_.Name -notmatch '^(Uninstall|Uninstaller)|uninstall|remove' })
    $desktopInventory = @(Get-GorDesktopAppInventory -Quick | Where-Object { $_.Name -notmatch '^(Uninstall|Uninstaller)|uninstall|remove' })
    $packageBank = @(Get-GorPackageBank -First 160)
    $packageSummary = [pscustomobject]@{
        Total = $packageBank.Count
        Installed = @($packageBank | Where-Object InstalledHint).Count
        ManagerReady = @($packageBank | Where-Object { $_.WorksHere -eq 'MANAGER_READY' }).Count
        NeedsManager = @($packageBank | Where-Object { $_.WorksHere -eq 'NEEDS_MANAGER' }).Count
        Managers = @($packageBank | Select-Object -ExpandProperty Manager -Unique)
    }
    $designApps = @($installedApps | Where-Object { $_.Name -match 'Canva|Figma|GIMP|Krita|Inkscape|Blender|OBS|ShareX|Paint|Photo' } | Select-Object -First 40)
    $promptMatrix = Get-GorPromptMatrix
    $laptopContext = Get-GorQuickLaptopContext
    $creativePipelines = Get-GorCreativePipelines -DesignApps $designApps
    $connectors = @(Get-GorConnectorStatus)
    $productVision = Get-GorProductVision
    $workflowPacks = @(Get-GorWorldClassWorkflowPacks)
    $backupPosture = Get-GorBackupPosture
    $hugeCheck = [pscustomobject]@{
        Status = if ($creativePipelines.Count -gt 0 -and $designApps.Count -ge 2 -and $status.ParserOk -and (@($connectors | Where-Object Status -eq 'READY').Count -ge 2)) { 'READY' } else { 'NEEDS_ATTENTION' }
        Score = if ($creativePipelines.Count -gt 0 -and $designApps.Count -ge 2 -and $status.ParserOk -and (@($connectors | Where-Object Status -eq 'READY').Count -ge 2)) { 92 } else { 68 }
        InstalledApps = $installedApps.Count
        DesignApps = $designApps.Count
        Pipelines = $creativePipelines.Count
        PromptMatrix = $promptMatrix.Count
        ConnectorsReady = @($connectors | Where-Object Status -eq 'READY').Count
        Path = ''
    }
    [pscustomobject]@{
        GeneratedAt = Get-GorNow
        Paths = [pscustomobject]@{
            Root = $paths.Root
            ModuleRoot = $paths.ModuleRoot
            Dashboard = $paths.Dashboard
            Reports = $paths.Reports
            Commands = $paths.CommandsMd
        }
        Status = $status
        FireDesk = [pscustomobject]@{
            Path = $fire.Path
            Exists = $fire.Exists
            Files = @($fire.Files)
            Port5000 = @($fire.Port5000)
            LocalHttp = $fire.LocalHttp
            BindingRisks = @($fire.BindingRisks)
            PythonCompile = $fire.PythonCompile
        }
        State = @(ConvertTo-GorArray $state)
        Alerts = @(ConvertTo-GorArray $alerts)
        Options = @(ConvertTo-GorArray $options)
        Models = @(ConvertTo-GorArray $models)
        Tools = @(ConvertTo-GorArray $tools)
        EliteStack = @(ConvertTo-GorArray $elite)
        EliteIssues = @(ConvertTo-GorArray $eliteIssues)
        LaunchCatalog = @(ConvertTo-GorArray $launchCatalog)
        InstalledApps = @(ConvertTo-GorArray $installedApps)
        DesktopApps = @(ConvertTo-GorArray $desktopInventory)
        PackageBank = @(ConvertTo-GorArray $packageBank)
        PackageSummary = $packageSummary
        DesignApps = @(ConvertTo-GorArray $designApps)
        ProductVision = $productVision
        Connectors = @(ConvertTo-GorArray $connectors)
        WorkflowPacks = @(ConvertTo-GorArray $workflowPacks)
        BackupPosture = $backupPosture
        CreativePipelines = @(ConvertTo-GorArray $creativePipelines)
        HugeCheck = $hugeCheck
        PromptMatrix = $promptMatrix
        LaptopContext = $laptopContext
        IntegrationMap = @(ConvertTo-GorArray $integrationMap)
        IntegrationBuilder = $integrationBuilder
        FixQueue = @(ConvertTo-GorArray $fixQueue)
        Workflows = @(ConvertTo-GorArray $workflows)
        PromptFiles = @(ConvertTo-GorArray $promptFiles)
        UpdatePlan = $updatePlan
        Profiles = @(ConvertTo-GorArray $profiles)
        Reports = @(ConvertTo-GorArray $reports)
        Tests = @(ConvertTo-GorArray $tests)
        BlackBox = @(ConvertTo-GorArray $black)
        Ledger = $ledger
        Commands = @(Get-GorCommandCatalog)
        Actions = $actions
        AppShell = [pscustomobject]@{
            Modes = @(
                [pscustomobject]@{ Name='Operate'; Detail='Daily status, safe fixes, workflows, and launch actions.' },
                [pscustomobject]@{ Name='Build'; Detail='Web app creation, project doctor, quality, and Playwright readiness.' },
                [pscustomobject]@{ Name='Secure'; Detail='Security review, fix queue, bind checks, and evidence reports.' },
                [pscustomobject]@{ Name='Update'; Detail='Version preview, backup, apply, and rollback posture.' }
            )
            StarterPrompts = @(
                'fix my machine safely',
                'show me what needs attention',
                'start the local AI lab',
                'create a new web app',
                'scan this app for security',
                'preview the next update',
                'open design tools',
                'map how my apps work together',
                'scan desktop apps',
                'open the package bank',
                'create a book with Word Canva and Adobe',
                'check which apps are signed in',
                'keep one solid backup and remove old test packs'
            )
        }
    }
}

function New-GorDashboard {
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $moduleAssets = Join-Path (Get-GorModuleRoot) 'assets'
    foreach ($assetName in @('gorrilla-launcher.ico')) {
        $sourceAsset = Join-Path $moduleAssets $assetName
        if (Test-Path -LiteralPath $sourceAsset) {
            Copy-Item -LiteralPath $sourceAsset -Destination (Join-Path $paths.Dashboard $assetName) -Force -ErrorAction SilentlyContinue
            Copy-Item -LiteralPath $sourceAsset -Destination (Join-Path $paths.Assets $assetName) -Force -ErrorAction SilentlyContinue
        }
    }
    $data = Get-GorVisualAppData
    $dataPath = Join-Path $paths.Dashboard 'gorrilla-data.json'
    Write-GorJson -Path $dataPath -Value $data
    $json = (ConvertTo-GorJson -Value $data).Replace('</', '<\/')
    $path = Join-Path $paths.Dashboard 'index.html'
    $html = @'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PowerShell Gorrilla Visual Control Center</title>
<style>
:root{color-scheme:light;--bg:#eef3f7;--surface:#ffffff;--panel:#f7fbff;--panel2:#edf4fb;--line:#d7e3ee;--text:#112b42;--muted:#5c7084;--green:#1f8d55;--amber:#bb7a1c;--red:#a83232;--blue:#2a59d6;--violet:#7452d8;--ink:#102038;--shadow:0 24px 80px rgba(16,38,56,.12)}
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:radial-gradient(circle at top left, rgba(42,89,214,.18), transparent 28%), radial-gradient(circle at bottom right, rgba(31,141,85,.12), transparent 25%), var(--bg);color:var(--text);font-family:Inter,Segoe UI,system-ui,sans-serif;line-height:1.5}button,input{font:inherit}
.shell{display:grid;grid-template-columns:280px minmax(0,1fr);min-height:100vh}.side{position:sticky;top:0;height:100vh;background:rgba(255,255,255,.92);border-right:1px solid var(--line);padding:26px;overflow:auto;backdrop-filter:blur(20px)}.brand{display:flex;gap:14px;align-items:center;margin-bottom:24px}.mark{width:42px;height:42px;border-radius:14px;background:linear-gradient(135deg,var(--blue),var(--green));display:grid;place-items:center;color:#fff;font-weight:900;font-size:18px}.brand h1{font-size:18px;margin:0;color:var(--ink)}.brand p{margin:4px 0 0;color:var(--muted);font-size:13px}.nav a{display:flex;justify-content:space-between;align-items:center;color:var(--ink);text-decoration:none;padding:10px 12px;border-radius:14px;margin:6px 0;border:1px solid transparent}.nav a:hover{background:var(--panel2);border-color:var(--line)}.main{padding:28px;max-width:1520px}.hero{display:grid;grid-template-columns:minmax(0,1.4fr) minmax(320px,.6fr);gap:24px;align-items:stretch;margin-bottom:24px}.heroPanel{background:rgba(255,255,255,.96);border:1px solid var(--line);border-radius:26px;padding:28px;box-shadow:var(--shadow)}.hero h2{font-size:38px;line-height:1.05;margin:0 0 14px;color:var(--ink)}.hero p{color:var(--muted);max-width:760px;margin:0}.appbar{position:sticky;top:0;z-index:10;background:rgba(255,255,255,.92);border:1px solid var(--line);border-radius:20px;padding:20px;margin:0 0 24px;backdrop-filter:blur(22px)}.intent{display:grid;grid-template-columns:minmax(0,1fr) auto;gap:14px}.intent input,.select{width:100%;background:var(--surface);border:1px solid var(--line);border-radius:16px;color:var(--ink);padding:14px}.modebar{display:flex;gap:10px;flex-wrap:wrap;margin-top:14px}.mode{border:1px solid var(--line);background:var(--surface);color:var(--ink);border-radius:14px;padding:10px 14px;cursor:pointer}.mode.active{border-color:var(--blue);color:var(--blue)}.plan{display:grid;grid-template-columns:1fr 1fr;gap:18px;margin-top:16px}.planStep{border:1px solid var(--line);border-radius:20px;background:var(--panel2);padding:18px}.statusGrid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:18px;margin-top:22px}.metric,.panel{background:var(--surface);border:1px solid var(--line);border-radius:22px;padding:20px}.metric b{display:block;font-size:28px}.metric span,.sub{color:var(--muted);font-size:13px}.toolbar{display:flex;gap:14px;flex-wrap:wrap;margin-top:18px}.btn{border:1px solid var(--line);border-radius:16px;background:var(--surface);color:var(--ink);padding:12px 16px;cursor:pointer;text-decoration:none;display:inline-flex;align-items:center;gap:10px}.btn:hover{border-color:var(--blue)}.btn.primary{background:var(--blue);color:#fff;border-color:var(--blue);font-weight:700}.btn.warn{background:rgba(187,122,28,.14);border-color:rgba(187,122,28,.35);color:var(--ink)}.section{margin:28px 0}.section h3{font-size:21px;margin:0 0 14px;color:var(--ink)}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:18px}.card{background:var(--panel2);border:1px solid var(--line);border-radius:22px;padding:20px;min-height:150px;box-shadow:0 18px 45px rgba(16,38,56,.06)}.card h4{font-size:17px;margin:0 0 10px;color:var(--ink)}.card p{color:var(--muted);margin:0 0 14px;font-size:14px}.pill{display:inline-flex;align-items:center;border:1px solid var(--line);border-radius:999px;padding:4px 10px;font-size:12px;color:var(--muted);margin:3px 5px 3px 0}.ok{color:var(--green)}.warnText{color:var(--amber)}.bad{color:var(--red)}.blue{color:var(--blue)}.risk-LOW{border-color:rgba(31,141,85,.25)}.risk-MEDIUM{border-color:rgba(187,122,28,.30)}.risk-HIGH{border-color:rgba(168,50,50,.30)}.tableWrap{overflow:auto;border:1px solid var(--line);border-radius:20px;background:var(--surface)}table{width:100%;border-collapse:collapse;font-size:14px}th,td{padding:13px;border-bottom:1px solid var(--line);text-align:left;vertical-align:top}th{color:var(--ink);background:var(--panel2);font-size:11px;text-transform:uppercase}.search{width:100%;background:var(--surface);border:1px solid var(--line);border-radius:16px;color:var(--ink);padding:14px;margin-bottom:14px}.cmd{font-family:Cascadia Code,Consolas,monospace;background:var(--bg);border:1px solid var(--line);border-radius:16px;padding:14px;white-space:nowrap;overflow:auto}.split{display:grid;grid-template-columns:1fr 1fr;gap:18px}.toast{position:fixed;right:20px;bottom:20px;background:#102038;border:1px solid rgba(42,89,214,.25);padding:14px 16px;border-radius:18px;display:none}.hide{display:none!important}@media(max-width:980px){.shell{grid-template-columns:1fr}.side{position:relative;height:auto}.hero,.split,.plan{grid-template-columns:1fr}.statusGrid{grid-template-columns:repeat(2,minmax(0,1fr))}.intent{grid-template-columns:1fr}}@media(max-width:560px){.main{padding:20px}.hero h2{font-size:30px}.statusGrid{grid-template-columns:1fr}}
.heroLogo{display:flex;align-items:center;gap:16px;margin-bottom:20px}.heroLogo img{width:86px;height:86px;border-radius:22px;object-fit:cover;border:1px solid var(--line);box-shadow:var(--shadow)}.heroLogo strong{display:block;font-size:22px}.heroLogo span{display:block;color:var(--muted);font-size:13px;margin-top:3px}.requestPanel{margin-top:24px;padding:16px;border:1px solid var(--line);border-radius:18px;background:rgba(255,255,255,.80)}.requestPanel label{display:block;color:var(--blue);font-weight:700;font-size:12px;text-transform:uppercase;letter-spacing:.1em;margin-bottom:8px}.requestHint{color:var(--muted);font-size:12px;margin:8px 0 0}.requestAnswer{margin-top:10px;border:1px solid var(--line);border-radius:16px;padding:14px;background:var(--panel);color:var(--ink);font-size:14px;white-space:pre-wrap}.requestAnswer:empty{display:none}
.brandMark{width:58px;height:58px;border-radius:16px;border:1px solid var(--line2);background:linear-gradient(135deg,#6ee7b7,#8ab8ff 58%,#f4c76b);color:#06100e;display:grid;place-items:center;font-weight:900;box-shadow:var(--shadow)}.brandMark.large{width:64px;height:64px;min-width:64px;border-radius:18px;font-size:24px}.commandPanel{background:linear-gradient(180deg,#111a18,#0b100f);border:1px solid var(--line);border-radius:18px;padding:18px;display:grid;grid-template-rows:auto 1fr auto;gap:16px;box-shadow:var(--shadow);overflow:hidden}.signalGrid{display:grid;grid-template-columns:1fr 1fr;gap:10px;align-content:start}.signalTile{border:1px solid var(--line);border-radius:14px;background:#0d1513;padding:12px;min-height:90px}.signalTile span{display:block;color:var(--muted);font-size:11px;text-transform:uppercase;letter-spacing:.08em}.signalTile b{display:block;font-size:24px;margin-top:5px}.signalTile p{margin:5px 0 0;color:#bdcac5;font-size:12px}.commandDiagram{border:1px solid var(--line2);border-radius:16px;background:linear-gradient(135deg,#0c1412,#101a1d);padding:16px;display:grid;gap:10px}.flowRow{display:grid;grid-template-columns:34px 1fr;gap:10px;align-items:center}.flowDot{width:34px;height:34px;border-radius:11px;display:grid;place-items:center;background:#172620;color:var(--green);border:1px solid var(--line2);font-weight:800}.flowRow h4{margin:0;font-size:14px}.flowRow p{margin:2px 0 0;color:var(--muted);font-size:12px}.heroLogo{display:flex;align-items:center;gap:16px;margin-bottom:20px}
</style>
</head>
<body>
<script id="gor-data" type="application/json">__GOR_DATA__</script>
<div class="shell">
<aside class="side">
  <div class="brand"><div class="mark">G</div><div><h1>Gorrilla Control</h1><p>Local AI reliability platform</p></div></div>
  <nav class="nav">
    <a href="#mission">Mission <span>01</span></a>
    <a href="#advisor">Advisor <span>02</span></a>
    <a href="#integration">Integration <span>03</span></a>
    <a href="#workflows">Workflows <span>04</span></a>
    <a href="#understanding">Understanding <span>05</span></a>
    <a href="#update">Updates <span>06</span></a>
    <a href="#actions">Actions <span>07</span></a>
    <a href="#firedesk">FireDesk <span>08</span></a>
    <a href="#models">Models <span>09</span></a>
    <a href="#tools">Tools <span>10</span></a>
    <a href="#commands">Commands <span>11</span></a>
    <a href="#evidence">Evidence <span>12</span></a>
  </nav>
</aside>
<main class="main">
  <section class="appbar" id="control">
    <div class="intent">
      <input id="missionInput" placeholder="Tell Gorrilla what you want: fix safely, build an app, scan security, update, launch tools...">
      <button class="btn primary" id="planButton">Plan</button>
    </div>
    <div class="modebar" id="modeBar"></div>
    <div class="toolbar" id="starterPrompts"></div>
    <div class="plan" id="planPanel"></div>
  </section>
  <section id="mission" class="hero">
    <div class="heroPanel">
      <span class="pill">Generated <span id="generated"></span></span>
      <span class="pill">Local only</span>
      <span class="pill">127.0.0.1 first</span>
      <h2>PowerShell Gorrilla Visual Control Center</h2>
      <p>A professional local cockpit for testing, repairing, securing, profiling, packaging and improving your apps without living in the terminal.</p>
      <div class="toolbar">
        <button class="btn primary" data-action="gordo now">Quick status</button>
        <button class="btn" data-action="gorintegrate">Map integrations</button>
        <button class="btn" data-action="gorworkflow list">Workflows</button>
        <button class="btn" data-action="gorupdate preview">Update preview</button>
        <button class="btn" data-action="gorfixqueue">Fix queue</button>
        <button class="btn warn" data-action="gordo boost">Safe boost</button>
      </div>
    </div>
    <div class="panel">
      <h3>System Signal</h3>
      <div id="systemSignal"></div>
    </div>
  </section>
  <div class="statusGrid" id="metrics"></div>
  <section class="section"><h3>Live Task Runner</h3><div class="panel"><div id="taskStatus" class="sub">No task running.</div><div style="height:12px;background:#0a0d11;border:1px solid var(--line);border-radius:999px;overflow:hidden;margin:10px 0"><div id="taskBar" style="height:100%;width:0;background:linear-gradient(90deg,var(--green),var(--blue));transition:width .35s"></div></div><pre id="taskOutput" class="cmd">Select a task button to run a whitelisted PowerShell action.</pre></div></section>
  <section id="advisor" class="section split"><div class="panel"><h3>Needs Attention</h3><div id="alertsPanel"></div></div><div class="panel"><h3>Options</h3><div id="optionsPanel"></div></div></section>
  <section id="integration" class="section split"><div class="panel"><h3>App Integration Map</h3><div id="integrationPanel"></div></div><div class="panel"><h3>Safe Fix Queue</h3><div id="fixQueuePanel"></div></div></section>
  <section id="workflows" class="section"><h3>Workflow Catalog</h3><div id="workflowsPanel"></div></section>
  <section id="understanding" class="section split"><div class="panel"><h3>Prompt Library</h3><div id="promptsPanel"></div></div><div class="panel"><h3>Request Understanding</h3><div id="understandingPanel"></div></div></section>
  <section id="update" class="section"><h3>Update Center</h3><div id="updatePanel"></div></section>
  <section class="section"><h3>Launch Catalog</h3><div id="launchPanel"></div></section>
  <section id="actions" class="section"><h3>Mission Actions</h3><div class="grid" id="actionsGrid"></div></section>
  <section id="firedesk" class="section split"><div class="panel"><h3>FireDesk Readiness</h3><div id="fireDeskPanel"></div></div><div class="panel"><h3>Desired State</h3><div id="statePanel"></div></div></section>
  <section id="models" class="section split"><div class="panel"><h3>Local AI Models</h3><div id="modelsPanel"></div></div><div class="panel"><h3>App Profiles</h3><div id="profilesPanel"></div></div></section>
  <section id="tools" class="section"><h3>Tool Manager</h3><div id="toolsPanel"></div></section>
  <section id="commands" class="section"><h3>Command Palette</h3><input id="commandSearch" class="search" placeholder="Search commands, risks, categories..."><div id="commandsPanel"></div></section>
  <section id="evidence" class="section split"><div class="panel"><h3>Reports</h3><div id="reportsPanel"></div></div><div class="panel"><h3>Test Lab / Ledger</h3><div id="evidencePanel"></div></div></section>
</main>
</div>
<div class="toast" id="toast">Copied command</div>
<script>
const data = JSON.parse(document.getElementById('gor-data').textContent);
const esc = value => String(value ?? '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
const byId = id => document.getElementById(id);
const pill = (text, cls='') => `<span class="pill ${cls}">${esc(text)}</span>`;
const cmd = c => `<div class="cmd">${esc(c)}</div>`;
let currentMode = 'Operate';
function statusClass(value){ const v=String(value||'').toUpperCase(); if(v.includes('FAILED')||v.includes('HIGH')) return 'bad'; if(v.includes('WARN')||v.includes('MEDIUM')||v.includes('TIMEOUT')) return 'warnText'; return 'ok'; }
function rows(items, cols){ const arr=Array.isArray(items)?items:[]; if(!arr.length) return '<p class="sub">No data yet.</p>'; return `<div class="tableWrap"><table><thead><tr>${cols.map(c=>`<th>${esc(c.label)}</th>`).join('')}</tr></thead><tbody>${arr.map(item=>`<tr>${cols.map(c=>`<td>${esc(typeof c.value==='function'?c.value(item):item[c.value])}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`; }
function copyCommand(command){ navigator.clipboard?.writeText(command); const t=byId('toast'); t.textContent='Copied: '+command; t.style.display='block'; setTimeout(()=>t.style.display='none',1600); }
document.addEventListener('click', e => { const el=e.target.closest('[data-copy]'); if(el) copyCommand(el.dataset.copy); const action=e.target.closest('[data-action]'); if(action) runAction(action.dataset.action); });
function matchAction(text){
  const q = String(text||'').toLowerCase();
  const actions = data.Actions || [];
  const score = a => {
    const hay = `${a.Title} ${a.Command} ${a.Area} ${a.Detail}`.toLowerCase();
    let s = 0;
    q.split(/\s+/).filter(Boolean).forEach(w => { if(hay.includes(w)) s += 2; });
    if(q.match(/fix|repair|broken|problem|attention/)&&a.Command==='gorfixqueue') s += 10;
    if(q.match(/status|now|today|check/)&&a.Command==='gordo now') s += 10;
    if(q.match(/ai|ollama|model/)&&a.Command==='gordo ai') s += 10;
    if(q.match(/web|next|site|build|create/)&&a.Command==='gorworkflow list') s += 8;
    if(q.match(/security|scan|secret|vulner/)&&a.Command==='gorsecurity FireDesk') s += 8;
    if(q.match(/update|upgrade|rollback|version/)&&a.Command==='gorupdate preview') s += 10;
    if(q.match(/design|figma|canva/)&&a.Command==='gorlaunch figma') s += 10;
    if(q.match(/api|postman|bruno|database|db/)&&a.Command==='gorlaunch bruno') s += 10;
    if(q.match(/together|integrat|workflow/)&&a.Command==='gorintegrate') s += 10;
    return s;
  };
  return actions.map(a=>({...a,Score:score(a)})).filter(a=>a.Score>0).sort((a,b)=>b.Score-a.Score).slice(0,4);
}
function renderPlan(text){
  const query = text || byId('missionInput').value || currentMode;
  const suggestions = matchAction(query);
  const list = suggestions.length ? suggestions : (data.Actions||[]).filter(a=>['gordo now','goradvisor','gorworkflow list','gorupdate preview'].includes(a.Command));
  byId('planPanel').innerHTML = list.map((a,i)=>`<div class="planStep risk-${esc(a.Risk)}"><span class="pill">Step ${i+1}</span>${pill(a.Risk,statusClass(a.Risk))}<h4>${esc(a.Title)}</h4><p class="sub">${esc(a.Detail)}</p>${cmd(a.Command)}<div class="toolbar"><button class="btn primary" data-action="${esc(a.Command)}">Run</button><button class="btn" data-copy="${esc(a.Command)}">Copy</button></div></div>`).join('');
}
function setMode(name){
  currentMode = name;
  document.querySelectorAll('.mode').forEach(x=>x.classList.toggle('active',x.dataset.mode===name));
  const mode = (data.AppShell?.Modes||[]).find(m=>m.Name===name);
  byId('missionInput').value = mode ? mode.Detail : name;
  renderPlan(byId('missionInput').value);
}
async function runAction(command){
  const action = (data.Actions||[]).find(x => x.Command === command) || {Risk:'LOW'};
  let confirmText = '';
  if(action.Risk === 'MEDIUM') confirmText = prompt('This action needs typed confirmation. Type BINDLOCALGORRILLA or TIDYGORRILLA if requested by the action.');
  if(action.Risk === 'HIGH') confirmText = prompt('High risk action. Type KILL5000 to continue.');
  byId('taskStatus').textContent = 'Starting: '+command;
  byId('taskBar').style.width = '4%';
  byId('taskOutput').textContent = '';
  const res = await fetch('/api/run',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({command,confirm:confirmText||''})});
  const start = await res.json();
  if(!res.ok){ byId('taskStatus').textContent = start.Error || 'Action blocked'; byId('taskOutput').textContent = JSON.stringify(start,null,2); return; }
  pollTask(start.Id);
}
async function pollTask(id){
  const res = await fetch('/api/task?id='+encodeURIComponent(id));
  const task = await res.json();
  byId('taskStatus').textContent = `${task.Command} - ${task.Status} - ${task.ElapsedSeconds}s`;
  byId('taskBar').style.width = `${task.Progress||10}%`;
  if(task.Output) byId('taskOutput').textContent = task.Output;
  if(task.Status === 'Running' || task.Status === 'NotStarted') setTimeout(()=>pollTask(id),900);
  else setTimeout(async()=>{ try { const fresh=await fetch('/api/status'); Object.assign(data, await fresh.json()); } catch(e){} },600);
}
byId('generated').textContent = data.GeneratedAt;
byId('modeBar').innerHTML = (data.AppShell?.Modes||[]).map(m=>`<button class="mode" data-mode="${esc(m.Name)}" title="${esc(m.Detail)}">${esc(m.Name)}</button>`).join('');
byId('starterPrompts').innerHTML = (data.AppShell?.StarterPrompts||[]).map(p=>`<button class="btn" data-prompt="${esc(p)}">${esc(p)}</button>`).join('');
byId('planButton').addEventListener('click',()=>renderPlan());
byId('missionInput').addEventListener('keydown',e=>{ if(e.key==='Enter') renderPlan(); });
document.addEventListener('click',e=>{ const mode=e.target.closest('[data-mode]'); if(mode) setMode(mode.dataset.mode); const prompt=e.target.closest('[data-prompt]'); if(prompt){ byId('missionInput').value=prompt.dataset.prompt; renderPlan(prompt.dataset.prompt); } });
setMode('Operate');
byId('systemSignal').innerHTML = [
  pill('Version '+data.Status.Version,'blue'),
  pill(data.Status.ParserOk ? 'Parser OK' : 'Parser failed', data.Status.ParserOk ? 'ok':'bad'),
  pill(data.Status.OllamaAvailable ? 'Ollama ready' : 'Ollama missing', data.Status.OllamaAvailable ? 'ok':'warnText'),
  pill('PowerShell '+data.Status.PowerShell),
  `<p class="sub">${esc(data.Paths.Root)}</p>`
].join('');
const bindRisks = data.FireDesk.BindingRisks?.length || 0;
const failedState = (data.State||[]).filter(x => x.Status === 'FAILED').length;
const warnState = (data.State||[]).filter(x => x.Status === 'WARN').length;
byId('metrics').innerHTML = [
  ['FireDesk', data.FireDesk.Exists ? 'Ready' : 'Missing', data.FireDesk.Path],
  ['Alerts', (data.Alerts||[]).filter(a => a.Severity !== 'OK').length, 'Items Gorrilla thinks need attention'],
  ['Bind risks', bindRisks, bindRisks ? 'Review before network use' : 'Loopback posture clean'],
  ['State issues', failedState + warnState, 'Desired state warnings/failures']
].map(m=>`<div class="metric"><span>${esc(m[0])}</span><b>${esc(m[1])}</b><span>${esc(m[2])}</span></div>`).join('');
byId('actionsGrid').innerHTML = data.Actions.map(a => `<article class="card risk-${esc(a.Risk)}"><h4>${esc(a.Title)}</h4><p>${esc(a.Detail)}</p>${pill(a.Area)}${pill(a.Risk, statusClass(a.Risk))}${cmd(a.Command)}<div class="toolbar"><button class="btn primary" data-action="${esc(a.Command)}">Run task</button><button class="btn" data-copy="${esc(a.Command)}">Copy</button></div></article>`).join('');
byId('alertsPanel').innerHTML = rows(data.Alerts, [{label:'Severity',value:'Severity'},{label:'Area',value:'Area'},{label:'Problem',value:'Title'},{label:'Detail',value:'Detail'},{label:'Command',value:'Command'}]);
byId('optionsPanel').innerHTML = rows(data.Options, [{label:'Priority',value:'Priority'},{label:'Option',value:'Option'},{label:'Command',value:'Command'},{label:'Why',value:'Why'}]);
byId('integrationPanel').innerHTML = rows(data.IntegrationMap, [{label:'Flow',value:'Flow'},{label:'Apps',value:'Apps'},{label:'Status',value:'Status'},{label:'Command',value:'Command'},{label:'Safety',value:'Safe'}]);
byId('fixQueuePanel').innerHTML = rows(data.FixQueue, [{label:'Priority',value:'Priority'},{label:'Area',value:'Area'},{label:'Item',value:'Item'},{label:'Risk',value:'Risk'},{label:'Fix',value:'Fix'},{label:'Command',value:'Command'}]);
byId('workflowsPanel').innerHTML = rows(data.Workflows, [{label:'Name',value:'Name'},{label:'Title',value:'Title'},{label:'Risk',value:'Risk'},{label:'Command',value:'Command'},{label:'Detail',value:'Detail'}]);
byId('promptsPanel').innerHTML = rows(data.PromptFiles, [{label:'Prompt',value:'Name'},{label:'Purpose',value:'Purpose'},{label:'Path',value:'Path'}]);
byId('understandingPanel').innerHTML = [
  '<p class="sub">Natural language becomes suggested commands first. Nothing from this panel changes the machine by itself.</p>',
  cmd('gorunderstand fix my machine'),
  '<div class="toolbar"><button class="btn primary" data-action="gorunderstand fix my machine">Try safe suggestion</button><button class="btn" data-action="gorprompt list">Show prompts</button></div>'
].join('');
byId('updatePanel').innerHTML = rows([data.UpdatePlan], [{label:'Current',value:'CurrentVersion'},{label:'Candidate',value:'CandidateVersion'},{label:'Source',value:'SourcePath'},{label:'Action',value:'Action'},{label:'Risk',value:'Risk'},{label:'Notes',value:'Notes'}]);
byId('launchPanel').innerHTML = rows(data.LaunchCatalog, [{label:'Name',value:'Name'},{label:'Category',value:'Category'},{label:'Command',value:'Command'},{label:'Launch',value:item=>`gorlaunch ${item.Name}`}]);
byId('fireDeskPanel').innerHTML = [
  pill(data.FireDesk.Exists ? 'Dashboard exists' : 'Dashboard missing', data.FireDesk.Exists ? 'ok':'bad'),
  pill((data.FireDesk.Port5000||[]).length + ' port owner(s)'),
  pill((data.FireDesk.BindingRisks||[]).length + ' binding risk(s)', bindRisks ? 'warnText':'ok'),
  pill('Compile '+(data.FireDesk.PythonCompile?.Status || 'N/A'), statusClass(data.FireDesk.PythonCompile?.Status)),
  rows(data.FireDesk.Files, [{label:'File',value:'Name'},{label:'Exists',value:'Exists'},{label:'Path',value:'Path'}])
].join('');
byId('statePanel').innerHTML = rows(data.State, [{label:'Check',value:'Check'},{label:'Status',value:'Status'},{label:'Detail',value:'Detail'}]);
byId('modelsPanel').innerHTML = rows(data.Models, [{label:'Model',value:'Name'},{label:'Status',value:'Status'},{label:'Detail',value:'Detail'}]);
byId('profilesPanel').innerHTML = rows(data.Profiles, [{label:'Name',value:'Name'},{label:'Type',value:'AppType'},{label:'Path',value:'Path'}]);
byId('toolsPanel').innerHTML = rows(data.Tools, [{label:'Tool',value:'Tool'},{label:'Status',value:'Status'},{label:'Source',value:'Source'}]);
function renderCommands(filter=''){ const q=filter.toLowerCase(); const list=data.Commands.filter(c=>JSON.stringify(c).toLowerCase().includes(q)); byId('commandsPanel').innerHTML = rows(list, [{label:'Command',value:'Command'},{label:'Category',value:'Category'},{label:'Risk',value:'Risk'},{label:'Description',value:'Description'},{label:'Example',value:'Example'}]); }
byId('commandSearch').addEventListener('input', e => renderCommands(e.target.value)); renderCommands();
byId('reportsPanel').innerHTML = rows(data.Reports, [{label:'Report',value:'Name'},{label:'Updated',value:'LastWriteTime'},{label:'Path',value:'Path'}]);
byId('evidencePanel').innerHTML = '<h4>Test Lab</h4>' + rows(data.Tests, [{label:'Result',value:'Name'},{label:'Updated',value:'LastWriteTime'}]) + '<h4>Ledger tail</h4><div class="cmd">' + esc((data.Ledger||[]).join('\\n') || 'No ledger entries yet.') + '</div>';
</script>
</body>
</html>
'@
    $html = New-GorPlainDashboardHtml
    $html = $html.Replace('__GOR_DATA__', $json)
    Set-Content -LiteralPath $path -Value $html -Encoding UTF8
    return $path
}

function New-GorPlainDashboardHtml {
    return @'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="Cache-Control" content="no-store, no-cache, must-revalidate">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="0">
<title>PowerShell Gorrilla</title>
<style>
:root{color-scheme:light;--bg:#f4f6f8;--panel:#fff;--line:#d8e0e8;--text:#172534;--muted:#627386;--blue:#1f5fbf;--green:#18794e;--amber:#95610a;--red:#b42318}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font-family:Segoe UI,Arial,sans-serif;font-size:14px;line-height:1.45}button,input{font:inherit}
.wrap{max-width:1360px;margin:0 auto;padding:18px}.top{display:flex;align-items:center;justify-content:space-between;gap:14px;border-bottom:1px solid var(--line);padding:0 0 14px;margin-bottom:16px}.title h1{margin:0;font-size:24px}.title p{margin:3px 0 0;color:var(--muted)}
.status{display:flex;gap:8px;flex-wrap:wrap}.pill{display:inline-flex;align-items:center;border:1px solid var(--line);border-radius:999px;padding:4px 9px;background:#fff;color:var(--muted);font-size:12px}.ok{color:var(--green)}.warn{color:var(--amber)}.bad{color:var(--red)}
.panel{background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:14px;margin:12px 0}.panel h2{font-size:17px;margin:0 0 10px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:12px}.metric b{display:block;font-size:24px;margin-top:4px}.muted{color:var(--muted)}
.commandBar{display:grid;grid-template-columns:minmax(0,1fr) auto;gap:10px}.commandBar input,.search{width:100%;border:1px solid var(--line);border-radius:8px;background:#fff;color:var(--text);padding:10px}.buttons{display:flex;gap:8px;flex-wrap:wrap}.btn{border:1px solid var(--line);background:#fff;color:var(--text);border-radius:8px;padding:8px 10px;cursor:pointer}.btn.primary{background:var(--blue);border-color:var(--blue);color:#fff}.btn:hover{border-color:var(--blue)}
.output{font-family:Cascadia Code,Consolas,monospace;background:#101820;color:#e9f1f8;border-radius:8px;padding:12px;white-space:pre-wrap;min-height:96px;max-height:320px;overflow:auto}.barShell{height:8px;background:#e9eef4;border-radius:999px;overflow:hidden;margin:8px 0}.bar{height:100%;width:0;background:var(--blue);transition:width .25s}
.card{border:1px solid var(--line);border-radius:8px;background:#fbfdff;padding:12px}.card h3{font-size:15px;margin:0 0 6px}.card p{margin:0 0 8px;color:var(--muted)}.cmd{font-family:Cascadia Code,Consolas,monospace;background:#eef3f7;border:1px solid var(--line);border-radius:6px;padding:7px;overflow:auto;white-space:nowrap}
.tableWrap{overflow:auto;border:1px solid var(--line);border-radius:8px;background:#fff}table{width:100%;border-collapse:collapse}th,td{padding:9px;border-bottom:1px solid var(--line);text-align:left;vertical-align:top}th{background:#eef3f7;font-size:12px}td{font-size:13px}
.iconBuilder{display:grid;grid-template-columns:minmax(300px,.9fr) minmax(0,1.25fr);gap:12px}.iconControls{display:grid;grid-template-columns:minmax(0,1fr) minmax(130px,180px);gap:8px;margin-bottom:10px}.iconToggles{display:flex;gap:10px;flex-wrap:wrap;margin-bottom:10px}.iconToggles label{font-size:12px;color:var(--muted)}.iconGrid{display:grid;grid-template-columns:repeat(auto-fill,minmax(118px,1fr));gap:8px;max-height:560px;overflow:auto;padding-right:4px}.iconTile{border:1px solid var(--line);border-radius:8px;background:#fbfdff;padding:9px;display:grid;gap:6px;text-align:left;color:var(--text);cursor:pointer}.iconTile.active,.iconTile:hover{border-color:var(--blue);background:#eef6ff}.appIconImg{width:42px;height:42px;object-fit:contain;border:1px solid var(--line);border-radius:8px;background:#fff;padding:5px}.iconTile b{font-size:13px;line-height:1.2;min-height:31px}.iconTile span{font-size:11px;color:var(--muted);overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.builderCanvas{display:grid;gap:10px}.slotRow{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:8px}.dropSlot{min-height:118px;border:1px dashed var(--line);border-radius:8px;background:#f8fafc;display:grid;place-items:center;text-align:center;padding:10px;color:var(--muted)}.dropSlot.filled{border-style:solid;border-color:var(--blue);background:#eef6ff;color:var(--text)}.equation{display:flex;gap:8px;flex-wrap:wrap;align-items:center;border:1px solid var(--line);border-radius:8px;background:#fbfdff;padding:10px}.equationApp{display:flex;align-items:center;gap:7px}.equationSymbol{color:var(--blue);font-weight:800}.workflowCards{display:grid;gap:10px}.workflowCard{border:1px solid var(--line);border-radius:8px;background:#fbfdff;padding:12px}.workflowCard h3{margin:8px 0 6px}.suggestionStrip{display:flex;gap:8px;flex-wrap:wrap}.suggestionStrip button{border:1px solid var(--line);background:#fff;color:var(--text);border-radius:999px;padding:5px 8px;font-size:12px;cursor:pointer}.smallNote{font-size:12px;color:var(--muted)}
@media(max-width:720px){.wrap{padding:12px}.top{display:block}.commandBar{grid-template-columns:1fr}.buttons .btn{width:100%;justify-content:center}.grid{grid-template-columns:1fr}}
@media(max-width:980px){.iconBuilder{grid-template-columns:1fr}.slotRow{grid-template-columns:1fr 1fr}.iconControls{grid-template-columns:1fr}}
@media(max-width:560px){.slotRow{grid-template-columns:1fr}.iconGrid{grid-template-columns:repeat(auto-fill,minmax(104px,1fr))}}
</style>
</head>
<body>
<script id="gor-data" type="application/json">__GOR_DATA__</script>
<div class="wrap">
  <header class="top">
    <div class="title">
      <h1>PowerShell Gorrilla</h1>
      <p>Plain local control screen. No showcase panels, no image banner, no page tabs.</p>
    </div>
    <div class="status" id="statusPills"></div>
  </header>

  <section class="panel">
    <h2>Run A Task</h2>
    <div class="commandBar">
      <input id="intent" placeholder="Type what you want, for example: check status, fix queue, update preview, scan apps">
      <button class="btn primary" id="planBtn">Suggest</button>
    </div>
    <div class="buttons" id="quickButtons" style="margin-top:10px"></div>
    <div class="grid" id="suggestions" style="margin-top:10px"></div>
  </section>

  <section class="panel">
    <h2>Live Output</h2>
    <div id="taskStatus" class="muted">No task running.</div>
    <div class="barShell"><div class="bar" id="taskBar"></div></div>
    <pre class="output" id="taskOutput">Use a button above to run a whitelisted local action.</pre>
  </section>

  <section class="grid" id="metrics"></section>

  <section class="panel">
    <h2>Main Actions</h2>
    <div class="grid" id="actions"></div>
  </section>

  <section class="panel">
    <h2>Alerts And Fix Queue</h2>
    <div id="alerts"></div>
  </section>

  <section class="panel">
    <h2>Workflows</h2>
    <div id="workflows"></div>
  </section>

  <section class="panel">
    <h2>Apps And Packages</h2>
    <input class="search" id="appSearch" placeholder="Search launch catalog, installed apps, package bank">
    <div id="apps" style="margin-top:10px"></div>
  </section>

  <section class="panel">
    <h2>Visual App Icon Integration Builder</h2>
    <p class="muted">Click or drag 2, 3, or 4 app icons to find matching workflows from the local CSV integration brain. Buttons here preview or export plans only.</p>
    <div class="grid" id="iconBuilderStats" style="margin:10px 0"></div>
    <div class="iconBuilder">
      <div>
        <div class="iconControls">
          <input class="search" id="iconSearch" placeholder="Search app name, category, status">
          <select class="search" id="workflowFilter">
            <option value="">All workflows</option>
            <option value="easy">Easy workflows</option>
            <option value="powerful">Powerful workflows</option>
            <option value="fixer">Computer fixer workflows</option>
            <option value="updater">Updater workflows</option>
            <option value="creative">Creative workflows</option>
            <option value="automation">Automation-ready workflows</option>
          </select>
        </div>
        <div class="iconToggles">
          <label><input type="checkbox" id="filterInstalled"> Installed only</label>
          <label><input type="checkbox" id="filterLocal"> Local only</label>
          <label><input type="checkbox" id="filterFree"> Free/open-source only</label>
        </div>
        <div class="iconGrid" id="appIconGrid"></div>
      </div>
      <div class="builderCanvas">
        <div class="slotRow" id="builderSlots"></div>
        <div class="equation" id="builderEquation"></div>
        <div class="suggestionStrip" id="builderSuggestions"></div>
        <div class="workflowCards" id="builderResults"></div>
        <pre class="output" id="builderPlanPreview">Select 2, 3, or 4 apps to generate a safe local PowerShell plan.</pre>
        <div class="buttons"><button class="btn" id="clearIconBuilder">Clear selection</button></div>
        <p class="smallNote" id="favouriteNotice">Favourites are saved in local browser storage for this dashboard.</p>
      </div>
    </div>
  </section>

  <section class="panel">
    <h2>Update And Evidence</h2>
    <div id="update"></div>
  </section>
</div>
<script>
const data=JSON.parse(document.getElementById('gor-data').textContent);
const $=id=>document.getElementById(id);
const esc=v=>String(v??'').replace(/[&<>"']/g,ch=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
const pill=(t,c='')=>`<span class="pill ${c}">${esc(t)}</span>`;
function statusClass(v){v=String(v||'').toUpperCase();if(v.includes('FAIL')||v.includes('HIGH'))return'bad';if(v.includes('WARN')||v.includes('MEDIUM')||v.includes('MISSING'))return'warn';return'ok'}
function rows(items,cols){const arr=Array.isArray(items)?items:[];if(!arr.length)return'<p class="muted">No data.</p>';return`<div class="tableWrap"><table><thead><tr>${cols.map(c=>`<th>${esc(c.label)}</th>`).join('')}</tr></thead><tbody>${arr.map(item=>`<tr>${cols.map(c=>`<td>${esc(typeof c.value==='function'?c.value(item):item[c.value])}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`}
function button(command,label,primary=false){return`<button class="btn ${primary?'primary':''}" data-run="${esc(command)}">${esc(label||command)}</button>`}
function setTask(status,progress,output){$('taskStatus').textContent=status;$('taskBar').style.width=(progress||0)+'%';if(output!==undefined)$('taskOutput').textContent=output}
async function runCommand(command){
  setTask('Starting '+command,8,'Starting local action...');
  try{
    const res=await fetch('/api/run',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({command,confirm:''})});
    const body=await res.json();
    if(!res.ok){setTask('Action blocked',100,body.Error||JSON.stringify(body,null,2));return}
    pollTask(body.Id);
  }catch(e){setTask('Local API unavailable',100,String(e))}
}
async function pollTask(id){
  try{
    const res=await fetch('/api/task?id='+encodeURIComponent(id));
    const task=await res.json();
    const done=!(task.Status==='Running'||task.Status==='NotStarted');
    const output=(task.Output||task.Error||'').toString();
    setTask((task.Command||'Task')+' - '+task.Status,task.Progress||10,output||JSON.stringify(task,null,2));
    if(!done)setTimeout(()=>pollTask(id),900);
  }catch(e){setTask('Could not read task status',100,String(e))}
}
document.addEventListener('click',e=>{const b=e.target.closest('[data-run]');if(b)runCommand(b.dataset.run)});
function suggest(){
  const q=$('intent').value.toLowerCase();
  const commands=q.match(/update|upgrade|version/)?['gorupdate preview','gorelite-report']:q.match(/fix|broken|repair|queue/)?['gorfixqueue','gordo now']:q.match(/app|desktop|scan|launch/)?['gorappdiscover','gordesktopapps']:q.match(/package|install|software/)?['gorpackagebank']:q.match(/backup|clean/)?['gorkeeponebackup preview']:['gordo now','gorfixqueue','gorworkflow list','gorupdate preview'];
  $('suggestions').innerHTML=commands.map((c,i)=>`<div class="card"><h3>${esc(c)}</h3><p>Suggested from your request.</p><div class="cmd">${esc(c)}</div><div style="margin-top:8px">${button(c,'Run',i===0)}</div></div>`).join('');
}
$('planBtn').addEventListener('click',suggest);$('intent').addEventListener('keydown',e=>{if(e.key==='Enter')suggest()});
$('statusPills').innerHTML=[pill('Generated '+data.GeneratedAt),pill('Version '+data.Status.Version,'ok'),pill(data.Status.ParserOk?'Parser OK':'Parser failed',data.Status.ParserOk?'ok':'bad'),pill(data.Status.OllamaAvailable?'Ollama ready':'Ollama missing',data.Status.OllamaAvailable?'ok':'warn')].join('');
$('quickButtons').innerHTML=[['gordo now','Status'],['gorfixqueue','Fix queue'],['gorworkflow list','Workflows'],['gorupdate preview','Update'],['gorconnectors','Connectors'],['gordesktopapps','Apps'],['gorpackagebank','Packages']].map(x=>button(x[0],x[1],x[0]==='gordo now')).join('');
const bindRisks=(data.FireDesk.BindingRisks||[]).length;const alerts=(data.Alerts||[]).filter(a=>a.Severity!=='OK').length;
$('metrics').innerHTML=[['FireDesk',data.FireDesk.Exists?'Ready':'Missing',data.FireDesk.Path],['Alerts',alerts,'Items needing attention'],['Binding risks',bindRisks,bindRisks?'Review network binding':'Loopback posture clean'],['Backups',data.BackupPosture?.ModuleBackups??0,'Kept generated module backups']].map(m=>`<div class="panel metric"><span class="muted">${esc(m[0])}</span><b>${esc(m[1])}</b><span class="muted">${esc(m[2])}</span></div>`).join('');
$('actions').innerHTML=(data.Actions||[]).slice(0,12).map(a=>`<div class="card"><h3>${esc(a.Title)}</h3><p>${esc(a.Detail)}</p>${pill(a.Risk,statusClass(a.Risk))} ${pill(a.Area||'Command')}<div class="cmd">${esc(a.Command)}</div><div style="margin-top:8px">${button(a.Command,'Run')}</div></div>`).join('');
$('alerts').innerHTML=rows((data.Alerts||[]).concat(data.FixQueue||[]),[{label:'Area',value:'Area'},{label:'Item',value:x=>x.Title||x.Item||x.Check},{label:'Risk',value:x=>x.Severity||x.Risk||x.Status},{label:'Command',value:'Command'}]);
$('workflows').innerHTML=rows(data.Workflows,[{label:'Name',value:'Name'},{label:'Title',value:'Title'},{label:'Risk',value:'Risk'},{label:'Command',value:'Command'},{label:'Detail',value:'Detail'}]);
function renderApps(filter=''){const q=filter.toLowerCase();const items=[...(data.LaunchCatalog||[]).map(x=>({Type:'Launch',Name:x.Name,Status:x.Category,Command:x.Command||('gorlaunch '+x.Name)})),...(data.PackageBank||[]).map(x=>({Type:'Package',Name:x.Name,Status:x.Status,Command:x.Command||x.InstallCommand}))].filter(x=>JSON.stringify(x).toLowerCase().includes(q)).slice(0,80);$('apps').innerHTML=rows(items,[{label:'Type',value:'Type'},{label:'Name',value:'Name'},{label:'Status',value:'Status'},{label:'Command',value:'Command'}])}
$('appSearch').addEventListener('input',e=>renderApps(e.target.value));renderApps();
const iconBrain=data.IntegrationBuilder||{Apps:[],Workflows:[],Stats:{},Sources:[]};let iconSelection=[];
function normApp(v){return String(v||'').toLowerCase().replace(/\.lnk$/,'').replace(/\s+\(\d+\)$/,'').replace(/\s+/g,' ').trim()}
function iconApps(){return Array.isArray(iconBrain.Apps)?iconBrain.Apps:[]}
function iconWorkflows(){return Array.isArray(iconBrain.Workflows)?iconBrain.Workflows:[]}
function appLookup(name){const key=normApp(name);return iconApps().find(a=>normApp(a.Name)===key)||{Name:name,IconUrl:'gorrilla-launcher.ico',Status:'Missing',Category:'Unknown',LicenseMode:'Unknown'}}
function workflowTypeOk(w,type){const hay=`${w.WorkflowName} ${w.WhatCanDo} ${w.BestUse} ${w.Category} ${w.Pattern} ${w.Difficulty} ${w.AutomationReadiness}`.toLowerCase();if(!type)return true;if(type==='easy')return hay.includes('easy');if(type==='powerful')return hay.includes('power')||hay.includes('advanced');if(type==='fixer')return hay.includes('fix')||hay.includes('repair')||hay.includes('clean')||hay.includes('maintenance');if(type==='updater')return hay.includes('update')||hay.includes('upgrade');if(type==='creative')return hay.includes('creative')||hay.includes('media')||hay.includes('image')||hay.includes('audio')||hay.includes('publish');if(type==='automation')return hay.includes('auto')||String(w.AutomationReadiness||'').toLowerCase().includes('preview');return true}
function selectedAppKeys(){return iconSelection.map(a=>normApp(a.Name))}
function workflowHasSelection(w){const keys=(w.Apps||[]).map(normApp);return selectedAppKeys().every(k=>keys.includes(k))}
function workflowScore(w){let s=0;if(w.LocalOnly)s+=6;if(String(w.FreeOpenSourceStatus||'').toLowerCase().match(/free|open-source/))s+=5;if(w.RiskLevel==='LOW')s+=4;if(String(w.AutomationReadiness||'').toLowerCase().includes('preview'))s+=3;if(String(w.Difficulty||'').toLowerCase().includes('easy'))s+=2;return s}
function currentWorkflowMatches(){const count=iconSelection.length;if(count<2)return[];const type=$('workflowFilter').value;return iconWorkflows().filter(w=>Number(w.Size)===count&&workflowHasSelection(w)&&workflowTypeOk(w,type)).sort((a,b)=>workflowScore(b)-workflowScore(a)).slice(0,8)}
function planText(w,mode='preview'){const appNames=(w.Apps||iconSelection.map(a=>a.Name)).join(' + ');return [`PowerShell Gorrilla visual workflow plan`,`Mode: ${mode}`,`Apps: ${appNames}`,`Workflow: ${w.WorkflowName||appNames}`,`What it can do: ${w.WhatCanDo||'Use the selected apps together with a safe local handoff.'}`,`Difficulty: ${w.Difficulty||'Unknown'}`,`Risk: ${w.RiskLevel||'LOW'}`,`Sign-in: ${w.SignInRequirement||'Unknown'}`,`Local availability: ${w.LocalOnly?'Local-only available':'Check app-specific sign-in before cloud features'}`,`Automation readiness: ${w.AutomationReadiness||'Manual plan'}`,`Safe steps:`,...(w.ActionPlan||[]).map((x,i)=>`${i+1}. ${x}`),`Preview commands:`,`gorintegrate`,`gorconnectors`,`gorworkflow list`,`No destructive action is triggered from the icon UI.`].join('\n')}
function setPlanPreview(text){$('builderPlanPreview').textContent=text}
function toggleIconApp(name){const app=appLookup(name);const key=normApp(app.Name);if(iconSelection.some(a=>normApp(a.Name)===key)){iconSelection=iconSelection.filter(a=>normApp(a.Name)!==key)}else{if(iconSelection.length>=4)iconSelection.shift();iconSelection.push(app)}renderIconBuilder()}
function renderIconStats(){const s=iconBrain.Stats||{};const ready=(iconBrain.Sources||[]).filter(x=>x.Status==='READY').length;$('iconBuilderStats').innerHTML=[['Apps',s.AppCount||iconApps().length,'Detected and normalized'],['Workflows',s.WorkflowCount||iconWorkflows().length,'Sampled from CSVs'],['Datasets',ready,'Ready local imports'],['Safety','Preview','No direct destructive actions']].map(m=>`<div class="card metric"><span class="muted">${esc(m[0])}</span><b>${esc(m[1])}</b><span class="muted">${esc(m[2])}</span></div>`).join('')}
function renderSlots(){$('builderSlots').innerHTML=[0,1,2,3].map(i=>{const a=iconSelection[i];return`<div class="dropSlot ${a?'filled':''}" data-icon-slot="${i}">${a?`<div><img class="appIconImg" src="${esc(a.IconUrl||'gorrilla-launcher.ico')}" alt=""><b>${esc(a.Name)}</b><p>${esc(a.Status)} · ${esc(a.SignInRequirement||'Unknown')}</p><button class="btn" data-remove-icon="${i}">Remove</button></div>`:`<div><b>Slot ${i+1}</b><p>${i<2?'Required':'Optional'}</p></div>`}</div>`}).join('');document.querySelectorAll('[data-icon-slot]').forEach(slot=>{slot.addEventListener('dragover',e=>e.preventDefault());slot.addEventListener('drop',e=>{e.preventDefault();const name=e.dataTransfer.getData('text/plain');iconSelection[Number(slot.dataset.iconSlot)]=appLookup(name);iconSelection=iconSelection.filter(Boolean).slice(0,4);renderIconBuilder()})})}
function renderEquation(matches){if(!iconSelection.length){$('builderEquation').innerHTML='<span class="pill">Select app icons to build an equation.</span>';return}const icons=iconSelection.map(a=>`<span class="equationApp"><img class="appIconImg" src="${esc(a.IconUrl||'gorrilla-launcher.ico')}" alt=""><b>${esc(a.Name)}</b></span>`).join('<span class="equationSymbol">+</span>');$('builderEquation').innerHTML=`${icons}<span class="equationSymbol">=</span><b>${esc(matches[0]?.WorkflowName||'Workflow search')}</b>`}
function renderSuggestions(){const keys=selectedAppKeys();if(!keys.length){$('builderSuggestions').innerHTML='<span class="pill">Click one app to see smart suggestions.</span>';return}const scores={};iconWorkflows().filter(workflowHasSelection).forEach(w=>(w.Apps||[]).forEach(name=>{const key=normApp(name);if(!key||keys.includes(key))return;const app=appLookup(name);scores[key]=scores[key]||{Name:name,Score:0};scores[key].Score+=(app.Installed?6:0)+(app.LocalAvailability==='Local mode available'?4:0)+(String(app.LicenseMode||'').toLowerCase().match(/free|open/)?3:0)+(w.RiskLevel==='LOW'?2:0)+1}));const suggestions=Object.values(scores).sort((a,b)=>b.Score-a.Score).slice(0,10);$('builderSuggestions').innerHTML=suggestions.length?`<span class="pill">Smart suggestions</span>${suggestions.map(s=>`<button data-icon-app="${esc(s.Name)}">${esc(s.Name)}</button>`).join('')}`:'<span class="pill">No extra app suggestions for this exact selection.</span>'}
function renderWorkflowCards(matches){if(iconSelection.length<2){$('builderResults').innerHTML='<div class="card"><h3>Start With Two Apps</h3><p>Choose Slot 1 and Slot 2. Add Slot 3 or Slot 4 to search larger workflows.</p></div>';setPlanPreview('Select 2, 3, or 4 apps to generate a safe local PowerShell plan.');return}if(!matches.length){$('builderResults').innerHTML='<div class="card"><h3>No Exact Match Yet</h3><p>Try a smart suggestion or loosen the workflow filter.</p></div>';setPlanPreview('No exact match was found for the current app set. No action was run.');return}$('builderResults').innerHTML=matches.map(w=>{const idx=iconWorkflows().indexOf(w);const eq=(w.Apps||[]).map(n=>{const a=appLookup(n);return`<span class="equationApp"><img class="appIconImg" src="${esc(a.IconUrl||'gorrilla-launcher.ico')}" alt=""><b>${esc(n)}</b></span>`}).join('<span class="equationSymbol">+</span>');return`<div class="workflowCard"><div class="equation">${eq}<span class="equationSymbol">=</span><b>${esc(w.WorkflowName)}</b></div><h3>${esc(w.WorkflowName)}</h3><p>${esc(w.WhatCanDo||'Workflow details are available in the CSV source.')}</p>${pill(w.Kind||`${w.Size}-App`)} ${pill(w.RiskLevel||'LOW',w.RiskLevel==='LOW'?'ok':'warn')} ${pill(w.LocalOnly?'Local':'Check sign-in',w.LocalOnly?'ok':'warn')} ${pill(w.AutomationReadiness||'Manual plan')}<p><b>Best use:</b> ${esc(w.BestUse||'General workflow')}</p><p><b>Sign-in:</b> ${esc(w.SignInRequirement||'Unknown')}</p><div class="buttons"><button class="btn primary" data-workflow-action="preview" data-workflow-index="${idx}">Preview Plan</button><button class="btn" data-workflow-action="export" data-workflow-index="${idx}">Export Plan</button><button class="btn" data-workflow-action="fav" data-workflow-index="${idx}">Favourite</button><button class="btn" data-workflow-action="launch" data-workflow-index="${idx}">Launch Apps</button><button class="btn" data-workflow-action="generate" data-workflow-index="${idx}">Generate PowerShell Plan</button></div></div>`}).join('');setPlanPreview(planText(matches[0],'best match preview'))}
function renderIconBuilder(){if(!$('appIconGrid'))return;renderIconStats();const q=normApp($('iconSearch').value);const type=$('workflowFilter').value;const installed=$('filterInstalled').checked;const local=$('filterLocal').checked;const free=$('filterFree').checked;const hasType=a=>!type||iconWorkflows().some(w=>workflowTypeOk(w,type)&&(w.Apps||[]).map(normApp).includes(normApp(a.Name)));const apps=iconApps().filter(a=>(!q||`${a.Name} ${a.Category} ${a.Status} ${a.LicenseMode}`.toLowerCase().includes(q))&&(!installed||a.Installed)&&(!local||a.LocalAvailability==='Local mode available')&&(!free||String(a.LicenseMode||'').toLowerCase().match(/free|open/))&&hasType(a)).slice(0,220);$('appIconGrid').innerHTML=apps.map(a=>{const active=iconSelection.some(s=>normApp(s.Name)===normApp(a.Name));return`<button class="iconTile ${active?'active':''}" draggable="true" data-icon-app="${esc(a.Name)}"><img class="appIconImg" src="${esc(a.IconUrl||'gorrilla-launcher.ico')}" alt=""><b>${esc(a.Name)}</b><span>${esc(a.Category||'Unknown')}</span>${pill(a.Status||'Unknown',a.Installed?'ok':'warn')} ${pill(a.LicenseMode||'Unknown')}</button>`}).join('')||'<p class="muted">No apps match those filters.</p>';document.querySelectorAll('[data-icon-app]').forEach(tile=>tile.addEventListener('dragstart',e=>e.dataTransfer.setData('text/plain',tile.dataset.iconApp)));const matches=currentWorkflowMatches();renderSlots();renderEquation(matches);renderSuggestions();renderWorkflowCards(matches)}
function handleWorkflowAction(action,index){const w=iconWorkflows()[Number(index)];if(!w)return;const text=planText(w,action);if(action==='export'){const blob=new Blob([text],{type:'text/plain'});const link=document.createElement('a');link.href=URL.createObjectURL(blob);link.download='powershell-gorrilla-workflow-plan.txt';link.click();URL.revokeObjectURL(link.href);setPlanPreview(text+'\n\nExported through the browser download flow.')}else if(action==='fav'){const key='powershell-gorrilla-icon-favourites';const list=JSON.parse(localStorage.getItem(key)||'[]');list.push({savedAt:new Date().toISOString(),apps:w.Apps,icons:(w.Apps||[]).map(n=>appLookup(n).IconUrl),workflow:w.WorkflowName,description:w.WhatCanDo,actionPlan:text,tags:[w.Kind,w.RiskLevel,w.AutomationReadiness]});localStorage.setItem(key,JSON.stringify(list.slice(-80)));$('favouriteNotice').textContent='Favourite saved locally. Total saved: '+list.length;setPlanPreview(text)}else if(action==='launch'){setPlanPreview(text+'\n\nLaunch Apps preview: this button does not launch apps directly. Confirm the plan, then use trusted Gorilla launch commands manually.')}else{setPlanPreview(text)}}
document.addEventListener('click',e=>{const app=e.target.closest('[data-icon-app]');if(app){toggleIconApp(app.dataset.iconApp);return}const rem=e.target.closest('[data-remove-icon]');if(rem){iconSelection.splice(Number(rem.dataset.removeIcon),1);renderIconBuilder();return}const wf=e.target.closest('[data-workflow-action]');if(wf){handleWorkflowAction(wf.dataset.workflowAction,wf.dataset.workflowIndex);return}});
['iconSearch','workflowFilter','filterInstalled','filterLocal','filterFree'].forEach(id=>$(id)?.addEventListener(id==='workflowFilter'?'change':'input',renderIconBuilder));['filterInstalled','filterLocal','filterFree'].forEach(id=>$(id)?.addEventListener('change',renderIconBuilder));$('clearIconBuilder')?.addEventListener('click',()=>{iconSelection=[];renderIconBuilder()});renderIconBuilder();
$('update').innerHTML=rows([data.UpdatePlan],[{label:'Current',value:'CurrentVersion'},{label:'Candidate',value:'CandidateVersion'},{label:'Needs update',value:'NeedsUpdate'},{label:'Action',value:'Action'},{label:'Installed',value:'InstalledRoot'}])+'<div style="height:10px"></div>'+rows(data.Reports,[{label:'Report',value:'Name'},{label:'Updated',value:'LastWriteTime'},{label:'Path',value:'Path'}]);
</script>
</body>
</html>
'@
}

function New-GorProductDashboardHtml {
    return @'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PowerShell Gorrilla</title>
<style>
:root{color-scheme:dark;--bg:#080b0d;--ink:#f4f7f8;--muted:#9ba8ad;--line:#263237;--panel:#101619;--panel2:#151e22;--teal:#58d6b2;--blue:#75b8ff;--amber:#f3c15f;--red:#ff6f7f;--violet:#b9a1ff}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font-family:Segoe UI,Inter,Arial,sans-serif;line-height:1.42}button,input,textarea{font:inherit}button{cursor:pointer}
.layout{min-height:100vh;display:grid;grid-template-columns:280px minmax(0,1fr)}.side{position:sticky;top:0;height:100vh;padding:22px;background:#0b1012;border-right:1px solid var(--line);overflow:auto}.brand{display:flex;align-items:center;gap:13px;margin-bottom:22px}.brand img{width:54px;height:54px;border-radius:12px;object-fit:cover;border:1px solid #2f3e44}.brand h1{font-size:18px;margin:0}.brand p{font-size:12px;color:var(--muted);margin:3px 0 0}.nav a{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:10px;border-radius:8px;color:var(--ink);text-decoration:none;margin:4px 0}.nav a:hover{background:var(--panel2)}.main{padding:24px;max-width:1520px}
.hero{min-height:430px;display:grid;grid-template-columns:minmax(0,1.1fr) 420px;gap:22px;align-items:stretch;margin-bottom:22px}.heroText{display:flex;flex-direction:column;justify-content:center;border-bottom:1px solid var(--line);padding:18px 0 30px}.eyebrow{color:var(--teal);font-weight:700;letter-spacing:.08em;text-transform:uppercase;font-size:12px}.hero h2{font-size:52px;line-height:1.02;margin:12px 0 14px;max-width:900px;letter-spacing:0}.hero p{font-size:18px;color:#c8d2d5;max-width:830px;margin:0}.facePanel{border:1px solid var(--line);background:#101619;border-radius:8px;padding:18px;display:grid;place-items:center}.facePanel img{width:min(100%,330px);border-radius:18px;display:block}.quick{display:grid;grid-template-columns:1fr auto;gap:10px;margin-top:24px}.quick input{width:100%;background:#0d1316;border:1px solid var(--line);border-radius:8px;color:var(--ink);padding:14px}.btn{border:1px solid var(--line);border-radius:8px;background:var(--panel2);color:var(--ink);padding:10px 13px;text-decoration:none;display:inline-flex;align-items:center;gap:8px}.btn.primary{background:var(--teal);border-color:var(--teal);color:#07100e;font-weight:800}.btn.warn{border-color:rgba(243,193,95,.5);background:rgba(243,193,95,.1)}.btn:hover{border-color:var(--blue)}
.band{border-top:1px solid var(--line);padding:22px 0}.sectionHead{display:flex;justify-content:space-between;align-items:end;gap:16px;margin-bottom:14px}.sectionHead h3{margin:0;font-size:22px}.sectionHead p{margin:4px 0 0;color:var(--muted);max-width:760px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:12px}.capability,.panel,.step{background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:16px}.capability h4,.panel h4,.step h4{margin:0 0 7px;font-size:16px}.capability p,.panel p,.step p{margin:0 0 12px;color:#b7c2c6;font-size:13px}.pill{display:inline-flex;border:1px solid var(--line);border-radius:999px;padding:4px 9px;color:var(--muted);font-size:12px;margin:2px 4px 2px 0}.ok{color:var(--teal)}.warnText{color:var(--amber)}.bad{color:var(--red)}.blue{color:var(--blue)}.toolbar{display:flex;gap:8px;flex-wrap:wrap;margin-top:12px}.split{display:grid;grid-template-columns:minmax(0,1fr) minmax(360px,.75fr);gap:14px}.chat{display:grid;grid-template-rows:1fr auto;min-height:460px}.chatLog{background:#0c1214;border:1px solid var(--line);border-radius:8px;padding:14px;overflow:auto;max-height:390px}.msg{margin:0 0 12px;padding:10px;border-radius:8px;background:#111a1e}.msg.user{background:#132326}.msg b{display:block;font-size:12px;color:var(--teal);margin-bottom:4px}.chatInput{display:grid;grid-template-columns:1fr auto;gap:9px;margin-top:10px}.chatInput textarea{min-height:62px;resize:vertical;background:#0d1316;border:1px solid var(--line);border-radius:8px;color:var(--ink);padding:11px}.process{display:grid;gap:10px}.barShell{height:13px;background:#0c1214;border:1px solid var(--line);border-radius:999px;overflow:hidden}.bar{height:100%;width:0;background:linear-gradient(90deg,var(--teal),var(--blue));transition:width .35s}.cmd{font-family:Cascadia Code,Consolas,monospace;background:#090e10;border:1px solid var(--line);border-radius:8px;padding:10px;white-space:pre-wrap;overflow:auto;max-height:260px;color:#d8e4e7}.apps{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:12px}.appIcon{width:38px;height:38px;border-radius:8px;display:grid;place-items:center;background:#17262a;color:var(--teal);font-weight:900;margin-bottom:10px}.statusGrid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:12px}.metric{background:#0f171a;border:1px solid var(--line);border-radius:8px;padding:14px}.metric span{font-size:12px;color:var(--muted)}.metric b{font-size:26px;display:block;margin:4px 0}.recipe{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:8px}.recipe .step{min-height:145px}.tableWrap{overflow:auto;border:1px solid var(--line);border-radius:8px}table{width:100%;border-collapse:collapse;font-size:13px}th,td{border-bottom:1px solid var(--line);padding:10px;text-align:left;vertical-align:top}th{color:#cfdadd;background:#0f171a;text-transform:uppercase;font-size:11px}.hide{display:none!important}@media(max-width:1050px){.layout{grid-template-columns:1fr}.side{position:relative;height:auto}.hero,.split{grid-template-columns:1fr}.statusGrid{grid-template-columns:repeat(2,minmax(0,1fr))}.recipe{grid-template-columns:1fr}}@media(max-width:620px){.main{padding:15px}.hero h2{font-size:36px}.quick,.chatInput{grid-template-columns:1fr}.statusGrid{grid-template-columns:1fr}}
</style>
</head>
<body>
<script id="gor-data" type="application/json">__GOR_DATA__</script>
<div class="layout">
<aside class="side">
  <div class="brand"><div class="appIcon">PG</div><div><h1>PowerShell Gorrilla</h1><p>Local command center</p></div></div>
  <nav class="nav">
    <a href="#start">Start <span>01</span></a>
    <a href="#helper">Helper <span>02</span></a>
    <a href="#apps">Apps <span>03</span></a>
    <a href="#workflows">Workflows <span>04</span></a>
    <a href="#process">Process <span>05</span></a>
    <a href="#health">Health <span>06</span></a>
    <a href="#details">Details <span>07</span></a>
  </nav>
</aside>
<main class="main">
  <section id="start" class="hero">
    <div class="heroText">
      <div class="eyebrow">Local AI operator for your Windows workspace</div>
      <h2>Ask for an outcome. Let Gorrilla plan, launch, inspect, and report.</h2>
      <p>This is the control room for your local apps, tools, models, repair checks, launchers, and workflow runs. It explains what it can do, shows the next step, and keeps a visible trail while tasks run.</p>
      <div class="quick">
        <input id="intent" placeholder="Example: make a design from a picture, write about it, package the result">
        <button class="btn primary" id="planBtn">Build plan</button>
      </div>
      <div class="toolbar" id="starter"></div>
    </div>
    <div class="facePanel"><div class="appIcon">PG</div><div><span class="pill ok" id="aiPill">AI status</span><span class="pill blue" id="versionPill">Version</span></div></div>
  </section>

  <section id="helper" class="band split">
    <div>
      <div class="sectionHead"><div><h3>Helper Chat</h3><p>Ask what the system is for, what to run next, or how to connect apps. If Ollama is available, it answers locally; otherwise it falls back to guided built-in advice.</p></div></div>
      <div class="chat">
        <div class="chatLog" id="chatLog"></div>
        <div class="chatInput"><textarea id="chatText" placeholder="Ask Gorrilla what to do next..."></textarea><button class="btn primary" id="chatBtn">Ask</button></div>
      </div>
    </div>
    <div>
      <div class="sectionHead"><div><h3>Suggested Plan</h3><p>Natural language becomes a safe sequence before anything runs.</p></div></div>
      <div id="planPanel" class="process"></div>
    </div>
  </section>

  <section id="apps" class="band">
    <div class="sectionHead"><div><h3>What This Can Do</h3><p>Gorrilla is meant to be an operator layer: it sees your tools, picks a route, launches the right app, runs checks, and records evidence.</p></div></div>
    <div class="apps" id="appCards"></div>
  </section>

  <section class="band">
    <div class="sectionHead"><div><h3>Mission Matrix</h3><p>Pick a goal, then run each step with the app showing progress and outcome summaries. These are starting routes that can multiply into thousands of combinations as apps and profiles are added.</p></div></div>
    <div class="grid" id="missionMatrix"></div>
  </section>

  <section id="workflows" class="band">
    <div class="sectionHead"><div><h3>Superking Workflow Example</h3><p>A real target workflow: take an image, understand it locally, move it into a design tool, write copy, package the output, and show every step.</p></div></div>
    <div class="recipe" id="recipe"></div>
  </section>

  <section id="process" class="band split">
    <div>
      <div class="sectionHead"><div><h3>Run A Task</h3><p>Whitelisted tasks run through the local API with progress and output.</p></div></div>
      <div class="grid" id="actions"></div>
    </div>
    <div class="panel">
      <h4>Live Process</h4>
      <p id="taskStatus">No task running.</p>
      <div class="barShell"><div class="bar" id="taskBar"></div></div>
      <pre class="cmd" id="taskOutput">Choose a task. The process will appear here.</pre>
    </div>
  </section>

  <section id="health" class="band">
    <div class="sectionHead"><div><h3>Health At A Glance</h3><p>The important signals first, not a wall of numbers.</p></div></div>
    <div class="statusGrid" id="metrics"></div>
  </section>

  <section id="details" class="band">
    <div class="sectionHead"><div><h3>Deeper Details</h3><p>Open these when you need evidence, exact commands, reports, or raw state.</p></div></div>
    <div class="grid">
      <div class="panel"><h4>Launch Catalog</h4><div id="launch"></div></div>
      <div class="panel"><h4>Fix Queue</h4><div id="fixes"></div></div>
      <div class="panel"><h4>Models</h4><div id="models"></div></div>
      <div class="panel"><h4>Reports</h4><div id="reports"></div></div>
    </div>
  </section>
</main>
</div>
<style>
.taskPopup{position:fixed;right:22px;bottom:22px;z-index:80;width:min(460px,calc(100vw - 32px));background:linear-gradient(180deg,#121d1a,#0a100f);border:1px solid var(--line2);border-radius:18px;box-shadow:0 26px 90px rgba(0,0,0,.55);padding:15px;display:none}.taskPopup.active{display:block}.taskPopupHead{display:flex;justify-content:space-between;gap:12px;align-items:flex-start}.taskPopup h4{margin:0 0 4px;font-size:15px}.taskPopup p{margin:0;color:var(--muted);font-size:12px}.taskPopup .output{max-height:190px;margin-top:10px}.taskPopupClose{width:34px;height:34px;border-radius:10px;border:1px solid var(--line);background:#111916;color:var(--text)}.taskPulse{width:9px;height:9px;border-radius:999px;background:var(--green);box-shadow:0 0 0 0 rgba(110,231,183,.5);animation:pulse 1.4s infinite}.taskPopup.done .taskPulse{background:var(--blue);animation:none}.taskPopup.error .taskPulse{background:var(--red);animation:none}@keyframes pulse{70%{box-shadow:0 0 0 10px rgba(110,231,183,0)}100%{box-shadow:0 0 0 0 rgba(110,231,183,0)}}@media(max-width:650px){.taskPopup{right:12px;bottom:12px;width:calc(100vw - 24px)}}
</style>
<div class="taskPopup" id="taskPopup" role="status" aria-live="polite">
  <div class="taskPopupHead">
    <div><div class="taskPulse"></div><h4 id="taskPopupTitle">Task running</h4><p id="taskPopupStatus">Preparing...</p></div>
    <button class="taskPopupClose" id="taskPopupClose" title="Hide task popup">x</button>
  </div>
  <div class="barShell"><div class="bar" id="taskPopupBar"></div></div>
  <pre class="output" id="taskPopupOutput">Waiting for the outcome...</pre>
</div>
<script>
const data = JSON.parse(document.getElementById('gor-data').textContent);
const $ = id => document.getElementById(id);
const esc = value => String(value ?? '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
const pill = (text, cls='') => `<span class="pill ${cls}">${esc(text)}</span>`;
const command = c => `<pre class="cmd">${esc(c)}</pre>`;
function rows(items, cols){ const arr=Array.isArray(items)?items:[]; if(!arr.length) return '<p>No data yet.</p>'; return `<div class="tableWrap"><table><thead><tr>${cols.map(c=>`<th>${esc(c.label)}</th>`).join('')}</tr></thead><tbody>${arr.slice(0,8).map(item=>`<tr>${cols.map(c=>`<td>${esc(typeof c.value==='function'?c.value(item):item[c.value])}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`; }
function statusClass(v){ const s=String(v||'').toUpperCase(); if(s.includes('FAIL')||s.includes('HIGH')) return 'bad'; if(s.includes('WARN')||s.includes('MEDIUM')||s.includes('MISSING')) return 'warnText'; return 'ok'; }
const capabilityCards = [
  ['AI Lab','Start/check Ollama and local model readiness.','gordo ai','AI'],
  ['App Doctor','Inspect a project, find files, risks, dependencies, and repair paths.','gordoctor FireDesk','DOC'],
  ['Design Studio','Launch design tools and prepare image-to-design workflows.','gorlaunch figma','DES'],
  ['API Lab','Open API tooling and inspect local ports or services.','gorlaunch bruno','API'],
  ['Security Review','Check bind addresses, secrets, debug flags, and exposure.','gorsecurity FireDesk','SEC'],
  ['Update Center','Preview updates, backups, rollback posture, and release notes.','gorupdate preview','UP']
];
const missionRoutes = [
  ['Picture to Package','Understand an image request, open design tooling, write copy, and package evidence.',['gordo ai','gorlaunch figma','gorworkflow list','gorintegrate']],
  ['Fix My Local Stack','Check status, find the fix queue, run safe repairs, and refresh evidence.',['gordo now','gorfixqueue','goradvisor','gordo boost']],
  ['Secure An App','Review bindings, secrets, debug flags, and produce a patch plan before changing anything.',['gorsecurity FireDesk','gorpatchplan FireDesk','gorfiredeskreport']],
  ['Build A Web App','Create a starter project, check tools, launch code, and run workflow guidance.',['gornewweb','gorlaunch code','gorworkflow list','gortest all']],
  ['API Workbench','Open API tools, inspect ports, check services, and record findings.',['gorlaunch bruno','gorports','gorservices','gornetwork']],
  ['Update Safely','Preview update, back up module, check quality, then prepare rollback evidence.',['gorupdate preview','gorbackup-module','gorquality FireDesk','gorelite-report']]
];
const recipe = [
  ['Intake','Drop in a picture or describe the desired asset. Gorrilla records the intent and needed output.'],
  ['Understand','Ollama analyzes the request locally and writes a plan with risks, tools, and files.'],
  ['Create','Design tools such as Canva or Figma become the visual production step once connected.'],
  ['Write','The assistant drafts caption, article, prompt, product copy, or report from the design context.'],
  ['Produce','Gorrilla packages the result, opens the output, and saves evidence in the ledger.']
];
function matchAction(text){
  const q=String(text||'').toLowerCase();
  const actions=data.Actions||[];
  const boosts = [
    [/picture|image|photo|canva|design|move|create/,['gordo ai','gorlaunch figma','gorworkflow list','gorintegrate']],
    [/fix|problem|broken|repair/,['gorfixqueue','goradvisor','gordo boost']],
    [/security|secret|safe|scan/,['gorsecurity FireDesk','gorpatchplan FireDesk']],
    [/update|upgrade|version/,['gorupdate preview','gorbackup-module']],
    [/api|bruno|port|server/,['gorlaunch bruno','gorports']]
  ];
  const preferred = boosts.find(([rx])=>rx.test(q))?.[1] || ['gordo now','goradvisor','gorworkflow list','gorintegrate'];
  return preferred.map(cmd => actions.find(a=>a.Command===cmd) || {Title:cmd,Command:cmd,Risk:'LOW',Detail:'Run this step from the local command layer.'}).filter(Boolean);
}
function renderPlan(){
  const text=$('intent').value || 'show me what this can do';
  const steps=matchAction(text);
  $('planPanel').innerHTML=steps.map((a,i)=>`<div class="step"><span class="pill">Step ${i+1}</span>${pill(a.Risk,statusClass(a.Risk))}<h4>${esc(a.Title)}</h4><p>${esc(a.Detail)}</p>${command(a.Command)}<div class="toolbar"><button class="btn primary" data-run="${esc(a.Command)}">Run</button><button class="btn" data-copy="${esc(a.Command)}">Copy</button></div></div>`).join('');
}
function addMessage(who,text){ $('chatLog').insertAdjacentHTML('beforeend',`<div class="msg ${who==='You'?'user':''}"><b>${esc(who)}</b>${esc(text)}</div>`); $('chatLog').scrollTop=$('chatLog').scrollHeight; }
async function askChat(){
  const text=$('chatText').value.trim(); if(!text) return;
  addMessage('You',text); $('chatText').value=''; addMessage('Gorrilla','Thinking locally and checking the command map...');
  const msgs=document.querySelectorAll('.msg'); const last=msgs[msgs.length-1];
  try{ const res=await fetch('/api/chat',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({message:text})}); const body=await res.json(); last.innerHTML=`<b>Gorrilla</b>${esc(body.Answer||body.Error||'No answer returned.')}`; }
  catch(e){ last.innerHTML='<b>Gorrilla</b>I could not reach the local helper API. Try restarting with gorvisual.'; }
}
function findRisk(commandText){ return ((data.Actions||[]).find(a=>a.Command===commandText)||{}).Risk || 'LOW'; }
async function run(commandText){
  const risk = findRisk(commandText);
  let confirm = '';
  if(risk === 'MEDIUM') confirm = prompt('This is a medium-risk PowerShell action. Type the exact confirmation requested by the task if it asks for one, or leave blank to let the server block it safely.') || '';
  if(risk === 'HIGH') confirm = prompt('High-risk action. Type KILL5000 only if you really intend to stop the port owner.') || '';
  $('taskStatus').textContent='Starting '+commandText; $('taskBar').style.width='5%'; $('taskOutput').textContent='';
  const res=await fetch('/api/run',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({command:commandText,confirm})});
  const body=await res.json(); if(!res.ok){ $('taskStatus').textContent=body.Error||'Blocked'; $('taskOutput').textContent=JSON.stringify(body,null,2); return; }
  poll(body.Id);
}
async function poll(id){
  const res=await fetch('/api/task?id='+encodeURIComponent(id)); const t=await res.json();
  $('taskStatus').textContent=`${t.Command} - ${t.Status} - ${t.ElapsedSeconds}s`; $('taskBar').style.width=(t.Progress||10)+'%'; if(t.Output) $('taskOutput').textContent=t.Output;
  if(t.Status==='Running'||t.Status==='NotStarted') setTimeout(()=>poll(id),900);
}
document.addEventListener('click',e=>{ const runBtn=e.target.closest('[data-run]'); if(runBtn) run(runBtn.dataset.run); const copy=e.target.closest('[data-copy]'); if(copy) navigator.clipboard?.writeText(copy.dataset.copy); const prompt=e.target.closest('[data-prompt]'); if(prompt){ $('intent').value=prompt.dataset.prompt; renderPlan(); } });
$('planBtn').addEventListener('click',renderPlan); $('intent').addEventListener('keydown',e=>{ if(e.key==='Enter') renderPlan(); }); $('chatBtn').addEventListener('click',askChat);
$('starter').innerHTML=(data.AppShell?.StarterPrompts||[]).slice(0,8).map(p=>`<button class="btn" data-prompt="${esc(p)}">${esc(p)}</button>`).join('');
$('aiPill').textContent=data.Status.OllamaAvailable?'Ollama ready':'Ollama not connected'; $('aiPill').className='pill '+(data.Status.OllamaAvailable?'ok':'warnText'); $('versionPill').textContent='Version '+data.Status.Version;
$('appCards').innerHTML=capabilityCards.map(c=>`<div class="capability"><div class="appIcon">${esc(c[3])}</div><h4>${esc(c[0])}</h4><p>${esc(c[1])}</p>${command(c[2])}<button class="btn primary" data-run="${esc(c[2])}">Open</button></div>`).join('');
$('missionMatrix').innerHTML=missionRoutes.map(route=>`<div class="capability"><h4>${esc(route[0])}</h4><p>${esc(route[1])}</p><div class="toolbar">${route[2].map((cmd,i)=>`<button class="btn ${i===0?'primary':''}" data-run="${esc(cmd)}">${esc(cmd)}</button>`).join('')}</div></div>`).join('');
$('recipe').innerHTML=recipe.map((r,i)=>`<div class="step"><span class="pill">0${i+1}</span><h4>${esc(r[0])}</h4><p>${esc(r[1])}</p></div>`).join('');
$('actions').innerHTML=(data.Actions||[]).slice(0,9).map(a=>`<div class="capability"><h4>${esc(a.Title)}</h4><p>${esc(a.Detail)}</p>${pill(a.Area)}${pill(a.Risk,statusClass(a.Risk))}<button class="btn primary" data-run="${esc(a.Command)}">Run</button></div>`).join('');
const bindRisks=data.FireDesk.BindingRisks?.length||0; const stateIssues=(data.State||[]).filter(x=>x.Status==='FAILED'||x.Status==='WARN').length;
$('metrics').innerHTML=[
  ['Purpose','Operator','Plan, launch, inspect, repair, report'],
  ['AI',data.Status.OllamaAvailable?'Ready':'Missing','Local helper depends on Ollama'],
  ['Apps',(data.Profiles||[]).length,'Saved app profiles'],
  ['Risks',bindRisks+stateIssues,'Binding and desired-state warnings']
].map(m=>`<div class="metric"><span>${esc(m[0])}</span><b>${esc(m[1])}</b><span>${esc(m[2])}</span></div>`).join('');
$('launch').innerHTML=rows(data.LaunchCatalog,[{label:'App',value:'Name'},{label:'Category',value:'Category'},{label:'Command',value:'Command'}]);
$('fixes').innerHTML=rows(data.FixQueue,[{label:'Priority',value:'Priority'},{label:'Item',value:'Item'},{label:'Command',value:'Command'}]);
$('models').innerHTML=rows(data.Models,[{label:'Model',value:'Name'},{label:'Status',value:'Status'},{label:'Detail',value:'Detail'}]);
$('reports').innerHTML=rows(data.Reports,[{label:'Report',value:'Name'},{label:'Updated',value:'LastWriteTime'}]);
addMessage('Gorrilla','I am your local operator layer. Tell me the outcome you want, and I will suggest safe steps using your apps, tools, and local AI.');
renderPlan();
</script>
</body>
</html>
'@
}

function New-GorPremiumDashboardHtml {
    return @'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PowerShell Gorrilla Command Centre</title>
<style>
:root{color-scheme:dark;--bg:#070908;--bg2:#0c1110;--panel:#101716;--panel2:#141d1b;--panel3:#182320;--line:#263631;--line2:#355048;--text:#f4f7f4;--muted:#a3b2ad;--soft:#c9d4cf;--green:#6ee7b7;--green2:#2dd4a3;--blue:#8ab8ff;--amber:#f4c76b;--red:#ff7a86;--violet:#bda7ff;--shadow:0 22px 70px rgba(0,0,0,.35)}
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:radial-gradient(circle at top left,rgba(110,231,183,.09),transparent 34%),linear-gradient(180deg,#070908,#0a0e0d 42%,#080a09);color:var(--text);font-family:Segoe UI,Inter,Arial,sans-serif;line-height:1.45}button,input,textarea{font:inherit}button{cursor:pointer}.app{display:grid;grid-template-columns:292px minmax(0,1fr);min-height:100vh}.sidebar{position:sticky;top:0;height:100vh;padding:22px 18px;background:rgba(8,12,11,.92);border-right:1px solid var(--line);backdrop-filter:blur(18px);overflow:auto}.brand{display:grid;grid-template-columns:58px 1fr;gap:12px;align-items:center;margin-bottom:20px}.brand img{width:58px;height:58px;border-radius:16px;border:1px solid var(--line2);object-fit:cover;box-shadow:var(--shadow)}.brand h1{margin:0;font-size:18px;letter-spacing:.01em}.brand p{margin:3px 0 0;color:var(--muted);font-size:12px}.navLabel{margin:18px 9px 8px;color:#6f827c;font-size:11px;text-transform:uppercase;letter-spacing:.12em}.nav a{display:grid;grid-template-columns:28px 1fr auto;gap:10px;align-items:center;padding:10px;border-radius:10px;color:var(--soft);text-decoration:none;margin:3px 0}.nav a:hover{background:var(--panel2);color:var(--text)}.ico{width:28px;height:28px;border-radius:9px;display:grid;place-items:center;background:#13201d;border:1px solid var(--line);color:var(--green)}.ico svg{width:16px;height:16px;stroke:currentColor;fill:none;stroke-width:1.9;stroke-linecap:round;stroke-linejoin:round}.main{padding:24px;max-width:1580px}.hero{display:grid;grid-template-columns:minmax(0,1.1fr) 430px;gap:20px;min-height:520px;align-items:stretch}.heroCopy{padding:42px 0 24px;border-bottom:1px solid var(--line)}.kicker{display:inline-flex;align-items:center;gap:8px;color:var(--green);font-size:12px;text-transform:uppercase;letter-spacing:.12em;font-weight:800}.hero h2{font-size:56px;line-height:1.02;margin:14px 0 16px;letter-spacing:0;max-width:980px}.heroLead{font-size:19px;color:#d3ddd8;max-width:900px;margin:0}.heroActions{display:flex;gap:10px;flex-wrap:wrap;margin-top:24px}.btn{border:1px solid var(--line2);background:#14201d;color:var(--text);border-radius:10px;padding:9px 12px;display:inline-flex;align-items:center;gap:8px;text-decoration:none;min-height:38px}.btn.small{font-size:12px;min-height:32px;padding:6px 9px}.btn.primary{background:linear-gradient(180deg,var(--green),var(--green2));border-color:var(--green);color:#03110d;font-weight:850}.btn.secondary{background:#111916}.btn.ghost{background:transparent}.btn:hover{border-color:var(--green);transform:translateY(-1px)}.gorillaPanel{background:linear-gradient(180deg,#111a18,#0b100f);border:1px solid var(--line);border-radius:18px;padding:18px;display:grid;grid-template-rows:auto 1fr auto;box-shadow:var(--shadow);overflow:hidden}.gorillaPanel img{width:100%;max-width:340px;align-self:center;justify-self:center;border-radius:24px;border:1px solid var(--line2);object-fit:cover}.systemBadges{display:flex;gap:8px;flex-wrap:wrap}.badge{display:inline-flex;align-items:center;gap:7px;border:1px solid var(--line);border-radius:999px;padding:5px 9px;color:var(--muted);font-size:12px}.badge.ok{color:var(--green);border-color:rgba(110,231,183,.45)}.badge.warn{color:var(--amber);border-color:rgba(244,199,107,.45)}.badge.demo{color:var(--blue);border-color:rgba(138,184,255,.45)}.badge.plan{color:var(--violet);border-color:rgba(189,167,255,.45)}.mascotText{color:var(--muted);font-size:13px;margin:10px 0 0}.band{padding:26px 0;border-top:1px solid var(--line)}.sectionHead{display:flex;justify-content:space-between;align-items:end;gap:18px;margin-bottom:14px}.sectionHead h3{font-size:24px;margin:0}.sectionHead p{margin:5px 0 0;color:var(--muted);max-width:850px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:14px}.grid.wide{grid-template-columns:repeat(auto-fit,minmax(300px,1fr))}.card,.panel{background:linear-gradient(180deg,var(--panel),#0d1312);border:1px solid var(--line);border-radius:16px;padding:16px;box-shadow:0 12px 38px rgba(0,0,0,.18)}.cardTop{display:flex;align-items:flex-start;justify-content:space-between;gap:12px;margin-bottom:12px}.card h4,.panel h4{font-size:16px;margin:0 0 7px}.card p,.panel p{color:#bdcac5;font-size:13px;margin:0 0 12px}.outcome b{display:block;font-size:20px;margin-bottom:6px}.actionRow{display:flex;gap:8px;flex-wrap:wrap;margin-top:12px}.meta{display:flex;gap:6px;flex-wrap:wrap;margin-top:10px}.split{display:grid;grid-template-columns:minmax(0,1fr) 420px;gap:16px}.commandCentre{display:grid;grid-template-columns:minmax(0,1fr) 390px;gap:16px}.intentBox{display:grid;grid-template-columns:minmax(0,1fr) auto;gap:10px;margin-top:14px}.intentBox input,.chatInput textarea{background:#0b1110;border:1px solid var(--line2);border-radius:12px;color:var(--text);padding:13px}.intentBox input:focus,.chatInput textarea:focus{outline:1px solid var(--green)}.planList{display:grid;gap:10px;margin-top:12px}.step{border:1px solid var(--line);border-radius:14px;padding:13px;background:#0d1513}.step h4{margin:6px 0;font-size:15px}.step p{margin:0;color:var(--muted);font-size:13px}.integrationGrid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:12px}.integration{position:relative;min-height:170px}.integration .status{position:absolute;top:14px;right:14px}.demoStage{display:grid;grid-template-columns:1.05fr .95fr;gap:16px}.journey{display:grid;gap:10px}.journeyStep{display:grid;grid-template-columns:34px 1fr;gap:10px;align-items:start;padding:12px;border:1px solid var(--line);border-radius:14px;background:#0d1513}.number{width:34px;height:34px;border-radius:11px;display:grid;place-items:center;background:#172620;color:var(--green);border:1px solid var(--line2);font-weight:800}.resultCard{border:1px solid var(--line2);border-radius:16px;background:#0b1210;padding:14px}.resultGrid{display:grid;grid-template-columns:1fr 1fr;gap:10px}.resultBox{border:1px solid var(--line);border-radius:12px;padding:12px;background:#101815}.activity{display:grid;gap:10px}.activityItem{display:grid;grid-template-columns:30px 1fr;gap:10px;padding:11px;border:1px solid var(--line);border-radius:13px;background:#0d1412}.activityItem p{margin:2px 0 0}.processPanel{position:sticky;top:20px}.barShell{height:12px;background:#090e0d;border:1px solid var(--line);border-radius:999px;overflow:hidden;margin:12px 0}.bar{height:100%;width:0;background:linear-gradient(90deg,var(--green),var(--blue));transition:width .3s}.output{font-family:Cascadia Code,Consolas,monospace;font-size:12px;line-height:1.45;background:#070b0a;color:#dce7e2;border:1px solid var(--line);border-radius:12px;padding:12px;white-space:pre-wrap;max-height:360px;overflow:auto}.tableWrap{overflow:auto;border:1px solid var(--line);border-radius:14px}table{width:100%;border-collapse:collapse;font-size:13px}th,td{padding:10px;border-bottom:1px solid var(--line);text-align:left;vertical-align:top}th{font-size:11px;color:#d2ddd8;background:#0c1311;text-transform:uppercase;letter-spacing:.05em}.footer{display:flex;justify-content:space-between;gap:14px;flex-wrap:wrap;color:var(--muted);font-size:12px;padding:20px 0}.brandMark{width:58px;height:58px;border-radius:16px;border:1px solid var(--line2);background:linear-gradient(135deg,#6ee7b7,#8ab8ff 58%,#f4c76b);color:#06100e;display:grid;place-items:center;font-weight:900;box-shadow:var(--shadow)}.brandMark.large{width:64px;height:64px;min-width:64px;border-radius:18px;font-size:24px}.commandPanel{background:linear-gradient(180deg,#111a18,#0b100f);border:1px solid var(--line);border-radius:18px;padding:18px;display:grid;grid-template-rows:auto 1fr auto;gap:16px;box-shadow:var(--shadow);overflow:hidden}.signalGrid{display:grid;grid-template-columns:1fr 1fr;gap:10px;align-content:start}.signalTile{border:1px solid var(--line);border-radius:14px;background:#0d1513;padding:12px;min-height:90px}.signalTile span{display:block;color:var(--muted);font-size:11px;text-transform:uppercase;letter-spacing:.08em}.signalTile b{display:block;font-size:24px;margin-top:5px}.signalTile p{margin:5px 0 0;color:#bdcac5;font-size:12px}.commandDiagram{border:1px solid var(--line2);border-radius:16px;background:linear-gradient(135deg,#0c1412,#101a1d);padding:16px;display:grid;gap:10px}.flowRow{display:grid;grid-template-columns:34px 1fr;gap:10px;align-items:center}.flowDot{width:34px;height:34px;border-radius:11px;display:grid;place-items:center;background:#172620;color:var(--green);border:1px solid var(--line2);font-weight:800}.flowRow h4{margin:0;font-size:14px}.flowRow p{margin:2px 0 0;color:var(--muted);font-size:12px}.heroLogo{display:flex;align-items:center;gap:16px;margin-bottom:20px}.hide{display:none!important}@media(max-width:1120px){.app{grid-template-columns:1fr}.sidebar{position:relative;height:auto}.hero,.split,.commandCentre,.demoStage,.missionGrid{grid-template-columns:1fr}.processPanel{position:relative;top:0}.commandPanel{min-height:0}}@media(max-width:650px){.main{padding:15px}.hero h2{font-size:36px}.intentBox{grid-template-columns:1fr}.hero{min-height:0}.resultGrid,.signalGrid{grid-template-columns:1fr}}
</style>
<style>
.missionGrid{display:grid;grid-template-columns:minmax(0,1fr) minmax(320px,.8fr);gap:14px}.connectorGrid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:12px}.connectorCard{border:1px solid var(--line);border-radius:16px;background:#0d1513;padding:14px;display:grid;gap:10px}.connectorCard h4{margin:0}.connectorCard p{margin:0;color:var(--muted);font-size:13px}.connectorMeta{display:flex;gap:6px;flex-wrap:wrap}.pipelineGrid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:12px}.pipelineCard{border:1px solid var(--line);border-radius:16px;background:#0d1513;padding:14px}.pipelineCard h4{margin:0 0 8px}.pipelineCard p{color:var(--muted);font-size:13px;margin:0 0 10px}.pipelineApps{display:flex;gap:6px;flex-wrap:wrap;margin:8px 0}.pipelineStep{font-size:12px;color:#bdcac5;margin:3px 0}.checkScore{font-size:42px;font-weight:900;line-height:1;color:var(--green)}.checkGrid{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:10px;margin-top:12px}
</style>
<style>
.hero{min-height:360px}.hero h2{font-size:44px}.heroActions{display:none!important}.heroCopy{padding-top:24px}.requestPanel{margin-top:18px}#capabilities .sectionHead p,#integrations .sectionHead p,#activity .sectionHead p{display:none}@media(max-width:650px){.hero h2{font-size:30px}.heroCopy{padding-top:18px}}
</style>
<style>
.hero{grid-template-columns:minmax(0,1fr)!important;min-height:0!important;gap:12px!important}.commandPanel{display:none!important}.heroCopy{padding:18px 0 20px!important}.hero h2{font-size:34px!important;max-width:780px!important}.heroLead{font-size:15px!important;max-width:760px!important}.heroLogo{margin-bottom:10px!important}.brandMark.large{width:42px!important;height:42px!important;min-width:42px!important;border-radius:12px!important;font-size:16px!important}.requestPanel{max-width:860px!important}.aboutGrid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:12px}.aboutCard{border:1px solid var(--line);border-radius:12px;background:#0d1513;padding:13px}.aboutCard h4{margin:0 0 6px;font-size:15px}.aboutCard p{margin:0;color:var(--muted);font-size:12px}.aboutSteps{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:10px;margin-top:12px}.aboutStep{display:grid;grid-template-columns:34px 1fr;gap:10px;border:1px solid var(--line);border-radius:12px;background:#0d1513;padding:11px}.facePanel img,.gorillaPanel img{display:none!important}.facePanel{min-height:0!important}.brand img{width:36px!important;height:36px!important}
</style>
<style>
#starter,#outcomes,#demo,#safety,footer{display:none!important}.sidebar{height:auto;min-height:100vh}.main{max-width:1440px}.operatorGrid{display:grid;grid-template-columns:minmax(0,1.15fr) minmax(360px,.85fr);gap:16px}.appChooser{display:grid;gap:10px}.appSearch{width:100%;background:#0b1110;border:1px solid var(--line2);border-radius:12px;color:var(--text);padding:12px}.appList{display:grid;gap:8px;max-height:430px;overflow:auto;padding-right:4px}.appRow{display:grid;grid-template-columns:1fr auto;gap:10px;align-items:center;border:1px solid var(--line);border-radius:12px;background:#0d1412;padding:11px}.appRow b{display:block}.appRow span{display:block;color:var(--muted);font-size:12px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.contextGrid{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:10px}.promptMatrix{display:grid;grid-template-columns:minmax(0,1fr) minmax(260px,.75fr);gap:14px}.samplePrompt{border:1px solid var(--line);border-radius:12px;background:#0d1513;padding:12px}.samplePrompt p{margin:5px 0 0;color:var(--muted);font-size:12px}@media(max-width:1120px){.operatorGrid,.promptMatrix{grid-template-columns:1fr}.sidebar{min-height:0}}
</style>
<style>
@media(max-width:650px){*{min-width:0}.app,.main,.band,.grid,.grid.wide,.integrationGrid,.demoStage,.commandCentre,.split,.activity{max-width:100%;overflow-x:hidden}.card,.panel,.step,.activityItem,.resultCard,.commandPanel,.requestPanel{max-width:100%}.tableWrap,.output{max-width:100%;overflow-x:auto}}
</style>
<style>
@media(max-width:650px){.band,.sectionHead,.sectionHead>*,.activity,.activityItem,.activityItem>div{min-width:0;max-width:100%}.sectionHead{display:block}.activityItem{grid-template-columns:30px minmax(0,1fr)}.activityItem p,.activityItem h4{overflow-wrap:anywhere}}
</style>
<style>
@media(max-width:650px){body{overflow-x:hidden}.sidebar,.main{max-width:100vw}.main{padding:15px}.hero h2{font-size:32px;overflow-wrap:break-word}.heroLead,.heroLogo span,.brand p{overflow-wrap:anywhere}.heroLogo>div:last-child{min-width:0}.heroActions .btn,#starter .btn{max-width:100%;white-space:normal}.intentBox{grid-template-columns:1fr}.hero{min-height:0}.resultGrid,.signalGrid{grid-template-columns:1fr}}
</style>
<style>
.doGrid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:12px}.doCard{border:1px solid var(--line);border-radius:14px;background:linear-gradient(180deg,#101816,#0c1210);padding:14px;min-height:145px}.doCard h4{margin:0 0 7px;font-size:15px}.doCard p{margin:0;color:var(--muted);font-size:12px}.pageSummary{display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:10px;margin-bottom:12px}.packageGrid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:12px}.packageCard{border:1px solid var(--line);border-radius:14px;background:#0d1513;padding:13px;display:grid;gap:8px}.packageCard h4{margin:0;font-size:15px}.packageCard p{margin:0;color:var(--muted);font-size:12px}.pageActions{display:flex;gap:8px;flex-wrap:wrap;margin-top:16px}.pageActions .btn{min-height:34px;padding:7px 10px}.aiFriendGrid{display:grid;grid-template-columns:minmax(0,1fr) minmax(280px,.55fr);gap:14px}.iconBuilderLayout{display:grid;grid-template-columns:minmax(320px,.95fr) minmax(0,1.25fr);gap:16px}.iconBuilderControls{display:grid;grid-template-columns:minmax(0,1fr) minmax(140px,200px) repeat(3,auto);gap:8px;align-items:center;margin-bottom:12px}.iconToggle{display:inline-flex;align-items:center;gap:6px;color:var(--muted);font-size:12px;white-space:nowrap}.iconGrid{display:grid;grid-template-columns:repeat(auto-fill,minmax(118px,1fr));gap:10px;max-height:620px;overflow:auto;padding-right:4px}.iconTile{border:1px solid var(--line);border-radius:14px;background:#0d1513;padding:10px;display:grid;gap:7px;text-align:left;color:var(--text)}.iconTile.active,.iconTile:hover{border-color:var(--green);background:#111d19}.appIconImg{width:44px;height:44px;border-radius:11px;object-fit:contain;background:#101916;border:1px solid var(--line2);padding:5px}.iconTile b{font-size:13px;line-height:1.2;min-height:32px}.iconTile span{color:var(--muted);font-size:11px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.builderCanvas{display:grid;gap:12px}.slotRow{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:10px}.dropSlot{min-height:132px;border:1px dashed var(--line2);border-radius:16px;background:#0b1110;display:grid;place-items:center;text-align:center;padding:12px;color:var(--muted)}.dropSlot.filled{border-style:solid;border-color:var(--green);background:#0f1a16;color:var(--text)}.equation{display:flex;gap:10px;flex-wrap:wrap;align-items:center;border:1px solid var(--line);border-radius:16px;background:#0d1513;padding:12px}.equationApp{display:flex;align-items:center;gap:8px}.equationSymbol{color:var(--green);font-weight:900}.workflowResultGrid{display:grid;gap:12px}.workflowCard{border:1px solid var(--line);border-radius:16px;background:linear-gradient(180deg,#101816,#0b1110);padding:14px}.workflowCard h4{margin:8px 0 6px}.workflowCard p{margin:0 0 10px;color:var(--muted);font-size:13px}.suggestionStrip{display:flex;gap:8px;flex-wrap:wrap}.suggestionStrip button{border:1px solid var(--line);background:#111916;color:var(--text);border-radius:999px;padding:6px 9px;font-size:12px}.planPreview{min-height:190px}.favouriteNotice{color:var(--muted);font-size:12px}@media(max-width:980px){.iconBuilderLayout{grid-template-columns:1fr}.iconBuilderControls{grid-template-columns:1fr 1fr}.slotRow{grid-template-columns:1fr 1fr}}@media(max-width:900px){.aiFriendGrid{grid-template-columns:1fr}.nav a{grid-template-columns:28px 1fr}.nav a span:last-child{display:none}}@media(max-width:560px){.slotRow,.iconBuilderControls{grid-template-columns:1fr}.iconGrid{grid-template-columns:repeat(auto-fill,minmax(105px,1fr))}}
</style>
</head>
<body>
<script id="gor-data" type="application/json">__GOR_DATA__</script>
<div class="app">
<aside class="sidebar">
  <div class="brand"><div class="brandMark" aria-hidden="true">PG</div><div><h1>PowerShell Gorrilla</h1><p>Local-first command centre</p></div></div>
  <div class="navLabel">Command centre</div>
  <nav class="nav">
    <a href="#hero"><span class="ico" data-icon="dashboard"></span><span>Overview</span></a>
    <a href="#outcomes"><span class="ico" data-icon="target"></span><span>Outcomes</span></a>
    <a href="#capabilities"><span class="ico" data-icon="apps"></span><span>Capabilities</span></a>
    <a href="#integrations"><span class="ico" data-icon="integrations"></span><span>Integrations</span></a>
    <a href="#icon-builder"><span class="ico" data-icon="apps"></span><span>Icon Builder</span></a>
    <a href="#demo"><span class="ico" data-icon="showcase"></span><span>Demo Mode</span></a>
    <a href="#operate"><span class="ico" data-icon="tools"></span><span>Operate</span></a>
    <a href="#activity"><span class="ico" data-icon="logs"></span><span>Activity</span></a>
    <a href="#safety"><span class="ico" data-icon="shield"></span><span>Safety</span></a>
  </nav>
</aside>
<main class="main">
  <section id="hero" class="hero">
    <div class="heroCopy">
      <div class="heroLogo">
        <div class="brandMark large" aria-hidden="true">PG</div>
      <div><strong style="display:block;font-size:20px">PowerShell Gorrilla</strong><span style="display:block;color:var(--muted);font-size:13px;margin-top:4px">Check apps. Start workflows. Keep proof.</span></div>
      </div>
      <span class="kicker"><span class="ico" data-icon="dashboard"></span> Local app control</span>
      <h2>Make your apps work as one team.</h2>
      <p class="heroLead">Gorilla checks which apps are ready, picks the right workflow, then runs safe steps behind the app while you see outcomes, project packs, and proof. Start with Connector Passport or Book Factory.</p>
      <div class="heroActions">
        <button class="btn primary" data-scroll="#operate"><span class="ico" data-icon="target"></span> Start guided command</button>
        <button class="btn secondary" data-scroll="#demo"><span class="ico" data-icon="showcase"></span> Show demo mode</button>
        <button class="btn ghost" data-run="gordo now"><span class="ico" data-icon="health"></span> Check system now</button>
      </div>
      <div class="requestPanel">
        <label for="intent">Ask Gorrilla</label>
        <div class="intentBox">
          <input id="intent" placeholder="Example: check app connections, create a book pack, clean old backups, scan my laptop">
          <button class="btn primary" id="askBtn">Ask / Do</button>
        </div>
        <p class="requestHint">Use plain English. Gorilla will show the next safe steps before running anything.</p>
        <div id="requestAnswer" class="requestAnswer"></div>
      </div>
      <div class="meta" id="starter"></div>
    </div>
    <aside class="commandPanel">
      <div class="systemBadges" id="systemBadges"></div>
      <div class="signalGrid" id="heroSignals"></div>
      <div class="commandDiagram" aria-label="Local command flow">
        <div class="flowRow"><div class="flowDot">1</div><div><h4>Check apps</h4><p>See what is installed, signed in, or missing.</p></div></div>
        <div class="flowRow"><div class="flowDot">2</div><div><h4>Pick workflow</h4><p>Choose Book Factory, reports, repair, or design.</p></div></div>
        <div class="flowRow"><div class="flowDot">3</div><div><h4>Run safely</h4><p>Get output and keep evidence.</p></div></div>
      </div>
    </aside>
  </section>

  <section id="about" class="band">
    <div class="sectionHead"><div><h3>What Gorilla Does</h3><p>Three jobs: check app connections, start useful workflow packs, and keep a clean evidence trail.</p></div></div>
    <div class="aboutGrid">
      <article class="aboutCard"><h4>Connector Passport</h4><p>Shows whether Word, Canva, Adobe, app-window web tools, local AI, and Gorilla are ready, missing, or need sign-in confirmation.</p></article>
      <article class="aboutCard"><h4>Workflow Packs</h4><p>Turns big jobs into steps, starting with Book Factory: plan, write, cover, size, illustrate, and package.</p></article>
      <article class="aboutCard"><h4>Safe Runner</h4><p>Runs approved local actions and records output so you can see what happened.</p></article>
      <article class="aboutCard"><h4>Clean Workspace</h4><p>Keeps one solid backup and removes old generated test clutter only after preview.</p></article>
    </div>
    <div class="aboutSteps">
      <div class="aboutStep"><span class="number">1</span><div><b>Check readiness</b><p>Run Connector Passport first.</p></div></div>
      <div class="aboutStep"><span class="number">2</span><div><b>Choose a pack</b><p>Start Book Factory or another workflow.</p></div></div>
      <div class="aboutStep"><span class="number">3</span><div><b>Run with proof</b><p>Every step returns output and evidence.</p></div></div>
    </div>
  </section>

  <section id="mission" class="band">
    <div class="sectionHead"><div><h3>World-Class Direction</h3><p id="visionDirection">The product strategy appears here from the local Gorilla brain.</p></div><button class="btn primary" data-run="gorconnectors">Check connectors</button></div>
    <div class="missionGrid">
      <article class="panel"><h4 id="visionName">Gorilla Command OS</h4><p id="visionOneLine"></p><div class="resultBox" id="visionNorthStar"></div></article>
      <article class="panel"><h4>Operating principles</h4><div class="activity" id="visionPrinciples"></div></article>
    </div>
  </section>

  <section id="connector-passport" class="band">
    <div class="sectionHead"><div><h3>Connector Passport</h3><p>Answers the question: can Gorilla use this app right now?</p></div><button class="btn primary" data-run="gorconnectors">Refresh passport</button></div>
    <div class="connectorGrid" id="connectorGrid"></div>
  </section>

  <section id="workflow-packs" class="band">
    <div class="sectionHead"><div><h3>Workflow Packs</h3><p>Pick a ready-made job. Gorilla creates the plan, opens the right tools, and keeps the trail.</p></div><button class="btn primary" data-run="gorbook &quot;My Book&quot;">Start book factory</button></div>
    <div class="pipelineGrid" id="workflowPackGrid"></div>
  </section>

  <section id="cleanliness" class="band operatorGrid">
    <div class="panel">
      <div class="sectionHead"><div><h3>Backup Discipline</h3><p>Gorilla keeps useful evidence and removes old generated clutter deliberately. Preview first, then apply only with confirmation.</p></div><button class="btn primary" data-run="gorkeeponebackup preview">Preview cleanup</button></div>
      <div class="checkGrid" id="backupPostureGrid"></div>
    </div>
    <div class="panel processPanel">
      <h4>Cleanup rule</h4>
      <pre class="output" id="backupPostureOutput">Only the newest solid module backup and newest generated book project pack are kept by the cleanup command.</pre>
    </div>
  </section>

  <section id="operator" class="band operatorGrid">
    <div class="panel">
      <div class="sectionHead"><div><h3>App Operator</h3><p>Choose any discovered app or shortcut on this laptop. Gorrilla can launch it, include it in the plan, and use the app list when routing Ollama.</p></div></div>
      <div class="appChooser">
        <input id="appSearch" class="appSearch" placeholder="Search installed apps, shortcuts, tools, folders...">
        <div class="appList" id="installedAppList"></div>
      </div>
    </div>
    <div class="panel">
      <div class="sectionHead"><div><h3>Laptop Reality</h3><p>Live local signals for AI routing: ports, processes, disk, services, errors, network, models, and risk notes.</p></div></div>
      <div class="contextGrid" id="laptopContextGrid"></div>
      <div id="laptopContextDetail" class="activity" style="margin-top:12px"></div>
    </div>
  </section>

  <section id="prompt-matrix" class="band promptMatrix">
    <div class="panel">
      <div class="sectionHead"><div><h3>Ollama Prompt Matrix</h3><p>Generated operator prompts cover app choice, laptop inspection, repair planning, launch routing, testing, security, cleanup, and reporting without storing a massive slow file.</p></div></div>
      <div class="contextGrid" id="promptMatrixStats"></div>
    </div>
    <div class="panel">
      <h4>Prompt samples</h4>
      <div id="promptSamples" class="activity"></div>
    </div>
  </section>

  <section id="creative-pipelines" class="band">
    <div class="sectionHead"><div><h3>Creative Pipelines</h3><p>Use 2-3 apps together to make something bigger: design, edit, capture, record, or present. Pick a pipeline and Gorrilla creates a local project pack with steps and app choices.</p></div></div>
    <div class="pipelineGrid" id="pipelineGrid"></div>
  </section>

  <section id="huge-check" class="band operatorGrid">
    <div class="panel">
      <div class="sectionHead"><div><h3>Huge Check Over</h3><p>A broad readiness check over the app, installed apps, creative pipelines, laptop context, Ollama, prompt matrix, reports, and alerts.</p></div><button class="btn primary" id="hugeCheckBtn">Run huge check</button></div>
      <div class="checkGrid" id="hugeCheckGrid"></div>
    </div>
    <div class="panel processPanel"><h4>Huge check output</h4><pre class="output" id="hugeCheckOutput">No huge check has run in this screen yet.</pre></div>
  </section>
  <section id="design-studio" class="band operatorGrid">
    <div class="panel">
      <div class="sectionHead"><div><h3>Design Studio</h3><p>Pick a creative app, generate a clear brief, then open the right tool. This is built for Canva, Figma, GIMP, Krita, Blender, OBS, ShareX, and similar apps found on the laptop.</p></div></div>
      <div class="intentBox">
        <input id="designGoal" placeholder="Example: bold poster explaining PowerShell Gorrilla as a local AI command centre">
        <button class="btn primary" id="designBriefBtn">Create brief</button>
      </div>
      <div class="appList" id="designAppList" style="margin-top:12px"></div>
    </div>
    <div class="panel processPanel">
      <div class="cardTop"><div><h4>Design output</h4><p>Briefs are saved locally in Reports so you can use them in Canva, Figma, GIMP, or another design app.</p></div><span class="badge ok">Local file</span></div>
      <pre class="output" id="designOutput">Create a design brief to start.</pre>
    </div>
  </section>

  <section id="outcomes" class="band">
    <div class="sectionHead"><div><h3>Outcome Overview</h3><p>Instead of showing raw commands first, the app explains the real-world results you can get from the command centre.</p></div></div>
    <div class="grid" id="outcomeGrid"></div>
  </section>

  <section id="capabilities" class="band">
    <div class="sectionHead"><div><h3>Main Capability Grid</h3><p>Every card explains what it does, why it matters, and what happens when you choose the action.</p></div></div>
    <div class="grid wide" id="capabilityGrid"></div>
  </section>

  <section id="integrations" class="band">
    <div class="sectionHead"><div><h3>Integration Universe</h3><p>A truthful map of what is available now, what is ready to connect, what is demo-preview, and what is planned.</p></div></div>
    <div class="integrationGrid" id="integrationUniverse"></div>
  </section>

  <section id="icon-builder" class="band">
    <div class="sectionHead"><div><h3>Visual App Icon Builder</h3><p>Select or drag 2, 3, or 4 local app icons to see matching workflows from your integration CSV brain. This page only previews plans and exports local notes.</p></div><button class="btn secondary" id="clearIconBuilder">Clear selection</button></div>
    <div class="pageSummary" id="iconBuilderStats"></div>
    <div class="iconBuilderLayout">
      <div class="panel">
        <div class="iconBuilderControls">
          <input id="iconSearch" class="appSearch" placeholder="Search apps, categories, status...">
          <select id="workflowFilter" class="appSearch" title="Filter workflow type">
            <option value="">All workflows</option>
            <option value="easy">Easy</option>
            <option value="powerful">Powerful</option>
            <option value="fixer">Computer fixer</option>
            <option value="updater">Updater</option>
            <option value="creative">Creative</option>
            <option value="automation">Automation-ready</option>
          </select>
          <label class="iconToggle"><input type="checkbox" id="filterInstalled"> Installed</label>
          <label class="iconToggle"><input type="checkbox" id="filterLocal"> Local</label>
          <label class="iconToggle"><input type="checkbox" id="filterFree"> Free/open</label>
        </div>
        <div class="iconGrid" id="appIconGrid"></div>
      </div>
      <div class="builderCanvas">
        <div class="panel">
          <div class="slotRow" id="builderSlots"></div>
          <div class="equation" id="builderEquation"></div>
          <div class="suggestionStrip" id="builderSuggestions"></div>
        </div>
        <div class="workflowResultGrid" id="builderResults"></div>
        <div class="panel">
          <div class="cardTop"><div><h4>Safe PowerShell Plan Preview</h4><p>Generated plans are text only. They do not run updates, fixes, installs, deletes, or credential actions.</p></div><span class="badge ok">Preview only</span></div>
          <pre class="output planPreview" id="builderPlanPreview">Select 2, 3, or 4 apps to generate a safe local workflow plan.</pre>
          <p class="favouriteNotice" id="favouriteNotice">Favourites are stored locally in this browser for this dashboard.</p>
        </div>
      </div>
    </div>
  </section>

  <section id="demo" class="band">
    <div class="sectionHead"><div><h3>Demo Mode: Connected Command Journey</h3><p>A polished showcase of the maximum-capability vision without pretending every connector is already wired.</p></div><button class="btn primary" id="demoBtn"><span class="ico" data-icon="showcase"></span> Run demo preview</button></div>
    <div class="demoStage">
      <div class="journey" id="demoJourney"></div>
      <div class="resultCard">
        <h4>Example outcome summary</h4>
        <p id="demoSummary">Choose Run demo preview to see how Gorrilla explains a connected workflow.</p>
        <div class="resultGrid" id="demoResults"></div>
      </div>
    </div>
  </section>

  <section id="operate" class="band commandCentre">
    <div>
    <div class="sectionHead"><div><h3>Operate With Purpose</h3><p>These actions are connected to the existing PowerShell backend, but this screen stays outcome-first.</p></div></div>
      <div class="planList" id="planPanel"></div>
      <div class="grid wide" id="actionGrid"></div>
    </div>
    <aside class="panel processPanel">
      <div class="cardTop"><div><h4>Activity and results</h4><p>Progress and outcome summaries appear here. Detailed command work stays behind the scenes in reports and the local API.</p></div><span class="badge ok">Local API</span></div>
      <p id="taskStatus">Ready. Choose a purposeful action to begin.</p>
      <div class="barShell"><div class="bar" id="taskBar"></div></div>
      <pre class="output" id="taskOutput">No outcome has been produced in this session yet.</pre>
    </aside>
  </section>

  <section id="activity" class="band split">
    <div>
      <div class="sectionHead"><div><h3>Activity Feed</h3><p>Human-readable recent actions, demo events, and useful system signals.</p></div></div>
      <div class="activity" id="activityFeed"></div>
    </div>
    <div class="panel">
      <h4>Smart empty states</h4>
      <p id="emptyStateText">If a section has no saved data yet, the app explains what to do next instead of showing an empty box.</p>
      <div id="detailPanels"></div>
    </div>
  </section>

  <section id="safety" class="band">
    <div class="sectionHead"><div><h3>Safety, Settings, and Local-First Behaviour</h3><p>Power is only useful when it is controlled. Gorrilla separates low-risk actions from actions that need confirmation.</p></div></div>
    <div class="grid" id="safetyGrid"></div>
  </section>

  <footer class="footer"><span id="footerStatus"></span><span>Advanced data remains available through reports, logs, and the local API.</span></footer>
</main>
</div>
<style>
.taskPopup{position:fixed;right:22px;bottom:22px;z-index:80;width:min(460px,calc(100vw - 32px));background:linear-gradient(180deg,#121d1a,#0a100f);border:1px solid var(--line2);border-radius:18px;box-shadow:0 26px 90px rgba(0,0,0,.55);padding:15px;display:none}.taskPopup.active{display:block}.taskPopupHead{display:flex;justify-content:space-between;gap:12px;align-items:flex-start}.taskPopup h4{margin:0 0 4px;font-size:15px}.taskPopup p{margin:0;color:var(--muted);font-size:12px}.taskPopup .output{max-height:190px;margin-top:10px}.taskPopupClose{width:34px;height:34px;border-radius:10px;border:1px solid var(--line);background:#111916;color:var(--text)}.taskPulse{width:9px;height:9px;border-radius:999px;background:var(--green);box-shadow:0 0 0 0 rgba(110,231,183,.5);animation:pulse 1.4s infinite}.taskPopup.done .taskPulse{background:var(--blue);animation:none}.taskPopup.error .taskPulse{background:var(--red);animation:none}@keyframes pulse{70%{box-shadow:0 0 0 10px rgba(110,231,183,0)}100%{box-shadow:0 0 0 0 rgba(110,231,183,0)}}@media(max-width:650px){.taskPopup{right:12px;bottom:12px;width:calc(100vw - 24px)}}
</style>
<div class="taskPopup" id="taskPopup" role="status" aria-live="polite">
  <div class="taskPopupHead">
    <div><div class="taskPulse"></div><h4 id="taskPopupTitle">Task running</h4><p id="taskPopupStatus">Preparing...</p></div>
    <button class="taskPopupClose" id="taskPopupClose" title="Hide task popup">x</button>
  </div>
  <div class="barShell"><div class="bar" id="taskPopupBar"></div></div>
  <pre class="output" id="taskPopupOutput">Waiting for the outcome...</pre>
</div>
<script>
const data = JSON.parse(document.getElementById('gor-data').textContent);
const $ = id => document.getElementById(id);
const esc = value => String(value ?? '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
const iconPaths={dashboard:'M4 13h7V4H4v9Zm9 7h7V4h-7v16ZM4 20h7v-5H4v5Z',target:'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18Zm0-4a5 5 0 1 0 0-10 5 5 0 0 0 0 10Zm0-3a2 2 0 1 0 0-4 2 2 0 0 0 0 4Z',apps:'M4 4h7v7H4V4Zm9 0h7v7h-7V4ZM4 13h7v7H4v-7Zm9 0h7v7h-7v-7Z',integrations:'M7 8a3 3 0 1 0 0-6 3 3 0 0 0 0 6Zm10 14a3 3 0 1 0 0-6 3 3 0 0 0 0 6ZM7 8v3a3 3 0 0 0 3 3h4a3 3 0 0 1 3 3v-1',tools:'M14 7l3-3 3 3-3 3-3-3ZM4 20l7-7m0 0 3 3m-3-3-3-3',media:'M5 4h14v16H5V4Zm4 4 6 4-6 4V8Z',devices:'M7 4h10v16H7V4Zm3 13h4',health:'M20 12h-4l-2 5-4-10-2 5H4',settings:'M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8Zm0-5v3m0 12v3M4.2 4.2l2.1 2.1m11.4 11.4 2.1 2.1M3 12h3m12 0h3M4.2 19.8l2.1-2.1M17.7 6.3l2.1-2.1',logs:'M5 4h14v16H5V4Zm4 5h6M9 13h6M9 17h4',shield:'M12 3l7 3v5c0 5-3 8-7 10-4-2-7-5-7-10V6l7-3Z',showcase:'M4 5h16v10H4V5Zm5 14h6m-3-4v4',cloud:'M7 18h10a4 4 0 0 0 0-8 6 6 0 0 0-11-2 5 5 0 0 0 1 10Z'};
function icon(name){return `<span class="ico"><svg viewBox="0 0 24 24"><path d="${iconPaths[name]||iconPaths.dashboard}"/></svg></span>`}
function paintIcons(){document.querySelectorAll('[data-icon]').forEach(el=>{el.innerHTML=`<svg viewBox="0 0 24 24"><path d="${iconPaths[el.dataset.icon]||iconPaths.dashboard}"/></svg>`})}
function badge(label,type='demo'){return `<span class="badge ${type}">${esc(label)}</span>`}
function statusClass(value){const v=String(value||'').toUpperCase();if(v.includes('FAIL')||v.includes('HIGH'))return'warn';if(v.includes('WARN')||v.includes('MEDIUM')||v.includes('MISSING'))return'warn';return'ok'}
function actionButton(label,command,style='secondary'){return `<button class="btn ${style}" data-run="${esc(command)}">${esc(label)}</button>`}
function labelForCommand(commandText){const c=String(commandText||'');if(c.includes('gorconnectors'))return'Check passport';if(c.includes('gorbook'))return'Create book plan';if(c.includes('gorkeeponebackup'))return'Preview cleanup';if(c.includes('gorsecurity'))return'Scan safety';if(c.includes('gordoctor'))return'Analyse project';if(c.includes('gorappdiscover'))return'Discover apps';if(c.includes('gorlaptopscan'))return'Scan laptop';if(c.includes('gorlaunch'))return'Launch app';if(c.includes('gorports'))return'Check ports';if(c.includes('gorservices'))return'Check services';if(c.includes('gornetwork'))return'Check connection';if(c.includes('gorupdate'))return'Preview update';if(c.includes('gorbackup'))return'Back up';if(c.includes('gorworkflow'))return'Preview workflow';if(c.includes('gorintegrate'))return'View integrations';if(c.includes('gorfixqueue'))return'View fixes';if(c.includes('goradvisor'))return'Get advice';if(c.includes('gordo now'))return'Check status';if(c.includes('gordo ai'))return'Check AI lab';if(c.includes('gortest'))return'Test system';if(c.includes('gorvisual'))return'Open dashboard';return'View result'}
function cleanOutcomeText(value){return String(value||'').replace(/\r/g,'').split('\n').map(x=>x.trim()).filter(Boolean).filter(x=>!x.match(/^(VERBOSE|DEBUG|WARNING):/i)).slice(0,5).join('\n')}
function outcomeForTask(task){const label=labelForCommand(task.Command);const state=String(task.Status||'').toLowerCase();if(state==='failed'||state==='stopped')return `${label} needs attention.\nThe detailed failure is saved behind the app for review.`;if(state==='running'||state==='notstarted')return `${label} is working inside the local runner.\nYou can keep using the app while the behind-the-scenes work finishes.`;const text=cleanOutcomeText(task.Output);if(text)return `${label} complete.\n${text}`;return `${label} complete.\nThe app state, reports, or connector passport has been refreshed.`}
function rows(items,cols){const arr=Array.isArray(items)?items:[];if(!arr.length)return '<p>No saved data yet. Start with a scan or connect an app to populate this area.</p>';return `<div class="tableWrap"><table><thead><tr>${cols.map(c=>`<th>${esc(c.label)}</th>`).join('')}</tr></thead><tbody>${arr.slice(0,6).map(item=>`<tr>${cols.map(c=>`<td>${esc(typeof c.value==='function'?c.value(item):item[c.value])}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`}
const outcomes=[
 ['Control','One cockpit to open tools, start checks, and see results without hunting through folders.', 'dashboard'],
 ['Organisation','Keeps app data, launchers, reports, and evidence structured away from the desktop mess.', 'apps'],
 ['Automation','Turns repeatable tasks into guided routes with visible progress and outcome summaries.', 'settings'],
 ['Diagnostics','Scans ports, services, app state, project quality, and common local problems.', 'health'],
 ['Media and devices','Creates a place for Firestick, Android TV, media library, and device workflows to live.', 'devices'],
 ['Local-first intelligence','Uses Ollama/local models where available and labels anything not connected yet.', 'shield'],
 ['Integration expansion','Shows the possible universe clearly without pretending planned connectors are finished.', 'integrations']
];
const capabilities=[
 {icon:'integrations',title:'Connector Passport',body:'Checks which apps are installed, launchable, local-ready, or still need visible sign-in confirmation.',outcome:'Outcome: truthful app readiness before automation.',label:'Check passport',cmd:'gorconnectors',status:'Available now'},
 {icon:'media',title:'Book Factory',body:'Creates the flagship workflow plan across local AI, Word, Canva, Adobe, and Gorilla evidence.',outcome:'Outcome: a governed multi-app production pack.',label:'Create book plan',cmd:'gorbook "My Book"',status:'Available now'},
 {icon:'dashboard',title:'Launch Command Centre',body:'Opens the local dashboard and refreshes current status. Use this when you want the main visual control room.',outcome:'Outcome: a live, local command screen.',label:'Open command centre',cmd:'gorvisual',status:'Available now'},
 {icon:'health',title:'Run Safe Diagnostic',body:'Checks the local stack, highlights issues, and returns a clean outcome summary to the activity panel.',outcome:'Outcome: know what needs attention.',label:'Run diagnostic',cmd:'gordo now',status:'Available now'},
 {icon:'apps',title:'Open App Manager',body:'Shows saved app profiles and launchable tools so the system can grow beyond one project.',outcome:'Outcome: see what Gorrilla can control.',label:'View apps',cmd:'gorintegrate',status:'Available now'},
 {icon:'integrations',title:'Discover installed apps',body:'Scans the laptop for shortcuts, start menu links, and installed Windows launchers.',outcome:'Outcome: a complete local app inventory.',label:'Discover apps',cmd:'gorappdiscover',status:'Available now'},
 {icon:'devices',title:'Laptop-wide assessment',body:'Runs a full local scan of security, performance, and integration posture.',outcome:'Outcome: a single report of the machine health.',label:'Scan laptop',cmd:'gorlaptopscan',status:'Available now'},
 {icon:'tools',title:'Analyse Project Health',body:'Inspects a project for files, configuration, risks, dependencies, and repair signals.',outcome:'Outcome: get a project health picture.',label:'Analyse FireDesk',cmd:'gordoctor FireDesk',status:'Available now'},
 {icon:'shield',title:'Scan Safety and Exposure',body:'Looks for bind-address risks, debug settings, secret-like strings, and unsafe local exposure.',outcome:'Outcome: safer local apps.',label:'Scan safety',cmd:'gorsecurity FireDesk',status:'Available now'},
 {icon:'media',title:'Prepare Media Workflow',body:'Frames image-to-design-to-copy workflows and opens the design step when tools are present.',outcome:'Outcome: a guided creative route.',label:'Preview workflow',cmd:'gorworkflow list',status:'Ready to connect'},
 {icon:'devices',title:'Device Diagnostics',body:'Provides the product space for Firestick and Android TV checks such as connection, storage, app status, and common issues.',outcome:'Outcome: device health in one place.',label:'Show demo',cmd:'gorfiredesk',status:'Demo preview'},
 {icon:'settings',title:'Update Safely',body:'Previews updates, checks backup posture, and keeps rollback thinking visible before changes.',outcome:'Outcome: safer upgrades.',label:'Preview update',cmd:'gorupdate preview',status:'Available now'},
 {icon:'logs',title:'One Solid Backup',body:'Previews old generated backup clutter while keeping the newest solid module backup and project pack.',outcome:'Outcome: clean app state without losing the useful rollback point.',label:'Preview cleanup',cmd:'gorkeeponebackup preview',status:'Available now'}
];
const integrations=[
 ['Connector Passport','Truth status for local AI, Word, Canva, Adobe, app-window web tools, and Gorilla.', 'Available now','ok','integrations'],
 ['Book Factory','Flagship multi-app workflow: plan, write, cover, size, illustrate, package.', 'Available now','ok','media'],
 ['Local apps','Launchers, app profiles, reports, and local folders.', 'Available now','ok','apps'],
 ['Ollama/local AI','Local model readiness and helper planning.', data.Status.OllamaAvailable?'Available now':'Ready to connect', data.Status.OllamaAvailable?'ok':'plan','dashboard'],
 ['Firestick / Android TV','Device health, media workflows, and diagnostics surface.', 'Demo preview','demo','devices'],
 ['Media libraries','Scan, organise, summarize, and package media output.', 'Planned','plan','media'],
 ['Automation scripts','PowerShell-backed safe routes with progress and outcome summaries.', 'Available now','ok','settings'],
 ['File scanning','Project indexing, text search, app doctor, and reports.', 'Available now','ok','logs'],
 ['Desktop shortcuts','Clean launcher and hidden app data root.', 'Available now','ok','apps'],
 ['Email / calendar','Future connector space for briefings and scheduling.', 'Planned','plan','cloud'],
 ['Reports / backups','HTML reports, ledgers, snapshots, one-solid-backup posture, and restore routes.', 'Available now','ok','shield'],
 ['Home dashboard','A future always-on status wall for apps and devices.', 'Planned','plan','showcase']
];
const demoJourney=[
 ['Capture request','User asks for an outcome such as turn this picture into a design and written post.'],
 ['Understand locally','Gorrilla checks intent, available tools, risk level, and whether Ollama can help.'],
 ['Open the right tool','Design, API, app, or diagnostic tool is launched from the command centre.'],
 ['Run safe checks','PowerShell tasks run behind the scenes while this screen stays focused on progress and outcomes.'],
 ['Deliver result','Reports, logs, summaries, and next actions are saved for review.']
];
const safety=[
 ['Local-first by default','The dashboard binds to 127.0.0.1 and stores data under LocalAppData, not scattered on the desktop.','shield'],
 ['Risk-aware actions','Medium and high-risk actions require explicit confirmation before the backend runs them.','health'],
 ['Truthful integrations','Unavailable connectors are labelled Ready to connect, Demo preview, or Planned.','integrations'],
 ['Evidence trail','Reports, activity, ledgers, and outcome summaries make it clear what happened.','logs']
];
function renderOutcomes(){ $('outcomeGrid').innerHTML=outcomes.map(o=>`<article class="card outcome">${icon(o[2])}<b>${esc(o[0])}</b><p>${esc(o[1])}</p></article>`).join('') }
function renderCapabilities(){ $('capabilityGrid').innerHTML=capabilities.map(c=>`<article class="card"><div class="cardTop"><div>${icon(c.icon)}</div>${badge(c.status,c.status==='Available now'?'ok':c.status==='Planned'?'plan':'demo')}</div><h4>${esc(c.title)}</h4><p>${esc(c.body)}</p><p><b>${esc(c.outcome)}</b></p><div class="actionRow">${actionButton(c.label,c.cmd,'primary')}</div></article>`).join('') }
function renderIntegrations(){ $('integrationUniverse').innerHTML=integrations.map(i=>`<article class="card integration"><div class="status">${badge(i[2],i[3])}</div>${icon(i[4])}<h4>${esc(i[0])}</h4><p>${esc(i[1])}</p><div class="actionRow"><button class="btn small secondary" data-scroll="#demo">${i[2]==='Available now'?'View route':'Preview role'}</button></div></article>`).join('') }
const iconBuilder=data.IntegrationBuilder||{Apps:[],Workflows:[],Stats:{},Sources:[],Safety:{}};let builderSelection=[];
function ibNorm(value){return String(value||'').toLowerCase().replace(/\.lnk$/,'').replace(/\s+\(\d+\)$/,'').replace(/\s+/g,' ').trim()}
function ibApps(){return Array.isArray(iconBuilder.Apps)?iconBuilder.Apps:[]}
function ibWorkflows(){return Array.isArray(iconBuilder.Workflows)?iconBuilder.Workflows:[]}
function appByName(name){const key=ibNorm(name);return ibApps().find(a=>ibNorm(a.Name)===key)||{Name:name,IconUrl:'gorrilla-launcher.ico',Status:'Missing',Category:'Unknown',LicenseMode:'Unknown'}}
function workflowTypeMatch(w,type){const hay=`${w.WorkflowName} ${w.WhatCanDo} ${w.BestUse} ${w.Category} ${w.Pattern} ${w.Difficulty} ${w.AutomationReadiness}`.toLowerCase();if(!type)return true;if(type==='easy')return hay.includes('easy');if(type==='powerful')return hay.includes('power')||hay.includes('advanced');if(type==='fixer')return hay.includes('fix')||hay.includes('repair')||hay.includes('clean')||hay.includes('maintenance');if(type==='updater')return hay.includes('update')||hay.includes('upgrade');if(type==='creative')return hay.includes('creative')||hay.includes('media')||hay.includes('image')||hay.includes('audio')||hay.includes('publish');if(type==='automation')return hay.includes('auto')||String(w.AutomationReadiness||'').toLowerCase().includes('preview');return true}
function selectedKeys(){return builderSelection.map(a=>ibNorm(a.Name))}
function workflowContainsSelection(w){const keys=(w.Apps||[]).map(ibNorm);return selectedKeys().every(k=>keys.includes(k))}
function exactWorkflowMatches(){const count=builderSelection.length;if(count<2)return[];const type=$('workflowFilter')?.value||'';return ibWorkflows().filter(w=>Number(w.Size)===count&&workflowContainsSelection(w)&&workflowTypeMatch(w,type)).sort((a,b)=>scoreWorkflow(b)-scoreWorkflow(a)).slice(0,10)}
function scoreWorkflow(w){let s=0;if(w.LocalOnly)s+=6;if(String(w.FreeOpenSourceStatus||'').toLowerCase().match(/open-source|free/))s+=5;if(w.RiskLevel==='LOW')s+=4;if(String(w.AutomationReadiness||'').toLowerCase().includes('preview'))s+=3;if(String(w.Difficulty||'').toLowerCase().includes('easy'))s+=2;return s}
function planForWorkflow(w,mode='preview'){const apps=(w.Apps||builderSelection.map(a=>a.Name)).join(' + ');return [`PowerShell Gorrilla visual workflow plan`,`Mode: ${mode}`,`Apps: ${apps}`,`Workflow: ${w.WorkflowName||apps}`,`Result: ${w.WhatCanDo||'Use these apps together with a safe local file handoff.'}`,`Risk: ${w.RiskLevel||'LOW'}`,`Sign-in: ${w.SignInRequirement||'Unknown'}`,`Local availability: ${w.LocalOnly?'Local-only available':'Check app-specific cloud features before use'}`,`Automation readiness: ${w.AutomationReadiness||'Manual plan'}`,`Safe steps:`,...(w.ActionPlan||[]).map((x,i)=>`${i+1}. ${x}`),`Commands to preview:`,`gorintegrate`,`gorconnectors`,`gorworkflow list`,`No destructive action is triggered from this icon builder.`].join('\n')}
function setBuilderPreview(text){const el=$('builderPlanPreview');if(el)el.textContent=text}
function chooseBuilderApp(name){const app=appByName(name);const key=ibNorm(app.Name);if(!key)return;if(builderSelection.some(a=>ibNorm(a.Name)===key)){builderSelection=builderSelection.filter(a=>ibNorm(a.Name)!==key)}else{if(builderSelection.length>=4)builderSelection.shift();builderSelection.push(app)}renderIconBuilder()}
function renderBuilderStats(){const s=iconBuilder.Stats||{};const sources=(iconBuilder.Sources||[]).filter(x=>x.Status==='READY').length;$('iconBuilderStats').innerHTML=[['Apps',s.AppCount||ibApps().length,'Detected/icon-ready'],['Workflows',s.WorkflowCount||ibWorkflows().length,'Sampled from CSVs'],['Datasets',sources,'Ready imports'],['Mode','Read-only','No direct destructive actions']].map(x=>`<div class="signalTile"><span>${esc(x[0])}</span><b>${esc(x[1])}</b><p>${esc(x[2])}</p></div>`).join('')}
function renderBuilderSlots(){const slots=[0,1,2,3];$('builderSlots').innerHTML=slots.map(i=>{const app=builderSelection[i];return `<div class="dropSlot ${app?'filled':''}" data-builder-slot="${i}">${app?`<div><img class="appIconImg" src="${esc(app.IconUrl||'gorrilla-launcher.ico')}" alt=""><b>${esc(app.Name)}</b><p>${esc(app.Status)} · ${esc(app.SignInRequirement||'Unknown')}</p><button class="btn small ghost" data-builder-remove="${i}">Remove</button></div>`:`<div><b>Slot ${i+1}</b><p>${i<2?'Required':'Optional'}</p></div>`}</div>`}).join('')}
function renderBuilderEquation(matches=[]){if(!builderSelection.length){$('builderEquation').innerHTML='<span class="badge demo">Select app icons to build a workflow equation.</span>';return}const apps=builderSelection.map(a=>`<span class="equationApp"><img class="appIconImg" src="${esc(a.IconUrl||'gorrilla-launcher.ico')}" alt=""><b>${esc(a.Name)}</b></span>`).join('<span class="equationSymbol">+</span>');const result=matches[0]?.WorkflowName||`${builderSelection.length}-app workflow search`;$('builderEquation').innerHTML=`${apps}<span class="equationSymbol">=</span><b>${esc(result)}</b>`}
function suggestionApps(){const keys=selectedKeys();if(!keys.length)return[];const counts={};ibWorkflows().filter(workflowContainsSelection).forEach(w=>(w.Apps||[]).forEach(name=>{const key=ibNorm(name);if(!key||keys.includes(key))return;const app=appByName(name);const add=(app.Installed?6:0)+(app.LocalAvailability==='Local mode available'?4:0)+(String(app.LicenseMode||'').toLowerCase().includes('free')?3:0)+(w.RiskLevel==='LOW'?2:0);counts[key]=counts[key]||{Name:name,Score:0};counts[key].Score+=add+1}));return Object.values(counts).sort((a,b)=>b.Score-a.Score).slice(0,10)}
function renderBuilderSuggestions(){const suggestions=suggestionApps();$('builderSuggestions').innerHTML=suggestions.length?`<span class="badge demo">Smart suggestions</span>${suggestions.map(s=>`<button data-builder-app="${esc(s.Name)}">${esc(s.Name)}</button>`).join('')}`:'<span class="badge plan">Click one app to get pairing suggestions.</span>'}
function renderBuilderResults(matches){if(builderSelection.length<2){$('builderResults').innerHTML='<div class="panel"><h4>Start with two apps</h4><p>Click or drag app icons into Slot 1 and Slot 2. Gorrilla will search your 2-app, 3-app, and 4-app CSV brain as soon as enough apps are selected.</p></div>';setBuilderPreview('Select 2, 3, or 4 apps to generate a safe local workflow plan.');return}if(!matches.length){$('builderResults').innerHTML='<div class="panel"><h4>No exact match yet</h4><p>Try one of the smart suggestions or clear a slot. The builder is using local sampled CSV indexes and will never invent apps as installed.</p></div>';setBuilderPreview('No exact workflow match was found for this selected set. Try adding a suggested app or changing the workflow filter.');return}$('builderResults').innerHTML=matches.map(w=>{const idx=ibWorkflows().indexOf(w);const eq=(w.Apps||[]).map(n=>{const a=appByName(n);return `<span class="equationApp"><img class="appIconImg" src="${esc(a.IconUrl||'gorrilla-launcher.ico')}" alt=""><b>${esc(n)}</b></span>`}).join('<span class="equationSymbol">+</span>');return `<article class="workflowCard"><div class="equation">${eq}<span class="equationSymbol">=</span><b>${esc(w.WorkflowName)}</b></div><h4>${esc(w.WorkflowName)}</h4><p>${esc(w.WhatCanDo||'Workflow details are available in the CSV source.')}</p><div class="meta">${badge(w.Kind||`${w.Size}-App`,'demo')}${badge(w.RiskLevel||'LOW',w.RiskLevel==='LOW'?'ok':'warn')}${badge(w.LocalOnly?'Local':'Check sign-in',w.LocalOnly?'ok':'plan')}${badge(w.AutomationReadiness||'Manual plan','demo')}${badge(w.FreeOpenSourceStatus||'Status unknown','ok')}</div><p><b>Best use:</b> ${esc(w.BestUse||'General local workflow')}</p><p><b>Sign-in:</b> ${esc(w.SignInRequirement||'Unknown')}</p><div class="actionRow"><button class="btn small primary" data-workflow-action="preview" data-workflow-index="${idx}">Preview Plan</button><button class="btn small secondary" data-workflow-action="export" data-workflow-index="${idx}">Export Plan</button><button class="btn small secondary" data-workflow-action="fav" data-workflow-index="${idx}">Add to Favourites</button><button class="btn small secondary" data-workflow-action="launch" data-workflow-index="${idx}">Launch Apps</button><button class="btn small secondary" data-workflow-action="generate" data-workflow-index="${idx}">Generate PowerShell Plan</button></div></article>`}).join('');setBuilderPreview(planForWorkflow(matches[0],'best match preview'))}
function renderIconBuilder(){if(!$('appIconGrid'))return;renderBuilderStats();const query=ibNorm($('iconSearch')?.value||'');const type=$('workflowFilter')?.value||'';const installedOnly=$('filterInstalled')?.checked;const localOnly=$('filterLocal')?.checked;const freeOnly=$('filterFree')?.checked;const appHasType=a=>!type||ibWorkflows().some(w=>workflowTypeMatch(w,type)&&(w.Apps||[]).map(ibNorm).includes(ibNorm(a.Name)));const apps=ibApps().filter(a=>(!query||`${a.Name} ${a.Category} ${a.Status} ${a.LicenseMode}`.toLowerCase().includes(query))&&(!installedOnly||a.Installed)&&(!localOnly||a.LocalAvailability==='Local mode available')&&(!freeOnly||String(a.LicenseMode||'').toLowerCase().match(/free|open/))&&appHasType(a)).slice(0,220);$('appIconGrid').innerHTML=apps.map(a=>{const active=builderSelection.some(s=>ibNorm(s.Name)===ibNorm(a.Name));return `<button class="iconTile ${active?'active':''}" draggable="true" data-builder-app="${esc(a.Name)}"><img class="appIconImg" src="${esc(a.IconUrl||'gorrilla-launcher.ico')}" alt=""><b>${esc(a.Name)}</b><span>${esc(a.Category||'Unknown')}</span><div class="meta">${badge(a.Status||'Unknown',a.Installed?'ok':'plan')}${badge(a.LicenseMode||'Unknown',String(a.LicenseMode||'').toLowerCase().match(/free|open/)?'ok':'demo')}</div></button>`}).join('')||'<p>No apps match the current filters.</p>';const matches=exactWorkflowMatches();renderBuilderSlots();renderBuilderEquation(matches);renderBuilderSuggestions();renderBuilderResults(matches);document.querySelectorAll('[data-builder-slot]').forEach(slot=>{slot.addEventListener('dragover',e=>e.preventDefault());slot.addEventListener('drop',e=>{e.preventDefault();const name=e.dataTransfer.getData('text/plain');const app=appByName(name);builderSelection[Number(slot.dataset.builderSlot)]=app;builderSelection=builderSelection.filter(Boolean).slice(0,4);renderIconBuilder()})});document.querySelectorAll('[data-builder-app]').forEach(tile=>tile.addEventListener('dragstart',e=>e.dataTransfer.setData('text/plain',tile.dataset.builderApp)))}
function handleWorkflowAction(action,index){const w=ibWorkflows()[Number(index)];if(!w)return;const text=planForWorkflow(w,action);if(action==='export'){const blob=new Blob([text],{type:'text/plain'});const a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download='powershell-gorrilla-workflow-plan.txt';a.click();URL.revokeObjectURL(a.href);setBuilderPreview(text+'\n\nExported through the browser download flow.')}else if(action==='fav'){const key='powershell-gorrilla-icon-favourites';const list=JSON.parse(localStorage.getItem(key)||'[]');list.push({savedAt:new Date().toISOString(),apps:w.Apps,icons:(w.Apps||[]).map(n=>appByName(n).IconUrl),workflow:w.WorkflowName,description:w.WhatCanDo,actionPlan:text,tags:[w.Kind,w.RiskLevel,w.AutomationReadiness]});localStorage.setItem(key,JSON.stringify(list.slice(-80)));$('favouriteNotice').textContent='Favourite saved locally. Total saved: '+list.length;setBuilderPreview(text)}else if(action==='launch'){setBuilderPreview(text+'\n\nLaunch Apps preview: this button does not open apps directly. Use app-specific launch commands only after confirming the plan.')}else{setBuilderPreview(text)}}
function renderDemo(){ $('demoJourney').innerHTML=demoJourney.map((s,i)=>`<div class="journeyStep"><span class="number">${i+1}</span><div><h4>${esc(s[0])}</h4><p>${esc(s[1])}</p></div></div>`).join(''); $('demoResults').innerHTML=['Connected apps: 6 shown','Device cards: demo preview','Automation routes: 6 available','Safety: confirmation gated'].map(x=>`<div class="resultBox">${esc(x)}</div>`).join('') }
function renderSafety(){ $('safetyGrid').innerHTML=safety.map(s=>`<article class="card">${icon(s[2])}<h4>${esc(s[0])}</h4><p>${esc(s[1])}</p></article>`).join('') }
function renderActivity(){const reports=(data.Reports||[]).slice(0,3);const alerts=(data.Alerts||[]).filter(a=>a.Severity!=='OK').slice(0,3);const items=[['System ready','Dashboard generated and local API available.'],['AI status',data.Status.OllamaAvailable?'Ollama is available for local helper workflows.':'Ollama is not connected yet. The app will use deterministic guidance.'],...alerts.map(a=>[a.Title,a.Detail]),...reports.map(r=>['Report available',r.Name])];$('activityFeed').innerHTML=items.slice(0,8).map(i=>`<div class="activityItem">${icon('logs')}<div><h4>${esc(i[0])}</h4><p>${esc(i[1])}</p></div></div>`).join('')}
function renderVision(){const v=data.ProductVision||{};$('visionName').textContent=v.Name||'Gorilla Command OS';$('visionOneLine').textContent=v.OneLine||'';$('visionDirection').textContent=v.Direction||'';$('visionNorthStar').textContent=(v.NorthStar||'')+(v.Flagship?' | Flagship: '+v.Flagship:'');$('visionPrinciples').innerHTML=(v.Principles||[]).map((p,i)=>`<div class="activityItem">${icon('target')}<div><h4>Principle ${i+1}</h4><p>${esc(p)}</p></div></div>`).join('')}
function connectorBadge(status){const s=String(status||'').toUpperCase();if(s.includes('READY')&&!s.includes('NEEDS'))return'ok';if(s.includes('UNKNOWN')||s.includes('NEEDS'))return'warn';return'plan'}
function renderConnectors(){const rows=data.Connectors||[];$('connectorGrid').innerHTML=rows.map(c=>{const verified=String(c.AuthStatus||'').includes('SIGNED_IN');const canConfirm=c.Launchable&&!String(c.AuthStatus||'').includes('LOCAL_READY');return `<article class="connectorCard"><div class="cardTop"><h4>${esc(c.Name)}</h4>${badge(c.Status,connectorBadge(c.Status))}</div><p>${esc(c.Role)}</p><div class="connectorMeta">${badge(c.AuthStatus||'Unknown',connectorBadge(c.AuthStatus))}${badge(c.Launchable?'Launchable':'Not launchable',c.Launchable?'ok':'plan')}${badge(c.AuthMode||'Connector','demo')}${c.VerifiedAt?badge('Checked '+c.VerifiedAt,'ok'):''}</div><p>${esc(c.NextStep)}</p><div class="actionRow">${canConfirm?`<button class="btn small primary" data-connector-verify="${esc(c.Id)}" data-signed-in="${verified?'false':'true'}">${verified?'Needs sign-in':'Mark signed in'}</button>`:''}<button class="btn small secondary" data-run="gorconnectors">Refresh</button></div></article>`}).join('')||'<p>No connector status yet.</p>'}
async function verifyConnector(id,signedIn){setTaskView('Updating passport','Saving visible sign-in state',30,'Updating the connector passport...');try{const res=await fetch('/api/connector-verify',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({id,signedIn})});const body=await res.json();if(!res.ok){setTaskError(body.Error||'Could not update connector passport','The connector passport could not be updated.');return}data.Connectors=body.Connectors||data.Connectors;renderConnectors();const connector=(data.Connectors||[]).find(c=>c.Id===id)||{Name:id};setTaskView('Passport updated',connector.Name+' passport updated',100,`${connector.Name} is now ${signedIn?'marked signed in':'marked as needing sign-in'}.\nGorilla will use this truth status when building workflows.`,'done')}catch(e){setTaskError('Could not reach local API','Connector passport was not updated.')}} 
function renderWorkflowPacks(){const packs=data.WorkflowPacks||[];$('workflowPackGrid').innerHTML=packs.map(p=>`<article class="pipelineCard"><div class="cardTop"><h4>${esc(p.Name)}</h4>${badge(p.Tier||'Pack','demo')}</div><p>${esc(p.Detail)}</p><div class="pipelineApps">${String(p.Apps||'').split(',').map(a=>`<span class="badge ok">${esc(a.trim())}</span>`).join('')}</div><div class="pipelineStep">${esc(p.Outcome)}</div><div class="actionRow">${actionButton(labelForCommand(p.Command||'gorworkflow list'),p.Command||'gorworkflow list','primary')}</div></article>`).join('')}
function renderBackupPosture(){const b=data.BackupPosture||{};$('backupPostureGrid').innerHTML=[['Status',b.Status||'Unknown','Cleanliness'],['Backups',b.ModuleBackups||0,'Module backups'],['Remove',b.ModuleBackupsToRemove||0,'Old backups'],['Book packs',b.BookProjectPacks||0,'Generated packs'],['Clean packs',b.BookProjectPacksToRemove||0,'Old packs']].map(x=>`<div class="signalTile"><span>${esc(x[0])}</span><b>${esc(x[1])}</b><p>${esc(x[2])}</p></div>`).join('');$('backupPostureOutput').textContent=`${b.Rule||'Keep one solid backup.'}\n\nLatest backup:\n${b.LatestModuleBackup||'None yet'}\n\nRun gorkeeponebackup apply -ConfirmText KEEPONEGORILLA only after reviewing the preview.`}
function renderDetails(){ $('detailPanels').innerHTML=`<h4>Launch catalog</h4>${rows(data.LaunchCatalog,[{label:'App',value:'Name'},{label:'Purpose',value:'Category'},{label:'Command',value:'Command'}])}<h4>Installed apps</h4>${rows(data.InstalledApps,[{label:'Name',value:'Name'},{label:'Type',value:'Type'},{label:'Location',value:'Location'}])}<h4>Models</h4>${rows(data.Models,[{label:'Model',value:'Name'},{label:'Status',value:'Status'}])}` }
function renderInstalledApps(filter=''){const q=String(filter||'').toLowerCase();const apps=(data.InstalledApps||[]).filter(a=>!q||`${a.Name} ${a.Type} ${a.Location} ${a.RelativePath}`.toLowerCase().includes(q)).slice(0,120);$('installedAppList').innerHTML=apps.map(a=>`<div class="appRow"><div><b>${esc(a.Name)}</b><span>${esc(a.Type)} · ${esc(a.RelativePath||a.Path)}</span></div><div class="actionRow"><button class="btn small secondary" data-use-app="${esc(a.Name)}">Use</button><button class="btn small primary" data-open-app="${esc(a.Path)}" data-app-name="${esc(a.Name)}">Open</button></div></div>`).join('')||'<p>No matching apps found.</p>'}
async function openInstalledApp(path,name){setTaskView('Opening app','Opening '+name,35,'Starting the selected app from Gorilla.');try{const res=await fetch('/api/open-app',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({path,name})});const body=await res.json();if(!res.ok){setTaskError(body.Error||'Could not open app','Gorilla blocked the launch because the app path was not trusted.');return}setTaskView('App opened','Opened '+name,100,`${name} is open.\nReturn here to mark sign-in or continue the project workflow.`,'done')}catch(e){setTaskError('Could not reach local API','The local app runner was not available.')}}
function renderLaptopContext(){const ctx=data.LaptopContext||{Summary:{}};const s=ctx.Summary||{};$('laptopContextGrid').innerHTML=[['Ports',s.ListeningPorts||0,'Listening endpoints'],['Processes',s.TopProcesses||0,'Top resource users'],['Errors',s.RecentErrors||0,'Recent event log items'],['Services',s.StoppedAutoServices||0,'Stopped auto services'],['Disks',s.Disks||0,'Disk checks'],['Network',s.NetworkChecks||0,'Network checks']].map(x=>`<div class="signalTile"><span>${esc(x[0])}</span><b>${esc(x[1])}</b><p>${esc(x[2])}</p></div>`).join('');const ports=(ctx.ListeningPorts||[]).slice(0,4).map(p=>['Port '+(p.LocalPort||p.Port||''),`${p.ProcessName||p.OwningProcess||''} ${p.LocalAddress||''}`]);const processes=(ctx.TopProcesses||[]).slice(0,4).map(p=>[p.Name||p.ProcessName||'Process',`CPU ${p.CPU||''} WS ${p.WorkingSetMB||p.MemoryMB||''}`]);$('laptopContextDetail').innerHTML=[...ports,...processes].map(i=>`<div class="activityItem">${icon('health')}<div><h4>${esc(i[0])}</h4><p>${esc(i[1])}</p></div></div>`).join('')||'<p>No laptop context yet.</p>'}
function renderPromptMatrix(){const m=data.PromptMatrix||{Count:0,Samples:[]};$('promptMatrixStats').innerHTML=[['Prompts',m.Count||0,'Generated routing combinations'],['Domains',(m.Domains||[]).length,'Work areas'],['Apps/tools',(m.Tools||[]).length,'Operator choices'],['Outcomes',(m.Outcomes||[]).length,'Task intents']].map(x=>`<div class="signalTile"><span>${esc(x[0])}</span><b>${esc(x[1])}</b><p>${esc(x[2])}</p></div>`).join('');$('promptSamples').innerHTML=(m.Samples||[]).slice(0,5).map(p=>`<div class="samplePrompt"><b>${esc(p.Title)}</b><p>${esc(p.Prompt)}</p></div>`).join('')}
function renderDesignStudio(){const apps=(data.DesignApps||[]).slice(0,20);$('designAppList').innerHTML=apps.map(a=>`<div class="appRow"><div><b>${esc(a.Name)}</b><span>${esc(a.Type)} · ${esc(a.RelativePath||a.Path)}</span></div><div class="actionRow"><button class="btn small secondary" data-design-app="${esc(a.Name)}">Use</button><button class="btn small primary" data-open-app="${esc(a.Path)}" data-app-name="${esc(a.Name)}">Open</button></div></div>`).join('')||'<p>No design apps found yet. Run app discovery.</p>'}
async function createDesignBrief(){const goal=$('designGoal').value.trim()||'Bold poster explaining PowerShell Gorrilla as a local AI command centre';const app=$('designGoal').dataset.app||((data.DesignApps||[])[0]?.Name)||'Canva';$('designOutput').textContent='Creating brief for '+app+'...';try{const res=await fetch('/api/design-brief',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({goal,app})});const body=await res.json();if(!res.ok){$('designOutput').textContent=JSON.stringify(body,null,2);return}$('designOutput').textContent=`${body.Summary}\n\nApp: ${body.App}\nGoal: ${body.Goal}\nSaved: ${body.Path}`}catch(e){$('designOutput').textContent='Could not create brief: '+String(e)}}
function renderPipelines(){const pipes=data.CreativePipelines||[];$('pipelineGrid').innerHTML=pipes.map(p=>`<article class="pipelineCard"><h4>${esc(p.Name)}</h4><p>${esc(p.Outcome)}</p><div class="pipelineApps">${(p.Apps||[]).map(a=>`<span class="badge ok">${esc(a.Name)}</span>`).join('')}</div>${(p.Steps||[]).map((s,i)=>`<div class="pipelineStep">${i+1}. ${esc(s)}</div>`).join('')}<div class="actionRow"><button class="btn primary" data-create-project="${esc(p.Name)}">Create project pack</button>${(p.Apps||[]).slice(0,3).map(a=>`<button class="btn small secondary" data-open-app="${esc(a.Path)}" data-app-name="${esc(a.Name)}">Open ${esc(a.Name)}</button>`).join('')}</div></article>`).join('')||'<p>No creative pipelines could be built yet.</p>'}
async function createCreativeProject(pipeline){const goal=$('designGoal')?.value?.trim()||'Create something amazing with 2-3 apps';$('designOutput').textContent='Creating creative project pack for '+pipeline+'...';try{const res=await fetch('/api/creative-project',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({goal,pipeline})});const body=await res.json();if(!res.ok){$('designOutput').textContent=JSON.stringify(body,null,2);return}$('designOutput').textContent=`Project pack created\n\nPipeline: ${body.Pipeline}\nApps: ${(body.Apps||[]).join(' -> ')}\nBrief: ${body.Brief}`}catch(e){$('designOutput').textContent='Could not create project pack: '+String(e)}}
function renderHugeCheck(){const c=data.HugeCheck||{};$('hugeCheckGrid').innerHTML=[['Score',c.Score??'--','Readiness'],['Status',c.Status||'Unknown','Overall'],['Apps',c.InstalledApps||0,'Installed'],['Design',c.DesignApps||0,'Creative apps'],['Pipelines',c.Pipelines||0,'2-3 app chains'],['Prompts',c.PromptMatrix||0,'AI routes']].map(x=>`<div class="signalTile"><span>${esc(x[0])}</span><b>${esc(x[1])}</b><p>${esc(x[2])}</p></div>`).join('')}
async function runHugeCheck(){setTaskView('Huge check','Running broad app and laptop check',20,'Checking app, laptop, prompts, pipelines and reports...');try{const res=await fetch('/api/huge-check',{method:'POST'});const body=await res.json();const summary=`Status: ${body.Status}\nReadiness score: ${body.Score}\nInstalled apps: ${body.InstalledApps}\nCreative pipelines: ${body.Pipelines}\nReport: ${body.Path}`;$('hugeCheckOutput').textContent=summary;setTaskView('Huge check complete',`${body.Status} score ${body.Score}`,100,summary,'done')}catch(e){$('hugeCheckOutput').textContent='Huge check needs attention.';setTaskError('Huge check failed','The broad readiness check did not complete.')}}
function renderPlan(){const q=$('intent').value.toLowerCase();const routes=q.match(/book|manuscript|cover|word|adobe|publish/)?['gorconnectors','gorbook "My Book"','gorworkflow list','gorkeeponebackup preview']:q.match(/signed|sign in|auth|connector|passport/)?['gorconnectors','gorintegrate','gorworkflow list']:q.match(/clean|rubbish|backup|unused|keep one/)?['gorkeeponebackup preview','gorbackup-module','gorworkflow list']:q.match(/picture|image|media|design|canva/)?['gordo ai','gorlaunch figma','gorworkflow list','gorintegrate']:q.match(/safe|security|scan|protect|laptop|health|diagnos/)?['gorlaptopscan','gorappdiscover','gorsecurity FireDesk','gorpatchplan FireDesk']:q.match(/discover|apps|install|shortcut/)?['gorappdiscover','gorintegrate','gorworkflow list']:q.match(/update|backup|version/)?['gorupdate preview','gorbackup-module','gorelite-report']:['gordo now','gorfixqueue','goradvisor','gorworkflow list'];$('planPanel').innerHTML=routes.map((cmd,i)=>{const action=(data.Actions||[]).find(a=>a.Command===cmd)||{Title:cmd,Detail:'Guided backend action.',Risk:'LOW'};return `<div class="step"><span class="badge ${statusClass(action.Risk)}">Step ${i+1}</span><h4>${esc(action.Title||cmd)}</h4><p>${esc(action.Detail||'Runs a safe local action and returns the outcome here.')}</p><div class="actionRow">${actionButton(labelForCommand(cmd),cmd,i===0?'primary':'secondary')}</div></div>`}).join('')}
function setTaskView(title,status,progress,output,state='running'){const visible=String(output||'');const popup=$('taskPopup');if(popup){popup.classList.add('active');popup.classList.toggle('done',state==='done');popup.classList.toggle('error',state==='error');$('taskPopupTitle').textContent=title||'Task running';$('taskPopupStatus').textContent=status||'';$('taskPopupBar').style.width=(progress||0)+'%';if(visible.length)$('taskPopupOutput').textContent=visible}$('taskStatus').textContent=status||title||'Working...';$('taskBar').style.width=(progress||0)+'%';if(visible.length)$('taskOutput').textContent=visible}
function setTaskError(status,output){setTaskView('Action needs attention',status,100,output,'error')}
async function fetchWithTimeout(url,options={},ms=8000){const controller=new AbortController();const timer=setTimeout(()=>controller.abort(),ms);try{return await fetch(url,{...options,signal:controller.signal})}finally{clearTimeout(timer)}}
async function askGorrilla(){const text=$('intent').value.trim();if(!text){$('requestAnswer').textContent='Tell Gorrilla what outcome you want. Example: scan my laptop and show safe fixes.';return}renderPlan();$('requestAnswer').textContent='Thinking locally and checking the app map...';setTaskView('Thinking locally','Gorrilla is interpreting your request',18,'Checking apps, connectors, and available routes...');try{const res=await fetchWithTimeout('/api/chat',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({message:text})},9000);const body=await res.json();const answer=body.Answer||body.Error||'I could not produce an answer yet.';$('requestAnswer').textContent=answer;setTaskView('Request answered','Request answered. Choose a suggested action when ready.',100,answer,'done');document.querySelector('#operate')?.scrollIntoView({behavior:'smooth',block:'start'})}catch(e){const fallback='The helper is taking too long, so I built the visible safe plan instead. Pick a suggested action below and Gorilla will keep the behind-the-scenes work out of the way.';$('requestAnswer').textContent=fallback;setTaskView('Plan ready','Suggested actions are ready.',100,fallback,'done');document.querySelector('#operate')?.scrollIntoView({behavior:'smooth',block:'start'})}}
function findRisk(cmd){return ((data.Actions||[]).find(a=>a.Command===cmd)||{}).Risk||'LOW'}
async function runCommand(cmd){const risk=findRisk(cmd);let confirm='';if(risk==='MEDIUM')confirm=prompt('This action needs confirmation. Type the requested confirmation phrase if you want to continue.')||'';if(risk==='HIGH')confirm=prompt('High-risk action. Type KILL5000 only if you intend to stop a process.')||'';const label=labelForCommand(cmd);setTaskView('Starting task',label+' started',6,'Gorilla is doing the behind-the-scenes work. The visible result will stay outcome-first.');try{const res=await fetch('/api/run',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({command:cmd,confirm})});const body=await res.json();if(!res.ok){setTaskError(body.Error||'Action blocked safely','The action was not run. Check the requested confirmation or connector state.');return}pollTask(body.Id)}catch(e){setTaskError('Could not reach local API','The local runner is not available right now.')}}
async function pollTask(id){try{const res=await fetch('/api/task?id='+encodeURIComponent(id));const task=await res.json();const done=!(task.Status==='Running'||task.Status==='NotStarted');const label=labelForCommand(task.Command);const status=done?`${label} complete`:`${label} running - ${task.ElapsedSeconds}s`;setTaskView(done?'Outcome ready':'Task running',status,task.Progress||10,outcomeForTask(task),done?'done':'running');if(!done)setTimeout(()=>pollTask(id),900)}catch(e){setTaskError('Task status unavailable','The local runner did not return a task update.')}}
function runDemo(){ const output='Demo only. No external app was changed. This shows the intended premium workflow: intake -> local AI planning -> tool launch -> diagnostic -> result package.';$('demoSummary').textContent='Demo preview: a connected request becomes a guided route, tool launch, safe diagnostic, generated report, and visible outcome summary.';setTaskView('Demo preview ready','Demo preview ready',100,output,'done')}
document.addEventListener('click',e=>{const builderApp=e.target.closest('[data-builder-app]');if(builderApp){chooseBuilderApp(builderApp.dataset.builderApp);return}const remove=e.target.closest('[data-builder-remove]');if(remove){builderSelection.splice(Number(remove.dataset.builderRemove),1);renderIconBuilder();return}const workflow=e.target.closest('[data-workflow-action]');if(workflow){handleWorkflowAction(workflow.dataset.workflowAction,workflow.dataset.workflowIndex);return}})
document.addEventListener('click',e=>{const verify=e.target.closest('[data-connector-verify]');if(verify)verifyConnector(verify.dataset.connectorVerify,verify.dataset.signedIn==='true');const run=e.target.closest('[data-run],[data-action]');if(run)runCommand(run.dataset.run||run.dataset.action);const scroll=e.target.closest('[data-scroll]');if(scroll)document.querySelector(scroll.dataset.scroll)?.scrollIntoView({behavior:'smooth'});const copy=e.target.closest('[data-copy]');if(copy)navigator.clipboard?.writeText(copy.dataset.copy);const open=e.target.closest('[data-open-app]');if(open)openInstalledApp(open.dataset.openApp,open.dataset.appName||'app');const use=e.target.closest('[data-use-app]');if(use){$('intent').value='Use '+use.dataset.useApp+' to help with: ';$('intent').focus();renderPlan()}const design=e.target.closest('[data-design-app]');if(design){$('designGoal').dataset.app=design.dataset.designApp;$('designOutput').textContent='Selected design app: '+design.dataset.designApp}const project=e.target.closest('[data-create-project]');if(project)createCreativeProject(project.dataset.createProject)})
$('taskPopupClose')?.addEventListener('click',()=>$('taskPopup')?.classList.remove('active'));
$('askBtn').addEventListener('click',askGorrilla);$('intent').addEventListener('keydown',e=>{if(e.key==='Enter')askGorrilla()});$('demoBtn').addEventListener('click',runDemo);
$('appSearch')?.addEventListener('input',e=>renderInstalledApps(e.target.value));
$('iconSearch')?.addEventListener('input',()=>renderIconBuilder());
$('workflowFilter')?.addEventListener('change',()=>renderIconBuilder());
$('filterInstalled')?.addEventListener('change',()=>renderIconBuilder());
$('filterLocal')?.addEventListener('change',()=>renderIconBuilder());
$('filterFree')?.addEventListener('change',()=>renderIconBuilder());
$('clearIconBuilder')?.addEventListener('click',()=>{builderSelection=[];renderIconBuilder()});
$('designBriefBtn')?.addEventListener('click',createDesignBrief);
$('hugeCheckBtn')?.addEventListener('click',runHugeCheck);
$('starter').innerHTML=['Create a book with Word Canva and Adobe','Check which apps are signed in','Keep one solid backup','Scan laptop health','Discover installed apps','Preview integration'].map(t=>`<button class="btn small ghost" data-prompt="${esc(t)}">${esc(t)}</button>`).join('');
document.addEventListener('click',e=>{const p=e.target.closest('[data-prompt]');if(p){$('intent').value=p.dataset.prompt;renderPlan();document.querySelector('#operate').scrollIntoView({behavior:'smooth'})}})
$('systemBadges').innerHTML=[badge('Local API online','ok'),badge(data.Status.OllamaAvailable?'Ollama ready':'Ollama ready to connect',data.Status.OllamaAvailable?'ok':'plan'),badge('Version '+data.Status.Version,'demo')].join('');
$('heroSignals').innerHTML=[
  ['Mode','Local','127.0.0.1 bound'],
  ['Ready apps',(data.Connectors||[]).filter(c=>c.Status==='READY').length,'Connector passport'],
  ['Backups',data.BackupPosture?.ModuleBackups??0,'Keep one solid copy'],
  ['Workflow packs',(data.WorkflowPacks||[]).length,'Business routes']
].map(s=>`<div class="signalTile"><span>${esc(s[0])}</span><b>${esc(s[1])}</b><p>${esc(s[2])}</p></div>`).join('');
$('footerStatus').textContent='Data root: '+data.Paths.Root+' | Generated: '+data.GeneratedAt;
paintIcons();renderVision();renderConnectors();renderWorkflowPacks();renderBackupPosture();renderOutcomes();renderCapabilities();renderIntegrations();renderIconBuilder();renderDemo();renderSafety();renderActivity();renderDetails();renderInstalledApps();renderLaptopContext();renderPromptMatrix();renderPipelines();renderHugeCheck();renderDesignStudio();renderPlan();
$('actionGrid').innerHTML=(data.Actions||[]).slice(0,9).map(a=>`<article class="card"><div class="cardTop">${icon('tools')}${badge(a.Risk,statusClass(a.Risk))}</div><h4>${esc(a.Title)}</h4><p>${esc(a.Detail)}</p><div class="meta">${badge(a.Area||'Command','demo')}</div><div class="actionRow"><button class="btn primary" data-run="${esc(a.Command)}">${esc(labelForCommand(a.Command))}</button></div></article>`).join('');
</script>
</body>
</html>
'@
}

function New-GorVisualServerScript {
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $manifest = Join-Path $paths.ModuleRoot 'CommandUnitGorrilla.psd1'
    $scriptPath = Join-Path $paths.Dashboard 'gorrilla-api-server.ps1'
    $content = @'
param(
    [int]$Port = 8765,
    [string]$Manifest = '',
    [string]$WebRoot = ''
)
$ErrorActionPreference = 'Continue'
Import-Module -Name $Manifest -Force
$script:Tasks = @{}
$script:Actions = @{
    'gortest all' = @{ Risk='LOW'; Script={ gortest all | Out-String } }
    'gorvisual' = @{ Risk='LOW'; Script={ 'Visual app is already running locally.' } }
    'gordo now' = @{ Risk='LOW'; Script={ gordo now | Out-String } }
    'gordo boost' = @{ Risk='MEDIUM'; Script={ gordo boost | Out-String } }
    'gordo full' = @{ Risk='MEDIUM'; Script={ gordo full | Out-String } }
    'gordo ai' = @{ Risk='LOW'; Script={ gordo ai | Out-String } }
    'gorintegrate' = @{ Risk='LOW'; Script={ gorintegrate | Out-String } }
    'gorfixqueue' = @{ Risk='LOW'; Script={ gorfixqueue | Out-String } }
    'gorconnectors' = @{ Risk='LOW'; Script={ gorconnectors | Out-String } }
    'gordesktopapps' = @{ Risk='LOW'; Script={ gordesktopapps | Out-String } }
    'gorpackagebank' = @{ Risk='LOW'; Script={ gorpackagebank | Out-String } }
    'gorbook "My Book"' = @{ Risk='LOW'; Script={ gorbook "My Book" | Out-String } }
    'gorkeeponebackup preview' = @{ Risk='LOW'; Script={ gorkeeponebackup preview | Out-String } }
    'gorkeeponebackup apply' = @{ Risk='MEDIUM'; Confirm='KEEPONEGORILLA'; Script={ gorkeeponebackup apply -ConfirmText KEEPONEGORILLA | Out-String } }
    'gorprompt list' = @{ Risk='LOW'; Script={ gorprompt list | Out-String } }
    'gorunderstand fix my machine' = @{ Risk='LOW'; Script={ gorunderstand fix my machine | Out-String } }
    'gorworkflow list' = @{ Risk='LOW'; Script={ gorworkflow list | Out-String } }
    'gorupdate preview' = @{ Risk='LOW'; Script={ gorupdate preview | Out-String } }
    'gornewweb' = @{ Risk='LOW'; Script={ gornewweb | Out-String } }
    'gorlaunch code' = @{ Risk='LOW'; Script={ gorlaunch code | Out-String } }
    'gorlaunch bruno' = @{ Risk='LOW'; Script={ gorlaunch bruno | Out-String } }
    'gorlaunch figma' = @{ Risk='LOW'; Script={ gorlaunch figma | Out-String } }
    'gorappdiscover' = @{ Risk='LOW'; Script={ gorappdiscover | Out-String } }
    'gorlaptopscan' = @{ Risk='LOW'; Script={ gorlaptopscan | Out-String } }
    'goradvisor' = @{ Risk='LOW'; Script={ goradvisor | Out-String } }
    'goralerts' = @{ Risk='LOW'; Script={ goralerts | Out-String } }
    'goroptions' = @{ Risk='LOW'; Script={ goroptions | Out-String } }
    'gorfiredesk' = @{ Risk='LOW'; Script={ gorfiredesk | Out-String } }
    'gorfiredeskreport' = @{ Risk='LOW'; Script={ gorfiredeskreport | Out-String } }
    'gorstate check' = @{ Risk='LOW'; Script={ gorstate check | Out-String } }
    'gorports' = @{ Risk='LOW'; Script={ gorports | Out-String } }
    'gorservices' = @{ Risk='LOW'; Script={ gorservices | Out-String } }
    'gornetwork' = @{ Risk='LOW'; Script={ gornetwork | Out-String } }
    'gorelite-report' = @{ Risk='LOW'; Script={ gorelite-report | Out-String } }
    'gordoctor FireDesk' = @{ Risk='LOW'; Script={ gordoctor FireDesk | Out-String } }
    'gorquality FireDesk' = @{ Risk='LOW'; Script={ gorquality FireDesk | Out-String } }
    'gorsecurity FireDesk' = @{ Risk='LOW'; Script={ gorsecurity FireDesk | Out-String } }
    'gorperf app FireDesk' = @{ Risk='LOW'; Script={ gorperf app FireDesk | Out-String } }
    'gorpatchplan FireDesk' = @{ Risk='LOW'; Script={ gorpatchplan FireDesk | Out-String } }
    'gorbackup-module' = @{ Risk='LOW'; Script={ gorbackup-module | Out-String } }
    'gorrescue' = @{ Risk='LOW'; Script={ gorrescue | Out-String } }
    'gordesktop tidy' = @{ Risk='LOW'; Script={ gordesktop tidy | Out-String } }
    'gordesktop apply' = @{ Risk='MEDIUM'; Confirm='TIDYGORRILLA'; Script={ gordesktop apply -ConfirmText TIDYGORRILLA | Out-String } }
    'gorbindlocal FireDesk' = @{ Risk='MEDIUM'; Confirm='BINDLOCALGORRILLA'; Script={ gorbindlocal FireDesk -ConfirmText BINDLOCALGORRILLA | Out-String } }
    'gorkill5000' = @{ Risk='HIGH'; Confirm='KILL5000'; Script={ gorkill5000 -ConfirmText KILL5000 | Out-String } }
}
function ConvertTo-ApiJson { param($Value) $Value | ConvertTo-Json -Depth 12 -Compress }
function Send-ApiText {
    param($Context, [int]$Status, [string]$ContentType, [string]$Text)
    $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
    $Context.Response.StatusCode = $Status
    $Context.Response.ContentType = $ContentType
    $Context.Response.ContentLength64 = $bytes.Length
    $Context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $Context.Response.OutputStream.Close()
}
function Send-ApiBytes {
    param($Context, [int]$Status, [string]$ContentType, [byte[]]$Bytes)
    $Context.Response.StatusCode = $Status
    $Context.Response.ContentType = $ContentType
    $Context.Response.ContentLength64 = $Bytes.Length
    $Context.Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
    $Context.Response.OutputStream.Close()
}
function Send-ApiJson { param($Context, [int]$Status, $Value) Send-ApiText -Context $Context -Status $Status -ContentType 'application/json; charset=utf-8' -Text (ConvertTo-ApiJson $Value) }
function Get-RequestJson {
    param($Request)
    $reader = [IO.StreamReader]::new($Request.InputStream, $Request.ContentEncoding)
    $raw = $reader.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { return [pscustomobject]@{} }
    return ($raw | ConvertFrom-Json)
}
function Get-ContentType {
    param([string]$Path)
    switch ([IO.Path]::GetExtension($Path).ToLowerInvariant()) {
        '.html' { 'text/html; charset=utf-8' }
        '.js' { 'text/javascript; charset=utf-8' }
        '.css' { 'text/css; charset=utf-8' }
        '.json' { 'application/json; charset=utf-8' }
        '.png' { 'image/png' }
        '.ico' { 'image/x-icon' }
        '.jpg' { 'image/jpeg' }
        '.jpeg' { 'image/jpeg' }
        '.webp' { 'image/webp' }
        default { 'text/plain; charset=utf-8' }
    }
}
function Test-AllowedAppPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) { return $false }
    $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue).Path
    if ([string]::IsNullOrWhiteSpace($resolved)) { return $false }
    $ext = [IO.Path]::GetExtension($resolved).ToLowerInvariant()
    if ($ext -notin @('.lnk','.appref-ms','.exe')) { return $false }
    $allowedRoots = @(
        [Environment]::GetFolderPath('ApplicationData'),
        [Environment]::GetFolderPath('CommonApplicationData'),
        [Environment]::GetFolderPath('Desktop'),
        [Environment]::GetFolderPath('CommonDesktopDirectory'),
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)}
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    foreach ($root in $allowedRoots) {
        try {
            $rootResolved = (Resolve-Path -LiteralPath $root -ErrorAction SilentlyContinue).Path
            if ($rootResolved -and $resolved.StartsWith($rootResolved, [StringComparison]::OrdinalIgnoreCase)) { return $true }
        }
        catch {}
    }
    return $false
}
$listener = [Net.HttpListener]::new()
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()
while ($listener.IsListening) {
    $context = $listener.GetContext()
    try {
        $requestPath = $context.Request.Url.AbsolutePath.TrimStart('/')
        if ($requestPath -eq '') { $requestPath = 'index.html' }
        if ($context.Request.HttpMethod -eq 'GET' -and $requestPath -eq 'api/status') {
            $dataFile = Join-Path $WebRoot 'gorrilla-data.json'
            if (Test-Path -LiteralPath $dataFile) {
                Send-ApiText -Context $context -Status 200 -ContentType 'application/json; charset=utf-8' -Text (Get-Content -LiteralPath $dataFile -Raw)
            }
            else {
                Send-ApiJson -Context $context -Status 404 -Value ([pscustomobject]@{ Error='Dashboard data not found.' })
            }
            continue
        }
        if ($context.Request.HttpMethod -eq 'GET' -and $requestPath -eq 'api/actions') {
            $rows = foreach ($key in $script:Actions.Keys) { [pscustomobject]@{ Command=$key; Risk=$script:Actions[$key].Risk; Confirm=$script:Actions[$key].Confirm } }
            Send-ApiJson -Context $context -Status 200 -Value $rows
            continue
        }
        if ($context.Request.HttpMethod -eq 'POST' -and $requestPath -like 'api/chat*') {
            $body = Get-RequestJson -Request $context.Request
            $message = [string]$body.message
            if ([string]::IsNullOrWhiteSpace($message)) {
                Send-ApiJson -Context $context -Status 400 -Value ([pscustomobject]@{ Error='Message is required.' })
                continue
            }
            $answer = ''
            try {
                $suggestions = @(Resolve-GorIntent -Text $message)
                $dataFile = Join-Path $WebRoot 'gorrilla-data.json'
                $dashboardData = if (Test-Path -LiteralPath $dataFile) { Get-Content -LiteralPath $dataFile -Raw | ConvertFrom-Json } else { $null }
                $apps = @($dashboardData.InstalledApps)
                $matchingApps = @($apps | Where-Object { $message -match [regex]::Escape($_.Name) -or $_.Name -match 'Canva|Figma|GIMP|Krita|Inkscape|Blender|OBS|ShareX|Paint|Photo' } | Select-Object -First 6)
                $lines = New-Object System.Collections.Generic.List[string]
                $lines.Add('Here is the fast safe route I would start with:')
                foreach ($suggestion in @($suggestions | Select-Object -First 4)) {
                    $lines.Add('- ' + [string]$suggestion.Command + ' [' + [string]$suggestion.Risk + '] - ' + [string]$suggestion.Why)
                }
                if ($matchingApps.Count -gt 0) {
                    $lines.Add('')
                    $lines.Add('Useful app choices found on this laptop:')
                    foreach ($app in $matchingApps) {
                        $lines.Add('- ' + [string]$app.Name + ' (' + [string]$app.Type + ')')
                    }
                }
                $lines.Add('')
                $lines.Add('Ollama context is available through the prompt matrix, but this quick answer avoids blocking app launch and status actions.')
                $answer = ($lines -join [Environment]::NewLine).Trim()
            }
            catch {
                $answer = ''
            }
            if ([string]::IsNullOrWhiteSpace($answer)) {
                $answer = "I can help plan this locally. Start with gorconnectors to check app readiness and sign-in truth, gorintegrate to see connected tools, gordo ai to check Ollama, and gorworkflow list to choose a route. For book or creative production, use gorbook so every handoff is visible and recorded."
            }
            Send-ApiJson -Context $context -Status 200 -Value ([pscustomobject]@{ Answer=$answer; LocalAI=(-not [string]::IsNullOrWhiteSpace($answer)) })
            continue
        }
        if ($context.Request.HttpMethod -eq 'POST' -and $requestPath -eq 'api/open-app') {
            $body = Get-RequestJson -Request $context.Request
            $appPath = [string]$body.path
            $appName = [string]$body.name
            if (-not (Test-AllowedAppPath -Path $appPath)) {
                Send-ApiJson -Context $context -Status 400 -Value ([pscustomobject]@{ Error='App path is not an allowed installed-app shortcut or executable.' })
                continue
            }
            Start-Process -FilePath $appPath -ErrorAction Stop | Out-Null
            Send-ApiJson -Context $context -Status 200 -Value ([pscustomobject]@{ Status='STARTED'; Name=$appName; Path=$appPath })
            continue
        }
        if ($context.Request.HttpMethod -eq 'POST' -and $requestPath -eq 'api/connector-verify') {
            $body = Get-RequestJson -Request $context.Request
            $connectorId = [string]$body.id
            if ([string]::IsNullOrWhiteSpace($connectorId)) {
                Send-ApiJson -Context $context -Status 400 -Value ([pscustomobject]@{ Error='Connector id is required.' })
                continue
            }
            $signedIn = $true
            if ($body.PSObject.Properties.Name -contains 'signedIn') {
                try { $signedIn = [System.Convert]::ToBoolean($body.signedIn) } catch { $signedIn = $true }
            }
            $record = Set-GorConnectorPassport -Id $connectorId -SignedIn:$signedIn -Note 'Updated from the Gorilla app Connector Passport.'
            $connectors = @(Get-GorConnectorStatus)
            Send-ApiJson -Context $context -Status 200 -Value ([pscustomobject]@{ Status='SAVED'; Record=$record; Connectors=$connectors })
            continue
        }
        if ($context.Request.HttpMethod -eq 'POST' -and $requestPath -eq 'api/design-brief') {
            $body = Get-RequestJson -Request $context.Request
            $brief = New-GorDesignBrief -Goal ([string]$body.goal) -App ([string]$body.app)
            Send-ApiJson -Context $context -Status 200 -Value $brief
            continue
        }
        if ($context.Request.HttpMethod -eq 'POST' -and $requestPath -eq 'api/creative-project') {
            $body = Get-RequestJson -Request $context.Request
            $goal = if ([string]::IsNullOrWhiteSpace([string]$body.goal)) { 'Create something amazing with 2-3 apps' } else { [string]$body.goal }
            $pipelineName = [string]$body.pipeline
            $dataFile = Join-Path $WebRoot 'gorrilla-data.json'
            $dashboardData = if (Test-Path -LiteralPath $dataFile) { Get-Content -LiteralPath $dataFile -Raw | ConvertFrom-Json } else { $null }
            $pipeline = @($dashboardData.CreativePipelines | Where-Object { [string]::IsNullOrWhiteSpace($pipelineName) -or $_.Name -eq $pipelineName } | Select-Object -First 1)
            if (-not $pipeline) { $pipeline = @($dashboardData.CreativePipelines | Select-Object -First 1) }
            if (-not $pipeline) { Send-ApiJson -Context $context -Status 404 -Value ([pscustomobject]@{ Error='Creative pipeline not found.' }); continue }
            $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $root = Split-Path -Parent $WebRoot
            $reports = Join-Path $root 'Reports'
            $folder = Join-Path $reports "creative-project-$stamp"
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
            $briefPath = Join-Path $folder 'creative-brief.md'
            $apps = @($pipeline.Apps | ForEach-Object { $_.Name })
            $lines = @(
                '# Creative Project Pack',
                '',
                "Goal: $goal",
                "Pipeline: $($pipeline.Name)",
                "Outcome: $($pipeline.Outcome)",
                "Apps: $($apps -join ' -> ')",
                "Created: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))",
                '',
                'Steps:'
            )
            $n = 1
            foreach ($step in @($pipeline.Steps)) { $lines += "$n. $step"; $n++ }
            $lines += @('', 'Prompt for local AI:', "Help create '$goal' using $($apps -join ', '). Give concise design direction, asset ideas, export checklist, and risks.")
            Set-Content -LiteralPath $briefPath -Value $lines -Encoding UTF8
            $project = [pscustomobject]@{ Status='CREATED'; Goal=$goal; Pipeline=$pipeline.Name; Apps=$apps; Folder=$folder; Brief=$briefPath; Steps=@($pipeline.Steps) }
            Send-ApiJson -Context $context -Status 200 -Value $project
            continue
        }
        if ($context.Request.HttpMethod -eq 'POST' -and $requestPath -eq 'api/huge-check') {
            $check = New-GorHugeCheck
            Send-ApiJson -Context $context -Status 200 -Value $check
            continue
        }
        if ($context.Request.HttpMethod -eq 'POST' -and $requestPath -eq 'api/run') {
            $body = Get-RequestJson -Request $context.Request
            $command = [string]$body.command
            if (-not $script:Actions.ContainsKey($command)) {
                Send-ApiJson -Context $context -Status 400 -Value ([pscustomobject]@{ Error='Command is not whitelisted.' })
                continue
            }
            $action = $script:Actions[$command]
            if ($action.Risk -ne 'LOW' -and [string]$body.confirm -ne [string]$action.Confirm) {
                Send-ApiJson -Context $context -Status 409 -Value ([pscustomobject]@{ Error='Typed confirmation required.'; Confirm=$action.Confirm; Risk=$action.Risk })
                continue
            }
            $id = [Guid]::NewGuid().ToString('N')
            $job = Start-Job -InitializationScript ([scriptblock]::Create("Import-Module -Name '$($Manifest.Replace("'","''"))' -Force")) -ScriptBlock $action.Script
            $script:Tasks[$id] = [pscustomobject]@{ Id=$id; Command=$command; Risk=$action.Risk; Started=(Get-Date); Job=$job }
            Send-ApiJson -Context $context -Status 202 -Value ([pscustomobject]@{ Id=$id; Command=$command; Risk=$action.Risk; Status='RUNNING' })
            continue
        }
        if ($context.Request.HttpMethod -eq 'GET' -and $requestPath -like 'api/task*') {
            $id = $context.Request.QueryString['id']
            if (-not $script:Tasks.ContainsKey($id)) {
                Send-ApiJson -Context $context -Status 404 -Value ([pscustomobject]@{ Error='Task not found.' })
                continue
            }
            $task = $script:Tasks[$id]
            $job = $task.Job
            $elapsed = [int]((Get-Date) - $task.Started).TotalSeconds
            $progress = [Math]::Min(95, 8 + ($elapsed * 7))
            $output = ''
            if ($job.State -in @('Completed','Failed','Stopped')) {
                $progress = 100
                $output = (Receive-Job -Job $job -Keep 2>&1 | Out-String)
            }
            Send-ApiJson -Context $context -Status 200 -Value ([pscustomobject]@{ Id=$id; Command=$task.Command; Risk=$task.Risk; Status=$job.State; Progress=$progress; ElapsedSeconds=$elapsed; Output=$output })
            continue
        }
        $file = Join-Path $WebRoot $requestPath
        $resolvedRoot = (Resolve-Path -LiteralPath $WebRoot).Path
        $resolvedFile = if (Test-Path -LiteralPath $file) { (Resolve-Path -LiteralPath $file).Path } else { '' }
        if ($resolvedFile -and $resolvedFile.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedFile -PathType Leaf)) {
            $contentType = Get-ContentType -Path $resolvedFile
            if ($contentType -like 'image/*') {
                Send-ApiBytes -Context $context -Status 200 -ContentType $contentType -Bytes ([IO.File]::ReadAllBytes($resolvedFile))
            }
            else {
                Send-ApiText -Context $context -Status 200 -ContentType $contentType -Text (Get-Content -LiteralPath $resolvedFile -Raw)
            }
        }
        else {
            Send-ApiJson -Context $context -Status 404 -Value ([pscustomobject]@{ Error='Not found.' })
        }
    }
    catch {
        Send-ApiJson -Context $context -Status 500 -Value ([pscustomobject]@{ Error=$_.Exception.Message })
    }
}
'@
    $content = $content.Replace('__MANIFEST__', $manifest)
    Set-Content -LiteralPath $scriptPath -Value $content -Encoding UTF8
    return $scriptPath
}

function gortest {
    param([Parameter(Position=0)][string]$Suite = 'all')
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $rows = New-Object System.Collections.Generic.List[object]
    $suiteName = $Suite.ToLowerInvariant()
    if ($suiteName -in @('module','all')) {
        $moduleFile = Join-Path $paths.ModuleRoot 'CommandUnitGorrilla.psm1'
        $parse = Test-GorParseFile -Path $moduleFile
        $rows.Add([pscustomobject]@{ Suite='module'; Check='Parse'; Status=if ($parse.Ok) { 'OK' } else { 'FAILED' }; Detail=$moduleFile })
        foreach ($cmd in $script:GorExpectedCommands) {
            $found = Get-Command $cmd -ErrorAction SilentlyContinue
            $rows.Add([pscustomobject]@{ Suite='module'; Check=$cmd; Status=if ($found) { 'OK' } else { 'FAILED' }; Detail='exported command' })
        }
    }
    if ($suiteName -in @('firedesk','all')) {
        $fire = Get-GorFireDeskStatus
        $rows.Add([pscustomobject]@{ Suite='firedesk'; Check='Dashboard path'; Status=if ($fire.Exists) { 'OK' } else { 'WARN' }; Detail=$fire.Path })
        foreach ($file in (ConvertTo-GorArray $fire.Files)) {
            $rows.Add([pscustomobject]@{ Suite='firedesk'; Check=$file.Name; Status=if ($file.Exists) { 'OK' } else { 'WARN' }; Detail=$file.Path })
        }
        $rows.Add([pscustomobject]@{ Suite='firedesk'; Check='Port 5000'; Status='INFO'; Detail=(@($fire.Port5000).Count) })
        $compileDetail = if ($fire.PythonCompile) { [string]$fire.PythonCompile.Message + ' ' + [string]$fire.PythonCompile.Output } else { 'N/A' }
        $rows.Add([pscustomobject]@{ Suite='firedesk'; Check='Compile'; Status=if ($fire.PythonCompile -and $fire.PythonCompile.Status -eq 'OK') { 'OK' } else { 'WARN' }; Detail=$compileDetail.Trim() })
    }
    if ($suiteName -in @('repairs','all')) {
        $rows.Add([pscustomobject]@{ Suite='repairs'; Check='Backup folder'; Status=if (Test-Path -LiteralPath $paths.Backups) { 'OK' } else { 'FAILED' }; Detail=$paths.Backups })
        $rows.Add([pscustomobject]@{ Suite='repairs'; Check='Cleanup preview'; Status='OK'; Detail=(@(Get-GorCleanupCandidates).Count) })
    }
    if ($suiteName -in @('reports','all')) {
        $testReport = New-GorHtmlReport -Title 'Gorrilla Test Lab Smoke Report' -Sections @([pscustomobject]@{ Title='Smoke'; Data=@([pscustomobject]@{ Status='OK'; Time=Get-GorNow }) }) -Path (Join-Path $paths.TestLab 'smoke-report.html')
        $rows.Add([pscustomobject]@{ Suite='reports'; Check='HTML report write'; Status=if (Test-Path -LiteralPath $testReport) { 'OK' } else { 'FAILED' }; Detail=$testReport })
    }
    $id = New-GorId -Prefix 'gortest'
    $resultPath = Join-Path $paths.TestLab ($id + '.json')
    Write-GorJson -Path $resultPath -Value @(ConvertTo-GorArray $rows)
    Write-GorLedger -Type 'test' -Message "Test suite completed: $Suite" -Data ([pscustomobject]@{ Path=$resultPath }) | Out-Null
    Write-GorTable -Rows $rows
    Write-Host "Test results written: $resultPath" -ForegroundColor Green
    return (ConvertTo-GorArray $rows)
}

function gorrescue {
    $launcher = New-GorRescueLauncher
    Write-GorTable -Rows @($launcher)
    return $launcher
}

function gorpanic {
    $lines = @(
        'PowerShell Gorrilla emergency commands:',
        'pwsh -NoProfile -NoLogo',
        'Import-Module "$HOME\Documents\PowerShell\Modules\CommandUnitGorrilla\CommandUnitGorrilla.psd1" -Force',
        'gorstatus',
        'gorprofile-check',
        'gorrestore-lastgood',
        'gormodule-rollback',
        'gortest module'
    )
    foreach ($line in $lines) {
        Write-Host $line
    }
    return $lines
}

function gorrestore-lastgood {
    $backups = @(Get-GorLastGoodModuleBackups)
    Write-GorTable -Rows $backups
    if ($backups.Count -eq 0) {
        Write-Warning 'No module backups found.'
        return
    }
    $typed = Read-Host 'Type RESTOREGORRILLA to restore the newest module backup'
    if ($typed -ne 'RESTOREGORRILLA') {
        Write-Warning 'Confirmation did not match. Restore cancelled.'
        return
    }
    $source = $backups[0].ModuleFile
    $paths = Get-GorPaths
    gorbackup-module | Out-Null
    Copy-Item -LiteralPath $source -Destination (Join-Path $paths.ModuleRoot 'CommandUnitGorrilla.psm1') -Force
    Write-GorLedger -Type 'restore' -Message 'Restored newest last-good module backup.' -Data $backups[0] | Out-Null
    Write-Host 'Module restored from newest backup.' -ForegroundColor Green
}

function gormodule-rollback {
    param([Parameter(Position=0)][string]$BackupId = '')
    $backups = @(Get-GorLastGoodModuleBackups)
    if ([string]::IsNullOrWhiteSpace($BackupId)) {
        Write-GorTable -Rows $backups
        return (ConvertTo-GorArray $backups)
    }
    $match = @($backups | Where-Object { $_.Id -like "*$BackupId*" }) | Select-Object -First 1
    if (-not $match) {
        throw "Backup not found: $BackupId"
    }
    $typed = Read-Host 'Type RESTOREGORRILLA to roll back the module'
    if ($typed -ne 'RESTOREGORRILLA') {
        Write-Warning 'Confirmation did not match. Rollback cancelled.'
        return
    }
    gorbackup-module | Out-Null
    Copy-Item -LiteralPath $match.ModuleFile -Destination (Join-Path (Get-GorPaths).ModuleRoot 'CommandUnitGorrilla.psm1') -Force
    Write-GorLedger -Type 'rollback' -Message 'Module rollback completed.' -Data $match | Out-Null
    Write-Host 'Module rollback completed.' -ForegroundColor Green
}

function gorprofile-check {
    param([switch]$Quiet)
    $paths = Get-GorPaths
    $profilePaths = @($PROFILE.CurrentUserCurrentHost, $PROFILE.CurrentUserAllHosts) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
    $needle = 'CommandUnitGorrilla.psd1'
    $hit = $false
    foreach ($profilePath in $profilePaths) {
        if (Test-Path -LiteralPath $profilePath) {
            $raw = Get-Content -LiteralPath $profilePath -Raw -ErrorAction SilentlyContinue
            if ($raw -like "*$needle*") {
                $hit = $true
            }
        }
    }
    $result = [pscustomobject]@{ Status=if ($hit) { 'OK' } else { 'WARN' }; Detail=if ($hit) { 'Profile autoload found.' } else { 'No Gorrilla autoload block found in current user profiles.' }; Module=$paths.ModuleRoot }
    if (-not $Quiet) {
        Write-GorTable -Rows @($result)
    }
    return $result
}

function gorprofile-repair {
    $paths = Get-GorPaths
    $manifest = Join-Path $paths.ModuleRoot 'CommandUnitGorrilla.psd1'
    $targetProfile = $PROFILE.CurrentUserCurrentHost
    Write-Host "Profile to update: $targetProfile"
    $typed = Read-Host 'Type REPAIRGORPROFILE to backup and add Gorrilla autoload'
    if ($typed -ne 'REPAIRGORPROFILE') {
        Write-Warning 'Confirmation did not match. Profile unchanged.'
        return
    }
    $parent = Split-Path -Parent $targetProfile
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    if (-not (Test-Path -LiteralPath $targetProfile)) {
        Set-Content -LiteralPath $targetProfile -Value @() -Encoding UTF8
    }
    Copy-Item -LiteralPath $targetProfile -Destination ($targetProfile + '.CommandUnitGorrilla.bak') -Force
    $block = @(
        '# >>> CommandUnitGorrilla autoload >>>',
        'try {',
        '    Import-Module -Name "' + $manifest.Replace('"','""') + '" -ErrorAction SilentlyContinue',
        '} catch { Write-Verbose ("CommandUnitGorrilla autoload skipped: " + $_.Exception.Message) }',
        '# <<< CommandUnitGorrilla autoload <<<'
    )
    Add-Content -LiteralPath $targetProfile -Value $block -Encoding UTF8
    Write-GorLedger -Type 'profile' -Message 'Profile autoload repaired.' -Data ([pscustomobject]@{ Profile=$targetProfile }) | Out-Null
    gorprofile-check
}

function gorstate {
    param([Parameter(Position=0)][string]$Action = 'check')
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    switch ($Action.ToLowerInvariant()) {
        'export' {
            $state = Get-GorDesiredState
            $path = Join-Path $paths.State 'desired-state.json'
            Write-GorJson -Path $path -Value $state
            Write-Host "State exported: $path" -ForegroundColor Green
            return $state
        }
        'check' {
            $rows = Test-GorDesiredState
            Write-GorTable -Rows $rows
            return (ConvertTo-GorArray $rows)
        }
        'repair' {
            $rows = Test-GorDesiredState
            Write-GorTable -Rows $rows
            $typed = Read-Host 'Type REPAIRGORSTATE to create missing folders/launchers only'
            if ($typed -ne 'REPAIRGORSTATE') {
                Write-Warning 'Confirmation did not match. State repair cancelled.'
                return
            }
            Initialize-GorEnvironment
            New-GorLauncher | Out-Null
            New-GorRescueLauncher | Out-Null
            Write-GorLedger -Type 'state' -Message 'Desired state conservative repair completed.' | Out-Null
            return (Test-GorDesiredState)
        }
        'report' {
            return (New-GorReport -Title 'Gorrilla Desired State Report' -Sections @([pscustomobject]@{ Title='State'; Data=(Test-GorDesiredState) }) -FileName 'desired-state.html')
        }
        default { throw "Unknown gorstate action: $Action" }
    }
}

function gorblackbox {
    param(
        [Parameter(Position=0)][string]$Action = 'list',
        [Parameter(Position=1)][string]$NameOrPath = ''
    )
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    switch ($Action.ToLowerInvariant()) {
        'start' {
            if ([string]::IsNullOrWhiteSpace($NameOrPath)) { throw 'Usage: gorblackbox start NAME_OR_PATH' }
            $capture = Invoke-GorCapture -NameOrPath $NameOrPath
            $id = New-GorId -Prefix 'blackbox'
            $folder = Join-Path $paths.BlackBox $id
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
            Write-GorJson -Path (Join-Path $folder 'before.json') -Value $capture
            Write-Host "Black box started: $folder" -ForegroundColor Green
            return $capture
        }
        'stop' {
            if ([string]::IsNullOrWhiteSpace($NameOrPath)) { throw 'Usage: gorblackbox stop NAME_OR_PATH' }
            $dirs = @(Get-ChildItem -LiteralPath $paths.BlackBox -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
            if ($dirs.Count -eq 0) { throw 'No black box sessions found.' }
            $capture = Invoke-GorCapture -NameOrPath $NameOrPath
            Write-GorJson -Path (Join-Path $dirs[0].FullName 'after.json') -Value $capture
            Write-GorLedger -Type 'blackbox' -Message 'Black box stopped.' -Data ([pscustomobject]@{ Folder=$dirs[0].FullName }) | Out-Null
            Write-Host "Black box stopped: $($dirs[0].FullName)" -ForegroundColor Green
            return $capture
        }
        'report' {
            $dirs = @(Get-ChildItem -LiteralPath $paths.BlackBox -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
            return (New-GorReport -Title 'Gorrilla Black Box Report' -Sections @([pscustomobject]@{ Title='Records'; Data=$dirs }) -FileName 'blackbox.html')
        }
        'list' {
            $rows = Get-ChildItem -LiteralPath $paths.BlackBox -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
            Write-GorTable -Rows $rows
            return (ConvertTo-GorArray $rows)
        }
        default { throw "Unknown gorblackbox action: $Action" }
    }
}

function gorpatchplan {
    param([Parameter(Position=0, Mandatory=$true)][string]$NameOrPath)
    $plan = New-GorPatchPlan -NameOrPath $NameOrPath
    Write-GorTable -Rows $plan.Actions
    Write-Host "Patch session: $($plan.Id)" -ForegroundColor Green
    return $plan
}

function gorpatchdiff {
    param([Parameter(Position=0, Mandatory=$true)][string]$Session)
    $plan = Get-GorPatchPlan -Session $Session
    Write-GorTable -Rows $plan.Actions
    return $plan.Actions
}

function gorpatchapply {
    param([Parameter(Position=0, Mandatory=$true)][string]$Session)
    $plan = Get-GorPatchPlan -Session $Session
    $auto = @($plan.Actions | Where-Object { $_.AutoPatch -eq $true })
    Write-GorTable -Rows $auto
    if ($auto.Count -eq 0) { Write-Host 'No auto-patch actions found.' -ForegroundColor Yellow; return @() }
    $typed = Read-Host 'Type APPLYGORPATCH to backup and apply this patch plan'
    if ($typed -ne 'APPLYGORPATCH') { Write-Warning 'Confirmation did not match. Patch cancelled.'; return }
    $backup = New-GorBackup -Path $plan.Target -Reason "patch-$($plan.Id)"
    $result = Invoke-GorPatchBindLocal -TargetPath $plan.Target
    $folder = Resolve-GorPatchFolder -Session $Session
    $plan.BackupId = $backup.Id
    Write-GorJson -Path (Join-Path $folder 'patch-plan.json') -Value $plan
    Write-GorJson -Path (Join-Path $folder 'apply-result.json') -Value @(ConvertTo-GorArray $result)
    Write-GorLedger -Type 'patch' -Message "Patch applied: $($plan.Id)" -Data ([pscustomobject]@{ Backup=$backup; Result=$result }) | Out-Null
    Write-GorTable -Rows $result
    return (ConvertTo-GorArray $result)
}

function gorpatchundo {
    param([Parameter(Position=0, Mandatory=$true)][string]$Session)
    $plan = Get-GorPatchPlan -Session $Session
    if ([string]::IsNullOrWhiteSpace([string]$plan.BackupId)) { throw 'No patch backup id recorded for this session.' }
    $backupFolder = Resolve-GorSnapshotLikeBackup -BackupId $plan.BackupId
    Write-Host "Backup folder: $backupFolder"
    $typed = Read-Host 'Type UNDOGORPATCH to restore the patch backup over the target'
    if ($typed -ne 'UNDOGORPATCH') { Write-Warning 'Confirmation did not match. Undo cancelled.'; return }
    $sourceItem = Get-ChildItem -LiteralPath $backupFolder -Force | Where-Object { $_.Name -ne 'backup.json' } | Select-Object -First 1
    if (-not $sourceItem) { throw 'Backup payload not found.' }
    if ($sourceItem.PSIsContainer) {
        Copy-Item -LiteralPath (Join-Path $sourceItem.FullName '*') -Destination $plan.Target -Recurse -Force
    }
    else {
        Copy-Item -LiteralPath $sourceItem.FullName -Destination $plan.Target -Force
    }
    Write-GorLedger -Type 'patch-undo' -Message "Patch undone: $($plan.Id)" -Data $plan | Out-Null
    Write-Host 'Patch undo completed.' -ForegroundColor Green
}

function Resolve-GorSnapshotLikeBackup {
    param([Parameter(Mandatory=$true)][string]$BackupId)
    $paths = Get-GorPaths
    $candidate = Join-Path $paths.Backups $BackupId
    if (Test-Path -LiteralPath $candidate) { return (Resolve-Path -LiteralPath $candidate).Path }
    $matches = @(Get-ChildItem -LiteralPath $paths.Backups -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$BackupId*" })
    if ($matches.Count -eq 1) { return $matches[0].FullName }
    throw "Backup not found or ambiguous: $BackupId"
}

function gorpatchreport {
    param([Parameter(Position=0, Mandatory=$true)][string]$Session)
    $plan = Get-GorPatchPlan -Session $Session
    return (New-GorReport -Title 'Gorrilla Patch Report' -Sections @([pscustomobject]@{ Title='Patch Plan'; Data=$plan }, [pscustomobject]@{ Title='Actions'; Data=$plan.Actions }) -FileName ($plan.Id + '.html'))
}

function gormodels {
    $rows = Get-GorOllamaModels
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

function gormodel {
    param(
        [Parameter(Position=0)][string]$Action = 'status',
        [Parameter(Position=1)][string]$Slot = '',
        [Parameter(Position=2)][string]$Model = ''
    )
    $paths = Get-GorPaths
    $prefs = Read-GorJson -Path $paths.ModelsJson -Default ([pscustomobject]@{ Fast=''; Code=''; Deep=''; Vision=''; UpdatedAt=Get-GorNow })
    switch ($Action.ToLowerInvariant()) {
        'status' {
            Write-GorTable -Rows @($prefs)
            gormodels | Out-Null
            return $prefs
        }
        'set' {
            if ($Slot -notin @('fast','code','deep','vision')) { throw 'Usage: gormodel set fast|code|deep|vision MODEL' }
            if ([string]::IsNullOrWhiteSpace($Model)) { throw 'Model is required.' }
            $prop = (Get-Culture).TextInfo.ToTitleCase($Slot.ToLowerInvariant())
            $prefs.$prop = $Model
            $prefs.UpdatedAt = Get-GorNow
            Write-GorJson -Path $paths.ModelsJson -Value $prefs
            Write-GorLedger -Type 'model' -Message "Model preference set: $Slot" -Data $prefs | Out-Null
            return $prefs
        }
        'auto' {
            $models = @(Get-GorOllamaModels | Where-Object { $_.Status -eq 'INSTALLED' })
            $names = @($models | Select-Object -ExpandProperty Name)
            $small = @($names | Where-Object { $_ -match '1b|2b|3b|mini|small|phi|qwen' }) | Select-Object -First 1
            $code = @($names | Where-Object { $_ -match 'code|coder|qwen|deepseek' }) | Select-Object -First 1
            if ($small) { $prefs.Fast = $small }
            if ($code) { $prefs.Code = $code }
            if (-not $prefs.Deep -and $names.Count -gt 0) { $prefs.Deep = $names[0] }
            $prefs.UpdatedAt = Get-GorNow
            Write-GorJson -Path $paths.ModelsJson -Value $prefs
            Write-GorTable -Rows @($prefs)
            return $prefs
        }
        default { throw "Unknown gormodel action: $Action" }
    }
}

function goraskfile {
    param(
        [Parameter(Position=0, Mandatory=$true)][string]$File,
        [Parameter(Position=1, Mandatory=$true, ValueFromRemainingArguments=$true)][string[]]$Question
    )
    $path = Resolve-Path -LiteralPath $File -ErrorAction Stop
    $raw = Get-Content -LiteralPath $path.Path -Raw -ErrorAction Stop
    $prompt = "Answer using this file only.`nFILE: $($path.Path)`nQUESTION: $($Question -join ' ')`nCONTENT:`n$($raw.Substring(0,[Math]::Min(12000,$raw.Length)))"
    $answer = Invoke-GorAsk -Prompt $prompt -TimeoutSeconds 90
    if ($answer) { Write-Host $answer; return $answer }
    Write-Warning 'Local model unavailable or did not answer.'
}

function goraskproject {
    param(
        [Parameter(Position=0, Mandatory=$true)][string]$Path,
        [Parameter(Position=1, Mandatory=$true, ValueFromRemainingArguments=$true)][string[]]$Question
    )
    $target = Resolve-GorTarget -NameOrPath $Path
    $files = @(Get-GorAppFiles -Path $target -MaxFiles 300 | Where-Object { $_.Length -lt 120000 } | Select-Object -First 40)
    $snips = New-Object System.Collections.Generic.List[string]
    foreach ($file in $files) {
        try {
            $raw = Get-Content -LiteralPath $file.Path -Raw -ErrorAction Stop
            $snips.Add("PATH: $($file.RelativePath)`n$($raw.Substring(0,[Math]::Min(900,$raw.Length)))")
        }
        catch { }
    }
    $prompt = "Answer using local project snippets only.`nPROJECT: $target`nQUESTION: $($Question -join ' ')`nSNIPPETS:`n$($snips -join "`n---`n")"
    $answer = Invoke-GorAsk -Prompt $prompt -TimeoutSeconds 120
    if ($answer) { Write-Host $answer; return $answer }
    Write-Warning 'Local model unavailable or did not answer.'
}

function gortools {
    param([Parameter(Position=0)][string]$Action = 'check')
    $rows = Get-GorToolRows
    switch ($Action.ToLowerInvariant()) {
        'check' { Write-GorTable -Rows $rows; return (ConvertTo-GorArray $rows) }
        'report' { return (New-GorReport -Title 'Gorrilla Tools Report' -Sections @([pscustomobject]@{ Title='Tools'; Data=$rows }) -FileName 'tools.html') }
        'install' {
            Write-GorTable -Rows ($rows | Where-Object Status -eq 'MISSING')
            $typed = Read-Host 'Type INSTALLGORTOOLS to install missing PowerShell modules only'
            if ($typed -ne 'INSTALLGORTOOLS') { Write-Warning 'Confirmation did not match. Nothing installed.'; return }
            foreach ($module in @('Pester','Microsoft.PowerShell.SecretManagement','Microsoft.PowerShell.PSResourceGet')) {
                if (-not (Get-Module -ListAvailable -Name $module -ErrorAction SilentlyContinue)) {
                    Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
                }
            }
            return (Get-GorToolRows)
        }
        'update' {
            $typed = Read-Host 'Type UPDATEGORTOOLS to update known PowerShell modules in CurrentUser scope'
            if ($typed -ne 'UPDATEGORTOOLS') { Write-Warning 'Confirmation did not match. Nothing updated.'; return }
            foreach ($module in @('Pester','Microsoft.PowerShell.SecretManagement','Microsoft.PowerShell.PSResourceGet')) {
                if (Get-Module -ListAvailable -Name $module -ErrorAction SilentlyContinue) {
                    Update-Module -Name $module -ErrorAction SilentlyContinue
                }
            }
            return (Get-GorToolRows)
        }
        default { throw "Unknown gortools action: $Action" }
    }
}

function gorprofile {
    param(
        [Parameter(Position=0, Mandatory=$true)][string]$Name,
        [Parameter(Position=1)][string]$Action = 'show'
    )
    Initialize-GorEnvironment
    if ($Name -in @('edit','report','test','repair','start','stop')) {
        $oldAction = $Name
        $Name = $Action
        $Action = $oldAction
        if ([string]::IsNullOrWhiteSpace($Name) -or $Name -eq $Action) {
            throw "Usage: gorprofile $Action NAME"
        }
    }
    if ($Name -eq 'FireDesk') {
        Initialize-GorFireDeskProfile -Paths (Get-GorPaths)
    }
    $profile = Get-GorProfileObject -Name $Name
    if (-not $profile) {
        $target = if ($Name -eq 'FireDesk') { Get-GorFireDeskPath } else { $Name }
        $profile = [pscustomobject]@{ Name=$Name; Path=$target; AppType=if (Test-Path -LiteralPath $target) { Get-GorAppType -Path $target } else { 'Unknown' }; StartCommand=''; TestCommand=''; RepairMode='Conservative'; Ports=@(); ImportantFiles=@(); LogPaths=@(); HealthChecks=@(); ModelPreference='code'; Notes='' }
        Save-GorProfileObject -Profile $profile | Out-Null
    }
    switch ($Action.ToLowerInvariant()) {
        'show' { Write-GorTable -Rows @($profile); return $profile }
        'edit' { Invoke-Item -LiteralPath (Get-GorProfilePath -Name $Name) -ErrorAction SilentlyContinue; return $profile }
        'report' { return (New-GorReport -Title "Gorrilla Profile $Name" -Sections @([pscustomobject]@{ Title='Profile'; Data=$profile }) -FileName ("profile-$Name.html")) }
        'test' { return (gortest firedesk) }
        'repair' { return (gorstate repair) }
        'start' { if ([string]::IsNullOrWhiteSpace([string]$profile.StartCommand)) { throw 'No start command in profile.' }; Start-Process -FilePath 'pwsh' -ArgumentList @('-NoProfile','-NoExit','-Command',"Set-Location -LiteralPath '$($profile.Path)'; $($profile.StartCommand)") -WorkingDirectory $profile.Path; return $profile }
        'stop' { Write-Warning 'Profile stop is conservative: use gorport/gorkill5000 for explicit process control.'; return $profile }
        default { throw "Unknown gorprofile action: $Action" }
    }
}

function gorserver {
    param(
        [Parameter(Position=0)][string]$Action = 'start',
        [Parameter(Position=1)][int]$Port = 8765
    )
    $paths = Get-GorPaths
    if ($Action -eq 'stop') {
        $state = Read-GorJson -Path $paths.ServerState -Default $null
        if ($state -and ($state.PSObject.Properties.Name -contains 'Pid') -and $state.Pid) {
            Stop-Process -Id ([int]$state.Pid) -Force -ErrorAction SilentlyContinue
        }
        try {
            $servers = @(Get-CimInstance Win32_Process -Filter "name = 'pwsh.exe' or name = 'powershell.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like '*gorrilla-api-server.ps1*' })
            foreach ($server in $servers) {
                if ($server.ProcessId -ne $PID) {
                    Stop-Process -Id ([int]$server.ProcessId) -Force -ErrorAction SilentlyContinue
                }
            }
        }
        catch {}
        Write-GorJson -Path $paths.ServerState -Value ([pscustomobject]@{ Status='STOPPED'; Bind='127.0.0.1'; UpdatedAt=Get-GorNow })
        Write-Host 'Gorrilla dashboard server state stopped.' -ForegroundColor Green
        return (Read-GorJson -Path $paths.ServerState -Default $null)
    }
    $index = New-GorDashboard
    $serverScript = New-GorVisualServerScript
    $existing = Read-GorJson -Path $paths.ServerState -Default $null
    if ($existing -and ($existing.PSObject.Properties.Name -contains 'Url') -and $existing.Url -and (Test-GorVisualServer -Url ([string]$existing.Url))) {
        Write-Host "Gorrilla dashboard already running: $($existing.Url)" -ForegroundColor Green
        return $existing.Url
    }
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if (-not $pwsh) {
        $pwsh = Get-Command powershell -ErrorAction SilentlyContinue
    }
    if (-not $pwsh) {
        throw 'PowerShell executable was not found for the visual API server.'
    }
    $manifest = Join-Path $paths.ModuleRoot 'CommandUnitGorrilla.psd1'
    $argLine = '-NoProfile -ExecutionPolicy Bypass -File "' + ($serverScript.Replace('"','\"')) + '" -Port ' + [string]$Port + ' -Manifest "' + ($manifest.Replace('"','\"')) + '" -WebRoot "' + ($paths.Dashboard.Replace('"','\"')) + '"'
    $proc = Start-Process -FilePath $pwsh.Source -ArgumentList $argLine -WindowStyle Hidden -PassThru
    $url = "http://127.0.0.1:$Port/index.html"
    Write-GorJson -Path $paths.ServerState -Value ([pscustomobject]@{ Status='RUNNING'; Bind='127.0.0.1'; Port=$Port; Url=$url; Pid=$proc.Id; Path=$index; UpdatedAt=Get-GorNow })
    Write-Host "Gorrilla visual app running: $url" -ForegroundColor Green
    return $url
}

function Test-GorVisualServer {
    param([Parameter(Mandatory=$true)][string]$Url)
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2 -ErrorAction Stop
        return ($response.StatusCode -eq 200 -and [string]$response.Content -like '*PowerShell Gorrilla*')
    }
    catch {
        return $false
    }
}

function goropen {
    $paths = Get-GorPaths
    $state = Read-GorJson -Path $paths.ServerState -Default $null
    $target = $null
    if ($state -and ($state.PSObject.Properties.Name -contains 'Url') -and $state.Url -and (Test-GorVisualServer -Url ([string]$state.Url))) {
        $target = [string]$state.Url
    }
    else {
        $target = gorserver
    }
    $openTarget = $target
    if ($openTarget -notmatch '\?') {
        $openTarget = $openTarget + '?v=' + (Get-Date -Format 'yyyyMMddHHmmss')
    }
    try {
        $window = Open-GorAppWindow -Url $openTarget
        $state = Read-GorJson -Path $paths.ServerState -Default $null
        if ($state) {
            Write-GorJson -Path $paths.ServerState -Value ([pscustomobject]@{
                Status = $state.Status
                Bind = $state.Bind
                Port = $state.Port
                Url = $state.Url
                Pid = $state.Pid
                Path = $state.Path
                AppWindow = $window
                UpdatedAt = Get-GorNow
            })
        }
    }
    catch {
        Write-Warning $_.Exception.Message
    }
    return $openTarget
}

function gorvisual {
    $target = goropen
    Write-Host "Visual app opened in no-tabs app window: $target" -ForegroundColor Green
    return $target
}

function gorapi {
    param([Parameter(Position=0)][string]$Resource = 'status')
    switch ($Resource.ToLowerInvariant()) {
        'status' { $data = Get-GorStatusObject }
        'apps' { $data = Get-GorSavedApps }
        'sessions' { $data = gorsessions }
        'reports' { $data = Get-ChildItem -LiteralPath (Get-GorPaths).Reports -File -ErrorAction SilentlyContinue }
        default { throw "Unknown gorapi resource: $Resource" }
    }
    $json = ConvertTo-GorJson -Value $data
    Write-Host $json
    return $data
}

function gorledger {
    param(
        [Parameter(Position=0)][string]$Action = 'list',
        [Parameter(Position=1)][string]$Type = '',
        [Parameter(Position=2, ValueFromRemainingArguments=$true)][string[]]$Message
    )
    $paths = Get-GorPaths
    if (-not (Test-Path -LiteralPath $paths.LedgerJsonl)) { Set-Content -LiteralPath $paths.LedgerJsonl -Value @() -Encoding UTF8 }
    switch ($Action.ToLowerInvariant()) {
        'add' {
            if ([string]::IsNullOrWhiteSpace($Type)) { throw 'Usage: gorledger add TYPE MESSAGE' }
            $entry = Write-GorLedger -Type $Type -Message ($Message -join ' ')
            Write-GorTable -Rows @($entry)
            return $entry
        }
        'search' {
            $text = ($Type + ' ' + ($Message -join ' ')).Trim()
            $rows = Get-Content -LiteralPath $paths.LedgerJsonl -ErrorAction SilentlyContinue | Where-Object { $_ -like "*$text*" }
            foreach ($row in $rows) { Write-Host $row }
            return $rows
        }
        'report' {
            $rows = Get-Content -LiteralPath $paths.LedgerJsonl -ErrorAction SilentlyContinue
            return (New-GorReport -Title 'Gorrilla Evidence Ledger' -Sections @([pscustomobject]@{ Title='Ledger'; Data=$rows }) -FileName 'ledger.html')
        }
        default {
            $rows = Get-Content -LiteralPath $paths.LedgerJsonl -Tail 50 -ErrorAction SilentlyContinue
            foreach ($row in $rows) { Write-Host $row }
            return $rows
        }
    }
}

function gorbackup-module {
    $paths = Get-GorPaths
    $moduleRoot = Resolve-GorLaunchModuleRoot
    $backup = New-GorBackup -Path $moduleRoot -Reason 'module-backup'
    Write-GorLedger -Type 'backup' -Message 'Module backup created.' -Data $backup | Out-Null
    Write-GorTable -Rows @($backup)
    return $backup
}

function gorupgrade-check {
    $moduleRoot = Resolve-GorLaunchModuleRoot
    $rows = @(
        [pscustomobject]@{ Check='Version'; Value=$script:GorVersion },
        [pscustomobject]@{ Check='SourceRoot'; Value=(Get-GorPaths).ModuleRoot },
        [pscustomobject]@{ Check='LauncherModuleRoot'; Value=$moduleRoot },
        [pscustomobject]@{ Check='Backups'; Value=@(Get-GorLastGoodModuleBackups).Count },
        [pscustomobject]@{ Check='Parse'; Value=(Test-GorParseFile -Path (Join-Path $moduleRoot 'CommandUnitGorrilla.psm1')).Ok }
    )
    Write-GorTable -Rows $rows
    return $rows
}

function gorrollback-module {
    param([Parameter(Position=0)][string]$BackupId = '')
    return (gormodule-rollback -BackupId $BackupId)
}

function gorversion {
    $info = [pscustomobject]@{ Version=$script:GorVersion; ModuleRoot=(Get-GorPaths).ModuleRoot; PowerShell=$PSVersionTable.PSVersion.ToString(); DataRoot=(Get-GorPaths).Root }
    Write-GorTable -Rows @($info)
    return $info
}

function gorchangelog {
    $lines = @(
        '2.0.0 - Professional Reliability Pack: test lab, rescue, state, black box, patch studio, model router, profiles, dashboard, ledger, quality, doctor, security, performance, packaging.',
        '1.0.0 - Consolidated local-first Gorrilla module.'
    )
    foreach ($line in $lines) { Write-Host $line }
    return $lines
}

function gorquality {
    param(
        [Parameter(Position=0, Mandatory=$true)][string]$NameOrPath,
        [Parameter(Position=1)][string]$Action = 'show'
    )
    if ($NameOrPath -eq 'report') {
        $NameOrPath = $Action
        $Action = 'report'
    }
    $quality = Get-GorQualityRows -NameOrPath $NameOrPath
    if ($Action -eq 'report') {
        return (New-GorReport -Title 'Gorrilla App Quality Score' -Sections @([pscustomobject]@{ Title='Score'; Data=@([pscustomobject]@{ Target=$quality.Target; Score=$quality.Score }) }, [pscustomobject]@{ Title='Checks'; Data=$quality.Checks }) -FileName 'quality.html')
    }
    Write-GorTable -Rows @([pscustomobject]@{ Target=$quality.Target; Score=$quality.Score })
    Write-GorTable -Rows $quality.Checks
    return $quality
}

function gordoctor {
    param(
        [Parameter(Position=0, Mandatory=$true)][string]$ActionOrPath,
        [Parameter(Position=1)][string]$MaybePath = ''
    )
    $deep = $false
    $report = $false
    $target = $ActionOrPath
    if ($ActionOrPath -eq 'deep') { $deep = $true; $target = $MaybePath }
    if ($ActionOrPath -eq 'report') { $report = $true; $target = $MaybePath }
    $doctor = Get-GorDoctorRows -NameOrPath $target -Deep:$deep
    if ($report) {
        return (New-GorReport -Title 'Gorrilla Project Doctor Pro' -Sections @([pscustomobject]@{ Title='Doctor'; Data=$doctor }, [pscustomobject]@{ Title='Security'; Data=$doctor.Security }, [pscustomobject]@{ Title='Performance'; Data=$doctor.Performance }) -FileName 'doctor.html')
    }
    Write-GorTable -Rows @([pscustomobject]@{ Target=$doctor.Target; AppType=$doctor.AppType; FileCount=$doctor.FileCount })
    return $doctor
}

function gorerror {
    param(
        [Parameter(Position=0)][string]$ActionOrText = '',
        [Parameter(Position=1)][string]$Pattern = '',
        [Parameter(Position=2, ValueFromRemainingArguments=$true)][string[]]$Fix
    )
    $paths = Get-GorPaths
    $errors = @(Read-GorJson -Path $paths.ErrorsJson -Default @())
    switch ($ActionOrText.ToLowerInvariant()) {
        'add' {
            if ([string]::IsNullOrWhiteSpace($Pattern)) { throw 'Usage: gorerror add PATTERN FIX' }
            $errors += [pscustomobject]@{ Pattern=$Pattern; Fix=($Fix -join ' ') }
            Write-GorJson -Path $paths.ErrorsJson -Value $errors
            return $errors[-1]
        }
        'search' {
            $text = ($Pattern + ' ' + ($Fix -join ' ')).Trim()
            $rows = @($errors | Where-Object { $_.Pattern -like "*$text*" -or $_.Fix -like "*$text*" })
            Write-GorTable -Rows $rows
            return $rows
        }
        'report' {
            return (New-GorReport -Title 'Gorrilla Error Knowledge Base' -Sections @([pscustomobject]@{ Title='Errors'; Data=$errors }) -FileName 'errors.html')
        }
        default {
            $text = ($ActionOrText + ' ' + $Pattern + ' ' + ($Fix -join ' ')).Trim()
            $rows = if ([string]::IsNullOrWhiteSpace($text)) { $errors } else { @($errors | Where-Object { $_.Pattern -like "*$text*" -or $_.Fix -like "*$text*" }) }
            Write-GorTable -Rows $rows
            return $rows
        }
    }
}

function gorcmd {
    param(
        [Parameter(Position=0)][string]$Action = 'list',
        [Parameter(Position=1, ValueFromRemainingArguments=$true)][string[]]$Text
    )
    $rows = Get-GorCommandCatalog
    if ($Action -eq 'search') {
        $query = ($Text -join ' ').Trim()
        $rows = @($rows | Where-Object { $_.Command -like "*$query*" -or $_.Category -like "*$query*" -or $_.Description -like "*$query*" })
    }
    elseif ($Action -eq 'report') {
        return (New-GorReport -Title 'Gorrilla Command Palette' -Sections @([pscustomobject]@{ Title='Commands'; Data=$rows }) -FileName 'commands.html')
    }
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

function gorwatch {
    param(
        [Parameter(Position=0)][string]$ActionOrPath = 'status',
        [Parameter(Position=1)][string]$MaybePath = ''
    )
    $paths = Get-GorPaths
    $watchFile = Join-Path $paths.Schedule 'watch.json'
    if ($ActionOrPath -eq 'stop') {
        Write-GorJson -Path $watchFile -Value ([pscustomobject]@{ Status='STOPPED'; UpdatedAt=Get-GorNow })
        Write-Host 'Watch mode stopped.' -ForegroundColor Green
        return
    }
    if ($ActionOrPath -eq 'status') {
        $state = Read-GorJson -Path $watchFile -Default ([pscustomobject]@{ Status='NOT_CONFIGURED' })
        Write-GorTable -Rows @($state)
        return $state
    }
    $target = Resolve-GorTarget -NameOrPath $ActionOrPath
    $state = [pscustomobject]@{ Status='WATCHING'; Target=$target; Mode='notify/report only'; AutoRepair=$false; UpdatedAt=Get-GorNow }
    Write-GorJson -Path $watchFile -Value $state
    Write-GorTable -Rows @($state)
    return $state
}

function gorschedule {
    param([Parameter(Position=0)][string]$Action = 'daily')
    $paths = Get-GorPaths
    if ($Action -eq 'clear') {
        $typed = Read-Host 'Type CLEARGORSCHEDULE to remove Gorrilla schedule config'
        if ($typed -ne 'CLEARGORSCHEDULE') { Write-Warning 'Confirmation did not match. Schedule unchanged.'; return }
        Remove-Item -LiteralPath (Join-Path $paths.Schedule 'schedule.json') -Force -ErrorAction SilentlyContinue
        Write-Host 'Gorrilla schedule config cleared.' -ForegroundColor Green
        return
    }
    if ($Action -eq 'daily') {
        $typed = Read-Host 'Type GORSCHEDULEDAILY to create a local schedule config. Windows Task creation remains manual.'
        if ($typed -ne 'GORSCHEDULEDAILY') { Write-Warning 'Confirmation did not match. Schedule unchanged.'; return }
        $state = [pscustomobject]@{ Status='CONFIGURED'; Frequency='Daily'; AutoRepair=$false; Command='gorreport health'; UpdatedAt=Get-GorNow }
        Write-GorJson -Path (Join-Path $paths.Schedule 'schedule.json') -Value $state
        Write-GorTable -Rows @($state)
        return $state
    }
    throw "Unknown gorschedule action: $Action"
}

function gorsecurity {
    param(
        [Parameter(Position=0)][string]$ActionOrPath = 'laptop',
        [Parameter(Position=1)][string]$MaybePath = ''
    )
    if ($ActionOrPath -eq 'report') {
        $rows = Get-GorSecurityFindings -NameOrPath $MaybePath
        return (New-GorReport -Title 'Gorrilla Security Review' -Sections @([pscustomobject]@{ Title='Findings'; Data=$rows }) -FileName 'security.html')
    }
    $target = if ($ActionOrPath -eq 'laptop') { '' } else { $ActionOrPath }
    $rows = Get-GorSecurityFindings -NameOrPath $target
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

function gorperf {
    param(
        [Parameter(Position=0)][string]$ActionOrPath = 'laptop',
        [Parameter(Position=1)][string]$MaybePath = ''
    )
    if ($ActionOrPath -eq 'report') {
        $rows = Get-GorPerfRows -NameOrPath $MaybePath
        return (New-GorReport -Title 'Gorrilla Performance Lab' -Sections @([pscustomobject]@{ Title='Performance'; Data=$rows }) -FileName 'performance.html')
    }
    $target = if ($ActionOrPath -eq 'app') { $MaybePath } elseif ($ActionOrPath -eq 'laptop') { '' } else { $ActionOrPath }
    $rows = Get-GorPerfRows -NameOrPath $target
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

function gorpackage {
    param(
        [Parameter(Position=0, Mandatory=$true)][string]$NameOrPath,
        [Parameter(Position=1)][string]$Action = 'create'
    )
    if ($NameOrPath -eq 'report') {
        $NameOrPath = $Action
        $Action = 'report'
    }
    $target = Resolve-GorTarget -NameOrPath $NameOrPath
    if ($Action -eq 'report') {
        $files = @(Get-GorAppFiles -Path $target -MaxFiles 5000 | Where-Object { $_.RelativePath -notmatch '(^|\\)(node_modules|\.venv|__pycache__|dist|build)(\\|$)' })
        return (New-GorReport -Title 'Gorrilla Release Package Plan' -Sections @([pscustomobject]@{ Title='Files'; Data=$files }) -FileName 'package-plan.html')
    }
    $filesForSize = @(Get-GorAppFiles -Path $target -MaxFiles 10000 | Where-Object { $_.RelativePath -notmatch '(^|\\)(node_modules|\.venv|__pycache__|dist|build)(\\|$)' })
    $size = ($filesForSize | Measure-Object Length -Sum).Sum
    Write-Host ("Package source: {0}" -f $target)
    Write-Host ("Estimated included size MB: {0}" -f ([math]::Round(($size / 1MB),2)))
    $typed = Read-Host 'Type PACKAGEGORRILLA to create the zip package'
    if ($typed -ne 'PACKAGEGORRILLA') { Write-Warning 'Confirmation did not match. Package cancelled.'; return }
    $paths = Get-GorPaths
    $name = (Split-Path -Leaf $target)
    $staging = Join-Path $paths.Packages (New-GorId -Prefix "package-$name")
    New-Item -ItemType Directory -Path $staging -Force | Out-Null
    foreach ($file in $filesForSize) {
        $dest = Join-Path $staging $file.RelativePath
        $parent = Split-Path -Parent $dest
        if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item -LiteralPath $file.Path -Destination $dest -Force
    }
    $zip = $staging + '.zip'
    Compress-Archive -LiteralPath (Join-Path $staging '*') -DestinationPath $zip -Force
    Write-GorLedger -Type 'package' -Message 'Release package created.' -Data ([pscustomobject]@{ Zip=$zip; Source=$target }) | Out-Null
    Write-Host "Package written: $zip" -ForegroundColor Green
    return $zip
}

function goralerts {
    param([Parameter(Position=0)][string]$Action = 'list')
    $alerts = Get-GorAlerts
    if ($Action -eq 'report') {
        return (New-GorReport -Title 'Gorrilla Alerts' -Sections @([pscustomobject]@{ Title='Alerts'; Data=$alerts }) -FileName 'alerts.html')
    }
    Write-GorTable -Rows $alerts
    return (ConvertTo-GorArray $alerts)
}

function goroptions {
    param([Parameter(Position=0)][string]$Action = 'list')
    $options = Get-GorOptions
    if ($Action -eq 'report') {
        return (New-GorReport -Title 'Gorrilla Fix Options' -Sections @([pscustomobject]@{ Title='Options'; Data=$options }) -FileName 'options.html')
    }
    Write-GorTable -Rows $options
    return (ConvertTo-GorArray $options)
}

function goradvisor {
    param([Parameter(Position=0)][string]$Action = 'run')
    $advisor = Invoke-GorAdvisor
    if ($Action -eq 'report') {
        return (New-GorReport -Title 'Gorrilla Advisor' -Sections @([pscustomobject]@{ Title='Alerts'; Data=$advisor.Alerts }, [pscustomobject]@{ Title='Options'; Data=$advisor.Options }) -FileName 'advisor.html')
    }
    Write-Host ("Advisor: " + $advisor.Summary) -ForegroundColor Cyan
    Write-GorTable -Rows $advisor.Alerts
    Write-GorTable -Rows $advisor.Options
    return $advisor
}

function gorelite {
    param([Parameter(Position=0)][string]$Action = 'status')
    switch ($Action.ToLowerInvariant()) {
        'status' {
            $rows = Get-GorEliteStackRows
            Write-GorTable -Rows $rows
            return (ConvertTo-GorArray $rows)
        }
        'issues' {
            $issues = Get-GorEliteStackIssues
            Write-GorTable -Rows $issues
            return (ConvertTo-GorArray $issues)
        }
        'report' {
            return (gorelite-report)
        }
        'fix' {
            return (gorelite-fix)
        }
        default {
            throw 'Usage: gorelite [status|issues|report|fix]'
        }
    }
}

function gorstack {
    param([Parameter(Position=0)][string]$Action = 'status')
    return (gorelite -Action $Action)
}

function gorelite-fix {
    $results = Repair-GorEliteStack
    Write-GorTable -Rows $results
    Write-Host 'Run gorelite again. For MSI/app installer failures such as LM Studio or Node LTS 1603, reopen PowerShell first; if they persist, run the vendor installer interactively.' -ForegroundColor Yellow
    return (ConvertTo-GorArray $results)
}

function gorstack-fix {
    return (gorelite-fix)
}

function gorelite-report {
    $path = New-GorEliteStackReport
    Write-Host "Elite stack report written: $path" -ForegroundColor Green
    return $path
}

function gordo {
    param(
        [Parameter(Position=0)][string]$Mode = 'now',
        [Parameter(Position=1)][string]$Target = ''
    )
    Initialize-GorEnvironment
    $modeName = $Mode.ToLowerInvariant()
    $results = New-Object System.Collections.Generic.List[object]
    switch ($modeName) {
        'now' {
            $results.Add((Invoke-GorEverythingStep -Step 'Status' -Script { gorstatus }))
            $results.Add((Invoke-GorEverythingStep -Step 'Elite summary' -Script { Get-GorEliteStackSummary }))
            $results.Add((Invoke-GorEverythingStep -Step 'Launch catalog' -Script { Get-GorLaunchCatalog }))
        }
        'boost' {
            $results.Add((Invoke-GorEverythingStep -Step 'Elite safe repair' -Script { gorelite-fix }))
            $results.Add((Invoke-GorEverythingStep -Step 'Baseline' -Script { gorbaseline }))
            $results.Add((Invoke-GorEverythingStep -Step 'Elite report' -Script { gorelite-report }))
            $results.Add((Invoke-GorEverythingStep -Step 'Visual dashboard' -Script { gorvisual }))
        }
        'full' {
            $results.Add((Invoke-GorEverythingStep -Step 'Module self-test' -Script { gorselftest }))
            $results.Add((Invoke-GorEverythingStep -Step 'Test lab' -Script { gortest all }))
            $results.Add((Invoke-GorEverythingStep -Step 'All reports' -Script { gorreport all }))
            $results.Add((Invoke-GorEverythingStep -Step 'Elite report' -Script { gorelite-report }))
            $results.Add((Invoke-GorEverythingStep -Step 'Visual dashboard' -Script { gorvisual }))
        }
        'fix' {
            $results.Add((Invoke-GorEverythingStep -Step 'Elite safe repair' -Script { gorelite-fix }))
            $results.Add((Invoke-GorEverythingStep -Step 'Profile check' -Script { gorprofile-check }))
            $results.Add((Invoke-GorEverythingStep -Step 'Advisor' -Script { goradvisor }))
        }
        'ai' {
            $results.Add((Invoke-GorEverythingStep -Step 'AI lab' -Script { gorai }))
        }
        'web' {
            if ([string]::IsNullOrWhiteSpace($Target)) {
                throw 'Usage: gordo web APP_NAME'
            }
            $results.Add((Invoke-GorEverythingStep -Step "Create web app $Target" -Script { gornewweb $Target }))
        }
        'app' {
            if ([string]::IsNullOrWhiteSpace($Target)) {
                $Target = (Get-Location).Path
            }
            $resolvedTarget = $Target
            $results.Add((Invoke-GorEverythingStep -Step 'Project doctor' -Script { gordoctor $resolvedTarget }))
            $results.Add((Invoke-GorEverythingStep -Step 'Quality score' -Script { gorquality $resolvedTarget }))
            $results.Add((Invoke-GorEverythingStep -Step 'Security scan' -Script { gorsecurity $resolvedTarget }))
            $results.Add((Invoke-GorEverythingStep -Step 'Performance scan' -Script { gorperf app $resolvedTarget }))
            $results.Add((Invoke-GorEverythingStep -Step 'Patch preview' -Script { gorpatchplan $resolvedTarget }))
        }
        'launch' {
            if ([string]::IsNullOrWhiteSpace($Target)) {
                $Target = 'list'
            }
            $results.Add((Invoke-GorEverythingStep -Step "Launch $Target" -Script { gorlaunch $Target }))
        }
        'report' {
            $results.Add((Invoke-GorEverythingStep -Step 'All reports' -Script { gorreport all }))
            $results.Add((Invoke-GorEverythingStep -Step 'Elite report' -Script { gorelite-report }))
        }
        default {
            throw 'Usage: gordo now|boost|full|fix|ai|web APP_NAME|app PATH|launch NAME|report'
        }
    }
    Write-GorLedger -Type 'everything' -Message "gordo completed: $Mode" -Data $results | Out-Null
    Write-GorTable -Rows $results
    return (ConvertTo-GorArray $results)
}

function goreverything {
    param(
        [Parameter(Position=0)][string]$Mode = 'now',
        [Parameter(Position=1)][string]$Target = ''
    )
    return (gordo -Mode $Mode -Target $Target)
}

function gorboost {
    return (gordo boost)
}

function gorai {
    $rows = Invoke-GorAiLab
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

function gorlaunch {
    param([Parameter(Position=0)][string]$Name = 'list')
    $result = Start-GorLaunchTarget -Name $Name
    Write-GorTable -Rows $result
    return $result
}

function gornewweb {
    param(
        [Parameter(Position=0, Mandatory=$true)][string]$Name,
        [Parameter(Position=1)][string]$ParentPath = ''
    )
    $result = New-GorNextWebApp -Name $Name -ParentPath $ParentPath
    Write-GorTable -Rows @($result)
    return $result
}

function gorintegrate {
    $rows = Get-GorIntegrationMap
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

function gorfixqueue {
    $rows = Get-GorFixQueue
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

function gorprompt {
    param([Parameter(Position=0)][string]$Action = 'list')
    $paths = Get-GorPaths
    switch ($Action.ToLowerInvariant()) {
        'list' {
            $rows = @(
                [pscustomobject]@{ Name='intent'; Path=$paths.IntentPrompt; Purpose='Routes natural language to safe Gorilla command suggestions.' },
                [pscustomobject]@{ Name='safety'; Path=$paths.SafetyPrompt; Purpose='Documents local-first safety rules.' }
            )
            Write-GorTable -Rows $rows
            return $rows
        }
        'intent' { Invoke-Item -LiteralPath $paths.IntentPrompt -ErrorAction SilentlyContinue; return $paths.IntentPrompt }
        'safety' { Invoke-Item -LiteralPath $paths.SafetyPrompt -ErrorAction SilentlyContinue; return $paths.SafetyPrompt }
        'show' {
            Get-Content -LiteralPath $paths.IntentPrompt -ErrorAction SilentlyContinue
            Get-Content -LiteralPath $paths.SafetyPrompt -ErrorAction SilentlyContinue
            return
        }
        default { throw 'Usage: gorprompt list|intent|safety|show' }
    }
}

function gorunderstand {
    param([Parameter(Position=0, Mandatory=$true, ValueFromRemainingArguments=$true)][string[]]$Text)
    $result = Invoke-GorUnderstanding -Text ($Text -join ' ')
    Write-Host 'Suggested safe commands:' -ForegroundColor Cyan
    Write-GorTable -Rows $result.Suggestions
    Write-Host ''
    Write-Host 'Ollama / local reasoning:' -ForegroundColor Cyan
    Write-Host $result.Ollama
    return $result
}

function gorworkflow {
    param(
        [Parameter(Position=0)][string]$Action = 'list',
        [Parameter(Position=1)][string]$Name = ''
    )
    $catalog = @(Get-GorWorkflowCatalog)
    if ($Action -eq 'list') {
        Write-GorTable -Rows $catalog
        return $catalog
    }
    if ($Action -eq 'show') {
        $row = $catalog | Where-Object Name -eq $Name | Select-Object -First 1
        if (-not $row) { throw "Workflow not found: $Name" }
        Write-GorTable -Rows @($row)
        return $row
    }
    if ($Action -eq 'run') {
        $row = $catalog | Where-Object Name -eq $Name | Select-Object -First 1
        if (-not $row) { throw "Workflow not found: $Name" }
        switch ($row.Name) {
            'daily' { return (gordo now) }
            'boost' { return (gordo boost) }
            'full' { return (gordo full) }
            'app' { return (gordo app '.') }
            'ai' { return (gordo ai) }
            'security' { return (gorsecurity '.') }
            'design' { return (gorlaunch figma) }
            'api' { return (gorlaunch bruno) }
            'update' { return (gorupdate preview) }
            default { Write-Warning "Workflow needs an argument. Use command manually: $($row.Command)"; return $row }
        }
    }
    throw 'Usage: gorworkflow list|show NAME|run NAME'
}

function gorupdate {
    param(
        [Parameter(Position=0)][string]$Action = 'preview',
        [Parameter(Position=1)][string]$SourcePath = '',
        [string]$ConfirmText = ''
    )
    switch ($Action.ToLowerInvariant()) {
        'preview' {
            $plan = Get-GorUpdatePlan -SourcePath $SourcePath
            Write-GorJson -Path (Get-GorPaths).UpdatePlanJson -Value $plan
            Write-GorTable -Rows @($plan)
            return $plan
        }
        'report' {
            $plan = Get-GorUpdatePlan -SourcePath $SourcePath
            return (New-GorReport -Title 'Gorrilla Update Center' -Sections @([pscustomobject]@{ Title='Update Plan'; Data=$plan }, [pscustomobject]@{ Title='Backups'; Data=(Get-GorLastGoodModuleBackups) }) -FileName 'update-center.html')
        }
        'apply' {
            if ([string]::IsNullOrWhiteSpace($SourcePath)) { throw 'Usage: gorupdate apply SOURCE_PATH -ConfirmText UPDATEGORRILLA' }
            $result = Invoke-GorUpdateApply -SourcePath $SourcePath -ConfirmText $ConfirmText
            Write-GorTable -Rows @($result)
            return $result
        }
        'rollback' {
            return (gormodule-rollback $SourcePath)
        }
        default { throw 'Usage: gorupdate preview [SOURCE_PATH] | report [SOURCE_PATH] | apply SOURCE_PATH -ConfirmText UPDATEGORRILLA | rollback BACKUP_ID' }
    }
}

function Get-GorDesktopTidyPlan {
    $desktop = Get-GorDesktop
    $rows = New-Object System.Collections.Generic.List[object]
    $shortcutsFolder = Join-Path $desktop '02 - App Library\Shortcuts'
    $launchersFolder = Join-Path $desktop '01 - Active Projects\CommandUnitGorrilla Launchers'
    $testingFolder = Join-Path $desktop '04 - Testing and Checkpoints'
    $items = Get-ChildItem -LiteralPath $desktop -Force -ErrorAction SilentlyContinue
    foreach ($item in $items) {
        if ($item.Name -in @('desktop.ini','CommandUnitGorrilla','FireDeskElite','CommandUnit Gorrilla.cmd','CommandUnit Gorrilla Rescue.cmd','FireDeskElite.lnk','01 - Active Projects','02 - App Library','03 - Private','04 - Testing and Checkpoints','05 - Reports and Archives','06 - Installers')) {
            continue
        }
        if ($item.Extension -eq '.lnk') {
            $rows.Add([pscustomobject]@{ Name=$item.Name; From=$item.FullName; To=(Join-Path $shortcutsFolder $item.Name); Reason='Desktop app shortcut'; Action='MOVE' })
        }
        elseif ($item.Name -like 'CommandUnit*.cmd') {
            $rows.Add([pscustomobject]@{ Name=$item.Name; From=$item.FullName; To=(Join-Path $launchersFolder $item.Name); Reason='Gorrilla launcher'; Action='MOVE' })
        }
        elseif ($item.PSIsContainer -and $item.Name -like 'Test*') {
            $rows.Add([pscustomobject]@{ Name=$item.Name; From=$item.FullName; To=(Join-Path $testingFolder $item.Name); Reason='Testing/checkpoint folder'; Action='MOVE' })
        }
    }
    return (ConvertTo-GorArray $rows)
}

function gordesktop {
    param(
        [Parameter(Position=0)][string]$Action = 'tidy',
        [string]$ConfirmText = ''
    )
    $plan = @(Get-GorDesktopTidyPlan)
    if ($Action -in @('tidy','preview')) {
        Write-GorTable -Rows $plan
        return (ConvertTo-GorArray $plan)
    }
    if ($Action -ne 'apply') {
        throw 'Usage: gordesktop tidy | gordesktop apply'
    }
    Write-GorTable -Rows $plan
    if ($plan.Count -eq 0) {
        Write-Host 'Desktop tidy plan is empty.' -ForegroundColor Green
        return @()
    }
    if ($ConfirmText -ne 'TIDYGORRILLA') {
        $ConfirmText = Read-Host 'Type TIDYGORRILLA to move desktop items into the numbered folders'
    }
    if ($ConfirmText -ne 'TIDYGORRILLA') {
        Write-Warning 'Confirmation did not match. Desktop unchanged.'
        return
    }
    $paths = Get-GorPaths
    $backupFolder = Join-Path $paths.Backups (New-GorId -Prefix 'desktop-tidy-plan')
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
    $backup = [pscustomobject]@{ Id=(Split-Path -Leaf $backupFolder); BackupPath=(Join-Path $backupFolder 'desktop-tidy-plan.json'); CreatedAt=Get-GorNow; Mode='Move plan only; original files are moved, not copied.' }
    Write-GorJson -Path $backup.BackupPath -Value $plan
    $results = New-Object System.Collections.Generic.List[object]
    foreach ($item in $plan) {
        try {
            $parent = Split-Path -Parent $item.To
            if ($parent -and -not (Test-Path -LiteralPath $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }
            Move-Item -LiteralPath $item.From -Destination $item.To -Force -ErrorAction Stop
            $results.Add([pscustomobject]@{ Name=$item.Name; Status='MOVED'; To=$item.To })
        }
        catch {
            $results.Add([pscustomobject]@{ Name=$item.Name; Status='FAILED'; Detail=$_.Exception.Message })
        }
    }
    Write-GorLedger -Type 'desktop' -Message 'Desktop tidy applied.' -Data ([pscustomobject]@{ Backup=$backup; Results=$results }) | Out-Null
    Write-GorTable -Rows $results
    return (ConvertTo-GorArray $results)
}

function gorselftest {
    Initialize-GorEnvironment
    $paths = Get-GorPaths
    $rows = New-Object System.Collections.Generic.List[object]
    $moduleFile = Join-Path $paths.ModuleRoot 'CommandUnitGorrilla.psm1'
    if (Test-Path -LiteralPath $moduleFile) {
        $parse = Test-GorParseFile -Path $moduleFile
        $rows.Add([pscustomobject]@{ Check='Parser'; Target=$moduleFile; Status=if ($parse.Ok) { 'OK' } else { 'FAILED' }; Detail=(@($parse.Errors) | Out-String).Trim() })
    }
    else {
        $rows.Add([pscustomobject]@{ Check='Parser'; Target=$moduleFile; Status='FAILED'; Detail='Module file missing.' })
    }
    foreach ($folder in @($paths.Root,$paths.Fleet,$paths.Sessions,$paths.Snapshots,$paths.Reports,$paths.Vault,$paths.Backups,$paths.Launchers)) {
        $rows.Add([pscustomobject]@{ Check='Folder'; Target=$folder; Status=if (Test-Path -LiteralPath $folder) { 'OK' } else { 'FAILED' }; Detail='' })
    }
    foreach ($cmd in $script:GorExpectedCommands) {
        $found = Get-Command $cmd -ErrorAction Ignore
        $rows.Add([pscustomobject]@{ Check='Command'; Target=$cmd; Status=if ($found) { 'OK' } else { 'FAILED' }; Detail=if ($found) { $found.CommandType } else { 'Missing' } })
    }
    $aliasRows = Get-Alias -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'gor*' -or $_.Name -eq 'gorrilla' }
    foreach ($alias in $aliasRows) {
        $targetCmd = Get-Command $alias.Definition -ErrorAction Ignore
        $rows.Add([pscustomobject]@{ Check='Alias'; Target=$alias.Name; Status=if ($targetCmd) { 'OK' } else { 'FAILED' }; Detail=$alias.Definition })
    }
    Write-GorTable -Rows $rows
    return (ConvertTo-GorArray $rows)
}

Initialize-GorEnvironment

Export-ModuleMember -Function $script:GorExpectedCommands







