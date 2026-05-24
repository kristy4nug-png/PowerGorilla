// frontend/lib/services/demoModeService.ts
// Demo mode support - works without authentication
// Perfect for GitHub free users to explore features

import { supabase } from '../supabase';

export interface DemoIntegrationApp {
  id: string;
  name: string;
  slug: string;
  app_type: 'online' | 'desktop' | 'hybrid';
  category: string;
  official_url?: string;
  launch_url?: string;
  icon_id?: string;
  confidence: number;
  safe_to_launch: boolean;
  is_pinned: boolean;
  is_hidden: boolean;
}

export interface DemoSession {
  sessionId: string;
  createdAt: string;
  expiresAt: string;
  isAuthenticated: boolean;
  apps: DemoIntegrationApp[];
}

const DEMO_APPS: DemoIntegrationApp[] = [
  {
    id: 'demo-spotify',
    name: 'Spotify',
    slug: 'spotify',
    app_type: 'online',
    category: 'Music',
    official_url: 'https://www.spotify.com',
    launch_url: 'https://open.spotify.com',
    confidence: 0.95,
    safe_to_launch: true,
    is_pinned: true,
    is_hidden: false,
  },
  {
    id: 'demo-youtube',
    name: 'YouTube',
    slug: 'youtube',
    app_type: 'online',
    category: 'Video',
    official_url: 'https://www.youtube.com',
    launch_url: 'https://www.youtube.com',
    confidence: 0.95,
    safe_to_launch: true,
    is_pinned: true,
    is_hidden: false,
  },
  {
    id: 'demo-vscode',
    name: 'Visual Studio Code',
    slug: 'vscode',
    app_type: 'desktop',
    category: 'Development',
    confidence: 0.90,
    safe_to_launch: true,
    is_pinned: false,
    is_hidden: false,
  },
  {
    id: 'demo-figma',
    name: 'Figma',
    slug: 'figma',
    app_type: 'online',
    category: 'Design',
    official_url: 'https://www.figma.com',
    launch_url: 'https://www.figma.com',
    confidence: 0.92,
    safe_to_launch: true,
    is_pinned: false,
    is_hidden: false,
  },
  {
    id: 'demo-notion',
    name: 'Notion',
    slug: 'notion',
    app_type: 'online',
    category: 'Productivity',
    official_url: 'https://www.notion.so',
    launch_url: 'https://www.notion.so',
    confidence: 0.93,
    safe_to_launch: true,
    is_pinned: false,
    is_hidden: false,
  },
  {
    id: 'demo-discord',
    name: 'Discord',
    slug: 'discord',
    app_type: 'hybrid',
    category: 'Communication',
    official_url: 'https://discord.com',
    launch_url: 'https://discord.com/app',
    confidence: 0.94,
    safe_to_launch: true,
    is_pinned: false,
    is_hidden: false,
  },
];

const DEMO_SESSION_DURATION = 24 * 60 * 60 * 1000; // 24 hours
const DEMO_SESSION_KEY = 'powergorrilla_demo_session';

/**
 * Initialize demo mode session in local storage
 */
export function initializeDemoSession(): DemoSession {
  const now = new Date();
  const expiresAt = new Date(now.getTime() + DEMO_SESSION_DURATION);

  const session: DemoSession = {
    sessionId: `demo-${Date.now()}`,
    createdAt: now.toISOString(),
    expiresAt: expiresAt.toISOString(),
    isAuthenticated: false,
    apps: [...DEMO_APPS],
  };

  try {
    if (typeof window !== 'undefined' && window.localStorage) {
      localStorage.setItem(DEMO_SESSION_KEY, JSON.stringify(session));
    }
  } catch (error) {
    console.warn('Could not save demo session to localStorage:', error);
  }

  return session;
}

/**
 * Get current demo session, or create new one if expired
 */
export function getDemoSession(): DemoSession | null {
  try {
    if (typeof window === 'undefined' || !window.localStorage) {
      return initializeDemoSession();
    }

    const stored = localStorage.getItem(DEMO_SESSION_KEY);
    if (!stored) {
      return initializeDemoSession();
    }

    const session = JSON.parse(stored) as DemoSession;
    const expiresAt = new Date(session.expiresAt);
    const now = new Date();

    // Check if session expired
    if (now > expiresAt) {
      return initializeDemoSession();
    }

    return session;
  } catch (error) {
    console.error('Error loading demo session:', error);
    return initializeDemoSession();
  }
}

/**
 * Get demo apps for current session
 */
