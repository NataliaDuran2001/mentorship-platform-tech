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

  /// Where the confirmation email sends the user back (issue #34).
  ///
  /// It is derived from the origin the app is actually running on instead of
  /// being hardcoded, so the same build works on localhost and on a real
  /// domain. Supabase's redirect allow-list still has to authorize it: it is
  /// an explicit list, and a URL that is not on it silently falls back to the
  /// Site URL.
  ///
  /// The `/#/` is not decoration: Flutter Web routes with the hash strategy,
  /// so that is the shape of every route in this app.
  static String get emailRedirectTo {
    const override = String.fromEnvironment('SUPABASE_EMAIL_REDIRECT');
    if (override.isNotEmpty) return override;
    return '${Uri.base.origin}/#/auth/confirmed';
  }

  /// Boots the Supabase SDK. Must be called in main() before runApp().
  static Future<void> initialize() async {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }

  /// Already initialized client. Only for the get_it registration.
  static SupabaseClient get client => Supabase.instance.client;
}
