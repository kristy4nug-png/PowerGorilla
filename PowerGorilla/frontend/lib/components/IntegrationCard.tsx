// frontend/lib/components/IntegrationCard.tsx
// Premium integration app card with icon, name, category, and action buttons

import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Pressable,
  Image,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../theme';

interface IntegrationAction {
  id: string;
  label: string;
  action_type: string;
  target?: string;
  icon_emoji?: string;
  button_color?: string;
  is_destructive?: boolean;
  confirm_before_action?: boolean;
}

interface IntegrationApp {
  id: string;
  name: string;
  slug: string;
  app_type: 'online' | 'desktop' | 'hybrid';
  category: string;
  icon_id?: string;
  confidence: number;
  safe_to_launch: boolean;
  needs_review: boolean;
  is_pinned: boolean;
  official_url?: string;
  launch_url?: string;
  custom_label?: string;
}

interface IntegrationCardProps {
  app: IntegrationApp;
  iconData?: string; // base64 data URI
  actions?: IntegrationAction[];
  onAction?: (actionId: string, app: IntegrationApp) => Promise<void>;
  onPin?: (appId: string, pinned: boolean) => Promise<void>;
  onEdit?: (appId: string) => void;
  onRemove?: (appId: string) => Promise<void>;
  isLoading?: boolean;
  style?: any;
}

