// lib/theme.ts — Design system tokens for PowerShell Gorilla

export const Colors = {
  bg:       '#0a0e1a',
  panel:    '#111827',
  panel2:   '#1a2236',
  border:   '#1e2d45',
  text:     '#e2eaf6',
  textSecondary: '#8899b4',
  muted:    '#8899b4',
  ok:       '#34d399',
  warn:     '#fbbf24',
  danger:   '#f87171',
  accent:   '#60a5fa',
  accent2:  '#a78bfa',
  gradient: ['#0a0e1a', '#111827'] as const,
};

export const Typography = {
  heading1: { fontSize: 28, fontWeight: '700' as const, color: Colors.text, letterSpacing: -0.5 },
  heading2: { fontSize: 20, fontWeight: '700' as const, color: Colors.text },
  heading3: { fontSize: 16, fontWeight: '600' as const, color: Colors.text },
  body:     { fontSize: 14, fontWeight: '400' as const, color: Colors.text, lineHeight: 22 },
  small:    { fontSize: 12, fontWeight: '400' as const, color: Colors.muted },
  mono:     { fontSize: 13, fontFamily: 'monospace' as const, color: Colors.accent },
};

export const Spacing = {
  xs: 4, sm: 8, md: 16, lg: 24, xl: 32, xxl: 48,
};

export const Radius = {
  sm: 6, md: 10, lg: 16, full: 999,
};

export const Shadow = {
  card: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 12,
    elevation: 8,
  },
};
