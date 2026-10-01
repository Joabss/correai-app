/// Base URL of the CorreAI API. Override with:
/// flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.100.76:8080',
);
