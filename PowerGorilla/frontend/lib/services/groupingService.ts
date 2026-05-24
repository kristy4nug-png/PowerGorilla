// frontend/lib/services/groupingService.ts
// Manage custom app groups/combinations
// Enables users to create themed collections (2-4 apps per group)

import { supabase } from '../supabase';

export interface AppGroupCombination {
  id: string;
  user_id: string;
  name: string;
  icon_emoji: string;
  color: string;
  app_ids: string[];
  description?: string;
  created_at: string;
  updated_at: string;
  order_index: number;
}

export interface GroupedAppsView {
  groupId: string;
  groupName: string;
  emoji: string;
  color: string;
  appCount: number;
  description?: string;
}

/**
 * Create new app group/combination
 */
export async function createAppGroup(
  groupName: string,
  appIds: string[],
  emoji: string,
  color: string,
  description?: string
): Promise<AppGroupCombination | null> {
  try {
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      console.error('User not authenticated');
      return null;
    }

    // Validate app count
    if (appIds.length < 2 || appIds.length > 4) {
      throw new Error('Groups must have 2-4 apps');
    }

    // Get max order_index for this user
    const { data: existingGroups } = await supabase
      .from('app_group_combinations')
      .select('order_index')
      .eq('user_id', user.id)
      .order('order_index', { ascending: false })
      .limit(1);

    const orderIndex = existingGroups && existingGroups.length > 0
      ? (existingGroups[0].order_index || 0) + 1
      : 0;

    const { data, error } = await supabase
      .from('app_group_combinations')
      .insert({
        user_id: user.id,
        name: groupName,
        icon_emoji: emoji,
        color,
        app_ids: appIds,
        description,
        order_index: orderIndex,
      })
      .select()
      .single();

    if (error) {
      console.error('Failed to create group:', error);
      return null;
    }

    return data;
  } catch (error) {
    console.error('Error in createAppGroup:', error);
    return null;
  }
}

/**
 * Get all groups for current user
 */
export async function getUserAppGroups(): Promise<AppGroupCombination[]> {
  try {
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return [];
    }

    const { data, error } = await supabase
      .from('app_group_combinations')
      .select('*')
      .eq('user_id', user.id)
      .order('order_index', { ascending: true });

    if (error) {
      console.error('Failed to fetch groups:', error);
      return [];
    }

    return data || [];
  } catch (error) {
    console.error('Error in getUserAppGroups:', error);
    return [];
  }
}

/**
 * Update app group
 */
export async function updateAppGroup(
  groupId: string,
  updates: Partial<Omit<AppGroupCombination, 'id' | 'user_id' | 'created_at'>>
): Promise<AppGroupCombination | null> {
  try {
    const { data, error } = await supabase
      .from('app_group_combinations')
      .update(updates)
      .eq('id', groupId)
      .select()
      .single();

    if (error) {
      console.error('Failed to update group:', error);
      return null;
    }

    return data;
  } catch (error) {
    console.error('Error in updateAppGroup:', error);
    return null;
  }
}

/**
 * Delete app group
 */
export async function deleteAppGroup(groupId: string): Promise<boolean> {
  try {
    const { error } = await supabase
      .from('app_group_combinations')
      .delete()
      .eq('id', groupId);

    if (error) {
      console.error('Failed to delete group:', error);
      return false;
    }

    return true;
  } catch (error) {
    console.error('Error in deleteAppGroup:', error);
    return false;
  }
}

/**
 * Reorder groups (for drag-and-drop UI)
 */
export async function reorderAppGroups(
  groupIds: string[]
): Promise<boolean> {
  try {
    // Update each group with new order index
    const updates = groupIds.map((id, index) => ({
      id,
      order_index: index,
    }));

    for (const update of updates) {
      const { error } = await supabase
        .from('app_group_combinations')
        .update({ order_index: update.order_index })
        .eq('id', update.id);

      if (error) {
        console.error('Failed to reorder group:', error);
        return false;
      }
    }

    return true;
  } catch (error) {
    console.error('Error in reorderAppGroups:', error);
    return false;
  }
}

/**
 * Add app to existing group
 */
export async function addAppToGroup(
  groupId: string,
  appId: string
): Promise<AppGroupCombination | null> {
  try {
    const { data: group } = await supabase
      .from('app_group_combinations')
      .select('app_ids')
      .eq('id', groupId)
      .single();

    if (!group) {
      return null;
    }

    const appIds = group.app_ids || [];
    if (appIds.includes(appId)) {
      return { ...group, id: groupId } as AppGroupCombination;
    }

    if (appIds.length >= 4) {
      throw new Error('Group already has maximum 4 apps');
    }

    const { data, error } = await supabase
      .from('app_group_combinations')
      .update({ app_ids: [...appIds, appId] })
      .eq('id', groupId)
      .select()
      .single();

    if (error) {
      console.error('Failed to add app to group:', error);
      return null;
    }

    return data;
  } catch (error) {
    console.error('Error in addAppToGroup:', error);
    return null;
  }
}

/**
 * Remove app from group
 */
export async function removeAppFromGroup(
  groupId: string,
  appId: string
): Promise<AppGroupCombination | null> {
  try {
    const { data: group } = await supabase
      .from('app_group_combinations')
      .select('app_ids')
      .eq('id', groupId)
      .single();

    if (!group) {
      return null;
    }

    const appIds = (group.app_ids || []).filter((id: string) => id !== appId);

    if (appIds.length < 2) {
      throw new Error('Groups must have at least 2 apps');
    }

    const { data, error } = await supabase
      .from('app_group_combinations')
      .update({ app_ids: appIds })
      .eq('id', groupId)
      .select()
      .single();

    if (error) {
      console.error('Failed to remove app from group:', error);
      return null;
    }

    return data;
  } catch (error) {
    console.error('Error in removeAppFromGroup:', error);
    return null;
  }
}
