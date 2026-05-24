// lib/supabase.ts
// Supabase client - reads from environment variables injected at build time.
// Public reads are cached on the web so the UI stays fast on free-tier limits.

import 'react-native-url-polyfill/auto';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl  = process.env.EXPO_PUBLIC_SUPABASE_URL  ?? '';
const supabaseAnon = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY ?? '';

if (!supabaseUrl || !supabaseAnon) {
  console.warn('[Gorilla] Supabase env vars not set. Create PowerGorilla/frontend/.env.local');
}

export const supabase = createClient(supabaseUrl, supabaseAnon, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
    detectSessionInUrl: false,
  },
  global: {
    headers: { 'X-Client-Info': 'phat-gorrilla-frontend' },
  },
});

type SupabaseResult<T> = {
  data: T | null;
  error: any;
};

type CacheEntry<T> = {
  savedAt: number;
  value: T;
};

const QUERY_TIMEOUT_MS = 8000;
const STALE_FALLBACK_MS = 24 * 60 * 60 * 1000;
const DASHBOARD_TTL_MS = 60 * 1000;
const LIST_TTL_MS = 30 * 1000;
const CATEGORY_TTL_MS = 10 * 60 * 1000;
const AUDIT_TTL_MS = 20 * 1000;
const CACHE_PREFIX = 'phat-gorrilla:supabase:';

const memoryCache = new Map<string, CacheEntry<unknown>>();

function canUseLocalStorage() {
  return typeof window !== 'undefined' && typeof window.localStorage !== 'undefined';
}

function readCache<T>(key: string, maxAgeMs: number): T | undefined {
  const entry = memoryCache.get(key) as CacheEntry<T> | undefined;
  if (entry && Date.now() - entry.savedAt <= maxAgeMs) return entry.value;

  if (!canUseLocalStorage()) return undefined;

  try {
    const raw = window.localStorage.getItem(key);
    if (!raw) return undefined;
    const parsed = JSON.parse(raw) as CacheEntry<T>;
    if (Date.now() - parsed.savedAt > maxAgeMs) return undefined;
    memoryCache.set(key, parsed);
    return parsed.value;
  } catch {
    return undefined;
  }
}

function writeCache<T>(key: string, value: T) {
  const entry: CacheEntry<T> = { savedAt: Date.now(), value };
  memoryCache.set(key, entry);

  if (!canUseLocalStorage()) return;

  try {
    window.localStorage.setItem(key, JSON.stringify(entry));
  } catch {
    // Storage can be unavailable in private windows; in-memory cache still works.
  }
}

function cacheKey(name: string, opts?: Record<string, unknown>) {
  const filtered = Object.fromEntries(
    Object.entries(opts ?? {}).filter(([, value]) => value !== undefined && value !== ''),
  );
  return `${CACHE_PREFIX}${name}:${JSON.stringify(filtered)}`;
}

async function runSupabase<T>(
  label: string,
  query: PromiseLike<unknown>,
  timeoutMs = QUERY_TIMEOUT_MS,
): Promise<T | null> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  const timeout = new Promise<never>((_, reject) => {
    timer = setTimeout(() => reject(new Error(`${label} timed out after ${timeoutMs / 1000}s`)), timeoutMs);
  });

  try {
    const response = await Promise.race([Promise.resolve(query), timeout]) as SupabaseResult<T>;
    if (response.error) throw response.error;
    return response.data;
  } finally {
    if (timer) clearTimeout(timer);
  }
}

async function cachedQuery<T>(
  key: string,
  ttlMs: number,
  fetcher: () => Promise<T>,
  force = false,
): Promise<T> {
  if (!force) {
    const cached = readCache<T>(key, ttlMs);
    if (cached !== undefined) return cached;
  }

  try {
    const fresh = await fetcher();
    writeCache(key, fresh);
    return fresh;
  } catch (error) {
    const stale = readCache<T>(key, STALE_FALLBACK_MS);
    if (stale !== undefined) return stale;
    throw error;
  }
}

// Dashboard stats
export async function fetchDashboardStats(opts?: { force?: boolean }) {
  const key = cacheKey('dashboard-stats');
  return cachedQuery(
    key,
    DASHBOARD_TTL_MS,
    async () => {
      const data = await runSupabase<any>(
        'Dashboard stats',
        supabase
          .from('dashboard_stats')
          .select('*')
          .single(),
      );
      return data;
    },
    opts?.force,
  );
}

