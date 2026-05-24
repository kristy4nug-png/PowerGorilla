# IntegrationCore Setup Guide

## Overview

IntegrationCore is a premium integration discovery and management system for PowerGorilla. It enables users to discover, integrate, and manage online and desktop applications through a beautiful UI with strict JSON command validation.

## Architecture

```
Frontend (Expo/React Native)
  ├─ IntegrationPanel (discover & browse)
  ├─ IntegrationCard (display app with actions)
  └─ integrationService (Supabase + Ollama)
        ├─ Load integrations
        ├─ Add/update/remove apps
        └─ Execute actions

Supabase Backend (PostgreSQL)
  ├─ integration_apps (user-owned, RLS)
  ├─ integration_icons (cached icon data)
  ├─ integration_actions (action definitions)
  └─ audit_log (append-only ledger)

Ollama (Local AI)
  ├─ Generate integration recipes
  ├─ Discover online apps
  ├─ Classify apps into categories
  └─ Validate commands

PowerShell
  └─ Scan-DesktopApps.ps1 (find installed apps)
```

## Setup Steps

### 1. Supabase Schema Migration

Run these SQL migrations in your Supabase dashboard at `https://app.supabase.com`:

**Step 1a: Apply `005_integration_apps.sql`**
- Creates `integration_apps` table with RLS
- Sets up indexes for performance
- Adds auto-updated_at trigger and audit logging

**Step 1b: Apply `006_integration_icons.sql`**
- Creates `integration_icons` table for icon caching
- Sets up deduplication and cache expiry
- Adds best_integration_icons view

**Step 1c: Apply `007_integration_actions.sql`**
- Creates `integration_actions` table for action definitions
- Sets up ordering and enable/disable controls
- Adds integration_app_actions_enabled view

**Verification:**
```sql
-- Check tables exist
SELECT * FROM integration_apps LIMIT 1;
SELECT * FROM integration_icons LIMIT 1;
SELECT * FROM integration_actions LIMIT 1;

-- Check RLS is enabled
SELECT tablename FROM pg_tables WHERE schemaname = 'public';
```

### 2. Frontend Environment Variables

Edit `frontend/.env.local` (create if missing):

```bash
# Supabase (public anon key only)
EXPO_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=your-public-anon-key

# Ollama (local AI - required for discovery)
EXPO_PUBLIC_OLLAMA_URL=http://localhost:11434
EXPO_PUBLIC_OLLAMA_MODEL=llama2

# Feature flags
EXPO_PUBLIC_ENABLE_INTEGRATION_DISCOVERY=true
```

**Never expose:**
- Supabase service role key
- Private API keys
- Auth secrets

### 3. Ollama Setup

**Install Ollama:**
- Download from https://ollama.ai
- Run: `ollama serve`

**Pull a model:**
```bash
ollama pull llama2
# or
ollama pull mistral  # faster, smaller
```

**Test Ollama:**
```bash
curl http://localhost:11434/api/tags
```

### 4. Add Integrations Tab

Update `frontend/app/(tabs)/_layout.tsx` to include the new integrations tab:

```tsx
import { Text } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../../lib/theme';

// Inside <Tabs> component, add:
<Tabs.Screen
  name="integrations"
  options={{
    title: 'Integrations',
    tabBarLabel: 'Integrations',
    tabBarIcon: ({ color, focused }) => (
      <Ionicons
        name={focused ? 'apps' : 'apps-outline'}
        size={24}
        color={color}
      />
    ),
  }}
/>
```

### 5. Test the System

**Local Testing:**

1. **Start Ollama:**
   ```bash
   ollama serve
   ```

2. **Start frontend:**
   ```bash
   cd frontend
   npm install  # if needed
   npx expo start
   ```

3. **Test discovery:**
   - Go to Integrations tab
   - Click "Discover Apps"
   - Try: "Add Spotify and YouTube to Music"
   - Should return structured JSON from Ollama

4. **Test desktop scanner (PowerShell):**
   ```powershell
   cd PowerGorilla
   .\scripts\Scan-DesktopApps.ps1 -OutputFile data/processed/desktop_apps.json
   ```

**Manual Testing Checklist:**
- [ ] Apps load from Supabase
- [ ] Pin/unpin works
- [ ] Discovery returns valid JSON
- [ ] Ollama validates commands
- [ ] Actions execute without errors
- [ ] Icons display with fallbacks
- [ ] Search filters apps
- [ ] Categories expand/collapse