export default function IntegrationCard({
  app,
  iconData,
  actions = [],
  onAction,
  onPin,
  onEdit,
  onRemove,
  isLoading = false,
  style,
}: IntegrationCardProps) {
  const [executing, setExecuting] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  const handleActionPress = async (action: IntegrationAction) => {
    if (action.confirm_before_action) {
      Alert.alert(
        'Confirm Action',
        `Execute: ${action.label}?`,
        [
          { text: 'Cancel', onPress: () => {}, style: 'cancel' },
          {
            text: 'Execute',
            onPress: () => executeAction(action),
            style: action.is_destructive ? 'destructive' : 'default',
          },
        ]
      );
    } else {
      executeAction(action);
    }
  };

  const executeAction = async (action: IntegrationAction) => {
    if (!onAction) return;
    
    setExecuting(action.id);
    setActionError(null);
    try {
      await onAction(action.id, app);
    } catch (error) {
      setActionError(error instanceof Error ? error.message : 'Action failed');
      Alert.alert('Action Error', error instanceof Error ? error.message : 'Unknown error');
    } finally {
      setExecuting(null);
    }
  };

  const handlePin = async () => {
    if (!onPin) return;
    try {
      await onPin(app.id, !app.is_pinned);
    } catch (error) {
      Alert.alert('Error', error instanceof Error ? error.message : 'Failed to update pin');
    }
  };

  const handleRemove = () => {
    if (!onRemove) return;
    Alert.alert(
      'Remove Integration',
      `Remove "${app.name}" from your integrations?`,
      [
        { text: 'Cancel', onPress: () => {}, style: 'cancel' },
        {
          text: 'Remove',
          onPress: async () => {
            try {
              await onRemove(app.id);
            } catch (error) {
              Alert.alert('Error', error instanceof Error ? error.message : 'Failed to remove');
            }
          },
          style: 'destructive',
        },
      ]
    );
  };

  const getAppTypeColor = () => {
    switch (app.app_type) {
      case 'online':
        return '#6366F1'; // Indigo
      case 'desktop':
        return '#EC4899'; // Pink
      case 'hybrid':
        return '#F59E0B'; // Amber
      default:
        return Colors.textSecondary;
    }
  };

  const getAppTypeLabel = () => {
    return app.app_type.charAt(0).toUpperCase() + app.app_type.slice(1);
  };

  return (
    <View style={[styles.card, style]}>
      {/* Header: Icon + Name + Type Badge */}
      <View style={styles.header}>
        <View style={styles.iconContainer}>
          {iconData ? (
            <Image
              source={{ uri: iconData }}
              style={styles.icon}
              onError={() => <IconFallback app={app} />}
            />
          ) : (
            <IconFallback app={app} />
          )}
          {!app.safe_to_launch && (
            <View style={styles.warningBadge}>
              <Ionicons name="warning" size={12} color="white" />
            </View>
          )}
        </View>

        <View style={styles.headerContent}>
          <Text style={styles.appName}>{app.custom_label || app.name}</Text>
          <View style={styles.metaRow}>
            <View
              style={[
                styles.typeBadge,
                { backgroundColor: getAppTypeColor() + '20', borderColor: getAppTypeColor() },
              ]}
            >
              <Text style={[styles.typeBadgeText, { color: getAppTypeColor() }]}>
                {getAppTypeLabel()}
              </Text>
            </View>
            <Text style={styles.category}>{app.category}</Text>
          </View>
          {app.needs_review && (
            <View style={styles.reviewNote}>
              <Ionicons name="alert-circle" size={12} color="#DC2626" />
              <Text style={styles.reviewText}>Review needed</Text>
            </View>
          )}
        </View>

        {/* Pin/Favourite Button */}
        <Pressable
          style={styles.pinButton}
          onPress={handlePin}
          disabled={isLoading}
        >
          <Ionicons
            name={app.is_pinned ? 'star' : 'star-outline'}
            size={24}
            color={app.is_pinned ? '#FCD34D' : Colors.textSecondary}
          />
        </Pressable>
      </View>

      {/* Divider */}
      <View style={styles.divider} />

      {/* Actions: Open, Search, Pin, Edit, Remove */}
      <View style={styles.actionsContainer}>
        {/* Default Open Button */}
        <Pressable
          style={[
            styles.actionButton,
            styles.openButton,
            executing === 'open' && styles.actionButtonActive,
          ]}
          onPress={() => handleActionPress({
            id: 'open',
            label: 'Open',
            action_type: 'open_url',
            target: app.launch_url || app.official_url,
            icon_emoji: '🔵',
          })}
          disabled={executing !== null || isLoading}
        >
          {executing === 'open' ? (
            <ActivityIndicator size={16} color="white" />
          ) : (
            <>
              <Text style={styles.actionButtonEmoji}>🔵</Text>
              <Text style={styles.actionButtonText}>Open</Text>
            </>
          )}
        </Pressable>

        {/* Search Button (for online apps) */}
        {app.app_type !== 'desktop' && (
          <Pressable
            style={[
              styles.actionButton,
              styles.searchButton,
              executing === 'search' && styles.actionButtonActive,
            ]}
            onPress={() => handleActionPress({
              id: 'search',
              label: 'Search',
              action_type: 'open_url_template',
              icon_emoji: '🔍',
            })}
            disabled={executing !== null || isLoading}
          >
            {executing === 'search' ? (
              <ActivityIndicator size={16} color="white" />
            ) : (
              <>
                <Text style={styles.actionButtonEmoji}>🔍</Text>
                <Text style={styles.actionButtonText}>Search</Text>
              </>
            )}
          </Pressable>
        )}

        {/* Edit Button */}
        <Pressable
          style={styles.actionButton}
          onPress={() => onEdit?.(app.id)}
          disabled={isLoading}
        >
          <Ionicons name="create-outline" size={16} color={Colors.text} />
          <Text style={styles.actionButtonTextSecondary}>Edit</Text>
        </Pressable>

        {/* Remove Button */}
        <Pressable
          style={[styles.actionButton, styles.removeButton]}
          onPress={handleRemove}
          disabled={isLoading}
        >
          <Ionicons name="trash-outline" size={16} color="#DC2626" />
          <Text style={styles.actionButtonTextDanger}>Remove</Text>
        </Pressable>
      </View>

      {/* Confidence & Safe-to-Launch Indicators */}
      <View style={styles.footer}>
        <View style={styles.confidenceIndicator}>
          <Text style={styles.confidenceLabel}>Confidence: {(app.confidence * 100).toFixed(0)}%</Text>
          <View
            style={[
              styles.confidenceBar,
              { width: `${app.confidence * 100}%` },
            ]}
          />
        </View>
        {!app.safe_to_launch && (
          <View style={styles.unsafeWarning}>
            <Ionicons name="warning" size={12} color="#DC2626" />
            <Text style={styles.unsafeText}>Requires caution</Text>
          </View>
        )}
      </View>

      {actionError && (
        <View style={styles.errorBanner}>
          <Text style={styles.errorText}>{actionError}</Text>
        </View>
      )}
    </View>
  );
}

