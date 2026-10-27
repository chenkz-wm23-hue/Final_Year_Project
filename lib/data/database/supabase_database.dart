import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';

/// Initializes the public client and restores its locally persisted Auth session.
class SupabaseDatabase {
  static Future<Supabase> connect() => Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
}
