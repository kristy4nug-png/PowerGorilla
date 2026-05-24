// app/(tabs)/workflows.tsx — Visual Workflow Builder

import React, { useEffect, useState } from 'react';
import {
  View, Text, FlatList, StyleSheet, TouchableOpacity,
  TextInput, ActivityIndicator, ScrollView,
} from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { fetchWorkflows } from '../../lib/supabase';
import { Colors, Typography, Spacing, Radius } from '../../lib/theme';
import { useDebouncedValue } from '../../lib/useDebouncedValue';

const RISK_COLOR: Record<string, string> = {
  Low: Colors.ok, Medium: Colors.warn, High: Colors.danger,
};
const DIFF_COLOR: Record<string, string> = {
  Easy: Colors.ok, Medium: Colors.warn, Hard: Colors.danger, Unknown: Colors.muted,
};
const SIZE_LABELS: Record<number, string> = { 2: '2-App', 3: '3-App', 4: '4-App' };

function Badge({ label, color }: { label: string; color: string }) {
  return (
    <View style={[styles.badge, { borderColor: color }]}>
      <Text style={[styles.badgeText, { color }]}>{label}</Text>
    </View>
  );
}

function WorkflowCard({ item }: { item: any }) {
  const [expanded, setExpanded] = useState(false);
  return (
    <TouchableOpacity style={styles.card} onPress={() => setExpanded(!expanded)} activeOpacity={0.85}>
      {/* App combination */}
      <View style={styles.appRow}>
        {(item.app_names ?? []).map((name: string, i: number) => (
          <React.Fragment key={name}>
            {i > 0 && <MaterialIcons name="add" size={14} color={Colors.muted} />}
            <View style={styles.appChip}>
              <Text style={styles.appChipText} numberOfLines={1}>{name}</Text>
            </View>
          </React.Fragment>
        ))}
        <MaterialIcons name="arrow-forward" size={14} color={Colors.accent} style={{ marginLeft: 4 }} />
      </View>

      <Text style={styles.workflowName}>{item.workflow_name}</Text>
      <Text style={styles.desc} numberOfLines={expanded ? undefined : 2}>{item.description}</Text>

      <View style={styles.badgeRow}>
        <Badge label={SIZE_LABELS[item.combination_size] ?? `${item.combination_size}-App`} color={Colors.accent} />
        <Badge label={item.risk_level ?? 'Low'} color={RISK_COLOR[item.risk_level] ?? Colors.muted} />
        <Badge label={item.difficulty ?? 'Unknown'} color={DIFF_COLOR[item.difficulty] ?? Colors.muted} />
        {item.automation_readiness && item.automation_readiness !== 'Unknown' && (
          <Badge label={item.automation_readiness} color={Colors.accent2} />
        )}
      </View>

      {expanded && item.sign_in_requirement && (
        <Text style={styles.signIn}>
          <Text style={{ color: Colors.muted }}>Sign-in: </Text>
          {item.sign_in_requirement}
        </Text>
      )}

      {expanded && item.category && (
        <Text style={styles.catLabel}>
          <Text style={{ color: Colors.muted }}>Category: </Text>
          {item.category}
        </Text>
      )}

      {item.rank_score != null && (
        <View style={styles.scoreRow}>
          <View style={[styles.scoreBar, { width: `${Math.min(100, item.rank_score)}%` }]} />
          <Text style={styles.scoreText}>{Math.round(item.rank_score)}</Text>
        </View>
      )}
    </TouchableOpacity>
  );
}

