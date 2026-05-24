// INTEGRATIONCORE_PHASE2_INTEGRATION_GUIDE.md
// How to wire icon picker, app type indicator, grouping, demo mode, and validation

# IntegrationCore Phase 2: Complete Integration Guide

This guide explains how to integrate all Phase 2 components into your existing IntegrationCore system to deliver the full premium experience: icon choosing, app type distinction, combination grouping, demo mode, and professional validation.

## 📋 Quick Overview

**Phase 2 Delivers:**
- ✅ **IconPicker** - Choose from 4 icon sources (brand, library, emoji, custom)
- ✅ **AppTypeIndicator** - Visual badges showing online (🌐) vs desktop (🖥️) vs hybrid (🔄)
- ✅ **CombinationCreator** - Group 2-4 apps into custom themed sections
- ✅ **DemoMode** - Free GitHub users explore without authentication
- ✅ **ValidationService** - Continuous pro-level integrity checking
- ✅ **GroupingService** - Database layer for app combinations

---

## 1. IconPicker Integration

### Location
`frontend/lib/components/IconPicker.tsx`

### Purpose
Allow users to select icons during app discovery. Shows 4 tabs:
1. **simple_icons** - Brand SVGs (Spotify, YouTube, Netflix, etc.)
2. **iconify** - Icon library search
3. **emoji** - 10 common emojis
4. **custom** - Generated initials or file upload

### Integration Steps

#### Step 1: Import IconPicker in integrations.tsx
```typescript
import IconPicker from '../lib/components/IconPicker';
```

#### Step 2: Add icon selection to discovery flow
Modify the discover modal in `frontend/app/(tabs)/integrations.tsx`:

```typescript
// After user selects an app from Ollama results:
const [selectedAppForIcon, setSelectedAppForIcon] = useState<IntegrationApp | null>(null);

// Show icon picker after app selection
if (selectedAppForIcon) {
  return (
    <IconPicker
      appName={selectedAppForIcon.name}
      appType={selectedAppForIcon.app_type}
      onSelectIcon={async (iconOption) => {
        // Save icon and finalize app add
        const iconId = await saveIconToDatabase(iconOption);
        
        // Update app with icon_id before saving
        selectedAppForIcon.icon_id = iconId;
        
        // Add to Supabase
        await integrationService.addIntegrationApp(selectedAppForIcon);
        
        setSelectedAppForIcon(null);
      }}
      isLoading={isDiscovering}
    />
  );
}
```

#### Step 3: Create saveIconToDatabase() helper
Add to `frontend/lib/services/integrationService.ts`:

```typescript
export async function saveIconToDatabase(
  iconOption: any
): Promise<string | undefined> {
  try {
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) return undefined;

    const iconRecord = {
      user_id: user.id,
      source_type: iconOption.source,
      source_slug: iconOption.slug,
      cached_data_uri: iconOption.data_uri || null,
      file_hash: generateHash(iconOption.data_uri),
      times_used: 1,
    };

    const { data, error } = await supabase
      .from('integration_icons')
      .insert(iconRecord)
      .select()
      .single();

    if (error) throw error;
    return data?.id;
  } catch (error) {
    console.error('Failed to save icon:', error);
    return undefined;
  }
}
```

---

## 2. AppTypeIndicator Integration

### Location
`frontend/lib/components/AppTypeIndicator.tsx`

### Purpose
Replace the plain type badge in IntegrationCard with a professional indicator showing:
- **🌐 Internet App** (Blue) - Web-based, requires internet
- **🖥️ Local App** (Pink) - Installed locally, works offline  
- **🔄 Hybrid App** (Amber) - Works both ways

### Integration Steps

#### Step 1: Import AppTypeIndicator in IntegrationCard.tsx
```typescript
import AppTypeIndicator from './AppTypeIndicator';
```

#### Step 2: Replace type badge
In `frontend/lib/components/IntegrationCard.tsx`, find the type badge section:

**Before:**
```typescript
<View style={styles.headerRight}>
  <Text style={styles.typeText}>{app.app_type}</Text>
</View>
```

**After:**
```typescript
<View style={styles.headerRight}>
  <AppTypeIndicator appType={app.app_type} variant="badge" size="medium" />
</View>
```

