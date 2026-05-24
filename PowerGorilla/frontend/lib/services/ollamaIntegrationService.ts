// frontend/lib/services/ollamaIntegrationService.ts
// Ollama integration service for generating and validating integration commands
// Strict JSON-only command system for app discovery and integration

import { supabase } from '../supabase';

export interface OnlineAppCandidate {
  type: 'online_app_candidate';
  name: string;
  slug: string;
  category: string;
  official_url: string;
  launch_url: string;
  icon_strategy: string[];
  requires_login: boolean;
  requires_payment: boolean;
  free_tier_available: boolean;
  confidence: number;
  safe_to_integrate: boolean;
  needs_review: boolean;
  notes: string[];
}

export interface DesktopAppCandidate {
  type: 'desktop_app_candidate';
  name: string;
  slug: string;
  category: string;
  exe_path?: string;
  shortcut_path?: string;
  launch_command: string;
  icon_source: string;
  icon_cache_path?: string;
  publisher?: string;
  confidence: number;
  safe_to_launch: boolean;
  needs_review: boolean;
  notes: string[];
}

export interface IntegrationCommand {
  command_type: 'create_integration_recipe' | 'discover_apps' | 'scan_desktop';
  app_name?: string;
  app_type?: string;
  category?: string;
  actions?: any[];
  icon_required?: boolean;
  requires_backend_change: boolean;
  requires_review: boolean;
  safe_mode: boolean;
  validation_errors?: string[];
}

export interface OllamaResponse {
  response: string;
  valid_json: boolean;
  parsed_object?: any;
  confidence: number;
  error?: string;
}

const OLLAMA_BASE_URL = process.env.EXPO_PUBLIC_OLLAMA_URL || 'http://localhost:11434';
const OLLAMA_MODEL = process.env.EXPO_PUBLIC_OLLAMA_MODEL || 'llama2';
const DEFAULT_TIMEOUT = 30000; // 30 seconds

/**
 * Validates JSON command against IntegrationCommand schema
 */
