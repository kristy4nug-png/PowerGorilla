// frontend/lib/components/CombinationCreator.tsx
// Create custom groups of 2-4 apps for organized dashboard sections

import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Pressable,
  FlatList,
  TextInput,
  Alert,
  Modal,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../theme';
import AppTypeIndicator from './AppTypeIndicator';

interface IntegrationApp {
  id: string;
  name: string;
  slug: string;
  app_type: 'online' | 'desktop' | 'hybrid';
  category: string;
  icon_id?: string;
}

interface CombinationGroup {
  id: string;
  name: string;
  icon_emoji: string;
  color: string;
  apps: IntegrationApp[];
  description?: string;
  created_at: string;
}

interface CombinationCreatorProps {
  availableApps: IntegrationApp[];
  onCreateGroup: (group: CombinationGroup) => Promise<void>;
  isLoading?: boolean;
}

const COLORS = ['#6366F1', '#EC4899', '#F59E0B', '#10B981', '#06B6D4', '#8B5CF6'];
const EMOJIS = ['🎵', '🎬', '💻', '🎨', '🛒', '📚', '💬', '🎮', '⭐', '🚀'];

export default function CombinationCreator({
  availableApps,
  onCreateGroup,
  isLoading = false,
}: CombinationCreatorProps) {
  const [showModal, setShowModal] = useState(false);
  const [groupName, setGroupName] = useState('');
  const [selectedApps, setSelectedApps] = useState<string[]>([]);
  const [selectedColor, setSelectedColor] = useState(COLORS[0]);
  const [selectedEmoji, setSelectedEmoji] = useState(EMOJIS[0]);
  const [groupDescription, setGroupDescription] = useState('');

  const handleAddApp = (appId: string) => {
    if (selectedApps.includes(appId)) {
      setSelectedApps(selectedApps.filter((id) => id !== appId));
    } else if (selectedApps.length < 4) {
      setSelectedApps([...selectedApps, appId]);
    } else {
      Alert.alert('Limit reached', 'You can add up to 4 apps per group');
    }
  };

  const handleCreateGroup = async () => {
    if (!groupName.trim()) {
      Alert.alert('Error', 'Please enter a group name');
      return;
    }

    if (selectedApps.length < 2) {
      Alert.alert('Error', 'Please select at least 2 apps');
      return;
    }

    const selectedAppObjects = availableApps.filter((app) =>
      selectedApps.includes(app.id)
    );

    const newGroup: CombinationGroup = {
      id: `combo-${Date.now()}`,
      name: groupName,
      icon_emoji: selectedEmoji,
      color: selectedColor,
      apps: selectedAppObjects,
      description: groupDescription || undefined,
      created_at: new Date().toISOString(),
    };

    try {
      await onCreateGroup(newGroup);
      setShowModal(false);
      setGroupName('');
      setSelectedApps([]);
      setGroupDescription('');
      setSelectedColor(COLORS[0]);
      setSelectedEmoji(EMOJIS[0]);
      Alert.alert('Success', `"${groupName}" group created!`);
    } catch (error) {
      Alert.alert('Error', error instanceof Error ? error.message : 'Failed to create group');
    }
  };

  const selectedAppObjects = availableApps.filter((app) => selectedApps.includes(app.id));

  return (
    <>
      {/* Trigger Button */}
      <Pressable
        style={styles.triggerButton}
        onPress={() => setShowModal(true)}
        disabled={isLoading}
      >
        <Ionicons name="add-circle" size={20} color="white" />
        <Text style={styles.triggerButtonText}>Create Group</Text>
      </Pressable>

      {/* Modal */}
      <Modal
        visible={showModal}
        animationType="slide"
        transparent={true}
        onRequestClose={() => setShowModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            {/* Header */}
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Create Group (2-4 apps)</Text>
              <Pressable onPress={() => setShowModal(false)}>
                <Ionicons name="close" size={24} color={Colors.text} />
              </Pressable>
            </View>

            {/* Group Name Input */}
            <View style={styles.section}>
              <Text style={styles.sectionLabel}>Group Name</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g., Music, Shopping, Development"
                placeholderTextColor={Colors.textSecondary}
                value={groupName}
                onChangeText={setGroupName}
              />
            </View>

            {/* Emoji & Color Selection */}
            <View style={styles.section}>
              <Text style={styles.sectionLabel}>Pick Icon & Color</Text>
              <View style={styles.emojiGrid}>
                {EMOJIS.map((emoji) => (
                  <Pressable
                    key={emoji}
                    style={[
                      styles.emojiOption,
                      selectedEmoji === emoji && styles.emojiOptionSelected,
                    ]}
                    onPress={() => setSelectedEmoji(emoji)}
                  >
                    <Text style={styles.emoji}>{emoji}</Text>
                  </Pressable>
                ))}
              </View>

              <View style={styles.colorGrid}>
                {COLORS.map((color) => (
                  <Pressable
                    key={color}
                    style={[
                      styles.colorOption,
                      { backgroundColor: color },
                      selectedColor === color && styles.colorOptionSelected,
                    ]}
                    onPress={() => setSelectedColor(color)}
                  >
                    {selectedColor === color && (
                      <Ionicons name="checkmark" size={16} color="white" />
                    )}
                  </Pressable>
                ))}
              </View>
            </View>

            {/* Description (Optional) */}
            <View style={styles.section}>
              <Text style={styles.sectionLabel}>Description (Optional)</Text>
              <TextInput
                style={[styles.input, styles.descriptionInput]}
                placeholder="What's this group for?"
                placeholderTextColor={Colors.textSecondary}
                value={groupDescription}
                onChangeText={setGroupDescription}
                multiline
              />
            </View>

            {/* App Selection */}
            <View style={styles.section}>
              <View style={styles.sectionHeaderRow}>
                <Text style={styles.sectionLabel}>Select Apps ({selectedApps.length}/4)</Text>
                {selectedApps.length >= 2 && (
                  <Text style={styles.appCountBadge}>{selectedApps.length}</Text>
                )}
              </View>

              <FlatList
                data={availableApps}
                keyExtractor={(item) => item.id}
                scrollEnabled={false}
                renderItem={({ item: app }) => {
                  const isSelected = selectedApps.includes(app.id);
                  return (
                    <Pressable
                      style={[
                        styles.appOption,
                        isSelected && styles.appOptionSelected,
                        selectedApps.length >= 4 &&
                          !isSelected && {
                            opacity: 0.5,
                          },
                      ]}
                      onPress={() => handleAddApp(app.id)}
                      disabled={selectedApps.length >= 4 && !isSelected}
                    >
                      <View style={styles.appOptionLeft}>
                        <Ionicons
                          name={
                            isSelected ? 'checkmark-circle' : 'ellipse-outline'
                          }
                          size={20}
                          color={isSelected ? '#10B981' : Colors.textSecondary}
                        />
                        <View style={styles.appInfo}>
                          <Text style={styles.appName}>{app.name}</Text>
                          <AppTypeIndicator appType={app.app_type} size="small" />
                        </View>
                      </View>
                      <Text style={styles.appCategory}>{app.category}</Text>
                    </Pressable>
                  );
                }}
              />
            </View>

            {/* Preview */}
            {selectedApps.length >= 2 && (
              <View style={[styles.preview, { backgroundColor: selectedColor + '20' }]}>
                <Text style={styles.previewEmoji}>{selectedEmoji}</Text>
                <View style={styles.previewContent}>
                  <Text style={styles.previewTitle}>{groupName || 'Group name'}</Text>
                  <View style={styles.previewApps}>
                    {selectedAppObjects.slice(0, 3).map((app) => (
                      <Text key={app.id} style={styles.previewApp}>
                        {app.name}
                      </Text>
                    ))}
                    {selectedAppObjects.length > 3 && (
                      <Text style={styles.previewApp}>
                        +{selectedAppObjects.length - 3} more
                      </Text>
                    )}
                  </View>
                </View>
              </View>
            )}

            {/* Action Buttons */}
            <View style={styles.actions}>
              <Pressable
                style={styles.cancelButton}
                onPress={() => setShowModal(false)}
                disabled={isLoading}
              >
                <Text style={styles.cancelButtonText}>Cancel</Text>
              </Pressable>
              <Pressable
                style={[
                  styles.createButton,
                  (selectedApps.length < 2 || !groupName.trim() || isLoading) &&
                    styles.createButtonDisabled,
                ]}
                onPress={handleCreateGroup}
                disabled={selectedApps.length < 2 || !groupName.trim() || isLoading}
              >
                <Text style={styles.createButtonText}>
                  {isLoading ? 'Creating...' : 'Create Group'}
                </Text>
              </Pressable>
            </View>
          </View>
        </View>
      </Modal>
    </>
  );
}

const styles = StyleSheet.create({
  triggerButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#6366F1',
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 8,
    gap: 8,
  },
  triggerButtonText: {
    color: 'white',
    fontSize: 14,
    fontWeight: '600',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: Colors.panel,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    paddingHorizontal: 16,
    paddingTop: 20,
    paddingBottom: 32,
    maxHeight: '90%',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  modalTitle: {
    color: Colors.text,
    fontSize: 18,
    fontWeight: '700',
  },
  section: {
    marginBottom: 16,
  },
  sectionLabel: {
    color: Colors.text,
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 8,
  },
  sectionHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  appCountBadge: {
    backgroundColor: '#6366F1',
    color: 'white',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 4,
    fontSize: 12,
    fontWeight: '600',
  },
  input: {
    backgroundColor: Colors.bg,
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    color: Colors.text,
    fontSize: 14,
  },
  descriptionInput: {
    minHeight: 60,
    textAlignVertical: 'top',
  },
  emojiGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 12,
  },
  emojiOption: {
    width: '23%',
    aspectRatio: 1,
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 8,
    backgroundColor: Colors.bg,
    borderWidth: 2,
    borderColor: 'transparent',
  },
  emojiOptionSelected: {
    borderColor: '#6366F1',
    backgroundColor: '#6366F1' + '20',
  },
  emoji: {
    fontSize: 32,
  },
  colorGrid: {
    flexDirection: 'row',
    gap: 8,
  },
  colorOption: {
    flex: 1,
    aspectRatio: 1,
    borderRadius: 8,
    borderWidth: 2,
    borderColor: 'transparent',
    justifyContent: 'center',
    alignItems: 'center',
  },
  colorOptionSelected: {
    borderColor: 'white',
  },
  appOption: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 12,
    paddingHorizontal: 12,
    borderRadius: 8,
    backgroundColor: Colors.bg,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  appOptionSelected: {
    backgroundColor: '#10B981' + '20',
    borderColor: '#10B981',
  },
  appOptionLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    flex: 1,
  },
  appInfo: {
    flex: 1,
  },
  appName: {
    color: Colors.text,
    fontSize: 13,
    fontWeight: '600',
    marginBottom: 4,
  },
  appCategory: {
    color: Colors.textSecondary,
    fontSize: 11,
  },
  preview: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 12,
    borderRadius: 8,
    marginBottom: 16,
    gap: 12,
  },
  previewEmoji: {
    fontSize: 40,
  },
  previewContent: {
    flex: 1,
  },
  previewTitle: {
    color: Colors.text,
    fontSize: 14,
    fontWeight: '700',
    marginBottom: 4,
  },
  previewApps: {
    gap: 2,
  },
  previewApp: {
    color: Colors.textSecondary,
    fontSize: 11,
  },
  actions: {
    flexDirection: 'row',
    gap: 8,
  },
  cancelButton: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 8,
    backgroundColor: Colors.bg,
    borderWidth: 1,
    borderColor: Colors.border,
    alignItems: 'center',
  },
  cancelButtonText: {
    color: Colors.text,
    fontSize: 14,
    fontWeight: '600',
  },
  createButton: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 8,
    backgroundColor: '#6366F1',
    alignItems: 'center',
  },
  createButtonDisabled: {
    opacity: 0.5,
  },
  createButtonText: {
    color: 'white',
    fontSize: 14,
    fontWeight: '600',
  },
});
