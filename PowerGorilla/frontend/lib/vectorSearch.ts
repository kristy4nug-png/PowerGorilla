// lib/vectorSearch.ts
// Client-side vector search — calls Ollama locally to generate embeddings,
// then queries Supabase pgvector via RPC.
// NOTE: Ollama must be running locally at http://localhost:11434

import { semanticSearchApps, semanticSearchWorkflows } from './supabase';

const OLLAMA_URL   = 'http://localhost:11434';
const EMBED_MODEL  = 'nomic-embed-text';

export async function getEmbedding(text: string): Promise<number[]> {
  const response = await fetch(`${OLLAMA_URL}/api/embed`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ model: EMBED_MODEL, input: text }),
  });
  if (!response.ok) throw new Error(`Ollama embed failed: ${response.status}`);
  const data = await response.json();
  return data.embeddings[0] as number[];
}

export async function vectorSearchApps(query: string, limit = 20) {
  const embedding = await getEmbedding(query);
  return semanticSearchApps(embedding, limit);
}

export async function vectorSearchWorkflows(query: string, limit = 20) {
  const embedding = await getEmbedding(query);
  return semanticSearchWorkflows(embedding, limit);
}

export async function vectorSearchBoth(query: string, limit = 10) {
  const embedding = await getEmbedding(query);
  const [apps, workflows] = await Promise.all([
    semanticSearchApps(embedding, limit),
    semanticSearchWorkflows(embedding, limit),
  ]);
  return { apps, workflows };
}

export async function isOllamaAvailable(): Promise<boolean> {
  try {
    const r = await fetch(`${OLLAMA_URL}/api/tags`, { signal: AbortSignal.timeout(2000) });
    return r.ok;
  } catch {
    return false;
  }
}
