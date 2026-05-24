// frontend/lib/components/IconPicker.tsx
// Icon selection component with multiple sources
// Allows users to choose from Simple Icons, Iconify, local, or custom

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Pressable,
  Image,
  TextInput,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../theme';

interface IconOption {
  id: string;
  source: 'simple_icons' | 'iconify' | 'local' | 'custom';
  slug: string;
  label: string;
  data_uri?: string;
  emoji?: string;
  color?: string;
}

interface IconPickerProps {
  appName: string;
  appType: 'online' | 'desktop' | 'hybrid';
  onSelectIcon: (icon: IconOption) => void;
  currentIcon?: IconOption;
  isLoading?: boolean;
}

export default function IconPicker({
  appName,
  appType,
  onSelectIcon,
  currentIcon,
  isLoading = false,
}: IconPickerProps) {
  const [activeTab, setActiveTab] = useState<'simple_icons' | 'iconify' | 'emoji' | 'custom'>('simple_icons');
  const [searchQuery, setSearchQuery] = useState('');
  const [icons, setIcons] = useState<IconOption[]>([]);
  const [searching, setSearching] = useState(false);
  const [customColor, setCustomColor] = useState(currentIcon?.color || '#6366F1');

  // Mock icon data for demo (in production, fetch from APIs)
  const MOCK_ICONS = {
    simple_icons: [
      { id: 'spotify', slug: 'spotify', label: 'Spotify', color: '#1DB954' },
      { id: 'youtube', slug: 'youtube', label: 'YouTube', color: '#FF0000' },
      { id: 'netflix', slug: 'netflix', label: 'Netflix', color: '#E50914' },
      { id: 'discord', slug: 'discord', label: 'Discord', color: '#5865F2' },
      { id: 'slack', slug: 'slack', label: 'Slack', color: '#E01E5A' },
      { id: 'figma', slug: 'figma', label: 'Figma', color: '#F24E1E' },
      { id: 'vscode', slug: 'vscode', label: 'VS Code', color: '#007ACC' },
      { id: 'github', slug: 'github', label: 'GitHub', color: '#181717' },
      { id: 'notion', slug: 'notion', label: 'Notion', color: '#000000' },
      { id: 'obsidian', slug: 'obsidian', label: 'Obsidian', color: '#483699' },
    ],
    emoji: [
      { id: 'music', emoji: '🎵', label: 'Music' },
      { id: 'video', emoji: '🎬', label: 'Video' },
      { id: 'code', emoji: '💻', label: 'Code' },
      { id: 'design', emoji: '🎨', label: 'Design' },
      { id: 'chat', emoji: '💬', label: 'Chat' },
      { id: 'shopping', emoji: '🛍️', label: 'Shopping' },
      { id: 'work', emoji: '📊', label: 'Work' },
      { id: 'book', emoji: '📚', label: 'Books' },
      { id: 'game', emoji: '🎮', label: 'Games' },
      { id: 'star', emoji: '⭐', label: 'Favourite' },
    ],
  };

  useEffect(() => {
    if (activeTab === 'simple_icons') {
      loadSimpleIcons();
    } else if (activeTab === 'emoji') {
      setIcons(
        MOCK_ICONS.emoji.map((icon: any) => ({
          ...icon,
          source: 'custom',
          id: `emoji-${icon.id}`,
        }))
      );
    }
  }, [activeTab]);

  const loadSimpleIcons = async () => {
    setSearching(true);
    try {
      // In production, search Simple Icons API
      // For now, use mock data
      const results = MOCK_ICONS.simple_icons
        .filter((icon) =>
          icon.label.toLowerCase().includes(searchQuery.toLowerCase()) ||
          icon.slug.toLowerCase().includes(searchQuery.toLowerCase())
        )
        .map((icon) => ({
          ...icon,
          id: `simple-${icon.id}`,
          source: 'simple_icons' as const,
        }));

      setIcons(results.length > 0 ? results : MOCK_ICONS.simple_icons.map(icon => ({
        ...icon,
        id: `simple-${icon.id}`,
        source: 'simple_icons' as const,
      })));
    } catch (error) {
      Alert.alert('Error', 'Failed to load icons');
    } finally {
      setSearching(false);
    }
  };

  const handleSelectIcon = (icon: IconOption) => {
    onSelectIcon(icon);
  };

  const handleGenerateInitials = () => {
    const initials = appName
      .split(' ')
      .map((w) => w[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);

    onSelectIcon({
      id: `custom-initials-${appName}`,
      source: 'custom',
      slug: `initials-${appName.toLowerCase()}`,
      label: `${initials} (initials)`,
      color: customColor,
    });
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>Choose Icon for {appName}</Text>
        <Text style={styles.subtitle}>
          {appType === 'online' ? '🌐 Internet App' : appType === 'desktop' ? '🖥️ Local App' : '🔄 Hybrid'}
        </Text>
      </View>

      {/* Tab buttons */}
      <View style={styles.tabs}>
        {(['simple_icons', 'iconify', 'emoji', 'custom'] as const).map((tab) => (
          <Pressable
            key={tab}
            style={[styles.tab, activeTab === tab && styles.tabActive]}
            onPress={() => {
              setActiveTab(tab);
              setSearchQuery('');
            }}
          >
            <Text
              style={[
                styles.tabText,
                activeTab === tab && styles.tabTextActive,
              ]}
            >
              {tab === 'simple_icons' && 'Brand'}
              {tab === 'iconify' && 'Library'}
              {tab === 'emoji' && 'Emoji'}
              {tab === 'custom' && 'Custom'}
            </Text>
          </Pressable>
        ))}
      </View>

      {/* Search bar (for simple_icons and iconify) */}
      {(activeTab === 'simple_icons' || activeTab === 'iconify') && (
        <View style={styles.searchContainer}>
          <Ionicons name="search" size={18} color={Colors.textSecondary} />
          <TextInput
            style={styles.searchInput}
            placeholder="Search icons..."
            placeholderTextColor={Colors.textSecondary}
            value={searchQuery}
            onChangeText={(text) => {
              setSearchQuery(text);
              loadSimpleIcons();
            }}
          />
        </View>
      )}

      {/* Icon Grid */}
      {searching ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#6366F1" />
        </View>
      ) : (
        <ScrollView style={styles.iconGrid} contentContainerStyle={styles.iconGridContent}>
          {activeTab === 'emoji' ? (
            // Emoji grid
            icons.map((icon) => (
              <Pressable
                key={icon.id}
                style={[
                  styles.iconItem,
                  currentIcon?.id === icon.id && styles.iconItemSelected,
                ]}
                onPress={() => handleSelectIcon(icon)}
              >
                <Text style={styles.emojiIcon}>{icon.emoji}</Text>
                <Text style={styles.iconLabel}>{icon.label}</Text>
                {currentIcon?.id === icon.id && (
                  <View style={styles.checkmark}>
                    <Ionicons name="checkmark-circle" size={20} color="#10B981" />
                  </View>
                )}
              </Pressable>
            ))
          ) : activeTab === 'custom' ? (
            // Custom icon options
            <View style={styles.customContainer}>
              <View style={styles.customOption}>
                <Text style={styles.customLabel}>Initials Avatar</Text>
                <View style={styles.colorPickerRow}>
                  {['#6366F1', '#EC4899', '#F59E0B', '#10B981', '#06B6D4', '#8B5CF6'].map((color) => (
                    <Pressable
                      key={color}
                      style={[
                        styles.colorOption,
                        { backgroundColor: color },
                        customColor === color && styles.colorOptionSelected,
                      ]}
                      onPress={() => setCustomColor(color)}
                    >
                      {customColor === color && (
                        <Ionicons name="checkmark" size={16} color="white" />
                      )}
                    </Pressable>
                  ))}
                </View>
                <Pressable
                  style={styles.generateButton}
                  onPress={handleGenerateInitials}
                >
                  <Text style={styles.generateButtonText}>Generate</Text>
                </Pressable>
              </View>

              <View style={styles.customOption}>
                <Text style={styles.customLabel}>Upload Custom Icon</Text>
                <Pressable style={styles.uploadButton}>
                  <Ionicons name="cloud-upload" size={24} color="#6366F1" />
                  <Text style={styles.uploadButtonText}>Choose file</Text>
                </Pressable>
              </View>
            </View>
          ) : (
            // Brand/Iconify grid
            icons.map((icon) => (
              <Pressable
                key={icon.id}
                style={[
                  styles.iconItem,
                  currentIcon?.id === icon.id && styles.iconItemSelected,
                ]}
                onPress={() => handleSelectIcon(icon)}
              >
                {icon.data_uri ? (
                  <Image
                    source={{ uri: icon.data_uri }}
                    style={styles.iconImage}
                  />
                ) : (
                  <View
                    style={[
                      styles.iconPlaceholder,
                      { backgroundColor: icon.color || '#6366F1' },
                    ]}
                  >
                    <Text style={styles.iconInitial}>
                      {icon.label.charAt(0).toUpperCase()}
                    </Text>
                  </View>
                )}
                <Text style={styles.iconLabel}>{icon.label}</Text>
                {currentIcon?.id === icon.id && (
                  <View style={styles.checkmark}>
                    <Ionicons name="checkmark-circle" size={20} color="#10B981" />
                  </View>
                )}
              </Pressable>
            ))
          )}
        </ScrollView>
      )}

      {/* Current selection preview */}
      {currentIcon && (
        <View style={styles.previewContainer}>
          <Text style={styles.previewLabel}>Preview:</Text>
          <View style={styles.preview}>
            {currentIcon.emoji ? (
              <Text style={styles.emojiPreview}>{currentIcon.emoji}</Text>
            ) : currentIcon.data_uri ? (
              <Image source={{ uri: currentIcon.data_uri }} style={styles.previewImage} />
            ) : (
              <View
                style={[
                  styles.previewPlaceholder,
                  { backgroundColor: currentIcon.color || '#6366F1' },
                ]}
              >
                <Text style={styles.previewText}>
                  {currentIcon.label
                    .split(' ')
                    .map((w) => w[0])
                    .join('')
                    .toUpperCase()
                    .slice(0, 2)}
                </Text>
              </View>
            )}
            <Text style={styles.previewName}>{currentIcon.label}</Text>
          </View>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.bg,
  },
  header: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: Colors.panel,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
  },
  title: {
    color: Colors.text,
    fontSize: 16,
    fontWeight: '700',
    marginBottom: 4,
  },
  subtitle: {
    color: Colors.textSecondary,
    fontSize: 12,
  },
  tabs: {
    flexDirection: 'row',
    paddingHorizontal: 8,
    paddingVertical: 8,
    backgroundColor: Colors.bg,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
    gap: 8,
  },
  tab: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
    backgroundColor: Colors.panel,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  tabActive: {
    backgroundColor: '#6366F1',
    borderColor: '#6366F1',
  },
  tabText: {
    color: Colors.text,
    fontSize: 12,
    fontWeight: '600',
  },
  tabTextActive: {
    color: 'white',
  },
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 8,
    backgroundColor: Colors.bg,
    gap: 8,
  },
  searchInput: {
    flex: 1,
    paddingVertical: 8,
    paddingHorizontal: 12,
    backgroundColor: Colors.panel,
    borderRadius: 8,
    color: Colors.text,
    fontSize: 14,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  iconGrid: {
    flex: 1,
  },
  iconGridContent: {
    paddingHorizontal: 8,
    paddingVertical: 8,
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  iconItem: {
    width: '25%',
    alignItems: 'center',
    paddingVertical: 12,
    paddingHorizontal: 4,
    borderRadius: 8,
    marginBottom: 8,
  },
  iconItemSelected: {
    backgroundColor: 'rgba(99, 102, 241, 0.1)',
    borderWidth: 2,
    borderColor: '#6366F1',
  },
  iconImage: {
    width: 48,
    height: 48,
    borderRadius: 8,
    marginBottom: 8,
  },
  iconPlaceholder: {
    width: 48,
    height: 48,
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  iconInitial: {
    color: 'white',
    fontWeight: '700',
    fontSize: 20,
  },
  emojiIcon: {
    fontSize: 32,
    marginBottom: 8,
  },
  iconLabel: {
    color: Colors.text,
    fontSize: 11,
    fontWeight: '500',
    textAlign: 'center',
  },
  checkmark: {
    position: 'absolute',
    top: 4,
    right: 4,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  customContainer: {
    padding: 16,
  },
  customOption: {
    backgroundColor: Colors.panel,
    borderRadius: 8,
    padding: 16,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  customLabel: {
    color: Colors.text,
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 12,
  },
  colorPickerRow: {
    flexDirection: 'row',
    gap: 8,
    marginBottom: 12,
  },
  colorOption: {
    width: 40,
    height: 40,
    borderRadius: 6,
    borderWidth: 2,
    borderColor: 'transparent',
    justifyContent: 'center',
    alignItems: 'center',
  },
  colorOptionSelected: {
    borderColor: Colors.text,
  },
  generateButton: {
    backgroundColor: '#6366F1',
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 6,
    alignItems: 'center',
  },
  generateButtonText: {
    color: 'white',
    fontSize: 12,
    fontWeight: '600',
  },
  uploadButton: {
    borderWidth: 2,
    borderColor: '#6366F1',
    borderStyle: 'dashed',
    borderRadius: 8,
    paddingVertical: 20,
    alignItems: 'center',
    gap: 8,
  },
  uploadButtonText: {
    color: '#6366F1',
    fontSize: 12,
    fontWeight: '600',
  },
  previewContainer: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: Colors.panel,
    borderTopWidth: 1,
    borderTopColor: Colors.border,
  },
  previewLabel: {
    color: Colors.textSecondary,
    fontSize: 11,
    fontWeight: '500',
    marginBottom: 8,
  },
  preview: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 12,
    paddingVertical: 12,
    backgroundColor: Colors.bg,
    borderRadius: 8,
  },
  previewImage: {
    width: 48,
    height: 48,
    borderRadius: 8,
  },
  previewPlaceholder: {
    width: 48,
    height: 48,
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
  },
  previewText: {
    color: 'white',
    fontWeight: '700',
    fontSize: 16,
  },
  emojiPreview: {
    fontSize: 32,
  },
  previewName: {
    color: Colors.text,
    fontSize: 12,
    fontWeight: '600',
  },
});
