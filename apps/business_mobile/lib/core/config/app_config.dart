class AppConfig {
  static const String appName = 'Nusa Dhipa Business OS';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8300',
  );
}
