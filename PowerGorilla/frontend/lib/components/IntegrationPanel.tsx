// frontend/lib/components/IntegrationPanel.tsx
// Discovery and management panel for integrations
// Allows browsing, searching, adding, and organizing integration apps

import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TextInput,
  Pressable,
  ActivityIndicator,
  Alert,
  SectionList,
  RefreshControl,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../theme';
import IntegrationCard from './IntegrationCard';

interface IntegrationApp {
  id: string;
  name: string;
  slug: string;
  app_type: 'online' | 'desktop' | 'hybrid';
  category: string;
  icon_id?: string;
  confidence: number;
  safe_to_launch: boolean;
  needs_review: boolean;
  is_pinned: boolean;
  official_url?: string;
  launch_url?: string;
  custom_label?: string;
}

interface IntegrationPanelProps {
  apps: IntegrationApp[];
  isLoading?: boolean;
  onRefresh?: () => Promise<void>;
  onAddApp?: () => void;
  onEditApp?: (appId: string) => void;
  onRemoveApp?: (appId: string) => Promise<void>;
  onPinApp?: (appId: string, pinned: boolean) => Promise<void>;
  onExecuteAction?: (appId: string, actionId: string) => Promise<void>;
  onDiscoverApps?: () => void;
  getIconData?: (iconId: string) => Promise<string | null>;
}

type ViewMode = 'all' | 'pinned' | 'desktop' | 'online' | 'category';

