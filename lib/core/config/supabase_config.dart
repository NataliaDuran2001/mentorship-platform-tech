// Core layer: Cross-cutting Supabase configuration (credentials and
// initialization). No other layer should call Supabase.initialize nor read the
// credentials directly; access to the client goes through get_it (see
// di/injection.dart).

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  // The URL and the publishable key are public values by design: the client
  // exposes them in any build. The real protection of the data lives in the
  // RLS policies of the database, not in hiding this key.
  // They can be overridden per environment without touching the code, for
  // example:
  //   fvm flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dtvfucqamakudgbwuhbw.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'sb_publishable_bAzEua7Wl02VoNofOuI7_g_iSXKUIwv',
  );

  /// Boots the Supabase SDK. Must be called in main() before runApp().
  static Future<void> initialize() async {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }

  /// Already initialized client. Only for the get_it registration.
  static SupabaseClient get client => Supabase.instance.client;
}
