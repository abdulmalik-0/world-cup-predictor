/// Copy to supabase_config.dart and fill in your project values.
/// supabase_config.dart is gitignored — never commit real keys.
class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_ANON_PUBLIC_KEY',
  );

  static bool get isConfigured =>
      !url.contains('YOUR_PROJECT') && !publishableKey.contains('YOUR_ANON');
}