function validateIntegrationCommand(obj: any): { valid: boolean; errors: string[] } {
  const errors: string[] = [];

  if (!obj.command_type) {
    errors.push('Missing required field: command_type');
  }
  if (!['create_integration_recipe', 'discover_apps', 'scan_desktop'].includes(obj.command_type)) {
    errors.push('Invalid command_type');
  }

  if (typeof obj.requires_backend_change !== 'boolean') {
    errors.push('Missing or invalid: requires_backend_change (boolean)');
  }
  if (typeof obj.requires_review !== 'boolean') {
    errors.push('Missing or invalid: requires_review (boolean)');
  }
  if (typeof obj.safe_mode !== 'boolean') {
    errors.push('Missing or invalid: safe_mode (boolean)');
  }

  // If it's a create_integration_recipe, validate additional fields
  if (obj.command_type === 'create_integration_recipe') {
    if (!obj.app_name || typeof obj.app_name !== 'string') {
      errors.push('create_integration_recipe requires app_name (string)');
    }
    if (!obj.app_type || !['online', 'desktop', 'hybrid'].includes(obj.app_type)) {
      errors.push('create_integration_recipe requires valid app_type');
    }
    if (!obj.category || typeof obj.category !== 'string') {
      errors.push('create_integration_recipe requires category (string)');
    }
    if (!Array.isArray(obj.actions)) {
      errors.push('create_integration_recipe requires actions (array)');
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

/**
 * Safely parses JSON response from Ollama
 */
function extractJSON(text: string): any | null {
  // Try to find JSON in the response
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) return null;

  try {
    return JSON.parse(jsonMatch[0]);
  } catch (error) {
    return null;
  }
}

/**
 * Makes a request to Ollama API
 */
async function callOllama(
  prompt: string,
  timeout = DEFAULT_TIMEOUT
): Promise<OllamaResponse> {
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);

    const response = await fetch(`${OLLAMA_BASE_URL}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: OLLAMA_MODEL,
        prompt,
        stream: false,
        temperature: 0.2,
        top_p: 0.9,
        num_predict: 1024,
      }),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      return {
        response: '',
        valid_json: false,
        confidence: 0,
        error: `Ollama API error: ${response.status}`,
      };
    }

    const data = await response.json();
    const responseText = data.response || '';

    // Extract JSON from response
    const parsedJson = extractJSON(responseText);

    return {
      response: responseText,
      valid_json: !!parsedJson,
      parsed_object: parsedJson,
      confidence: parsedJson ? 0.9 : 0,
      error: parsedJson ? undefined : 'Could not extract valid JSON',
    };
  } catch (error) {
    return {
      response: '',
      valid_json: false,
      confidence: 0,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

/**
 * Generates integration recipe for an app using Ollama
 */
export async function generateIntegrationRecipe(
  appName: string,
  appType: 'online' | 'desktop' | 'hybrid',
  category: string
): Promise<IntegrationCommand | null> {
  const prompt = `
You are an integration system for discovering and integrating apps. Return ONLY valid JSON, no other text.

Generate an integration recipe for this app:
- Name: ${appName}
- Type: ${appType}
- Category: ${category}

Return a JSON object with this exact structure (and ONLY this structure):
{
  "command_type": "create_integration_recipe",
  "app_name": "${appName}",
  "app_type": "${appType}",
  "category": "${category}",
  "actions": [
    {
      "id": "open",
      "label": "Open",
      "action_type": "open_url",
      "target": "https://example.com"
    },
    {
      "id": "search",
      "label": "Search",
      "action_type": "open_url_template",
      "target": "https://example.com/search/{query}"
    },
    {
      "id": "pin",
      "label": "Pin",
      "action_type": "update_preference",
      "target": "is_pinned"
    }
  ],
  "icon_required": true,
  "requires_backend_change": false,
  "requires_review": false,
  "safe_mode": true
}

IMPORTANT: Return ONLY the JSON object, nothing else.
  `;

  const result = await callOllama(prompt);

  if (!result.valid_json || !result.parsed_object) {
    console.error('[Ollama] Failed to generate recipe:', result.error);
    return null;
  }

  // Validate the command
  const validation = validateIntegrationCommand(result.parsed_object);
  if (!validation.valid) {
    console.error('[Ollama] Command validation failed:', validation.errors);
    return null;
  }

  return result.parsed_object as IntegrationCommand;
}

/**
 * Classifies apps into categories using Ollama
 */
export async function classifyApps(appNames: string[]): Promise<Record<string, string>> {
  const prompt = `
You are an app classification system. Return ONLY valid JSON, no other text.

Classify these apps into appropriate categories:
${appNames.map((name, i) => `${i + 1}. ${name}`).join('\n')}

Return a JSON object mapping app names to categories (ONLY):
{
  "${appNames[0]}": "Category Name",
  "${appNames[1]}": "Category Name"
}

IMPORTANT: Return ONLY the JSON object, nothing else.
  `;

  const result = await callOllama(prompt);

  if (!result.valid_json || !result.parsed_object) {
    console.error('[Ollama] Classification failed:', result.error);
    return {};
  }

  return result.parsed_object;
}

/**
 * Discovers online apps matching a query using Ollama
 */
export async function discoverOnlineApps(query: string): Promise<OnlineAppCandidate[]> {
  const prompt = `
You are an app discovery system. Return ONLY valid JSON array, no other text.

Find 5-10 popular online apps matching this query: "${query}"

For each app, return JSON objects with this exact structure:
[
  {
    "type": "online_app_candidate",
    "name": "App Name",
    "slug": "app-name",
    "category": "Category",
    "official_url": "https://official.site",
    "launch_url": "https://app.site",
    "icon_strategy": ["simple_icons", "iconify", "official_favicon", "tabler_fallback"],
    "requires_login": false,
    "requires_payment": false,
    "free_tier_available": true,
    "confidence": 0.95,
    "safe_to_integrate": true,
    "needs_review": false,
    "notes": []
  }
]

IMPORTANT: Return ONLY valid JSON array, nothing else.
  `;

  const result = await callOllama(prompt);

  if (!result.valid_json || !Array.isArray(result.parsed_object)) {
    console.error('[Ollama] Discovery failed:', result.error);
    return [];
  }

  return result.parsed_object.filter(
    (app) => app.type === 'online_app_candidate' && app.name && app.slug
  );
}

/**
 * Plans desktop app discovery scan using Ollama
 */
export async function planDesktopScan(
  installationPaths: string[]
): Promise<{ safe: boolean; scan_paths: string[]; notes: string[] }> {
  const prompt = `
You are a desktop app scanner safety validator. Return ONLY valid JSON, no other text.

Review these potential scan paths for safety:
${installationPaths.slice(0, 10).join('\n')}

Return a JSON object with this structure:
{
  "safe": true,
  "scan_paths": ["path1", "path2"],
  "notes": ["Any safety concerns or notes"]
}

Consider security, privacy, and performance impacts.

IMPORTANT: Return ONLY the JSON object, nothing else.
  `;

  const result = await callOllama(prompt);

  if (!result.valid_json || !result.parsed_object) {
    return {
      safe: false,
      scan_paths: [],
      notes: ['Failed to validate scan paths'],
    };
  }

  return result.parsed_object;
}

/**
 * Validates that a command is safe before execution
 */
export function validateCommandSafety(command: IntegrationCommand): {
  safe: boolean;
  warnings: string[];
} {
  const warnings: string[] = [];

  if (command.requires_backend_change) {
    warnings.push('This command requires backend changes');
  }

  if (command.requires_review) {
    warnings.push('This command requires manual review');
  }

  if (!command.safe_mode) {
    warnings.push('This command is not in safe mode');
  }

  // Validate all actions for safety
  if (command.actions && Array.isArray(command.actions)) {
    command.actions.forEach((action, index) => {
      if (!action.action_type) {
        warnings.push(`Action ${index}: missing action_type`);
      }
      if (action.action_type === 'open_app' && !action.target) {
        warnings.push(`Action ${index}: open_app requires target`);
      }
    });
  }

  const safe = warnings.length === 0;
  return { safe, warnings };
}

/**
 * Stores validation results in Supabase audit log
 */
export async function logCommandValidation(
  userId: string,
  command: IntegrationCommand,
  isValid: boolean,
  errors?: string[]
): Promise<void> {
  try {
    await supabase.from('audit_log').insert({
      type: 'ollama_command_validation',
      message: `Command validation: ${command.command_type}`,
      actor: 'ollama-integration-service',
      data: {
        user_id: userId,
        command_type: command.command_type,
        is_valid: isValid,
        errors: errors || [],
        timestamp: new Date().toISOString(),
      },
    });
  } catch (error) {
    console.error('Failed to log command validation:', error);
  }
}
