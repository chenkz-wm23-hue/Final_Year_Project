/// Publishable client configuration, not a secret or privileged server key.
class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://plmmhvvxsqiudqqrfijl.supabase.co',
  );
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_uIxW5UViV_eAJE44T01YjA_R-DemFRX',
  );
}