export default function IntegrationPanel({
  apps,
  isLoading = false,
  onRefresh,
  onAddApp,
  onEditApp,
  onRemoveApp,
  onPinApp,
  onExecuteAction,
  onDiscoverApps,
  getIconData,
}: IntegrationPanelProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [viewMode, setViewMode] = useState<ViewMode>('all');
  const [refreshing, setRefreshing] = useState(false);
  const [categoryExpanded, setCategoryExpanded] = useState<Record<string, boolean>>({});
  const [iconCache, setIconCache] = useState<Record<string, string | null>>({});

  // Filter apps based on search and view mode
  const filteredApps = useCallback(() => {
    let result = [...apps];

    // Filter by view mode
    if (viewMode === 'pinned') {
      result = result.filter((app) => app.is_pinned);
    } else if (viewMode === 'desktop') {
      result = result.filter((app) => app.app_type === 'desktop');
    } else if (viewMode === 'online') {
      result = result.filter((app) => app.app_type === 'online');
    }

    // Filter by search query
    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase();
      result = result.filter(
        (app) =>
          app.name.toLowerCase().includes(query) ||
          app.slug.toLowerCase().includes(query) ||
          app.category.toLowerCase().includes(query)
      );
    }

    return result;
  }, [apps, viewMode, searchQuery]);

  // Group apps by category
  const appsByCategory = useCallback(() => {
    const filtered = filteredApps();
    const grouped: Record<string, IntegrationApp[]> = {};

    filtered.forEach((app) => {
      if (!grouped[app.category]) {
        grouped[app.category] = [];
      }
      grouped[app.category].push(app);
    });

    return Object.entries(grouped)
      .map(([category, categoryApps]) => ({
        title: category,
        data: categoryApps.sort((a, b) => {
          if (a.is_pinned !== b.is_pinned) return a.is_pinned ? -1 : 1;
          return a.name.localeCompare(b.name);
        }),
      }))
      .sort((a, b) => a.title.localeCompare(b.title));
  }, [filteredApps]);

  const handleRefresh = async () => {
    setRefreshing(true);
    try {
      await onRefresh?.();
    } catch (error) {
      Alert.alert('Refresh Error', error instanceof Error ? error.message : 'Failed to refresh');
    } finally {
      setRefreshing(false);
    }
  };

  const loadIconData = useCallback(
    async (iconId: string) => {
      if (iconCache[iconId]) {
        return iconCache[iconId];
      }

      if (!getIconData) return null;

      try {
        const data = await getIconData(iconId);
        setIconCache((prev) => ({ ...prev, [iconId]: data }));
        return data;
      } catch (error) {
        console.error('Failed to load icon:', error);
        return null;
      }
    },
    [iconCache, getIconData]
  );

  const renderEmpty = () => (
    <View style={styles.emptyContainer}>
      <Ionicons name="apps-outline" size={48} color={Colors.textSecondary} />
      <Text style={styles.emptyTitle}>No Integrations Yet</Text>
      <Text style={styles.emptyText}>Discover and add your favorite apps to get started</Text>
      <Pressable style={styles.emptyButton} onPress={onDiscoverApps}>
        <Ionicons name="search" size={20} color="white" />
        <Text style={styles.emptyButtonText}>Discover Apps</Text>
      </Pressable>
    </View>
  );

  const renderViewModeButton = (mode: ViewMode, label: string) => (
    <Pressable
      style={[
        styles.viewModeButton,
        viewMode === mode && styles.viewModeButtonActive,
      ]}
      onPress={() => setViewMode(mode)}
    >
      <Text
        style={[
          styles.viewModeButtonText,
          viewMode === mode && styles.viewModeButtonTextActive,
        ]}
      >
        {label}
      </Text>
    </Pressable>
  );

  const renderCategoryHeader = (category: string) => {
    const isExpanded = categoryExpanded[category] ?? true;
    const count = appsByCategory().find((c) => c.title === category)?.data.length || 0;

    return (
      <Pressable
        style={styles.categoryHeader}
        onPress={() =>
          setCategoryExpanded((prev) => ({
            ...prev,
            [category]: !prev[category],
          }))
        }
      >
        <View style={styles.categoryHeaderContent}>
          <Ionicons
            name={isExpanded ? 'chevron-down' : 'chevron-forward'}
            size={20}
            color={Colors.text}
          />
          <Text style={styles.categoryTitle}>{category}</Text>
          <View style={styles.categoryCount}>
            <Text style={styles.categoryCountText}>{count}</Text>
          </View>
        </View>
      </Pressable>
    );
  };

  const renderAppCard = ({ item: app }: { item: IntegrationApp }) => {
    const isExpanded = categoryExpanded[app.category] ?? true;
    if (!isExpanded) return null;

    return (
      <IntegrationCard
        app={app}
        iconData={iconCache[app.icon_id || ''] ?? undefined}
        onEdit={onEditApp}
        onRemove={onRemoveApp}
        onPin={onPinApp}
        onAction={async (actionId) => {
          await onExecuteAction?.(app.id, actionId);
        }}
        isLoading={isLoading}
      />
    );
  };

  if (!apps || apps.length === 0) {
    return renderEmpty();
  }

  const sections = appsByCategory();
  const filtered = filteredApps();

  return (
    <View style={styles.container}>
      {/* Header with title and add button */}
      <View style={styles.header}>
        <View>
          <Text style={styles.title}>Integrations</Text>
          <Text style={styles.subtitle}>{filtered.length} app{filtered.length !== 1 ? 's' : ''}</Text>
        </View>
        <Pressable style={styles.addButton} onPress={onAddApp} disabled={isLoading}>
          <Ionicons name="add-circle" size={28} color="#6366F1" />
        </Pressable>
      </View>

      {/* Search bar */}
      <View style={styles.searchContainer}>
        <Ionicons name="search" size={18} color={Colors.textSecondary} />
        <TextInput
          style={styles.searchInput}
          placeholder="Search apps..."
          placeholderTextColor={Colors.textSecondary}
          value={searchQuery}
          onChangeText={setSearchQuery}
        />
        {searchQuery.length > 0 && (
          <Pressable onPress={() => setSearchQuery('')}>
            <Ionicons name="close-circle" size={18} color={Colors.textSecondary} />
          </Pressable>
        )}
      </View>

      {/* View mode buttons */}
      <View style={styles.viewModeContainer}>
        {renderViewModeButton('all', 'All')}
        {renderViewModeButton('pinned', '⭐ Pinned')}
        {renderViewModeButton('online', 'Online')}
        {renderViewModeButton('desktop', 'Desktop')}
      </View>

      {/* Apps list or empty state */}
      {filtered.length === 0 ? (
        <View style={styles.noResultsContainer}>
          <Ionicons name="search-outline" size={40} color={Colors.textSecondary} />
          <Text style={styles.noResultsText}>No apps found</Text>
          <Text style={styles.noResultsSubtext}>Try adjusting your search or view mode</Text>
        </View>
      ) : (
        <SectionList
          sections={sections}
          keyExtractor={(item) => item.id}
          renderItem={renderAppCard}
          renderSectionHeader={({ section: { title } }) => renderCategoryHeader(title)}
          contentContainerStyle={styles.listContent}
          scrollEnabled={true}
          refreshControl={
            <RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />
          }
          ListEmptyComponent={renderEmpty}
        />
      )}

      {/* Loading indicator */}
      {isLoading && (
        <View style={styles.loadingOverlay}>
          <ActivityIndicator size="large" color="#6366F1" />
        </View>
      )}

      {/* Discover button (floating) */}
      {filtered.length === 0 && !isLoading && (
        <Pressable
          style={styles.discoverFab}
          onPress={onDiscoverApps}
        >
          <Ionicons name="sparkles" size={24} color="white" />
        </Pressable>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.bg,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: Colors.panel,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
  },
  title: {
    color: Colors.text,
    fontSize: 20,
    fontWeight: '700',
  },
  subtitle: {
    color: Colors.textSecondary,
    fontSize: 12,
    marginTop: 2,
  },
  addButton: {
    padding: 8,
  },
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 8,
    backgroundColor: Colors.bg,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
    gap: 8,
  },
  searchInput: {
    flex: 1,
    paddingVertical: 8,
    paddingHorizontal: 12,
    backgroundColor: Colors.panel,
    borderRadius: 8,
    color: Colors.text,
    fontSize: 14,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  viewModeContainer: {
    flexDirection: 'row',
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: Colors.bg,
    gap: 6,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
  },
  viewModeButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
    backgroundColor: Colors.panel,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  viewModeButtonActive: {
    backgroundColor: '#6366F1',
    borderColor: '#6366F1',
  },
  viewModeButtonText: {
    color: Colors.text,
    fontSize: 12,
    fontWeight: '500',
  },
  viewModeButtonTextActive: {
    color: 'white',
  },
  listContent: {
    paddingVertical: 8,
  },
  categoryHeader: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    backgroundColor: Colors.panel,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
  },
  categoryHeaderContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  categoryTitle: {
    color: Colors.text,
    fontSize: 14,
    fontWeight: '600',
    flex: 1,
  },
  categoryCount: {
    backgroundColor: '#6366F1',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 4,
  },
  categoryCountText: {
    color: 'white',
    fontSize: 11,
    fontWeight: '600',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 32,
  },
  emptyTitle: {
    color: Colors.text,
    fontSize: 18,
    fontWeight: '700',
    marginTop: 16,
    textAlign: 'center',
  },
  emptyText: {
    color: Colors.textSecondary,
    fontSize: 14,
    marginTop: 8,
    textAlign: 'center',
  },
  emptyButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#6366F1',
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 8,
    marginTop: 20,
    gap: 8,
  },
  emptyButtonText: {
    color: 'white',
    fontSize: 14,
    fontWeight: '600',
  },
  noResultsContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 32,
  },
  noResultsText: {
    color: Colors.text,
    fontSize: 16,
    fontWeight: '600',
    marginTop: 12,
  },
  noResultsSubtext: {
    color: Colors.textSecondary,
    fontSize: 12,
    marginTop: 4,
    textAlign: 'center',
  },
  loadingOverlay: {
    ...StyleSheet.absoluteFill,
    backgroundColor: 'rgba(0, 0, 0, 0.3)',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 100,
  },
  discoverFab: {
    position: 'absolute',
    bottom: 24,
    right: 24,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: '#6366F1',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
    elevation: 5,
  },
});
