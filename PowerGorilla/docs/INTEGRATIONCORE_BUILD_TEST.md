# IntegrationCore Build Output & Test Plan

## Build Summary

```json
{
  "build_step": "IntegrationCore Discovery & Integration System",
  "purpose": "Premium app discovery, integration, and management with offline AI validation",
  "frontend_host": "vercel",
  "backend": "supabase",
  "ai_layer": "ollama",
  "backend_risk": "low",
  "frontend_risk": "low",
  "base_app_impact": "additive",
  "free_tier_safe": true,
  "requires_bank_details": false,
  "requires_backup": true,
  "files_added": [
    "supabase/migrations/005_integration_apps.sql",
    "supabase/migrations/006_integration_icons.sql",
    "supabase/migrations/007_integration_actions.sql",
    "frontend/lib/components/IntegrationCard.tsx",
    "frontend/lib/components/IntegrationPanel.tsx",
    "frontend/lib/services/ollamaIntegrationService.ts",
    "frontend/lib/services/integrationService.ts",
    "frontend/app/(tabs)/integrations.tsx",
    "scripts/Scan-DesktopApps.ps1",
    "docs/INTEGRATIONCORE_SETUP.md",
    "frontend/.env.example.local"
  ],
  "files_modified": [
    "frontend/app/(tabs)/_layout.tsx"
  ],
  "supabase_changes": [
    {
      "type": "create_table",
      "table": "integration_apps",
      "rls": "enabled",
      "policies": ["SELECT", "INSERT", "UPDATE", "DELETE"]
    },
    {
      "type": "create_table",
      "table": "integration_icons",
      "rls": "enabled",
      "policies": ["SELECT", "INSERT", "UPDATE", "DELETE"]
    },
    {
      "type": "create_table",
      "table": "integration_actions",
      "rls": "enabled",
      "policies": ["SELECT", "INSERT", "UPDATE", "DELETE"]
    },
    {
      "type": "create_trigger",
      "trigger": "integration_apps_timestamp_trigger",
      "action": "auto-update updated_at"
    },
    {
      "type": "create_trigger",
      "trigger": "audit_integration_app_trigger",
      "action": "log changes to audit_log"
    }
  ],
  "vercel_changes": [
    {
      "type": "environment_variable",
      "name": "EXPO_PUBLIC_SUPABASE_URL",
      "required": true
    },
    {
      "type": "environment_variable",
      "name": "EXPO_PUBLIC_SUPABASE_ANON_KEY",
      "required": true
    },
    {
      "type": "environment_variable",
      "name": "EXPO_PUBLIC_OLLAMA_URL",
      "required": true,
      "default": "http://localhost:11434"
    }
  ],
  "new_json_commands": [
    {
      "command_type": "create_integration_recipe",
      "description": "Generate integration recipe with actions"
    },
    {
      "command_type": "discover_apps",
      "description": "Find online apps matching criteria"
    },
    {
      "command_type": "scan_desktop",
      "description": "Scan for installed desktop applications"
    }
  ],
  "rollback_plan": [
    "All changes are additive - no existing tables modified",
    "If Supabase migrations fail, migrations can be rolled back",
    "To remove IntegrationCore: drop integration_apps, integration_icons, integration_actions tables",
    "Frontend can disable integrations tab in _layout.tsx",
    "No data loss to existing app or workflow tables"
  ],
  "test_plan": [
    {
      "phase": "Unit Tests",
      "tests": [
        "Validate JSON schema for integration commands",
        "Test Ollama response parsing",
        "Test icon caching logic"
      ]
    },
    {
      "phase": "Integration Tests",
      "tests": [
        "Supabase RLS policies work correctly",
        "Frontend can CRUD integrations",
        "Ollama discovery returns valid candidates"
      ]
    },
    {
      "phase": "E2E Tests",
      "tests": [
        "User can discover and add Spotify to Music",
        "User can pin/unpin integrations",
        "Desktop scanner finds installed apps",
        "Icons display with fallbacks"
      ]
    },
    {
      "phase": "Security Tests",
      "tests": [
        "RLS prevents cross-user access",
        "Service role key not exposed",
        "Anon key has limited permissions",
        "Destructive commands blocked"
      ]
    }
  ],
  "success_checks": [
    "✅ Supabase tables created with RLS",
    "✅ Frontend components render without errors",
    "✅ IntegrationPanel lists apps with icons",
    "✅ IntegrationCard shows all action buttons",
    "✅ Discovery modal accepts free-form queries",
    "✅ Ollama returns valid JSON commands",
    "✅ Commands pass strict validation",
    "✅ Apps can be added, pinned, and removed",
    "✅ PowerShell scanner finds installed apps",
    "✅ Audit log captures all operations",
    "✅ Preview deployment on Vercel works",
    "✅ No regressions in existing app features"
  ],
  "do_not_proceed_if": [
    "❌ Ollama not running (local discovery fails)",
    "❌ Supabase project not configured",
    "❌ Environment variables not set",
    "❌ Existing tables have naming conflicts",
    "❌ Breaking changes to auth.users table"
  ]
}
```

