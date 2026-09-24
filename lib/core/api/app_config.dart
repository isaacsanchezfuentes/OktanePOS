class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.oktane-pos.com/api/v1',
  );

  static const String appName = 'Oktane POS';
}
