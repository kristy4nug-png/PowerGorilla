// app/(tabs)/search.tsx — Semantic Vector Search screen

import React, { useState } from 'react';
import {
  View, Text, StyleSheet, TextInput, TouchableOpacity,
  ScrollView, ActivityIndicator,
} from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { vectorSearchBoth, isOllamaAvailable } from '../../lib/vectorSearch';
import { Colors, Typography, Spacing, Radius } from '../../lib/theme';

function ResultCard({ item, type }: { item: any; type: 'app' | 'workflow' }) {
  const sim = Math.round((item.similarity ?? 0) * 100);
  const simColor = sim > 80 ? Colors.ok : sim > 60 ? Colors.warn : Colors.muted;
  return (
    <View style={styles.card}>
      <View style={styles.cardTop}>
        <MaterialIcons
          name={type === 'app' ? 'apps' : 'account-tree'}
          size={16} color={Colors.accent}
          style={{ marginRight: Spacing.sm }}
        />
        <Text style={styles.cardTitle} numberOfLines={1}>
          {type === 'app' ? item.name : item.workflow_name}
        </Text>
        <View style={[styles.simBadge, { borderColor: simColor }]}>
          <Text style={[styles.simText, { color: simColor }]}>{sim}%</Text>
        </View>
      </View>
      {type === 'app' && (
        <View style={styles.metaRow}>
          <Text style={styles.meta}>{item.category}</Text>
          {item.status && (
            <Text style={[styles.status, { color: item.status === 'Installed' ? Colors.ok : Colors.warn }]}>
              {item.status}
            </Text>
          )}
        </View>
      )}
      {type === 'workflow' && item.description && (
        <Text style={styles.desc} numberOfLines={2}>{item.description}</Text>
      )}
      {type === 'workflow' && item.app_names && (
        <Text style={styles.meta}>{(item.app_names as string[]).join(' + ')}</Text>
      )}
      {/* Similarity bar */}
      <View style={styles.simBarBg}>
        <View style={[styles.simBarFill, { width: `${sim}%`, backgroundColor: simColor }]} />
      </View>
    </View>
  );
}

