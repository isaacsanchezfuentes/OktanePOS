class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://hfyrdtekmajrsadnlxia.supabase.co',
  );

  static const String appName = 'Oktane POS';
}
