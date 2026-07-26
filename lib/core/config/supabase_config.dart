// Capa Core: Configuración transversal de Supabase (credenciales e inicialización).
// Ninguna otra capa debe llamar a Supabase.initialize ni leer las credenciales
// directamente; el acceso al cliente se hace por get_it (ver di/injection.dart).

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  // La URL y la clave publishable son valores públicos por diseño: el cliente
  // los expone en cualquier build. La protección real de los datos vive en las
  // políticas RLS de la base de datos, no en ocultar esta clave.
  // Se pueden sobreescribir por entorno sin tocar el código, por ejemplo:
  //   fvm flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dtvfucqamakudgbwuhbw.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'sb_publishable_bAzEua7Wl02VoNofOuI7_g_iSXKUIwv',
  );

  /// Arranca el SDK de Supabase. Debe llamarse en main() antes de runApp().
  static Future<void> initialize() async {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }

  /// Cliente ya inicializado. Solo para el registro en get_it.
  static SupabaseClient get client => Supabase.instance.client;
}
