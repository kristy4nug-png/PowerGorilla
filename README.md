# PowerShell Gorilla 🦍

Local-first Windows command centre with a React Native web app, Supabase + pgvector database, Ollama AI extraction, and Vercel deployment.

## Stack

| Layer | Technology |
|---|---|
| Local engine | PowerShell 7 (CommandUnitGorrilla + PowerGorilla modules) |
| AI extraction | Ollama (llama3.2 for JSON, nomic-embed-text for vectors) |
| Database | Supabase (Postgres 15 + pgvector) |
| Web app | React Native Expo Web → expo-router |
| Deployment | Vercel (auto-deploy from GitHub) |
| Source control | GitHub — `powershell-gorrilla` |

## Quick Start

### 1. Set up Supabase
1. Create a project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor** and run `supabase/migrations/001_init.sql`
3. Copy your Project URL and API keys from **Settings → API**

### 2. Configure PowerShell
Edit `PowerGorilla/.env.ps1` with your Supabase keys, then run:
```powershell
Import-Module .\PowerGorilla\modules\PowerGorilla\PowerGorilla.Supabase.psm1

# Push your app inventory to Supabase
gorjson | gorpush -Type apps

# Extract workflows from CSVs using Ollama (batched, no thousands of commands)
gorextract -Path .\PowerGorilla\data\imports\Two_App_20K_Free_OpenSource_Combinations.csv -Type workflow -OutDir .\PowerGorilla\data\processed

# Generate pgvector embeddings
gorembed -Type apps
gorembed -Type workflows

# Semantic search
gorsemantic "automate video editing"
```

### 3. Run the web app locally
```powershell
cd gorilla-app
# Create .env.local with your Supabase URL and anon key
npm run web
```

### 4. Deploy to Vercel
1. Push to GitHub
2. Connect repo at [vercel.com](https://vercel.com)
3. Add secrets: `EXPO_PUBLIC_SUPABASE_URL`, `EXPO_PUBLIC_SUPABASE_ANON_KEY`, `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`
4. Every push to `main` auto-deploys

## Screens

| Screen | Path | Description |
|---|---|---|
| Dashboard | `/` | Stats, vector DB metrics, audit log |
| Apps | `/apps` | App inventory with filters and infinite scroll |
| Workflows | `/workflows` | Visual workflow builder with rank scores |
| Semantic Search | `/search` | Ollama + pgvector cosine similarity search |
| Sessions | `/sessions` | Append-only audit log from PowerShell |

## PowerShell Commands

| Command | Description |
|---|---|
| `gorjson` | Emit app inventory as schema-valid JSON |
| `gorextract` | Batch CSV extraction via Ollama (no per-row loops) |
| `gorpush` | Push records to Supabase (upsert in batches) |
| `gorembed` | Generate Ollama embeddings → Supabase pgvector |
| `gorsemantic` | Semantic vector search from PowerShell |

## JSON Schemas

All data validated against strict schemas in `/schema/`:
- `app.schema.json` — `gorilla/app/v1`
- `workflow.schema.json` — `gorilla/workflow/v1`
- `extraction.schema.json` — `gorilla/ollama-extraction/v1`

## Safety

- No destructive system action from the dashboard
- No credentials stored in the app
- All PowerShell actions logged to Supabase `audit_log`
- Large CSVs (350MB) stay local — never committed to Git