function IconFallback({ app }: { app: IntegrationApp }) {
  const getInitials = (name: string) => {
    return name
      .split(' ')
      .map((w) => w[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
  };

  const colors = ['#6366F1', '#EC4899', '#F59E0B', '#10B981', '#06B6D4'];
  const hash = app.name.charCodeAt(0) % colors.length;
  const bgColor = colors[hash];

  return (
    <View style={[styles.iconFallback, { backgroundColor: bgColor }]}>
      <Text style={styles.iconFallbackText}>{getInitials(app.name)}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.panel,
    borderRadius: 12,
    overflow: 'hidden',
    marginHorizontal: 8,
    marginVertical: 8,
    paddingVertical: 12,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  header: {
    flexDirection: 'row',
    paddingHorizontal: 12,
    paddingVertical: 8,
    alignItems: 'flex-start',
  },
  iconContainer: {
    position: 'relative',
    marginRight: 12,
  },
  icon: {
    width: 56,
    height: 56,
    borderRadius: 8,
  },
  iconFallback: {
    width: 56,
    height: 56,
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
  },
  iconFallbackText: {
    color: 'white',
    fontWeight: '700',
    fontSize: 18,
  },
  warningBadge: {
    position: 'absolute',
    bottom: -2,
    right: -2,
    backgroundColor: '#DC2626',
    borderRadius: 12,
    width: 20,
    height: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  headerContent: {
    flex: 1,
  },
  appName: {
    color: Colors.text,
    fontWeight: '700',
    fontSize: 16,
    marginBottom: 4,
  },
  metaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  typeBadge: {
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 4,
    borderWidth: 1,
    marginRight: 8,
  },
  typeBadgeText: {
    fontSize: 10,
    fontWeight: '600',
  },
  category: {
    color: Colors.textSecondary,
    fontSize: 12,
  },
  reviewNote: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 4,
  },
  reviewText: {
    color: '#DC2626',
    fontSize: 11,
    fontWeight: '500',
    marginLeft: 4,
  },
  pinButton: {
    padding: 8,
  },
  divider: {
    height: 1,
    backgroundColor: Colors.border,
    marginVertical: 8,
  },
  actionsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: 8,
    gap: 6,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 6,
    paddingHorizontal: 10,
    borderRadius: 6,
    backgroundColor: Colors.bg,
    borderWidth: 1,
    borderColor: Colors.border,
    justifyContent: 'center',
  },
  openButton: {
    backgroundColor: '#6366F1',
    borderColor: '#6366F1',
    flex: 1,
    minWidth: '30%',
  },
  searchButton: {
    backgroundColor: '#10B981',
    borderColor: '#10B981',
    flex: 1,
    minWidth: '30%',
  },
  removeButton: {
    borderColor: '#FCA5A5',
  },
  actionButtonActive: {
    opacity: 0.8,
  },
  actionButtonEmoji: {
    marginRight: 4,
    fontSize: 14,
  },
  actionButtonText: {
    color: 'white',
    fontSize: 12,
    fontWeight: '600',
  },
  actionButtonTextSecondary: {
    color: Colors.text,
    fontSize: 12,
    fontWeight: '500',
    marginLeft: 4,
  },
  actionButtonTextDanger: {
    color: '#DC2626',
    fontSize: 12,
    fontWeight: '500',
    marginLeft: 4,
  },
  footer: {
    paddingHorizontal: 12,
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: Colors.border,
  },
  confidenceIndicator: {
    marginBottom: 8,
  },
  confidenceLabel: {
    color: Colors.textSecondary,
    fontSize: 11,
    fontWeight: '500',
    marginBottom: 2,
  },
  confidenceBar: {
    height: 2,
    backgroundColor: '#10B981',
    borderRadius: 1,
  },
  unsafeWarning: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 4,
  },
  unsafeText: {
    color: '#DC2626',
    fontSize: 11,
    fontWeight: '500',
    marginLeft: 4,
  },
  errorBanner: {
    backgroundColor: '#FEE2E2',
    paddingHorizontal: 12,
    paddingVertical: 8,
    marginTop: 8,
  },
  errorText: {
    color: '#DC2626',
    fontSize: 12,
    fontWeight: '500',
  },
});