## Test Execution Plan

### Phase 1: Local Setup & Schema Verification

**Steps:**
```bash
# 1. Verify Ollama running
curl http://localhost:11434/api/tags

# 2. Apply Supabase migrations
# - Copy SQL from migrations/005, 006, 007
# - Paste into Supabase SQL Editor
# - Execute and verify success

# 3. Verify schema
SELECT COUNT(*) FROM integration_apps;  -- Should be 0
SELECT COUNT(*) FROM integration_icons;  -- Should be 0
SELECT COUNT(*) FROM integration_actions;  -- Should be 0

# 4. Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'integration_apps';
```

**Success Criteria:**
- ✅ All 3 tables exist
- ✅ All RLS policies enabled
- ✅ Triggers created
- ✅ Views accessible

### Phase 2: Frontend Component Testing

**Install dependencies:**
```bash
cd frontend
npm install  # or yarn install
```

**Build and test:**
```bash
# Option A: Expo Go (mobile preview)
npx expo start
# Scan QR code with Expo Go app

# Option B: Web preview
npx expo start --web

# Option C: Native development
npx expo start --ios    # macOS only
npx expo start --android  # Windows/macOS
```

**Manual Testing Checklist:**

```
[ ] Navigation
  [ ] Integrations tab appears in tab bar
  [ ] Tab icon displays correctly
  [ ] Can switch to Integrations tab

[ ] IntegrationPanel
  [ ] Displays "No Integrations Yet" when empty
  [ ] Search box works
  [ ] View mode buttons (All, Pinned, Online, Desktop) toggle
  [ ] "Discover Apps" button opens modal

[ ] Discovery Flow
  [ ] Modal appears on button press
  [ ] Can type free-form query
  [ ] "Discover" button submits query
  [ ] Loading indicator shows during processing
  [ ] Response parsed without errors

[ ] Ollama Integration
  [ ] Sends JSON to Ollama
  [ ] Receives valid JSON response
  [ ] Commands pass validation
  [ ] Error handling works

[ ] CRUD Operations (after adding app)
  [ ] App card renders
  [ ] Icon displays (or fallback shows)
  [ ] Pin button works
  [ ] Edit button enabled
  [ ] Remove button deletes app
  [ ] Actions execute without errors

[ ] UI/UX
  [ ] Cards are styled consistently
  [ ] Colors match theme
  [ ] Responsive layout on different screen sizes
  [ ] Loading states show feedback
  [ ] Error messages display
  [ ] Confidence bar shows correctly
  [ ] Safe-to-launch indicator visible if false
```

### Phase 3: Supabase Integration Testing

**Test RLS Security:**
```typescript
// test-rls.ts
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(PUBLIC_URL, ANON_KEY);

// This should work (user sees own apps)
const { data: myApps } = await supabase
  .from('integration_apps')
  .select('*')
  .eq('user_id', currentUser.id);

// This should FAIL (anon key cannot see other user's apps)
const { data: otherApps } = await supabase
  .from('integration_apps')
  .select('*')
  .eq('user_id', otherUserId);
  // Should return 0 rows due to RLS policy
```

