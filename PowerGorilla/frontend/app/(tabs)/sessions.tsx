// app/(tabs)/sessions.tsx — Session / Audit Log screen

import React, { useEffect, useState } from 'react';
import {
  View, Text, FlatList, StyleSheet,
  ActivityIndicator, RefreshControl, TouchableOpacity,
} from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { fetchAuditLog } from '../../lib/supabase';
import { Colors, Typography, Spacing, Radius } from '../../lib/theme';

const TYPE_ICON: Record<string, any> = {
  push:       'cloud-upload',
  embed:      'memory',
  extract:    'psychology',
  inventory:  'inventory-2',
  profile:    'person',
  session:    'schedule',
  error:      'error-outline',
};

const TYPE_COLOR: Record<string, string> = {
  push:      Colors.ok,
  embed:     Colors.accent2,
  extract:   Colors.accent,
  inventory: Colors.warn,
  profile:   Colors.accent,
  session:   Colors.muted,
  error:     Colors.danger,
};

function LogCard({ item }: { item: any }) {
  const [expanded, setExpanded] = useState(false);
  const type  = (item.type ?? '').toLowerCase();
  const icon  = TYPE_ICON[type] ?? 'info-outline';
  const color = TYPE_COLOR[type] ?? Colors.muted;

  return (
    <TouchableOpacity style={styles.card} onPress={() => setExpanded(!expanded)} activeOpacity={0.85}>
      <View style={styles.cardRow}>
        <View style={[styles.iconBox, { borderColor: color }]}>
          <MaterialIcons name={icon} size={18} color={color} />
        </View>
        <View style={styles.cardBody}>
          <View style={styles.cardHeader}>
            <Text style={[styles.typeLabel, { color }]}>{item.type}</Text>
            <Text style={styles.ts}>{new Date(item.ts).toLocaleString()}</Text>
          </View>
          <Text style={styles.message} numberOfLines={expanded ? undefined : 2}>{item.message}</Text>
          {item.actor && item.actor !== 'powershell-gorilla' && (
            <Text style={styles.actor}>via {item.actor}</Text>
          )}
        </View>
      </View>
      {expanded && item.data && (
        <View style={styles.dataBox}>
          <Text style={styles.dataText}>
            {typeof item.data === 'string' ? item.data : JSON.stringify(item.data, null, 2)}
          </Text>
        </View>
      )}
    </TouchableOpacity>
  );
}

export default function SessionsScreen() {
  const [log, setLog]           = useState<any[]>([]);
  const [loading, setLoading]   = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  async function load(force = false) {
    try {
      const data = await fetchAuditLog(100, { force });
      setLog(data);
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
        <Text style={styles.loadingText}>Loading session log...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {/* Header summary */}
      <View style={styles.summary}>
        <MaterialIcons name="history" size={18} color={Colors.accent} />
        <Text style={styles.summaryText}>{log.length} recent events — tap any row for details</Text>
      </View>

      {log.length === 0 ? (
        <View style={styles.center}>
          <MaterialIcons name="inbox" size={48} color={Colors.muted} />
          <Text style={styles.emptyText}>No session events yet</Text>
          <Text style={styles.emptyHint}>
            Events are written here when you run gorpush, gorextract, or gorembed from PowerShell
          </Text>
        </View>
      ) : (
        <FlatList
          data={log}
          keyExtractor={item => String(item.id)}
          renderItem={({ item }) => <LogCard item={item} />}
          contentContainerStyle={styles.list}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={() => { setRefreshing(true); load(true); }}
              tintColor={Colors.accent}
            />
          }
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container:   { flex: 1, backgroundColor: Colors.bg },
  summary:     { flexDirection: 'row', alignItems: 'center', gap: Spacing.sm, padding: Spacing.md, paddingBottom: Spacing.sm },
  summaryText: { ...Typography.small },
  list:        { padding: Spacing.md, gap: Spacing.sm, paddingBottom: Spacing.xxl },
  card:        { backgroundColor: Colors.panel, borderRadius: Radius.md, padding: Spacing.md, borderWidth: 1, borderColor: Colors.border },
  cardRow:     { flexDirection: 'row', gap: Spacing.sm },
  iconBox:     { width: 36, height: 36, borderRadius: Radius.sm, borderWidth: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: Colors.panel2, flexShrink: 0 },
  cardBody:    { flex: 1 },
  cardHeader:  { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 2 },
  typeLabel:   { fontSize: 11, fontWeight: '800', textTransform: 'uppercase', letterSpacing: 0.5 },
  ts:          { ...Typography.small },
  message:     { ...Typography.body, color: Colors.text },
  actor:       { ...Typography.small, marginTop: 2 },
  dataBox:     { marginTop: Spacing.sm, backgroundColor: Colors.bg, borderRadius: Radius.sm, padding: Spacing.sm, borderWidth: 1, borderColor: Colors.border },
  dataText:    { ...Typography.mono, fontSize: 11 },
  center:      { flex: 1, alignItems: 'center', justifyContent: 'center', padding: Spacing.xl, backgroundColor: Colors.bg },
  loadingText: { ...Typography.body, color: Colors.muted, marginTop: Spacing.md },
  emptyText:   { ...Typography.heading3, color: Colors.muted, marginTop: Spacing.md },
  emptyHint:   { ...Typography.small, textAlign: 'center', marginTop: Spacing.sm, maxWidth: 300 },
});