export function getDemoApps(): DemoIntegrationApp[] {
  const session = getDemoSession();
  return session?.apps || DEMO_APPS;
}

/**
 * Add app to demo session
 */
export function addDemoApp(
  app: Omit<DemoIntegrationApp, 'id'>
): DemoIntegrationApp {
  const session = getDemoSession();
  if (!session) return app as DemoIntegrationApp;

  const newApp: DemoIntegrationApp = {
    ...app,
    id: `demo-${Date.now()}`,
  };

  session.apps.push(newApp);

  try {
    if (typeof window !== 'undefined' && window.localStorage) {
      localStorage.setItem(DEMO_SESSION_KEY, JSON.stringify(session));
    }
  } catch (error) {
    console.warn('Could not save to demo session:', error);
  }

  return newApp;
}

/**
 * Update demo app
 */
export function updateDemoApp(appId: string, updates: Partial<DemoIntegrationApp>): boolean {
  const session = getDemoSession();
  if (!session) return false;

  const index = session.apps.findIndex((app) => app.id === appId);
  if (index === -1) return false;

  session.apps[index] = { ...session.apps[index], ...updates };

  try {
    if (typeof window !== 'undefined' && window.localStorage) {
      localStorage.setItem(DEMO_SESSION_KEY, JSON.stringify(session));
    }
  } catch (error) {
    console.warn('Could not update demo session:', error);
  }

  return true;
}

/**
 * Remove demo app
 */
export function removeDemoApp(appId: string): boolean {
  const session = getDemoSession();
  if (!session) return false;

  const initialLength = session.apps.length;
  session.apps = session.apps.filter((app) => app.id !== appId);

  const removed = session.apps.length < initialLength;

  if (removed) {
    try {
      if (typeof window !== 'undefined' && window.localStorage) {
        localStorage.setItem(DEMO_SESSION_KEY, JSON.stringify(session));
      }
    } catch (error) {
      console.warn('Could not update demo session:', error);
    }
  }

  return removed;
}

/**
 * Toggle pin status for demo app
 */
export function toggleDemoPinStatus(appId: string): boolean {
  const session = getDemoSession();
  if (!session) return false;

  const app = session.apps.find((a) => a.id === appId);
  if (!app) return false;

  app.is_pinned = !app.is_pinned;

  try {
    if (typeof window !== 'undefined' && window.localStorage) {
      localStorage.setItem(DEMO_SESSION_KEY, JSON.stringify(session));
    }
  } catch (error) {
    console.warn('Could not update demo session:', error);
  }

  return true;
}

/**
 * Check if user is in demo mode or authenticated
 */
export async function checkAuthMode(): Promise<'authenticated' | 'demo'> {
  try {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    return user ? 'authenticated' : 'demo';
  } catch (error) {
    return 'demo';
  }
}

/**
 * Get demo mode badge/label for UI
 */
export function getDemoModeLabel(): string {
  const session = getDemoSession();
  if (!session) return 'Demo Mode';

  const expiresAt = new Date(session.expiresAt);
  const now = new Date();
  const hoursLeft = Math.floor(
    (expiresAt.getTime() - now.getTime()) / (60 * 60 * 1000)
  );

  if (hoursLeft <= 0) {
    return 'Demo Mode (Expired)';
  }

  return `Demo Mode (${hoursLeft}h left)`;
}

/**
 * Export demo data as JSON (for backup/sharing)
 */
export function exportDemoData(): string {
  const session = getDemoSession();
  if (!session) return '{}';

  return JSON.stringify(session, null, 2);
}

/**
 * Import demo data from JSON
 */
export function importDemoData(jsonString: string): boolean {
  try {
    const parsed = JSON.parse(jsonString) as DemoSession;

    // Validate structure
    if (!parsed.apps || !Array.isArray(parsed.apps)) {
      return false;
    }

    // Update session with fresh expiry
    const now = new Date();
    parsed.expiresAt = new Date(
      now.getTime() + DEMO_SESSION_DURATION
    ).toISOString();

    if (typeof window !== 'undefined' && window.localStorage) {
      localStorage.setItem(DEMO_SESSION_KEY, JSON.stringify(parsed));
    }

    return true;
  } catch (error) {
    console.error('Failed to import demo data:', error);
    return false;
  }
}

/**
 * Clear demo session (logout)
 */
export function clearDemoSession(): void {
  try {
    if (typeof window !== 'undefined' && window.localStorage) {
      localStorage.removeItem(DEMO_SESSION_KEY);
    }
  } catch (error) {
    console.warn('Could not clear demo session:', error);
  }
}
