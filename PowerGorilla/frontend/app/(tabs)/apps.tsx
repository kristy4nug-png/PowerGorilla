// app/(tabs)/apps.tsx — App Inventory screen

import React, { useEffect, useState, useCallback } from 'react';
import {
  View, Text, FlatList, StyleSheet, TextInput,
  TouchableOpacity, ActivityIndicator, RefreshControl,
} from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { fetchApps, fetchAppCategories } from '../../lib/supabase';
import { Colors, Typography, Spacing, Radius } from '../../lib/theme';
import { useDebouncedValue } from '../../lib/useDebouncedValue';

const STATUS_COLOR: Record<string, string> = {
  Installed: Colors.ok,
  Missing:   Colors.warn,
  Portable:  Colors.accent2,
  'Store app': Colors.accent,
  'Shortcut only': Colors.muted,
};

function AppCard({ item }: { item: any }) {
  const statusColor = STATUS_COLOR[item.status] ?? Colors.muted;
  return (
    <View style={styles.card}>
      <View style={styles.cardHeader}>
        <Text style={styles.appName} numberOfLines={1}>{item.name}</Text>
        <View style={[styles.badge, { borderColor: statusColor }]}>
          <Text style={[styles.badgeText, { color: statusColor }]}>{item.status}</Text>
        </View>
      </View>
      <Text style={styles.category}>{item.category ?? 'Unknown'}</Text>
      <View style={styles.tagRow}>
        {item.is_open_source && <Tag label="Open Source" color={Colors.ok} />}
        {item.is_free && !item.is_open_source && <Tag label="Free" color={Colors.accent} />}
        {item.local_mode === 'Local mode available' && <Tag label="Local" color={Colors.accent2} />}
        {item.licence_mode && item.licence_mode !== 'Unknown' && (
          <Tag label={item.licence_mode} color={Colors.muted} />
        )}
      </View>
      {item.version && (
        <Text style={styles.version}>v{item.version}{item.publisher ? ` · ${item.publisher}` : ''}</Text>
      )}
    </View>
  );
}

function Tag({ label, color }: { label: string; color: string }) {
  return (
    <View style={[styles.tag, { borderColor: color }]}>
      <Text style={[styles.tagText, { color }]}>{label}</Text>
    </View>
  );
}

function FilterChip({ label, active, onPress }: { label: string; active: boolean; onPress: () => void }) {
  return (
    <TouchableOpacity
      style={[styles.chip, active && styles.chipActive]}
      onPress={onPress}
    >
      <Text style={[styles.chipText, active && styles.chipTextActive]}>{label}</Text>
    </TouchableOpacity>
  );
}

const PAGE = 50;

