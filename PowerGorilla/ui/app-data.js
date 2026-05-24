window.POWER_GORILLA_STATE = {
  "generatedAt": "2026-05-24T00:00:00.0000000+01:00",
  "safety": {
    "mode": "Strict Safe Mode",
    "destructiveActionsEnabled": false,
    "dangerousButtonsPreviewOnly": true,
    "credentialsStored": false,
    "costPolicy": "Local-first; no paid subscriptions; free-tier only when a cloud service is unavoidable.",
    "paidOrTrialBlocked": true,
    "localFirst": true
  },
  "datasets": [
    {
      "Type": "Apps",
      "CombinationSize": 1,
      "ExpectedName": "Proper_Apps_Shortlist.csv",
      "Exists": false,
      "Length": 0
    },
    {
      "Type": "Two_App",
      "CombinationSize": 2,
      "ExpectedName": "Two_App_20K_Free_OpenSource_Combinations.csv",
      "Exists": false,
      "Length": 0
    },
    {
      "Type": "Three_App",
      "CombinationSize": 3,
      "ExpectedName": "Three_App_200K_Free_OpenSource_Integrations.csv",
      "Exists": false,
      "Length": 0
    },
    {
      "Type": "Four_App",
      "CombinationSize": 4,
      "ExpectedName": "Four_App_400K_Free_OpenSource_Integrations.csv",
      "Exists": false,
      "Length": 0
    }
  ],
  "apps": [
    {
      "Id": "powershell",
      "Name": "PowerShell",
      "Category": "Built-in automation",
      "LicenceMode": "Built-in",
      "IsOpenSource": true,
      "IsFreeOrFreeTier": true,
      "SignInMode": "No sign-in needed",
      "LocalMode": "Local mode available",
      "Status": "Installed",
      "Installed": true,
      "IconUrl": "../data/icons/fallback-app.svg",
      "CostAllowed": true,
      "CostPolicy": "Local-first; no paid subscriptions; free-tier only when a cloud service is unavoidable."
    },
    {
      "Id": "ollama",
      "Name": "Ollama",
      "Category": "Local AI runtime",
      "LicenceMode": "Free",
      "IsOpenSource": true,
      "IsFreeOrFreeTier": true,
      "SignInMode": "No sign-in needed",
      "LocalMode": "Local mode available",
      "Status": "Optional",
      "Installed": false,
      "IconUrl": "../data/icons/fallback-app.svg",
      "CostAllowed": true,
      "CostPolicy": "Local-first; no paid subscriptions; free-tier only when a cloud service is unavoidable."
    },
    {
      "Id": "supabase",
      "Name": "Supabase",
      "Category": "Optional free-tier backend",
      "LicenceMode": "Free-tier",
      "IsOpenSource": true,
      "IsFreeOrFreeTier": true,
      "SignInMode": "Optional sign-in",
      "LocalMode": "Local dashboard does not require it",
      "Status": "Optional",
      "Installed": false,
      "IconUrl": "../data/icons/fallback-app.svg",
      "CostAllowed": true,
      "CostPolicy": "Local-first; no paid subscriptions; free-tier only when a cloud service is unavoidable."
    },
    {
      "Id": "github",
      "Name": "GitHub",
      "Category": "Source control",
      "LicenceMode": "Free-tier",
      "IsOpenSource": false,
      "IsFreeOrFreeTier": true,
      "SignInMode": "Optional sign-in",
      "LocalMode": "Local git works without cloud sync",
      "Status": "Optional",
      "Installed": false,
      "IconUrl": "../data/icons/fallback-app.svg",
      "CostAllowed": true,
      "CostPolicy": "Local-first; no paid subscriptions; free-tier only when a cloud service is unavoidable."
    }
  ],
  "integrations": [
    {
      "Id": "demo-000001",
      "SourceFile": "README demo",
      "CombinationSize": 2,
      "AppNames": ["PowerShell", "Ollama"],
      "NormalizedAppNames": ["powershell", "ollama"],
      "WorkflowName": "Local AI batch processing",
      "Description": "Use PowerShell to feed schema-checked local work items to Ollama without paid APIs.",
      "Category": "Local automation",
      "Difficulty": "Medium",
      "RiskLevel": "Low",
      "AutomationReadiness": "Automation-ready",
      "InstalledCount": 1,
      "OpenSourceCount": 2,
      "FreeCount": 2,
      "LocalCount": 2,
      "FreeOpenSourceStatus": "All free/free-tier where known",
      "SignInRequirement": "No sign-in needed where known",
      "LocalOnlyAvailability": "Local-only available",
      "CostAllowed": true,
      "RankScore": 98,
      "PowerShellPlan": ["Invoke-PGCommand -Name 'LaunchApps' -Target 'PowerShell, Ollama' -WhatIf"]
    },
    {
      "Id": "demo-000002",
      "SourceFile": "README demo",
      "CombinationSize": 3,
      "AppNames": ["PowerShell", "Supabase", "GitHub"],
      "NormalizedAppNames": ["powershell", "supabase", "github"],
      "WorkflowName": "Optional free-tier sync and release flow",
      "Description": "Keep the dashboard local-first while publishing code, releases, and optional sync through free-tier services.",
      "Category": "Release readiness",
      "Difficulty": "Medium",
      "RiskLevel": "Low",
      "AutomationReadiness": "Automation-ready",
      "InstalledCount": 1,
      "OpenSourceCount": 2,
      "FreeCount": 3,
      "LocalCount": 1,
      "FreeOpenSourceStatus": "All free/free-tier where known",
      "SignInRequirement": "Supabase: Optional sign-in; GitHub: Optional sign-in",
      "LocalOnlyAvailability": "Partial local mode",
      "CostAllowed": true,
      "RankScore": 86,
      "PowerShellPlan": ["./scripts/Validate-PowerGorilla.ps1 -StaticOnly"]
    }
  ],
  "signIn": [],
  "suggestions": [],
  "favourites": [],
  "stats": {
    "apps": 4,
    "installedApps": 1,
    "missingApps": 3,
    "costAllowedApps": 4,
    "blockedPaidApps": 0,
    "workflows": 2,
    "twoApp": 1,
    "threeApp": 1,
    "fourApp": 0,
    "iconsExtracted": 0
  }
};
