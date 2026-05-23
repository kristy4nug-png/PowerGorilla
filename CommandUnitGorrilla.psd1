@{
    RootModule = 'CommandUnitGorrilla.psm1'
    ModuleVersion = '2.5.0'
    GUID = 'f6a7170d-d30f-4b7d-9801-3187aaef81fb'
    Author = 'PowerShell Gorrilla'
    CompanyName = 'Local'
    Copyright = '(c) 2026. Local-first module.'
    Description = 'Professional local-first Windows command operating layer for app inspection, reliability testing, repair, reporting, local AI routing, FireDesk support, fleet profiles, security review, and release packaging.'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop','Core')
    FunctionsToExport = @(
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
        'gorsecurity','gorperf','gorpackage','gorvisual','gordesktop','goralerts','goroptions','goradvisor','gorappdiscover','gorlaptopscan',
        'gorelite','gorstack','gorelite-fix','gorstack-fix','gorelite-report',
        'gordo','goreverything','gorboost','gorai','gorlaunch','gornewweb',
        'gorintegrate','gorfixqueue',
        'gorprompt','gorunderstand','gorworkflow','gorupdate','New-GorDesignBrief','Resolve-GorIntent','Get-GorInstalledApps',
        'Get-GorCreativePipelines','New-GorCreativeProject','New-GorHugeCheck',
        'Get-GorConnectorStatus','Set-GorConnectorPassport','New-GorBookProject','Get-GorProductVision','Get-GorWorldClassWorkflowPacks',
        'Get-GorBackupPosture','Invoke-GorKeepOneBackup','Get-GorDesktopAppInventory','Get-GorPackageBank',
        'gorconnectors','gorbook','gorkeeponebackup','gordesktopapps','gorpackagebank'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('CommandUnit','Gorrilla','LocalAI','Windows','Repair','Fleet')
            ProjectUri = ''
            ReleaseNotes = 'Real App Shell: adds Mission Control intent input, guided local plan cards, mode switching, starter prompts, safer run flow, and dashboard app data for a more complete local application experience.'
        }
    }
}
