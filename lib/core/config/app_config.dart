class AppConfig {
  static const bool demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: false);
  static const String apiBase = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://localhost:8000/api/v1');
}
