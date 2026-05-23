// lib/supabase.ts
// Supabase client — reads from environment variables injected at build time

import 'react-native-url-polyfill/auto';
import { createClient } from '@supabase/supabase-js';
import AsyncStorage from '@react-native-async-storage/async-storage';

const supabaseUrl  = process.env.EXPO_PUBLIC_SUPABASE_URL  ?? '';
const supabaseAnon = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY ?? '';

if (!supabaseUrl || !supabaseAnon) {
  console.warn('[Gorilla] Supabase env vars not set. Create gorilla-app/.env.local');
}

export const supabase = createClient(supabaseUrl, supabaseAnon, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});

// ─── Dashboard stats ───────────────────────────────────────────────────────
export async function fetchDashboardStats() {
  const { data, error } = await supabase
    .from('dashboard_stats')
    .select('*')
    .single();
  if (error) throw error;
  return data;
}

// ─── Apps ──────────────────────────────────────────────────────────────────
export async function fetchApps(opts?: {
  search?: string;
  category?: string;
  installedOnly?: boolean;
  openSourceOnly?: boolean;
  limit?: number;
  offset?: number;
}) {
  let query = supabase
    .from('apps')
    .select('id,name,category,status,installed,is_open_source,is_free,licence_mode,sign_in_mode,local_mode,icon_url,version,publisher')
    .order('name');

  if (opts?.installedOnly) query = query.eq('installed', true);
  if (opts?.openSourceOnly) query = query.eq('is_open_source', true);
  if (opts?.category)      query = query.eq('category', opts.category);
  if (opts?.search)        query = query.ilike('name', `%${opts.search}%`);
  if (opts?.limit)         query = query.limit(opts.limit);
  if (opts?.offset)        query = query.range(opts.offset!, (opts.offset! + (opts.limit ?? 50)) - 1);

  const { data, error } = await query;
  if (error) throw error;
  return data ?? [];
}

export async function fetchAppCategories(): Promise<string[]> {
  const { data, error } = await supabase
    .from('apps')
    .select('category')
    .order('category');
  if (error) throw error;
  const cats = [...new Set((data ?? []).map((r: any) => r.category).filter(Boolean))];
  return cats as string[];
}

// ─── Workflows ─────────────────────────────────────────────────────────────
export async function fetchWorkflows(opts?: {
  search?: string;
  combinationSize?: number;
  category?: string;
  riskLevel?: string;
  limit?: number;
  offset?: number;
}) {
  let query = supabase
    .from('workflows')
    .select('id,workflow_name,description,category,app_names,combination_size,difficulty,risk_level,automation_readiness,rank_score,sign_in_requirement')
    .order('rank_score', { ascending: false });

  if (opts?.combinationSize) query = query.eq('combination_size', opts.combinationSize);
  if (opts?.riskLevel)       query = query.eq('risk_level', opts.riskLevel);
  if (opts?.category)        query = query.eq('category', opts.category);
  if (opts?.search)          query = query.ilike('workflow_name', `%${opts.search}%`);
  if (opts?.limit)           query = query.limit(opts.limit);
  if (opts?.offset)          query = query.range(opts.offset!, (opts.offset! + (opts.limit ?? 50)) - 1);

  const { data, error } = await query;
  if (error) throw error;
  return data ?? [];
}

// ─── Vector / semantic search ───────────────────────────────────────────────
export async function semanticSearchApps(embedding: number[], matchCount = 20) {
  const { data, error } = await supabase
    .rpc('search_apps', { query_embedding: embedding, match_count: matchCount });
  if (error) throw error;
  return data ?? [];
}

export async function semanticSearchWorkflows(embedding: number[], matchCount = 20) {
  const { data, error } = await supabase
    .rpc('search_workflows', { query_embedding: embedding, match_count: matchCount });
  if (error) throw error;
  return data ?? [];
}

// ─── Audit log ─────────────────────────────────────────────────────────────
export async function fetchAuditLog(limit = 50) {
  const { data, error } = await supabase
    .from('audit_log')
    .select('*')
    .order('ts', { ascending: false })
    .limit(limit);
  if (error) throw error;
  return data ?? [];
}
