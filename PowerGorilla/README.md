# Power Gorilla

Power Gorilla is a PowerShell-first, local-first Windows command centre for app inventory, workflow integration search, visual app-icon workflow building, sign-in status review, and safe dry-run system care.

## Phase 1 Status

Built:
- Folder structure under `PowerGorilla`
- PowerShell module under `modules\PowerGorilla`
- Dataset imports under `data\imports`
- Processed dashboard data under `data\processed`
- Safe icon cache under `data\icons`
- Read-only dashboard under `ui`
- Setup, launcher, and validation scripts
- Dry-run command engine
- Sign-in/local availability classifier
- Visual app icon integration builder

Not yet enabled:
- Confirmed system-changing fixes
- Confirmed app updates
- Restore point execution
- Ollama-assisted analysis execution

## Setup

From the `PowerGorilla` folder:

```powershell
.\scripts\Setup-PowerGorilla.ps1
```

Optional desktop icon commands:

```powershell
.\scripts\Setup-PowerGorilla.ps1 -CreateDesktopIcon
.\scripts\Setup-PowerGorilla.ps1 -RepairDesktopIcon
.\scripts\Setup-PowerGorilla.ps1 -RemoveDesktopIcon
```

Optional icon extraction:

```powershell
.\scripts\Setup-PowerGorilla.ps1 -ExtractIcons
```

## Launch

```powershell
.\Start-PowerGorilla.ps1
```

The dashboard runs locally at:

```text
http://127.0.0.1:8765/
```

To launch without opening a browser:

```powershell
.\Start-PowerGorilla.ps1 -NoBrowser
```

## Validate

```powershell
.\scripts\Validate-PowerGorilla.ps1 -RefreshData
```

Validation writes a JSON report under `reports`.

## Source Datasets

Expected source files:

- `data\imports\Proper_Apps_Shortlist.csv`
- `data\imports\Two_App_20K_Free_OpenSource_Combinations.csv`
- `data\imports\Three_App_200K_Free_OpenSource_Integrations.csv`
- `data\imports\Four_App_400K_Free_OpenSource_Integrations.csv`

If `Proper_Apps_Shortlist.csv` is not present, Power Gorilla derives app candidates from the imported integration datasets.

## Safety Rules

- Strict Safe Mode is the default.
- Dashboard launch/update/fix buttons preview actions only in Phase 1.
- No passwords, tokens, cookies, sessions, or private keys are stored.
- No destructive system action runs without explicit future confirmation support.
- Logs redact common credential patterns.
- Cloud sign-in is detected as a status/classification only; Power Gorilla does not sign into apps.
