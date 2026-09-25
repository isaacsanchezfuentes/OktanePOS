class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hfyrdtekmajrsadnlxia.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_7abhSIG0uLBPzHpUEPbX5w_8vHx1K9N',
  );

  static const String bucketName = String.fromEnvironment(
    'SUPABASE_BUCKET',
    defaultValue: 'oktane-evidencias',
  );
}
