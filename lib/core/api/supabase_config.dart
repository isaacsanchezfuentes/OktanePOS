class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://placeholder.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_placeholder_key',
  );

  static const String bucketName = String.fromEnvironment(
    'SUPABASE_BUCKET',
    defaultValue: 'oktane-evidencias',
  );
}
