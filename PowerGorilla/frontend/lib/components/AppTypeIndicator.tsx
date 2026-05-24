// frontend/lib/components/AppTypeIndicator.tsx
// Visual indicator showing app type: Online (🌐), Desktop (🖥️), or Hybrid (🔄)

import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors } from '../theme';

interface AppTypeIndicatorProps {
  appType: 'online' | 'desktop' | 'hybrid';
  variant?: 'badge' | 'full' | 'minimal';
  size?: 'small' | 'medium' | 'large';
}

export default function AppTypeIndicator({
  appType,
  variant = 'badge',
  size = 'medium',
}: AppTypeIndicatorProps) {
  const getAppTypeInfo = () => {
    switch (appType) {
      case 'online':
        return {
          emoji: '🌐',
          label: 'Internet App',
          description: 'Web-based, requires internet connection',
          color: '#6366F1',
          bgColor: '#6366F1' + '20',
        };
      case 'desktop':
        return {
          emoji: '🖥️',
          label: 'Local App',
          description: 'Installed on your computer, works offline',
          color: '#EC4899',
          bgColor: '#EC4899' + '20',
        };
      case 'hybrid':
        return {
          emoji: '🔄',
          label: 'Hybrid App',
          description: 'Works both online and offline',
          color: '#F59E0B',
          bgColor: '#F59E0B' + '20',
        };
    }
  };

  const info = getAppTypeInfo();
  const sizeStyles = {
    small: { paddingHorizontal: 8, paddingVertical: 4 },
    medium: { paddingHorizontal: 12, paddingVertical: 6 },
    large: { paddingHorizontal: 16, paddingVertical: 8 },
  };

  if (variant === 'minimal') {
    return <Text style={styles.emoji}>{info.emoji}</Text>;
  }

  if (variant === 'full') {
    return (
      <View style={[styles.fullContainer, { backgroundColor: info.bgColor }]}>
        <Text style={styles.emoji}>{info.emoji}</Text>
        <View style={styles.fullContent}>
          <Text style={[styles.label, { color: info.color }]}>{info.label}</Text>
          <Text style={styles.description}>{info.description}</Text>
        </View>
      </View>
    );
  }

  // Badge variant (default)
  return (
    <View
      style={[
        styles.badge,
        sizeStyles[size],
        { backgroundColor: info.bgColor, borderColor: info.color },
      ]}
    >
      <Text style={styles.emoji}>{info.emoji}</Text>
      <Text style={[styles.label, { color: info.color }]}>{info.label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  badge: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 6,
    borderWidth: 1,
    gap: 6,
  },
  emoji: {
    fontSize: 16,
  },
  label: {
    fontSize: 12,
    fontWeight: '600',
  },
  fullContainer: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingHorizontal: 12,
    paddingVertical: 12,
    borderRadius: 8,
    gap: 12,
  },
  fullContent: {
    flex: 1,
  },
  description: {
    color: Colors.textSecondary,
    fontSize: 12,
    marginTop: 4,
    lineHeight: 16,
  },
});
