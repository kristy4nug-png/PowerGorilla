# Phat Gorrilla

<img src="PowerGorilla/docs/assets/phat-gorrilla-logo.png" alt="Phat Gorrilla logo" width="180">

Phat Gorrilla is now consolidated into one app folder: `PowerGorilla`.

It is a local-first Windows command centre for app inventory, visual workflow search, Ollama-backed JSON schema processing, safe dry-run system checks, and optional free-tier Supabase/Expo sync.

## Product Rules

- Local-first by default.
- No paid subscriptions, paid APIs, trials, premium plans, or commercial-only tools.
- Free, open-source, built-in Windows tools, and free-tier services are allowed.
- Supabase, Cloudflare Pages, GitHub Pages, and Expo are optional free-tier pieces; the PowerShell dashboard runs locally without them.

## Main Paths

| Path | Purpose |
|---|---|
| `PowerGorilla/Start-PowerGorilla.ps1` | Local dashboard launcher |
| `PowerGorilla/scripts/Setup-PowerGorilla.ps1` | Setup and data refresh |
| `PowerGorilla/scripts/Validate-PowerGorilla.ps1` | Validation checks |
| `PowerGorilla/frontend` | Expo web app |
| `PowerGorilla/site` | Free static promotional website |
| `PowerGorilla/schema` | JSON schemas |
| `PowerGorilla/supabase/migrations` | Optional free-tier Supabase migrations |
| `PowerGorilla/docs` | Architecture and build notes |

## Brand Assets

The Phat Gorrilla logo, app icons, desktop launcher icon, Expo favicon/splash assets, and GitHub/social preview images are checked in under `PowerGorilla/assets`, `PowerGorilla/frontend/assets`, `PowerGorilla/ui/assets`, and `PowerGorilla/docs/assets/brand`.

## Run Local Dashboard

```powershell
cd .\PowerGorilla
.\Start-PowerGorilla.ps1
```

The local dashboard opens at:

```text
http://127.0.0.1:8765/
```

## Run Expo Frontend

```powershell
cd .\PowerGorilla\frontend
npm run web
```

Create `PowerGorilla/frontend/.env.local` from `PowerGorilla/frontend/.env.example` only if you are using the optional Supabase free tier.

For the fastest Supabase-backed frontend, apply all SQL files in `PowerGorilla/supabase/migrations`, including `004_frontend_performance.sql`. The Expo app caches public reads, debounces search input, and forces a fresh read only when the user refreshes.

## Ollama JSON Schema Layer

Ollama is the local intelligence layer for large JSON schema work. Keep extraction, enrichment, and validation local first; push only validated app/workflow records to Supabase for fast read-only demos.

## Validate

Fast GitHub/package validation:

```powershell
.\PowerGorilla\scripts\Validate-PowerGorilla.ps1 -Root .\PowerGorilla -StaticOnly
```

Local runtime validation:

```powershell
.\PowerGorilla\scripts\Validate-PowerGorilla.ps1 -Root .\PowerGorilla
```

Supabase-backed validation:

```powershell
.\PowerGorilla\scripts\Validate-PowerGorilla.ps1 -Root .\PowerGorilla -UseSupabase
```

Deep local data refresh validation:

```powershell
.\PowerGorilla\scripts\Validate-PowerGorilla.ps1 -Root .\PowerGorilla -RefreshData
```

`-RefreshData` regenerates local dashboard data from this machine. Review `PowerGorilla/ui/app-data.js` before committing after a refresh.

## Backup Policy

Only one current source backup is kept under `backups/`. Older backups are removed after a new backup is created.