#### Step 3: Update style (optional)
Remove hardcoded type badge styling since AppTypeIndicator handles it:

```typescript
// Remove from IntegrationCard styles:
// typeText: { ... }
```

---

## 3. CombinationCreator Integration

### Location
`frontend/lib/components/CombinationCreator.tsx`

### Purpose
Let users create custom groups of 2-4 apps (e.g., "Shopping", "Music Dev Tools"). Each group has:
- Name, emoji icon, color
- 2-4 apps (enforced)
- Optional description
- Saved to database for persistence

### Integration Steps

#### Step 1: Add database migration
Run in Supabase:
```sql
-- supabase/migrations/008_app_group_combinations.sql
-- Already created, just run it
```

#### Step 2: Import CombinationCreator in IntegrationPanel.tsx
```typescript
import CombinationCreator from './CombinationCreator';
```

#### Step 3: Add to IntegrationPanel component
```typescript
// In IntegrationPanel.tsx render:
<CombinationCreator
  availableApps={apps}
  onCreateGroup={async (group) => {
    await groupingService.createAppGroup(
      group.name,
      group.apps.map((a) => a.id),
      group.icon_emoji,
      group.color,
      group.description
    );
    
    // Refresh UI
    onRefresh?.();
  }}
  isLoading={isLoading}
/>
```

#### Step 4: Display groups in UI (optional enhancement)
After creating groups, render them at top of IntegrationPanel:

```typescript
const [groups, setGroups] = useState<AppGroupCombination[]>([]);

useEffect(() => {
  loadGroups();
}, []);

const loadGroups = async () => {
  const userGroups = await groupingService.getUserAppGroups();
  setGroups(userGroups);
};

// Render groups section above regular apps
{groups.map((group) => (
  <View key={group.id} style={styles.groupSection}>
    <Text style={styles.groupEmoji}>{group.icon_emoji}</Text>
    <Text style={styles.groupName}>{group.name}</Text>
    {/* Render 2-4 apps in group */}
  </View>
))}
```

---

## 4. DemoMode Integration

### Location
`frontend/lib/services/demoModeService.ts`

### Purpose
Enable free GitHub users to explore without authentication. Demo mode:
- Provides 6 pre-loaded sample apps (Spotify, YouTube, VS Code, Figma, Notion, Discord)
- Stores changes in localStorage (browser only, not persisted to server)
- Auto-expires after 24 hours
- Shows "Demo Mode (Xh left)" label in UI

### Integration Steps

#### Step 1: Add environment variable
In `frontend/.env.local`:
```
EXPO_PUBLIC_DEMO_MODE=false
```

#### Step 2: Modify integrationService.ts
Add demo mode check at start:

```typescript
import {
  checkAuthMode,
  getDemoApps,
  getDemoSession,
  initializeDemoSession,
} from './demoModeService';

export async function loadUserIntegrations(): Promise<IntegrationApp[]> {
  const authMode = await checkAuthMode();

  if (authMode === 'demo') {
    // Return demo apps from localStorage
    return getDemoApps() as IntegrationApp[];
  }

  // Regular authenticated flow
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return [];

  const { data } = await supabase
    .from('integration_apps')
    .select('*')
    .eq('user_id', user.id)
    .order('is_pinned', { ascending: false });

  return data || [];
}
```

#### Step 3: Update addIntegrationApp() for demo
```typescript
export async function addIntegrationApp(
  app: Partial<IntegrationApp>
): Promise<IntegrationApp | null> {
  const authMode = await checkAuthMode();

  if (authMode === 'demo') {
    // Add to demo session in localStorage
    return addDemoApp(app as any) as IntegrationApp;
  }

  // Regular authenticated flow
  // ... existing code
}
```

#### Step 4: Add demo mode badge to UI
In `frontend/app/(tabs)/integrations.tsx`:

```typescript
import { getDemoModeLabel, checkAuthMode } from '../lib/services/demoModeService';

const IntegrationsScreen = () => {
  const [isDemoMode, setIsDemoMode] = useState(false);

  useEffect(() => {
    const checkMode = async () => {
      const mode = await checkAuthMode();
      setIsDemoMode(mode === 'demo');
    };
    checkMode();
  }, []);

  return (
    <View>
      {isDemoMode && (
        <View style={styles.demoBanner}>
          <Ionicons name="flask" size={16} color="white" />
          <Text style={styles.demoBannerText}>
            {getDemoModeLabel()}
          </Text>
        </View>
      )}
      {/* Rest of UI */}
    </View>
  );
};
```

---

## 5. ValidationService Integration

### Location
`frontend/lib/services/validationService.ts`

### Purpose
Continuous pro-level integrity checking:
- Schema validation on all app data
- URL/icon reachability checks
- Audit log review
- App health reports

### Integration Steps

#### Step 1: Run validation on app load
In `frontend/app/(tabs)/integrations.tsx`:

```typescript
import { runSystemValidation, logValidationResult } from '../lib/services/validationService';

useEffect(() => {
  const validate = async () => {
    const result = await runSystemValidation();
    await logValidationResult(result);
    
    if (result.summary.overallStatus !== 'healthy') {
      console.warn('System validation issues:', result.checks);
    }
  };
  
  validate();
}, []);
```

#### Step 2: Check individual app health
Before displaying an app, run health check:

```typescript
import { checkIntegrationHealth } from '../lib/services/validationService';

const renderApp = async (appId: string) => {
  const health = await checkIntegrationHealth(appId);
  
  if (health?.status !== 'healthy') {
    // Show warning badge on app card
    <View style={styles.warningBadge}>
      <Text>{health?.issues[0]}</Text>
    </View>
  }
};
```

#### Step 3: Validate before save
All create/update operations validate data first:

```typescript
import { validateAppData } from '../lib/services/validationService';

export async function addIntegrationApp(app: any): Promise<IntegrationApp | null> {
  // Validate before insert
  const validation = validateAppData(app);
  
  if (!validation.valid) {
    console.error('Validation errors:', validation.errors);
    throw new Error(`Validation failed: ${validation.errors.join(', ')}`);
  }
  
  if (validation.warnings.length > 0) {
    console.warn('Validation warnings:', validation.warnings);
  }
  
  // Proceed with insert if valid
  // ...
}
```

---

## 6. Complete Data Flow Example

### User Journey: "Add Spotify with custom icon and group it"

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User opens Integrations tab (demo mode)                   │
├─────────────────────────────────────────────────────────────┤
│ - loadUserIntegrations() → getDemoApps() → 6 sample apps     │
│ - runSystemValidation() → checks all systems healthy         │
└─────────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. User clicks "Discover Apps" → enters query "Spotify"      │
├─────────────────────────────────────────────────────────────┤
│ - ollamaIntegrationService.discoverOnlineApps("spotify")     │
│ - Returns OnlineAppCandidate[] with Spotify match            │
└─────────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. User selects Spotify → IconPicker modal opens             │
├─────────────────────────────────────────────────────────────┤
│ - Shows: simple_icons (Spotify green), emoji, custom         │
│ - User selects Spotify brand icon                            │
│ - onSelectIcon() → saveIconToDatabase() → icon_id            │
└─────────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. App added with icon                                       │
├─────────────────────────────────────────────────────────────┤
│ - addIntegrationApp(spotify + icon_id)                       │
│ - validateAppData() → passes                                 │
│ - Stored to demo localStorage (not Supabase in demo mode)    │
│ - AppTypeIndicator shows 🌐 "Internet App" badge             │
└─────────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. User creates "Music" group with Spotify + YouTube         │
├─────────────────────────────────────────────────────────────┤
│ - CombinationCreator modal opens                             │
│ - Selects 🎵 emoji, green color, "Music" name               │
│ - Adds Spotify + YouTube (2 apps)                            │
│ - groupingService.createAppGroup() → stored                  │
└─────────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. "Music" group displayed at top with Spotify + YouTube     │
├─────────────────────────────────────────────────────────────┤
│ - Group shows: 🎵 Music (Spotify 🌐 + YouTube 🌐)           │
│ - checkIntegrationHealth() runs → both healthy ✓             │
│ - Demo banner shows "Demo Mode (24h left)"                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. Professional-Grade Features

