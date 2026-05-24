// frontend/lib/services/integrationService.ts
// Main integration service - wires frontend, Supabase, and Ollama together

import { supabase } from '../supabase';
import {
  generateIntegrationRecipe,
  discoverOnlineApps,
  classifyApps,
  validateCommandSafety,
  logCommandValidation,
  type OnlineAppCandidate,
  type IntegrationCommand,
} from './ollamaIntegrationService';

export interface IntegrationApp {
  id: string;
  user_id: string;
  name: string;
  slug: string;
  app_type: 'online' | 'desktop' | 'hybrid';
  category: string;
  official_url?: string;
  launch_url?: string;
  exe_path?: string;
  shortcut_path?: string;
  icon_id?: string;
  confidence: number;
  safe_to_launch: boolean;
  needs_review: boolean;
  is_pinned: boolean;
  is_hidden: boolean;
  custom_label?: string;
  created_at: string;
  updated_at: string;
}

export interface IntegrationAction {
  id: string;
  user_id: string;
  integration_app_id: string;
  action_id: string;
  label: string;
  action_type: string;
  target?: string;
  icon_emoji?: string;
  button_color?: string;
  order_index: number;
  is_enabled: boolean;
}

/**
 * Load all integrations for current user
 */
export async function loadUserIntegrations(): Promise<IntegrationApp[]> {
  try {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('integration_apps')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  } catch (error) {
    console.error('Failed to load integrations:', error);
    return [];
  }
}

/**
 * Load actions for a specific integration app
 */
export async function loadIntegrationActions(
  appId: string
): Promise<IntegrationAction[]> {
  try {
    const { data, error } = await supabase
      .from('integration_actions')
      .select('*')
      .eq('integration_app_id', appId)
      .order('order_index', { ascending: true });

    if (error) throw error;
    return data || [];
  } catch (error) {
    console.error('Failed to load actions:', error);
    return [];
  }
}

/**
 * Add a new integration app
 */
export async function addIntegrationApp(
  app: Partial<IntegrationApp>
): Promise<IntegrationApp | null> {
  try {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const appToInsert = {
      ...app,
      user_id: user.id,
      confidence: app.confidence || 0.95,
      safe_to_launch: app.safe_to_launch !== false,
      needs_review: app.needs_review || false,
      is_pinned: app.is_pinned || false,
      is_hidden: app.is_hidden || false,
    };

    const { data, error } = await supabase
      .from('integration_apps')
      .insert([appToInsert])
      .select()
      .single();

    if (error) throw error;

    // Log to audit
    await supabase.from('audit_log').insert({
      type: 'integration_app_added',
      message: `Added integration: ${app.name}`,
      actor: 'integration-service',
      data: { app_id: data.id, app_name: app.name, app_type: app.app_type },
    });

    return data;
  } catch (error) {
    console.error('Failed to add integration:', error);
    return null;
  }
}

/**
 * Update integration app
 */
export async function updateIntegrationApp(
  appId: string,
  updates: Partial<IntegrationApp>
): Promise<IntegrationApp | null> {
  try {
    const { data, error } = await supabase
      .from('integration_apps')
      .update(updates)
      .eq('id', appId)
      .select()
      .single();

    if (error) throw error;

    // Log to audit
    await supabase.from('audit_log').insert({
      type: 'integration_app_updated',
      message: `Updated integration: ${updates.name || 'Unknown'}`,
      actor: 'integration-service',
      data: { app_id: appId, updates },
    });

    return data;
  } catch (error) {
    console.error('Failed to update integration:', error);
    return null;
  }
}

/**
 * Remove integration app
 */
export async function removeIntegrationApp(appId: string): Promise<boolean> {
  try {
    const { error } = await supabase
      .from('integration_apps')
      .delete()
      .eq('id', appId);

    if (error) throw error;

    // Log to audit
    await supabase.from('audit_log').insert({
      type: 'integration_app_removed',
      message: `Removed integration`,
      actor: 'integration-service',
      data: { app_id: appId },
    });

    return true;
  } catch (error) {
    console.error('Failed to remove integration:', error);
    return false;
  }
}

/**
 * Toggle pin status
 */
export async function toggleIntegrationPin(
  appId: string,
  isPinned: boolean
): Promise<boolean> {
  return !!(await updateIntegrationApp(appId, { is_pinned: isPinned }));
}

/**
 * Discover and add online apps matching a query
 * Example: "Add Spotify and YouTube to Music"
 */