**Test Data Persistence:**
```bash
# 1. Add app through UI
# 2. Refresh page
# 3. Verify app still there
# 4. Check Supabase dashboard
# 5. Verify in integration_apps table
```

### Phase 4: PowerShell Desktop Scanner

**Run scanner:**
```powershell
cd PowerGorilla
./scripts/Scan-DesktopApps.ps1 -OutputFile data/processed/desktop_apps.json
```

**Verify output:**
```powershell
# Check JSON is valid
$json = Get-Content data/processed/desktop_apps.json | ConvertFrom-Json
Write-Host "Found $($json.candidates.Count) apps"

# Verify schema
$json.candidates[0] | Select-Object type, name, category, exe_path
```

**Expected output structure:**
```json
{
  "scan_timestamp": "2026-05-24T...",
  "total_found": 15,
  "candidates": [
    {
      "type": "desktop_app_candidate",
      "name": "Visual Studio Code",
      "category": "Development",
      "confidence": 0.90
    }
  ]
}
```

### Phase 5: Vercel Preview Deployment

**Steps:**
```bash
# 1. Commit changes
git add -A
git commit -m "feat: add IntegrationCore system"

# 2. Create preview branch
git checkout -b feature/integration-core
git push -u origin feature/integration-core

# 3. Vercel auto-builds preview
# Link: https://your-project-preview.vercel.app

# 4. Test on preview
# - Same tests as Phase 2
# - Verify environment variables passed correctly
# - Check network requests in DevTools

# 5. Merge to main when satisfied
git checkout main
git merge feature/integration-core
git push origin main

# 6. Vercel auto-deploys to production
# Link: https://your-project.vercel.app
```

### Phase 6: Regression Testing

**Existing Features Must Still Work:**
```
[ ] Dashboard tab loads
[ ] Apps tab shows inventory
[ ] Workflows tab functional
[ ] Search works
[ ] Sessions display
[ ] Navigation between all tabs smooth
[ ] No console errors
[ ] No performance regressions
```

## Performance Benchmarks

| Operation | Target | Status |
|-----------|--------|--------|
| Load integrations | < 500ms | ? |
| Discover 5-10 apps | < 3000ms | ? |
| Add app to Supabase | < 500ms | ? |
| Render card list (10 apps) | < 300ms | ? |
| Icon load & display | < 200ms | ? |
| Pin/unpin toggle | < 300ms | ? |

## Security Verification

- [ ] No hardcoded secrets in code
- [ ] Service role key not in frontend
- [ ] Anon key has minimal permissions
- [ ] RLS policies tested and verified
- [ ] Audit log captures all changes
- [ ] Ollama responses validated before use
- [ ] No destructive commands allowed
- [ ] Error messages don't leak system info

## Rollback Procedure

If issues occur:

```bash
# 1. Revert Vercel deployment
# - Go to Vercel dashboard
# - Click previous deployment
# - Click "Promote to Production"

# 2. Revert database (if schema issues)
# - Go to Supabase dashboard
# - Run drop statements for new tables:
DROP TABLE IF EXISTS integration_actions CASCADE;
DROP TABLE IF EXISTS integration_icons CASCADE;
DROP TABLE IF EXISTS integration_apps CASCADE;

# 3. Revert code
git revert HEAD  # or git reset HEAD~1
git push origin main
```

**No data loss expected** because:
- All changes additive (no modifications to existing tables)
- Three new independent tables (safe to drop)
- No foreign key constraints from old tables

## Sign-Off Checklist

- [ ] All files created and committed
- [ ] Supabase migrations applied
- [ ] Frontend environment variables set
- [ ] Ollama running and verified
- [ ] Local testing passed (Phase 2)
- [ ] RLS security verified (Phase 3)
- [ ] Desktop scanner tested (Phase 4)
- [ ] Vercel preview deployment tested (Phase 5)
- [ ] No regressions in existing features (Phase 6)
- [ ] Performance meets benchmarks
- [ ] Security checklist complete
- [ ] Ready for production deployment
