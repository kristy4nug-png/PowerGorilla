import { StatusBar } from 'expo-status-bar';
import { StyleSheet, Text, View } from 'react-native';

export default function App() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Phat Gorrilla</Text>
      <Text style={styles.subtitle}>Local-first command centre</Text>
      <StatusBar style="light" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#05090d',
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: {
    color: '#f8f7ff',
    fontSize: 28,
    fontWeight: '800',
  },
  subtitle: {
    color: '#20f08a',
    fontSize: 14,
    marginTop: 8,
  },
});