export default function AppsScreen() {
  const [apps, setApps]             = useState<any[]>([]);
  const [categories, setCategories] = useState<string[]>([]);
  const [search, setSearch]         = useState('');
  const [category, setCategory]     = useState('');
  const [installedOnly, setInstalledOnly] = useState(false);
  const [openSourceOnly, setOpenSourceOnly] = useState(false);
  const debouncedSearch = useDebouncedValue(search.trim(), 250);
  const [loading, setLoading]       = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [offset, setOffset]         = useState(0);
  const [hasMore, setHasMore]       = useState(true);

  const loadApps = useCallback(async (reset = false, force = false) => {
    const off = reset ? 0 : offset;
    if (!reset) setLoadingMore(true);
    try {
      const data = await fetchApps({
        search: debouncedSearch || undefined,
        category: category || undefined,
        installedOnly,
        openSourceOnly,
        limit: PAGE,
        offset: off,
        force,
      });
      setApps(prev => reset ? data : [...prev, ...data]);
      setOffset(off + PAGE);
      setHasMore(data.length === PAGE);
    } finally {
      setLoading(false);
      setLoadingMore(false);
      setRefreshing(false);
    }
  }, [debouncedSearch, category, installedOnly, openSourceOnly, offset]);

  useEffect(() => {
    setLoading(true);
    setOffset(0);
    loadApps(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [debouncedSearch, category, installedOnly, openSourceOnly]);

  useEffect(() => {
    fetchAppCategories().then(setCategories).catch(() => {});
  }, []);

  return (
    <View style={styles.container}>
      {/* Search bar */}
      <View style={styles.searchRow}>
        <MaterialIcons name="search" size={20} color={Colors.muted} style={styles.searchIcon} />
        <TextInput
          style={styles.searchInput}
          placeholder="Search apps..."
          placeholderTextColor={Colors.muted}
          value={search}
          onChangeText={setSearch}
        />
        {search ? (
          <TouchableOpacity onPress={() => setSearch('')}>
            <MaterialIcons name="close" size={20} color={Colors.muted} />
          </TouchableOpacity>
        ) : null}
      </View>

      {/* Filters */}
      <View style={styles.filterRow}>
        <FilterChip label="All" active={!installedOnly && !openSourceOnly} onPress={() => { setInstalledOnly(false); setOpenSourceOnly(false); }} />
        <FilterChip label="Installed" active={installedOnly} onPress={() => setInstalledOnly(!installedOnly)} />
        <FilterChip label="Open Source" active={openSourceOnly} onPress={() => setOpenSourceOnly(!openSourceOnly)} />
        {categories.slice(0, 5).map(cat => (
          <FilterChip key={cat} label={cat} active={category === cat} onPress={() => setCategory(category === cat ? '' : cat)} />
        ))}
      </View>

      {loading ? (
        <View style={styles.center}>
          <ActivityIndicator size="large" color={Colors.accent} />
          <Text style={styles.loadingText}>Loading apps...</Text>
        </View>
      ) : apps.length === 0 ? (
        <View style={styles.center}>
          <MaterialIcons name="search-off" size={48} color={Colors.muted} />
          <Text style={styles.emptyText}>No apps found</Text>
          <Text style={styles.emptyHint}>Run gorpush in PowerShell to load your inventory</Text>
        </View>
      ) : (
        <FlatList
          data={apps}
          keyExtractor={item => item.id}
          renderItem={({ item }) => <AppCard item={item} />}
          contentContainerStyle={styles.list}
          refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); loadApps(true, true); }} tintColor={Colors.accent} />}
          onEndReached={() => { if (hasMore && !loadingMore) loadApps(); }}
          onEndReachedThreshold={0.3}
          ListFooterComponent={loadingMore ? <ActivityIndicator color={Colors.accent} style={{ margin: Spacing.md }} /> : null}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container:    { flex: 1, backgroundColor: Colors.bg },
  searchRow:    { flexDirection: 'row', alignItems: 'center', backgroundColor: Colors.panel, margin: Spacing.md, marginBottom: Spacing.sm, borderRadius: Radius.md, paddingHorizontal: Spacing.sm, borderWidth: 1, borderColor: Colors.border },
  searchIcon:   { marginRight: Spacing.sm },
  searchInput:  { flex: 1, color: Colors.text, fontSize: 15, paddingVertical: 12 },
  filterRow:    { flexDirection: 'row', flexWrap: 'wrap', paddingHorizontal: Spacing.md, gap: Spacing.xs, marginBottom: Spacing.sm },
  chip:         { paddingHorizontal: Spacing.sm, paddingVertical: 5, borderRadius: Radius.full, borderWidth: 1, borderColor: Colors.border, backgroundColor: Colors.panel },
  chipActive:   { borderColor: Colors.accent, backgroundColor: Colors.accent + '22' },
  chipText:     { ...Typography.small, color: Colors.muted },
  chipTextActive: { color: Colors.accent, fontWeight: '700' },
  list:         { padding: Spacing.md, gap: Spacing.sm, paddingBottom: Spacing.xxl },
  card:         { backgroundColor: Colors.panel, borderRadius: Radius.md, padding: Spacing.md, borderWidth: 1, borderColor: Colors.border },
  cardHeader:   { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 4 },
  appName:      { ...Typography.heading3, flex: 1, marginRight: Spacing.sm },
  badge:        { borderWidth: 1, borderRadius: Radius.full, paddingHorizontal: 8, paddingVertical: 2 },
  badgeText:    { fontSize: 11, fontWeight: '700' },
  category:     { ...Typography.small, marginBottom: Spacing.xs },
  tagRow:       { flexDirection: 'row', flexWrap: 'wrap', gap: 4, marginTop: 4 },
  tag:          { borderWidth: 1, borderRadius: Radius.full, paddingHorizontal: 7, paddingVertical: 2 },
  tagText:      { fontSize: 10, fontWeight: '600' },
  version:      { ...Typography.small, marginTop: Spacing.xs },
  center:       { flex: 1, alignItems: 'center', justifyContent: 'center', padding: Spacing.xl },
  loadingText:  { ...Typography.body, color: Colors.muted, marginTop: Spacing.md },
  emptyText:    { ...Typography.heading3, color: Colors.muted, marginTop: Spacing.md },
  emptyHint:    { ...Typography.small, textAlign: 'center', marginTop: Spacing.sm },
});
