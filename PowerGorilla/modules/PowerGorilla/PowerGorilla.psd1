@{
    RootModule = 'PowerGorilla.psm1'
    ModuleVersion = '0.1.0'
    GUID = '4d9cfc4e-81f6-4e7b-9b24-5a24b7a9c001'
    Author = 'Phat Gorrilla'
    CompanyName = 'Local'
    Copyright = '(c) 2026. Local-first utility.'
    Description = 'PowerShell-first local command centre for safe app inventory, workflow integration search, icon workflow building, sign-in status, and dry-run computer care.'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop','Core')
    FunctionsToExport = @(
        'Initialize-PGProject',
        'Invoke-PGRefreshData',
        'Get-PGDatasetStatus',
        'Get-PGAppInventory',
        'Import-PGIntegrationDatasets',
        'Get-PGIntegrationSearch',
        'Get-PGWorkflowSuggestions',
        'Get-PGSuggestedWorkflows',
        'Get-PGSignInReport',
        'Update-PGIconCache',
        'Invoke-PGCommand',
        'Get-PGSystemHealth',
        'Get-PGDiskHealth',
        'Get-PGOllamaModels',
        'Get-PGStartupApps',
        'Get-PGPorts',
        'New-PGWorkflowActionPlan',
        'Start-PGDashboardServer',
        'Write-PGLog'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('PowerGorilla','PowerShell','LocalFirst','Windows','SafeMode','Ollama')
            ProjectUri = ''
            ReleaseNotes = 'Phase 1 foundation: source CSV imports, app inventory, integration search, local icon cache, sign-in classification, dry-run command engine, and read-only dashboard data.'
        }
    }
}
