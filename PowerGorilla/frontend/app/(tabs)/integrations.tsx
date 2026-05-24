// frontend/app/(tabs)/integrations.tsx
// Integration discovery and management screen

import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  StyleSheet,
  SafeAreaView,
  ScrollView,
  Pressable,
  Text,
  Modal,
  TextInput,
  ActivityIndicator,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useFocusEffect } from 'expo-router';

import { Colors } from '../../lib/theme';
import IntegrationPanel from '../../lib/components/IntegrationPanel';
import {
  loadUserIntegrations,
  loadIntegrationActions,
  discoverAndAddApps,
  removeIntegrationApp,
  toggleIntegrationPin,
  executeIntegrationAction,
  getIntegrationIconData,
  batchLoadIcons,
  type IntegrationApp,
} from '../../lib/services/integrationService';

export default function IntegrationsScreen() {
  const [apps, setApps] = useState<IntegrationApp[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [showDiscoverModal, setShowDiscoverModal] = useState(false);
  const [discoverQuery, setDiscoverQuery] = useState('');
  const [isDiscovering, setIsDiscovering] = useState(false);

  // Load apps when screen is focused
  useFocusEffect(
    useCallback(() => {
      loadApps();
    }, [])
  );

  const loadApps = async () => {
    setIsLoading(true);
    try {
      const apps = await loadUserIntegrations();
      setApps(apps);

      // Preload icons
      const iconIds = apps
        .filter((app) => app.icon_id)
        .map((app) => app.icon_id!);
      if (iconIds.length > 0) {
        await batchLoadIcons(iconIds);
      }
    } catch (error) {
      console.error('Failed to load apps:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleDiscoverApps = async () => {
    if (!discoverQuery.trim()) return;

    setIsDiscovering(true);
    try {
      const discovered = await discoverAndAddApps(discoverQuery);
      if (discovered.length > 0) {
        // Refresh the list
        await loadApps();
        setShowDiscoverModal(false);
        setDiscoverQuery('');
      }
    } catch (error) {
      console.error('Discovery failed:', error);
    } finally {
      setIsDiscovering(false);
    }
  };

  const handleRemoveApp = async (appId: string) => {
    try {
      const success = await removeIntegrationApp(appId);
      if (success) {
        setApps((prev) => prev.filter((app) => app.id !== appId));
      }
    } catch (error) {
      console.error('Failed to remove app:', error);
    }
  };

  const handlePinApp = async (appId: string, isPinned: boolean) => {
    try {
      const success = await toggleIntegrationPin(appId, isPinned);
      if (success) {
        setApps((prev) =>
          prev.map((app) =>
            app.id === appId ? { ...app, is_pinned: isPinned } : app
          )
        );
      }
    } catch (error) {
      console.error('Failed to pin app:', error);
    }
  };

  const handleExecuteAction = async (appId: string, actionId: string) => {
    try {
      await executeIntegrationAction(appId, actionId);
    } catch (error) {
      console.error('Failed to execute action:', error);
      throw error;
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <IntegrationPanel
        apps={apps}
        isLoading={isLoading}
        onRefresh={loadApps}
        onAddApp={() => setShowDiscoverModal(true)}
        onRemoveApp={handleRemoveApp}
        onPinApp={handlePinApp}
        onExecuteAction={handleExecuteAction}
        onDiscoverApps={() => setShowDiscoverModal(true)}
        getIconData={getIntegrationIconData}
      />

      {/* Discover Modal */}
      <Modal
        visible={showDiscoverModal}
        animationType="slide"
        transparent={true}
        onRequestClose={() => setShowDiscoverModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Discover Apps</Text>
              <Pressable
                onPress={() => setShowDiscoverModal(false)}
                style={styles.modalCloseButton}
              >
                <Ionicons name="close" size={24} color={Colors.text} />
              </Pressable>
            </View>

            <View style={styles.modalBody}>
              <Text style={styles.modalSubtitle}>
                Describe the apps you want to integrate. Examples:
              </Text>
              <View style={styles.examplesList}>
                <Text style={styles.exampleItem}>
                  • "Add Spotify and YouTube to Music"
                </Text>
                <Text style={styles.exampleItem}>
                  • "Find my installed design apps"
                </Text>
                <Text style={styles.exampleItem}>
                  • "Add shopping apps: Amazon, eBay, Tesco"
                </Text>
              </View>

              <TextInput
                style={styles.discoverInput}
                placeholder="What apps do you want to add?"
                placeholderTextColor={Colors.textSecondary}
                value={discoverQuery}
                onChangeText={setDiscoverQuery}
                multiline
                editable={!isDiscovering}
              />

              <Pressable
                style={[
                  styles.discoverButton,
                  isDiscovering && styles.discoverButtonDisabled,
                ]}
                onPress={handleDiscoverApps}
                disabled={isDiscovering || !discoverQuery.trim()}
              >
                {isDiscovering ? (
                  <ActivityIndicator size="small" color="white" />
                ) : (
                  <>
                    <Ionicons name="sparkles" size={18} color="white" />
                    <Text style={styles.discoverButtonText}>Discover</Text>
                  </>
                )}
              </Pressable>

              <Text style={styles.safetyNote}>
                🔒 Discovery uses local AI (Ollama) and strict JSON validation.
                No data is sent to external servers.
              </Text>
            </View>
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.bg,
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
    paddingTop: 20,
    paddingHorizontal: 16,
    paddingBottom: 32,
    maxHeight: '80%',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  modalTitle: {
    color: Colors.text,
    fontSize: 20,
    fontWeight: '700',
  },
  modalCloseButton: {
    padding: 8,
  },
  modalBody: {
    paddingVertical: 12,
  },
  modalSubtitle: {
    color: Colors.text,
    fontSize: 14,
    fontWeight: '500',
    marginBottom: 12,
  },
  examplesList: {
    marginBottom: 16,
    paddingHorizontal: 8,
  },
  exampleItem: {
    color: Colors.textSecondary,
    fontSize: 12,
    marginBottom: 6,
    lineHeight: 16,
  },
  discoverInput: {
    backgroundColor: Colors.bg,
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    color: Colors.text,
    fontSize: 14,
    minHeight: 80,
    marginBottom: 16,
    textAlignVertical: 'top',
  },
  discoverButton: {
    flexDirection: 'row',
    backgroundColor: '#6366F1',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
    gap: 8,
    marginBottom: 12,
  },
  discoverButtonDisabled: {
    opacity: 0.5,
  },
  discoverButtonText: {
    color: 'white',
    fontSize: 14,
    fontWeight: '600',
  },
  safetyNote: {
    color: Colors.textSecondary,
    fontSize: 11,
    fontStyle: 'italic',
    textAlign: 'center',
    lineHeight: 14,
  },
});