export default function WorkflowsScreen() {
  const [workflows, setWorkflows]   = useState<any[]>([]);
  const [search, setSearch]         = useState('');
  const [comboSize, setComboSize]   = useState(0);
  const debouncedSearch = useDebouncedValue(search.trim(), 250);
  const [loading, setLoading]       = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  async function load(force = false) {
    try {
      const data = await fetchWorkflows({
        search: debouncedSearch || undefined,
        combinationSize: comboSize || undefined,
        limit: 60,
        force,
      });
      setWorkflows(data);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }

  useEffect(() => { setLoading(true); load(); }, [debouncedSearch, comboSize]);

  return (
    <View style={styles.container}>
      {/* Search */}
      <View style={styles.searchRow}>
        <MaterialIcons name="search" size={20} color={Colors.muted} style={{ marginRight: Spacing.sm }} />
        <TextInput
          style={styles.searchInput}
          placeholder="Search workflows..."
          placeholderTextColor={Colors.muted}
          value={search}
          onChangeText={setSearch}
        />
      </View>

      {/* Size filter */}
      <View style={styles.filterRow}>
        {[0, 2, 3, 4].map(size => (
          <TouchableOpacity
            key={size}
            style={[styles.chip, comboSize === size && styles.chipActive]}
            onPress={() => setComboSize(size)}
          >
            <Text style={[styles.chipText, comboSize === size && styles.chipTextActive]}>
              {size === 0 ? 'All' : SIZE_LABELS[size]}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {loading ? (
        <View style={styles.center}>
          <ActivityIndicator size="large" color={Colors.accent} />
          <Text style={styles.loadingText}>Loading workflows...</Text>
        </View>
      ) : workflows.length === 0 ? (
        <View style={styles.center}>
          <MaterialIcons name="account-tree" size={48} color={Colors.muted} />
          <Text style={styles.emptyText}>No workflows found</Text>
          <Text style={styles.emptyHint}>Run gorextract then gorpush to import workflows</Text>
        </View>
      ) : (
        <FlatList
          data={workflows}
          keyExtractor={item => item.id}
          renderItem={({ item }) => <WorkflowCard item={item} />}
          contentContainerStyle={styles.list}
          onRefresh={() => { setRefreshing(true); load(true); }}
          refreshing={refreshing}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container:    { flex: 1, backgroundColor: Colors.bg },
  searchRow:    { flexDirection: 'row', alignItems: 'center', backgroundColor: Colors.panel, margin: Spacing.md, marginBottom: Spacing.sm, borderRadius: Radius.md, paddingHorizontal: Spacing.sm, borderWidth: 1, borderColor: Colors.border },
  searchInput:  { flex: 1, color: Colors.text, fontSize: 15, paddingVertical: 12 },
  filterRow:    { flexDirection: 'row', paddingHorizontal: Spacing.md, gap: Spacing.xs, marginBottom: Spacing.sm },
  chip:         { paddingHorizontal: Spacing.sm, paddingVertical: 5, borderRadius: Radius.full, borderWidth: 1, borderColor: Colors.border, backgroundColor: Colors.panel },
  chipActive:   { borderColor: Colors.accent, backgroundColor: Colors.accent + '22' },
  chipText:     { ...Typography.small, color: Colors.muted },
  chipTextActive: { color: Colors.accent, fontWeight: '700' },
  list:         { padding: Spacing.md, gap: Spacing.sm, paddingBottom: Spacing.xxl },
  card:         { backgroundColor: Colors.panel, borderRadius: Radius.md, padding: Spacing.md, borderWidth: 1, borderColor: Colors.border },
  appRow:       { flexDirection: 'row', flexWrap: 'wrap', alignItems: 'center', gap: 4, marginBottom: Spacing.sm },
  appChip:      { backgroundColor: Colors.panel2, borderRadius: Radius.full, paddingHorizontal: 8, paddingVertical: 3, borderWidth: 1, borderColor: Colors.border },
  appChipText:  { fontSize: 11, color: Colors.accent, fontWeight: '600', maxWidth: 100 },
  workflowName: { ...Typography.heading3, marginBottom: 4 },
  desc:         { ...Typography.body, color: Colors.muted, marginBottom: Spacing.sm },
  badgeRow:     { flexDirection: 'row', flexWrap: 'wrap', gap: 4, marginBottom: Spacing.xs },
  badge:        { borderWidth: 1, borderRadius: Radius.full, paddingHorizontal: 8, paddingVertical: 2 },
  badgeText:    { fontSize: 11, fontWeight: '600' },
  signIn:       { ...Typography.small, marginTop: Spacing.xs },
  catLabel:     { ...Typography.small, marginTop: 2 },
  scoreRow:     { flexDirection: 'row', alignItems: 'center', marginTop: Spacing.sm, gap: Spacing.sm },
  scoreBar:     { height: 4, backgroundColor: Colors.accent, borderRadius: Radius.full, maxWidth: '85%' },
  scoreText:    { ...Typography.small, color: Colors.accent },
  center:       { flex: 1, alignItems: 'center', justifyContent: 'center', padding: Spacing.xl },
  loadingText:  { ...Typography.body, color: Colors.muted, marginTop: Spacing.md },
  emptyText:    { ...Typography.heading3, color: Colors.muted, marginTop: Spacing.md },
  emptyHint:    { ...Typography.small, textAlign: 'center', marginTop: Spacing.sm },
});