export default function SearchScreen() {
  const [query, setQuery]         = useState('');
  const [results, setResults]     = useState<{ apps: any[]; workflows: any[] } | null>(null);
  const [loading, setLoading]     = useState(false);
  const [error, setError]         = useState<string | null>(null);
  const [ollamaOk, setOllamaOk]  = useState<boolean | null>(null);

  React.useEffect(() => {
    isOllamaAvailable().then(setOllamaOk);
  }, []);

  async function search() {
    if (!query.trim()) return;
    setLoading(true);
    setError(null);
    try {
      const data = await vectorSearchBoth(query.trim(), 10);
      setResults(data);
    } catch (e: any) {
      setError(e.message ?? 'Search failed');
    } finally {
      setLoading(false);
    }
  }

  const totalResults = (results?.apps.length ?? 0) + (results?.workflows.length ?? 0);

  return (
    <View style={styles.container}>
      {/* Ollama status */}
      <View style={[styles.statusBar, { borderColor: ollamaOk === true ? Colors.ok : ollamaOk === false ? Colors.danger : Colors.border }]}>
        <MaterialIcons
          name={ollamaOk === true ? 'check-circle' : ollamaOk === false ? 'error' : 'hourglass-empty'}
          size={14}
          color={ollamaOk === true ? Colors.ok : ollamaOk === false ? Colors.danger : Colors.muted}
        />
        <Text style={[styles.statusText, { color: ollamaOk === true ? Colors.ok : ollamaOk === false ? Colors.danger : Colors.muted }]}>
          {ollamaOk === true ? 'Ollama running — semantic search ready'
           : ollamaOk === false ? 'Ollama not detected — start Ollama locally for semantic search'
           : 'Checking Ollama...'}
        </Text>
      </View>

      {/* Search input */}
      <View style={styles.searchBox}>
        <TextInput
          style={styles.input}
          placeholder="Describe what you need… e.g. video editing automation"
          placeholderTextColor={Colors.muted}
          value={query}
          onChangeText={setQuery}
          onSubmitEditing={search}
          returnKeyType="search"
          multiline={false}
        />
        <TouchableOpacity
          style={[styles.searchBtn, (!query.trim() || loading) && styles.searchBtnDisabled]}
          onPress={search}
          disabled={!query.trim() || loading}
        >
          {loading
            ? <ActivityIndicator size="small" color="#fff" />
            : <MaterialIcons name="search" size={22} color="#fff" />}
        </TouchableOpacity>
      </View>

      <Text style={styles.hint}>
        Uses Ollama (nomic-embed-text) + pgvector cosine similarity to find the most relevant apps and workflows
      </Text>

      {/* Error */}
      {error && (
        <View style={styles.errorBox}>
          <MaterialIcons name="error-outline" size={18} color={Colors.danger} />
          <Text style={styles.errorText}>{error}</Text>
        </View>
      )}

      {/* Results */}
      {results && (
        <ScrollView style={styles.resultsScroll} contentContainerStyle={styles.resultsList}>
          <Text style={styles.resultCount}>{totalResults} results for "{query}"</Text>

          {results.apps.length > 0 && (
            <>
              <Text style={styles.sectionLabel}>Apps</Text>
              {results.apps.map(item => (
                <ResultCard key={item.id} item={item} type="app" />
              ))}
            </>
          )}

          {results.workflows.length > 0 && (
            <>
              <Text style={styles.sectionLabel}>Workflows</Text>
              {results.workflows.map(item => (
                <ResultCard key={item.id} item={item} type="workflow" />
              ))}
            </>
          )}

          {totalResults === 0 && (
            <View style={styles.empty}>
              <MaterialIcons name="search-off" size={40} color={Colors.muted} />
              <Text style={styles.emptyText}>No results found. Try different keywords.</Text>
            </View>
          )}
        </ScrollView>
      )}

      {!results && !loading && (
        <View style={styles.placeholder}>
          <MaterialIcons name="psychology" size={56} color={Colors.accent2} />
          <Text style={styles.placeholderTitle}>Semantic Search</Text>
          <Text style={styles.placeholderSub}>
            Search using natural language. Powered by Ollama embeddings and Supabase pgvector.
          </Text>
          <View style={styles.exampleBox}>
            {['video editing with subtitles', 'automate code deployments', 'secure local file storage', 'creative design workflow'].map(ex => (
              <TouchableOpacity key={ex} style={styles.exampleChip} onPress={() => setQuery(ex)}>
                <Text style={styles.exampleText}>{ex}</Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container:         { flex: 1, backgroundColor: Colors.bg },
  statusBar:         { flexDirection: 'row', alignItems: 'center', gap: Spacing.xs, margin: Spacing.md, marginBottom: Spacing.sm, padding: Spacing.sm, borderRadius: Radius.md, borderWidth: 1, backgroundColor: Colors.panel },
  statusText:        { ...Typography.small },
  searchBox:         { flexDirection: 'row', margin: Spacing.md, marginTop: 0, gap: Spacing.sm },
  input:             { flex: 1, backgroundColor: Colors.panel, borderRadius: Radius.md, paddingHorizontal: Spacing.md, paddingVertical: 12, color: Colors.text, fontSize: 15, borderWidth: 1, borderColor: Colors.border },
  searchBtn:         { backgroundColor: Colors.accent, borderRadius: Radius.md, paddingHorizontal: Spacing.md, justifyContent: 'center', alignItems: 'center', minWidth: 50 },
  searchBtnDisabled: { opacity: 0.4 },
  hint:              { ...Typography.small, paddingHorizontal: Spacing.md, marginBottom: Spacing.sm },
  errorBox:          { flexDirection: 'row', alignItems: 'center', gap: Spacing.sm, margin: Spacing.md, padding: Spacing.md, backgroundColor: Colors.danger + '18', borderRadius: Radius.md, borderWidth: 1, borderColor: Colors.danger },
  errorText:         { ...Typography.body, color: Colors.danger, flex: 1 },
  resultsScroll:     { flex: 1 },
  resultsList:       { padding: Spacing.md, gap: Spacing.sm, paddingBottom: Spacing.xxl },
  resultCount:       { ...Typography.small, marginBottom: Spacing.sm },
  sectionLabel:      { ...Typography.heading3, color: Colors.muted, textTransform: 'uppercase', letterSpacing: 1, marginTop: Spacing.sm, marginBottom: Spacing.xs },
  card:              { backgroundColor: Colors.panel, borderRadius: Radius.md, padding: Spacing.md, borderWidth: 1, borderColor: Colors.border },
  cardTop:           { flexDirection: 'row', alignItems: 'center', marginBottom: 4 },
  cardTitle:         { ...Typography.heading3, flex: 1 },
  simBadge:          { borderWidth: 1, borderRadius: Radius.full, paddingHorizontal: 7, paddingVertical: 2 },
  simText:           { fontSize: 11, fontWeight: '700' },
  metaRow:           { flexDirection: 'row', gap: Spacing.sm },
  meta:              { ...Typography.small },
  status:            { ...Typography.small, fontWeight: '600' },
  desc:              { ...Typography.body, color: Colors.muted, marginTop: 2 },
  simBarBg:          { height: 3, backgroundColor: Colors.border, borderRadius: Radius.full, marginTop: Spacing.sm, overflow: 'hidden' },
  simBarFill:        { height: '100%', borderRadius: Radius.full },
  empty:             { alignItems: 'center', padding: Spacing.xl },
  emptyText:         { ...Typography.body, color: Colors.muted, textAlign: 'center', marginTop: Spacing.sm },
  placeholder:       { flex: 1, alignItems: 'center', justifyContent: 'center', padding: Spacing.xl },
  placeholderTitle:  { ...Typography.heading2, marginTop: Spacing.md },
  placeholderSub:    { ...Typography.body, color: Colors.muted, textAlign: 'center', marginTop: Spacing.sm, maxWidth: 360 },
  exampleBox:        { flexDirection: 'row', flexWrap: 'wrap', gap: Spacing.sm, marginTop: Spacing.lg, justifyContent: 'center' },
  exampleChip:       { backgroundColor: Colors.panel2, borderRadius: Radius.full, paddingHorizontal: Spacing.md, paddingVertical: Spacing.sm, borderWidth: 1, borderColor: Colors.border },
  exampleText:       { ...Typography.small, color: Colors.accent },
});
