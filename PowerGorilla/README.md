# Phat Gorrilla

<img src="docs/assets/phat-gorrilla-logo.png" alt="Phat Gorrilla logo" width="180">

Phat Gorrilla is a PowerShell-first, local-first Windows command centre for app inventory, workflow search, visual app-icon workflow building, sign-in status review, Ollama-backed JSON schema processing, and safe dry-run system care.

## Hard Rules

- Local-first operation is the default.
- No paid subscriptions, paid APIs, trials, premium plans, or commercial-only app recommendations.
- Free, open-source, built-in Windows tools, and free-tier services are allowed.
- Supabase, Cloudflare Pages, GitHub Pages, and Expo are optional free-tier integrations. The local dashboard does not require them.

## Built

- Local PowerShell app under `PowerGorilla`
- Dashboard under `ui`
- Expo frontend under `frontend`
- JSON schemas under `schema`
- Optional Supabase migrations under `supabase/migrations`
- Dataset imports under `data/imports`
- Processed local state under `data/processed`
- Setup, launcher, validation, batch, and orchestration scripts
- Strict Safe Mode with preview-only risky actions
- Cost policy filtering that blocks known paid/trial/subscription items
- Ollama extraction flow for large JSON schema enrichment before Supabase sync

## Brand Assets

The Phat Gorrilla logo, icon set, small dashboard image, Expo splash/favicon assets, desktop launcher icon, and GitHub/social preview pack live in `assets`, `frontend/assets`, `ui/assets`, and `docs/assets/brand`.

## Setup

```powershell
.\scripts\Setup-PowerGorilla.ps1
```

Optional desktop icon commands:

```powershell
.\scripts\Setup-PowerGorilla.ps1 -CreateDesktopIcon
.\scripts\Setup-PowerGorilla.ps1 -RepairDesktopIcon
.\scripts\Setup-PowerGorilla.ps1 -RemoveDesktopIcon
```

## Launch

```powershell
.\Start-PowerGorilla.ps1
```

The dashboard runs locally at:

```text
http://127.0.0.1:8765/
```

## Desktop Launcher

Create or repair the Phat Gorrilla desktop shortcut using the built-in launcher icon. The shortcut now launches Phat Gorrilla in a browser app window when supported, so it behaves like a standalone desktop app instead of a regular tabbed website.

```powershell
cd .\PowerGorilla
.\scripts\Setup-PowerGorilla.ps1 -CreateDesktopIcon
```

If the desktop shortcut still opens in a normal browser page, install Microsoft Edge, Chrome, Brave, or Opera and recreate the shortcut.

## GitHub connection

Connect the app repository to GitHub with the helper script:

```powershell
cd .\PowerGorilla
.\scripts\Connect-GitHub.ps1 -RepositoryUrl 'https://github.com/<user>/<repo>.git'
```

## Validate

Fast GitHub/package validation:

```powershell
.\scripts\Validate-PowerGorilla.ps1 -StaticOnly
```

Local runtime validation:

```powershell
.\scripts\Validate-PowerGorilla.ps1
```

Supabase-backed validation:

```powershell
.\scripts\Validate-PowerGorilla.ps1 -UseSupabase
```

Deep local data refresh validation:

```powershell
.\scripts\Validate-PowerGorilla.ps1 -RefreshData
```

Validation writes a JSON report under `reports`.
`-RefreshData` regenerates local dashboard data from this machine. Review `ui/app-data.js` before committing after a refresh.

## Optional Frontend

```powershell
cd .\frontend
npm run web
```

Create `frontend/.env.local` from `frontend/.env.example` only for optional free-tier Supabase access.

For the fastest Supabase-backed frontend, apply every file in `supabase/migrations`, including `004_frontend_performance.sql`. The Expo app caches public reads, debounces search input, and forces a fresh read only when the user refreshes.

## Ollama JSON Schema Layer

Ollama is the local intelligence layer for large schema work. Use it to extract, enrich, and validate app/workflow data against `schema` before pushing clean records to Supabase for fast read-only demos.