### Icon Resolution Cascade (never breaks UI)
1. ✅ User-selected icon (from IconPicker)
2. Simple Icons brand match (e.g., spotify-icon)
3. Iconify exact match (e.g., mdi:spotify)
4. Official favicon from website
5. Tabler category fallback
6. Generated initials fallback (always works)

### Confidence Scoring
- **0.95-1.0**: Official app (Spotify, YouTube)
- **0.85-0.94**: High confidence match
- **0.70-0.84**: Medium confidence (needs review)
- **<0.70**: Low confidence (warning shown)

### Safety Validation
All apps checked for:
- ✅ Valid schema (all required fields present)
- ✅ Safe URLs (no malicious patterns)
- ✅ Executable paths (desktop apps only)
- ✅ No suspicious actions
- ✅ Audit log tracking every change

### Demo Mode Persistence
- LocalStorage in browser (no server calls)
- Auto-clears after 24 hours
- Users can export/import for backup
- Perfect for GitHub free distribution

---

## 8. Quick Implementation Checklist

### Frontend Components
- [ ] `IconPicker.tsx` - Choose icon source
- [ ] `AppTypeIndicator.tsx` - Show online/desktop/hybrid
- [ ] `CombinationCreator.tsx` - Group 2-4 apps
- [ ] Update `IntegrationCard.tsx` - Use AppTypeIndicator
- [ ] Update `IntegrationPanel.tsx` - Show groups

### Services
- [ ] `demoModeService.ts` - localStorage-based demo
- [ ] `validationService.ts` - Continuous checks
- [ ] `groupingService.ts` - Group management
- [ ] Update `integrationService.ts` - Icon/demo/validation integration
- [ ] Update `ollamaIntegrationService.ts` - Validation on discovery

### Database
- [ ] Run migration `008_app_group_combinations.sql`
- [ ] Test group creation/update/delete
- [ ] Verify RLS policies work

### Environment
- [ ] Add `EXPO_PUBLIC_DEMO_MODE=false` to `.env.local`
- [ ] Test both authenticated and demo modes
- [ ] Verify icon caching works

### Testing
- [ ] ✅ Icon picker displays 4 tabs
- [ ] ✅ App type badges show correct colors/emoji
- [ ] ✅ Create group with 2-4 apps
- [ ] ✅ Groups persist (localStorage in demo, Supabase in auth)
- [ ] ✅ Validation catches invalid data
- [ ] ✅ Audit log records all operations

---

## 9. Rollback Safety

All Phase 2 changes are **rollback-safe**:

✅ **IconPicker** - Optional, apps work without icons  
✅ **AppTypeIndicator** - Visual only, no data dependency  
✅ **CombinationCreator** - New table, can be dropped  
✅ **DemoMode** - localStorage only, no server side  
✅ **ValidationService** - Read-only, doesn't block operations  

To rollback:
```sql
-- Drop group combinations
DROP TABLE IF EXISTS app_group_combinations;

-- Frontend can remove icon picker / combination creator imports
-- Services remain optional
```

---

## 10. Pro Tips

### Icon Selection UX
- Default to brand icon for known services (auto-select)
- Show preview before confirming
- Allow multiple icons per app (for future custom themes)

### Group Management
- Drag-to-reorder groups (use `reorderAppGroups()`)
- Edit group details after creation
- Pin/unpin groups like apps
- Delete groups (keeps apps, just ungrouped)

### Validation Best Practices
- Run health check on app focus
- Show warnings in UI, not errors
- Log all issues to audit_log for debugging
- Email users if confidence drops below 0.7

### Demo Mode Best Practices
- Show clear "Demo Mode" banner
- Explain data is browser-only
- Offer login to persist to cloud
- Auto-expire after 24 hours to prevent stale data
- Allow export before expiry

---

## Next Steps

1. **Immediate**: Integrate icon picker into discovery modal
2. **This week**: Wire app type indicator into card display
3. **This week**: Add combination creator to panel
4. **This week**: Enable demo mode for unauthenticated users
5. **Testing**: Run full suite against all 4 modes (demo, online, desktop, hybrid)
6. **Deploy**: Preview to Vercel, test live, then production

---

**Questions?** Review the component files and services directly - they're heavily commented with examples.