export async function discoverAndAddApps(query: string): Promise<IntegrationApp[]> {
  try {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Use Ollama to discover apps
    const candidates = await discoverOnlineApps(query);
    if (!candidates || candidates.length === 0) {
      return [];
    }

    const added: IntegrationApp[] = [];

    for (const candidate of candidates) {
      // Generate integration recipe
      const recipe = await generateIntegrationRecipe(
        candidate.name,
        'online',
        candidate.category
      );

      if (!recipe) {
        console.warn(`Failed to generate recipe for ${candidate.name}`);
        continue;
      }

      // Validate safety
      const safety = validateCommandSafety(recipe);
      if (!safety.safe) {
        console.warn(`Safety check failed for ${candidate.name}:`, safety.warnings);
      }

      // Add to Supabase
      const app = await addIntegrationApp({
        name: candidate.name,
        slug: candidate.slug,
        app_type: 'online',
        category: candidate.category,
        official_url: candidate.official_url,
        launch_url: candidate.launch_url,
        confidence: candidate.confidence,
        safe_to_launch: candidate.safe_to_integrate,
        needs_review: candidate.needs_review,
      });

      if (app) {
        added.push(app);

        // Add default actions from recipe
        if (recipe.actions && Array.isArray(recipe.actions)) {
          for (let i = 0; i < recipe.actions.length; i++) {
            const action = recipe.actions[i];
            await supabase.from('integration_actions').insert([
              {
                user_id: user.id,
                integration_app_id: app.id,
                action_id: action.id || `action-${i}`,
                label: action.label || '',
                action_type: action.action_type || '',
                target: action.target,
                icon_emoji: action.icon_emoji,
                order_index: i,
                is_enabled: true,
              },
            ]);
          }
        }
      }
    }

    return added;
  } catch (error) {
    console.error('Failed to discover and add apps:', error);
    return [];
  }
}

/**
 * Execute an action on an integration app
 * Handles open, search, and other action types
 */
export async function executeIntegrationAction(
  appId: string,
  actionId: string
): Promise<boolean> {
  try {
    const { data: app, error: appError } = await supabase
      .from('integration_apps')
      .select('*')
      .eq('id', appId)
      .single();

    if (appError) throw appError;

    const { data: action, error: actionError } = await supabase
      .from('integration_actions')
      .select('*')
      .eq('integration_app_id', appId)
      .eq('action_id', actionId)
      .single();

    if (actionError) throw actionError;

    // Handle action execution based on type
    switch (action.action_type) {
      case 'open_url':
      case 'open_url_template':
        // In a real app, this would open the URL
        // For now, just log and update last_executed
        console.log(`Opening URL: ${action.target}`);
        break;

      case 'open_app':
        console.log(`Opening app: ${app.exe_path}`);
        break;

      case 'update_preference':
        // Handle preference updates (pin, favorite, etc.)
        if (action.target === 'is_pinned') {
          await updateIntegrationApp(appId, { is_pinned: !app.is_pinned });
        }
        break;

      default:
        console.warn(`Unknown action type: ${action.action_type}`);
    }

    // Update last_executed and increment times_executed
    await supabase
      .from('integration_actions')
      .update({
        last_executed: new Date().toISOString(),
        times_executed: (action.times_executed || 0) + 1,
      })
      .eq('id', action.id);

    // Log to audit
    await supabase.from('audit_log').insert({
      type: 'integration_action_executed',
      message: `Executed action: ${action.label}`,
      actor: 'integration-service',
      data: { app_id: appId, action_id: actionId },
    });

    return true;
  } catch (error) {
    console.error('Failed to execute action:', error);
    return false;
  }
}

/**
 * Get icon data for an app
 */
export async function getIntegrationIconData(
  iconId: string
): Promise<string | null> {
  try {
    if (!iconId) return null;

    const { data, error } = await supabase
      .from('integration_icons')
      .select('cached_data_uri')
      .eq('id', iconId)
      .single();

    if (error) throw error;
    return data?.cached_data_uri || null;
  } catch (error) {
    console.error('Failed to load icon:', error);
    return null;
  }
}

/**
 * Batch load icons for multiple apps
 */
export async function batchLoadIcons(iconIds: string[]): Promise<Record<string, string>> {
  try {
    const validIds = iconIds.filter(Boolean);
    if (validIds.length === 0) return {};

    const { data, error } = await supabase
      .from('integration_icons')
      .select('id, cached_data_uri')
      .in('id', validIds);

    if (error) throw error;

    const result: Record<string, string> = {};
    data?.forEach((icon) => {
      if (icon.cached_data_uri) {
        result[icon.id] = icon.cached_data_uri;
      }
    });

    return result;
  } catch (error) {
    console.error('Failed to batch load icons:', error);
    return {};
  }
}

/**
 * Get app stats
 */
export async function getIntegrationStats(): Promise<{
  total: number;
  pinned: number;
  online: number;
  desktop: number;
  lastUpdated: string;
}> {
  try {
    const apps = await loadUserIntegrations();

    return {
      total: apps.length,
      pinned: apps.filter((a) => a.is_pinned).length,
      online: apps.filter((a) => a.app_type === 'online').length,
      desktop: apps.filter((a) => a.app_type === 'desktop').length,
      lastUpdated: new Date().toISOString(),
    };
  } catch (error) {
    console.error('Failed to get stats:', error);
    return {
      total: 0,
      pinned: 0,
      online: 0,
      desktop: 0,
      lastUpdated: new Date().toISOString(),
    };
  }
}