### 6. Vercel Deployment

**Prerequisites:**
- GitHub repo with code pushed
- Vercel linked to GitHub

**Steps:**

1. **Add environment variables to Vercel:**
   ```
   EXPO_PUBLIC_SUPABASE_URL=...
   EXPO_PUBLIC_SUPABASE_ANON_KEY=...
   EXPO_PUBLIC_OLLAMA_URL=...  (or omit for serverless)
   ```

2. **Build configuration (vercel.json):**
   ```json
   {
     "buildCommand": "cd frontend && npm run build",
     "outputDirectory": "frontend/.next",
     "env": {
       "EXPO_PUBLIC_SUPABASE_URL": "@supabase_url",
       "EXPO_PUBLIC_SUPABASE_ANON_KEY": "@supabase_anon_key"
     }
   }
   ```

3. **Create preview deployment:**
   - Push to feature branch
   - Vercel auto-builds and deploys preview
   - Test at preview URL

4. **Deploy to production:**
   - Merge to `main` branch
   - Vercel auto-deploys to production

### 7. Desktop App Scanner Integration

**Add to PowerShell startup (optional):**

Edit `Start-PowerGorilla.ps1`:

```powershell
if ($ExtractIcons -or $RefreshIcons) {
    Write-Progress -Activity 'Power Gorilla' -Status 'Scanning desktop apps' -PercentComplete 40
    & ./scripts/Scan-DesktopApps.ps1 -ExtractIcons -OutputFile 'data\processed\desktop_apps_candidates.json'
}
```

## JSON Command Format

All Ollama responses must be strict JSON:

```json
{
  "command_type": "create_integration_recipe",
  "app_name": "Spotify",
  "app_type": "online",
  "category": "Music",
  "actions": [
    {
      "id": "open",
      "label": "Open",
      "action_type": "open_url",
      "target": "https://open.spotify.com"
    }
  ],
  "icon_required": true,
  "requires_backend_change": false,
  "requires_review": false,
  "safe_mode": true
}
```

**Validation rules:**
- All required fields present
- No delete or destructive operations
- No auth secret exposure
- No external payment APIs
- Confidence >= 0.8

## Security Checklist

- ✅ RLS enabled on all user tables
- ✅ Frontend uses anon key only
- ✅ Service role key never exposed
- ✅ JSON command validation before execution
- ✅ Audit logging for all changes
- ✅ No bank details or payment APIs
- ✅ Free tier Supabase (no scaling limits)
- ✅ Local Ollama (no external AI requests)

## Troubleshooting

**"Ollama connection refused"**
```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# If not, start it
ollama serve
```

**"RLS policy prevents access"**
```sql
-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'integration_apps';

-- Verify user is authenticated
SELECT auth.uid();
```

**"Invalid JSON from Ollama"**
- Check Ollama model loaded: `ollama list`
- Ensure temperature is low (0.1-0.3 for deterministic output)
- Increase timeout in ollamaIntegrationService.ts

**"Icon not loading"**
- Check icon_id is valid in integration_icons table
- Verify cache_data_uri contains base64 or data URI
- Fallback should display initials (A·G)

## Next Steps

1. ✅ Schema created and tested
2. ✅ Frontend components built
3. ✅ Ollama integration working
4. ✅ PowerShell scanner ready
5. **→ Deploy preview to Vercel**
6. **→ Test in real environment**
7. **→ Merge to main and deploy production**

## Files Added

- `supabase/migrations/005_integration_apps.sql`
- `supabase/migrations/006_integration_icons.sql`
- `supabase/migrations/007_integration_actions.sql`
- `frontend/lib/components/IntegrationCard.tsx`
- `frontend/lib/components/IntegrationPanel.tsx`
- `frontend/lib/services/ollamaIntegrationService.ts`
- `frontend/lib/services/integrationService.ts`
- `frontend/app/(tabs)/integrations.tsx`
- `scripts/Scan-DesktopApps.ps1`

## Support

For issues:
1. Check Supabase logs: https://app.supabase.com → Logs
2. Check frontend console: Browser DevTools
3. Check Ollama: `curl http://localhost:11434/api/generate`
4. Check audit_log table for errors
