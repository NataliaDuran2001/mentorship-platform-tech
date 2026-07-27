// Capa Presentation (State): Estado de autenticación con signals.
//
// Este archivo solo declara señales; quien las llena es auth_actions.dart. La
// separación es a propósito: así el estado se puede leer y resetear desde un
// test sin arrastrar getIt ni Supabase.
//
// `isAuthenticated` es un `computed` derivado de la sesión real, no un booleano
// que la UI pone en `true` a mano como en el andamio original: era la deuda 3
// de la §3 del handoff. Ahora es imposible que la app se crea autenticada sin
// tener sesión.

import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/failures/auth_failure.dart';

/// Sesión vigente, o `null` si no hay. La escriben el arranque y el stream de
/// cambios de sesión del repositorio.
final currentSession = signal<AuthSession?>(null);

/// Perfil de la usuaria autenticada. `null` sin sesión o si todavía no se leyó.
final currentProfile = signal<UserProfile?>(null);

/// Hay sesión. Derivado, no escribible.
final isAuthenticated = computed(() => currentSession.value != null);

/// El onboarding está terminado. Exige track además de la marca de tiempo, así
/// que ningún camino lleva al dashboard con `track_id` nulo.
final hasCompletedOnboarding =
    computed(() => currentProfile.value?.hasCompletedOnboarding ?? false);

/// Hay una operación de autenticación en curso.
final authLoading = signal<bool>(false);

/// Mensaje de error en español, ya traducido. `null` si no hay error.
final authError = signal<String?>(null);

/// Tipo del último fallo, para las decisiones de la UI que dependen de *cuál*
/// error fue y no de su texto. Hoy la única: ofrecer el reenvío del correo solo
/// cuando la cuenta existe y falta confirmarla.
final authErrorKind = signal<AuthFailureKind?>(null);

/// Correo que quedó esperando confirmación después de un registro exitoso.
///
/// Con `mailer_autoconfirm: false` el registro no devuelve sesión, así que este
/// es el estado «revisá tu correo»: la pantalla de registro lo muestra y ofrece
/// reenviar el correo.
final pendingConfirmationEmail = signal<String?>(null);

/// Confirmación de que el correo se reenvió, para dar feedback visible.
final confirmationEmailResent = signal<bool>(false);

// ---------------------------------------------------------------------------
// Campos de los formularios
//
// Viven en señales y no en TextEditingController porque los widgets del
// proyecto son StatelessWidget: un controller necesitaría un State que lo
// libere. La contrapartida es que la contraseña queda en memoria global, así
// que se limpia en cuanto se usa (ver limpiarFormulariosDeAuth).
// ---------------------------------------------------------------------------

final loginEmail = signal<String>('');
final loginPassword = signal<String>('');
final signUpName = signal<String>('');
final signUpEmail = signal<String>('');
final signUpPassword = signal<String>('');

/// Vacía los campos y los mensajes. Se llama al entrar y al salir de las
/// pantallas de autenticación, y después de cada envío exitoso.
void limpiarFormulariosDeAuth() {
  loginEmail.value = '';
  loginPassword.value = '';
  signUpName.value = '';
  signUpEmail.value = '';
  signUpPassword.value = '';
  authError.value = null;
  authErrorKind.value = null;
  confirmationEmailResent.value = false;
}