// Apps
export async function fetchApps(opts?: {
  search?: string;
  category?: string;
  installedOnly?: boolean;
  openSourceOnly?: boolean;
  limit?: number;
  offset?: number;
  force?: boolean;
}) {
  const limit = opts?.limit ?? 50;
  const offset = opts?.offset ?? 0;
  const key = cacheKey('apps', {
    search: opts?.search,
    category: opts?.category,
    installedOnly: opts?.installedOnly,
    openSourceOnly: opts?.openSourceOnly,
    limit,
    offset,
  });

  return cachedQuery(
    key,
    LIST_TTL_MS,
    async () => {
      let query = supabase
        .from('apps')
        .select('id,name,category,status,installed,is_open_source,is_free,licence_mode,sign_in_mode,local_mode,icon_url,version,publisher')
        .eq('cost_allowed', true)
        .neq('licence_mode', 'Paid or trial')
        .order('name')
        .range(offset, offset + limit - 1);

      if (opts?.installedOnly) query = query.eq('installed', true);
      if (opts?.openSourceOnly) query = query.eq('is_open_source', true);
      if (opts?.category)      query = query.eq('category', opts.category);
      if (opts?.search)        query = query.ilike('name', `%${opts.search}%`);

      const data = await runSupabase<any[]>('Apps', query);
      return data ?? [];
    },
    opts?.force,
  );
}

export async function fetchAppCategories(opts?: { force?: boolean }): Promise<string[]> {
  const key = cacheKey('app-categories');
  return cachedQuery(
    key,
    CATEGORY_TTL_MS,
    async () => {
      try {
        const viewData = await runSupabase<any[]>(
          'App categories',
          supabase
            .from('app_categories')
            .select('category')
            .order('category'),
        );
        return (viewData ?? []).map((r: any) => r.category).filter(Boolean);
      } catch {
        const data = await runSupabase<any[]>(
          'App category fallback',
          supabase
            .from('apps')
            .select('category')
            .eq('cost_allowed', true)
            .order('category')
            .limit(2000),
        );
        return [...new Set((data ?? []).map((r: any) => r.category).filter(Boolean))] as string[];
      }
    },
    opts?.force,
  );
}

// Workflows
export async function fetchWorkflows(opts?: {
  search?: string;
  combinationSize?: number;
  category?: string;
  riskLevel?: string;
  limit?: number;
  offset?: number;
  force?: boolean;
}) {
  const limit = opts?.limit ?? 60;
  const offset = opts?.offset ?? 0;
  const key = cacheKey('workflows', {
    search: opts?.search,
    combinationSize: opts?.combinationSize,
    category: opts?.category,
    riskLevel: opts?.riskLevel,
    limit,
    offset,
  });

  return cachedQuery(
    key,
    LIST_TTL_MS,
    async () => {
      let query = supabase
        .from('workflows')
        .select('id,workflow_name,description,category,app_names,combination_size,difficulty,risk_level,automation_readiness,rank_score,sign_in_requirement')
        .eq('cost_allowed', true)
        .order('rank_score', { ascending: false })
        .range(offset, offset + limit - 1);

      if (opts?.combinationSize) query = query.eq('combination_size', opts.combinationSize);
      if (opts?.riskLevel)       query = query.eq('risk_level', opts.riskLevel);
      if (opts?.category)        query = query.eq('category', opts.category);
      if (opts?.search)          query = query.ilike('workflow_name', `%${opts.search}%`);

      const data = await runSupabase<any[]>('Workflows', query);
      return data ?? [];
    },
    opts?.force,
  );
}

// Vector / semantic search
export async function semanticSearchApps(embedding: number[], matchCount = 20) {
  const data = await runSupabase<any[]>(
    'Semantic app search',
    supabase.rpc('search_apps', { query_embedding: embedding, match_count: matchCount }),
  );
  return data ?? [];
}

export async function semanticSearchWorkflows(embedding: number[], matchCount = 20) {
  const data = await runSupabase<any[]>(
    'Semantic workflow search',
    supabase.rpc('search_workflows', { query_embedding: embedding, match_count: matchCount }),
  );
  return data ?? [];
}

// Audit log
export async function fetchAuditLog(limit = 50, opts?: { force?: boolean }) {
  const key = cacheKey('audit-log', { limit });
  return cachedQuery(
    key,
    AUDIT_TTL_MS,
    async () => {
      const data = await runSupabase<any[]>(
        'Audit log',
        supabase
          .from('audit_log')
          .select('id,ts,type,message,actor,data')
          .order('ts', { ascending: false })
          .limit(limit),
      );
      return data ?? [];
    },
    opts?.force,
  );
}
