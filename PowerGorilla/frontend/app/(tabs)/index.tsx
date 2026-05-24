// app/(tabs)/index.tsx — Dashboard screen

import React, { useEffect, useState } from 'react';
import {
  View, Text, ScrollView, StyleSheet, RefreshControl,
  TouchableOpacity, ActivityIndicator, Image,
} from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { fetchDashboardStats, fetchAuditLog } from '../../lib/supabase';
import { Colors, Typography, Spacing, Radius, Shadow } from '../../lib/theme';

const brandLogo = require('../../assets/icon.png');

interface Stats {
  total_apps: number;
  installed_apps: number;
  missing_apps: number;
  open_source_apps: number;
  total_workflows: number;
  two_app_workflows: number;
  three_app_workflows: number;
  four_app_workflows: number;
  apps_embedded: number;
  workflows_embedded: number;
  valid_extractions: number;
  generated_at: string;
}

function StatCard({ label, value, icon, accent }: {
  label: string; value: string | number; icon: any; accent?: string;
}) {
  const color = accent ?? Colors.accent;
  return (
    <View style={[styles.statCard, Shadow.card]}>
      <MaterialIcons name={icon} size={28} color={color} style={styles.statIcon} />
      <Text style={[styles.statValue, { color }]}>{value?.toLocaleString?.() ?? value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

function SectionHeader({ title }: { title: string }) {
  return <Text style={styles.sectionHeader}>{title}</Text>;
}

function LogRow({ item }: { item: any }) {
  return (
    <View style={styles.logRow}>
      <View style={styles.logDot} />
      <View style={styles.logBody}>
        <Text style={styles.logType}>{item.type}</Text>
        <Text style={styles.logMsg} numberOfLines={2}>{item.message}</Text>
        <Text style={styles.logTs}>{new Date(item.ts).toLocaleString()}</Text>
      </View>
    </View>
  );
}

export default function DashboardScreen() {
  const [stats, setStats]       = useState<Stats | null>(null);
  const [log, setLog]           = useState<any[]>([]);
  const [loading, setLoading]   = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError]       = useState<string | null>(null);

  async function load(force = false) {
    try {
      setError(null);
      const [s, l] = await Promise.all([
        fetchDashboardStats({ force }),
        fetchAuditLog(8, { force }),
      ]);
      setStats(s);
      setLog(l);
    } catch (e: any) {
      setError(e.message ?? 'Failed to load dashboard');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }

  useEffect(() => { load(); }, []);

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={Colors.accent} />
        <Text style={styles.loadingText}>Loading dashboard...</Text>
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.center}>
        <MaterialIcons name="error-outline" size={48} color={Colors.danger} />
        <Text style={styles.errorText}>{error}</Text>
        <TouchableOpacity style={styles.retryBtn} onPress={() => load(true)}>
          <Text style={styles.retryText}>Retry</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const embedPct = stats && stats.total_apps > 0
    ? Math.round((stats.apps_embedded / stats.total_apps) * 100)
    : 0;

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); load(true); }} tintColor={Colors.accent} />}
    >
      <View style={styles.hero}>
        <View style={styles.heroHeader}>
          <View style={styles.heroCopy}>
            <Text style={styles.heroTitle}>Phat Gorrilla</Text>
            <Text style={styles.heroSub}>Local-first command centre · Supabase · pgvector · Ollama JSON schema engine</Text>
            {stats && (
              <Text style={styles.heroTs}>
                Updated {new Date(stats.generated_at).toLocaleString()}
              </Text>
            )}
          </View>
          <Image source={brandLogo} style={styles.heroLogo} accessibilityLabel="Phat Gorrilla logo" />
        </View>
      </View>

      {/* App stats */}
      <SectionHeader title="App Inventory" />
      <View style={styles.statGrid}>
        <StatCard label="Total Apps"   value={stats?.total_apps ?? 0}       icon="inventory-2"   accent={Colors.accent} />
        <StatCard label="Installed"    value={stats?.installed_apps ?? 0}   icon="check-circle"  accent={Colors.ok} />
        <StatCard label="Missing"      value={stats?.missing_apps ?? 0}     icon="warning"       accent={Colors.warn} />
        <StatCard label="Open Source"  value={stats?.open_source_apps ?? 0} icon="lock-open"     accent={Colors.accent2} />
      </View>

      {/* Workflow stats */}
      <SectionHeader title="Workflows" />
      <View style={styles.statGrid}>
        <StatCard label="Total"    value={stats?.total_workflows ?? 0}       icon="account-tree" accent={Colors.accent} />
        <StatCard label="2-App"    value={stats?.two_app_workflows ?? 0}     icon="cable"        accent={Colors.ok} />
        <StatCard label="3-App"    value={stats?.three_app_workflows ?? 0}   icon="hub"          accent={Colors.warn} />
        <StatCard label="4-App"    value={stats?.four_app_workflows ?? 0}    icon="device-hub"   accent={Colors.accent2} />
      </View>

      {/* Vector / AI stats */}
      <SectionHeader title="Vector Database" />
      <View style={styles.vectorPanel}>
        <View style={styles.vectorRow}>
          <MaterialIcons name="memory" size={20} color={Colors.accent2} />
          <Text style={styles.vectorLabel}>Apps embedded</Text>
          <Text style={styles.vectorValue}>{stats?.apps_embedded ?? 0} / {stats?.total_apps ?? 0} ({embedPct}%)</Text>
        </View>
        <View style={styles.progressBar}>
          <View style={[styles.progressFill, { width: `${embedPct}%` }]} />
        </View>
        <View style={styles.vectorRow}>
          <MaterialIcons name="memory" size={20} color={Colors.ok} />
          <Text style={styles.vectorLabel}>Workflows embedded</Text>
          <Text style={styles.vectorValue}>{stats?.workflows_embedded ?? 0}</Text>
        </View>
        <View style={styles.vectorRow}>
          <MaterialIcons name="verified" size={20} color={Colors.ok} />
          <Text style={styles.vectorLabel}>Valid extractions</Text>
          <Text style={styles.vectorValue}>{stats?.valid_extractions ?? 0}</Text>
        </View>
      </View>

      {/* Audit log */}
      {log.length > 0 && (
        <>
          <SectionHeader title="Recent Activity" />
          <View style={styles.logPanel}>
            {log.map((item: any) => <LogRow key={item.id} item={item} />)}
          </View>
        </>
      )}

      {log.length === 0 && (
        <View style={styles.emptyLog}>
          <MaterialIcons name="info-outline" size={20} color={Colors.muted} />
          <Text style={styles.emptyLogText}>
            No activity yet. Run gorpush from PowerShell to load data.
          </Text>
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container:    { flex: 1, backgroundColor: Colors.bg },
  content:      { padding: Spacing.md, paddingBottom: Spacing.xxl },
  center:       { flex: 1, alignItems: 'center', justifyContent: 'center', padding: Spacing.xl, backgroundColor: Colors.bg },
  loadingText:  { ...Typography.body, color: Colors.muted, marginTop: Spacing.md },
  errorText:    { ...Typography.body, color: Colors.danger, textAlign: 'center', marginTop: Spacing.md },
  retryBtn:     { marginTop: Spacing.lg, backgroundColor: Colors.accent, paddingHorizontal: Spacing.lg, paddingVertical: Spacing.sm, borderRadius: Radius.md },
  retryText:    { ...Typography.body, color: '#fff', fontWeight: '700' },
  hero:         { backgroundColor: Colors.panel2, borderRadius: Radius.lg, padding: Spacing.lg, marginBottom: Spacing.lg, borderWidth: 1, borderColor: Colors.border },
  heroHeader:   { flexDirection: 'row', alignItems: 'center', gap: Spacing.md },
  heroCopy:     { flex: 1, minWidth: 0 },
  heroLogo:     { width: 84, height: 84, borderRadius: Radius.md, borderWidth: 1, borderColor: Colors.border },
  heroTitle:    { fontSize: 24, fontWeight: '800', color: Colors.text, marginBottom: 4 },
  heroSub:      { ...Typography.small, color: Colors.muted },
  heroTs:       { ...Typography.small, color: Colors.accent, marginTop: 4 },
  sectionHeader: { ...Typography.heading3, color: Colors.muted, marginBottom: Spacing.sm, marginTop: Spacing.lg, textTransform: 'uppercase', letterSpacing: 1 },
  statGrid:     { flexDirection: 'row', flexWrap: 'wrap', gap: Spacing.sm },
  statCard:     { flex: 1, minWidth: 140, backgroundColor: Colors.panel, borderRadius: Radius.md, padding: Spacing.md, borderWidth: 1, borderColor: Colors.border, alignItems: 'center' },
  statIcon:     { marginBottom: Spacing.xs },
  statValue:    { fontSize: 28, fontWeight: '800', marginBottom: 2 },
  statLabel:    { ...Typography.small, textAlign: 'center' },
  vectorPanel:  { backgroundColor: Colors.panel, borderRadius: Radius.md, padding: Spacing.md, borderWidth: 1, borderColor: Colors.border, gap: Spacing.sm },
  vectorRow:    { flexDirection: 'row', alignItems: 'center', gap: Spacing.sm },
  vectorLabel:  { ...Typography.body, flex: 1 },
  vectorValue:  { ...Typography.body, color: Colors.accent, fontWeight: '600' },
  progressBar:  { height: 6, backgroundColor: Colors.border, borderRadius: Radius.full, overflow: 'hidden' },
  progressFill: { height: '100%', backgroundColor: Colors.accent2, borderRadius: Radius.full },
  logPanel:     { backgroundColor: Colors.panel, borderRadius: Radius.md, borderWidth: 1, borderColor: Colors.border, overflow: 'hidden' },
  logRow:       { flexDirection: 'row', padding: Spacing.md, borderBottomWidth: 1, borderBottomColor: Colors.border, gap: Spacing.sm },
  logDot:       { width: 8, height: 8, borderRadius: 4, backgroundColor: Colors.accent, marginTop: 6 },
  logBody:      { flex: 1 },
  logType:      { ...Typography.small, color: Colors.accent, fontWeight: '700', textTransform: 'uppercase' },
  logMsg:       { ...Typography.body, marginTop: 2 },
  logTs:        { ...Typography.small, marginTop: 2 },
  emptyLog:     { flexDirection: 'row', alignItems: 'center', gap: Spacing.sm, padding: Spacing.md, backgroundColor: Colors.panel, borderRadius: Radius.md, borderWidth: 1, borderColor: Colors.border },
  emptyLogText: { ...Typography.small, flex: 1 },
});
