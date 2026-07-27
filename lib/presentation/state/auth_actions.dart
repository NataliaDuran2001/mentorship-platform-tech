// Capa Presentation (State): Acciones de autenticación.
//
// Es el único lugar de la capa Presentation que toca getIt. Los widgets llaman
// a estas funciones; no resuelven casos de uso ni construyen repositorios.
//
// Está separado de auth_state.dart por dos razones: el archivo de señales queda
// sin dependencias y testeable solo, y la lógica de sesión —arranque, stream de
// cambios, logout— necesita un hogar que no sea una página, porque más de una
// pantalla la usa.

import 'dart:async';

import '../../core/di/injection.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../utils/auth_error_messages.dart';
import 'auth_state.dart';
import 'onboarding_actions.dart';
import 'onboarding_state.dart';
import 'roadmap_state.dart';

StreamSubscription<AuthSession?>? _suscripcionSesion;

/// Deja el estado de autenticación listo antes de que se monte la UI.
///
/// Lee la sesión que el SDK ya restauró del almacenamiento —de ahí que
/// recargar la página no eche a nadie— y, si hay, trae el perfil. Se hace acá y
/// no dentro de los route guards para que el guard nunca tenga que decidir con
/// el perfil a medio cargar: cuando la app arranca, o hay sesión y perfil, o no
/// hay sesión.
Future<void> bootstrapAuth() async {
  final repositorio = getIt<AuthRepository>();

  currentSession.value = repositorio.currentSession;
  if (currentSession.value != null) {
    await refreshProfile();
  }

  _suscripcionSesion?.cancel();
  _suscripcionSesion = repositorio.sessionChanges.listen((sesion) async {
    final habiaSesion = currentSession.value != null;
    currentSession.value = sesion;

    if (sesion == null) {
      currentProfile.value = null;
      return;
    }
    // Al iniciar sesión trae el perfil; en un refresco de token ya lo tiene.
    if (!habiaSesion || currentProfile.value == null) {
      await refreshProfile();
    }
  });
}

/// Vuelve a leer el perfil de la usuaria autenticada.
///
/// Se llama después de entrar y cada vez que el onboarding cambia el perfil,
/// para que los route guards decidan con datos frescos.
Future<void> refreshProfile() async {
  try {
    final perfil = await getIt<OnboardingRepository>().loadProfile();
    currentProfile.value = perfil;

    // Onboarding a medio hacer: se reconstruye el estado parcial antes de que la
    // pantalla se monte, para aterrizar en el primer paso sin responder con lo
    // anterior ya marcado (issue #14). Acá y no en la página porque el route
    // guard decide a dónde ir antes de que exista ningún widget.
    if (perfil != null && !perfil.hasCompletedOnboarding) {
      await restoreOnboarding();
    }
  } catch (e) {
    // No se traduce a authError: el perfil se lee de fondo y un fallo acá no
    // debe pintar un error en la pantalla de login. El guard verá el perfil en
    // null y mandará al onboarding, que lo reintenta.
    currentProfile.value = null;
  }
}

/// Inicia sesión con correo y contraseña.
///
/// Devuelve `true` si quedó sesión abierta. Deja el mensaje de error, ya en
/// español, en [authError].
Future<bool> signInWithEmail() async {
  final email = loginEmail.value.trim();
  final password = loginPassword.value;

  if (email.isEmpty || password.isEmpty) {
    authError.value = 'Completá tu correo y tu contraseña.';
    return false;
  }

  authLoading.value = true;
  _limpiarError();

  try {
    final resultado = await getIt<SignInUseCase>()(
      email: email,
      password: password,
    );
    currentSession.value = resultado.session;
    if (resultado.session != null) await refreshProfile();

    // La contraseña no se queda en memoria más de lo necesario.
    loginPassword.value = '';
    return resultado.isSignedIn;
  } catch (e) {
    _registrarError(e);
    return false;
  } finally {
    authLoading.value = false;
  }
}

/// Registra una cuenta nueva.
///
/// Con la confirmación por correo activa el caso normal es que NO haya sesión:
/// se deja el correo en [pendingConfirmationEmail] y la pantalla muestra
/// «revisá tu correo». Devuelve `true` si el registro salió bien, con o sin
/// sesión.
Future<bool> signUpWithEmail() async {
  final email = signUpEmail.value.trim();
  final password = signUpPassword.value;
  final nombre = signUpName.value.trim();

  if (email.isEmpty || password.isEmpty) {
    authError.value = 'Completá tu correo y tu contraseña.';
    return false;
  }

  authLoading.value = true;
  _limpiarError();

  try {
    final resultado = await getIt<SignUpUseCase>()(
      email: email,
      password: password,
      displayName: nombre.isEmpty ? null : nombre,
    );

    if (resultado.requiresEmailConfirmation) {
      pendingConfirmationEmail.value = email;
    } else {
      currentSession.value = resultado.session;
      await refreshProfile();
    }

    signUpPassword.value = '';
    return true;
  } catch (e) {
    _registrarError(e);
    return false;
  } finally {
    authLoading.value = false;
  }
}

/// Reenvía el correo de confirmación al [email] indicado, o al que quedó
/// pendiente del último registro.
Future<void> resendConfirmationEmail({String? email}) async {
  final destino = email ?? pendingConfirmationEmail.value;
  if (destino == null || destino.isEmpty) return;

  authLoading.value = true;
  _limpiarError();
  confirmationEmailResent.value = false;

  try {
    await getIt<AuthRepository>().resendConfirmationEmail(email: destino);
    confirmationEmailResent.value = true;
  } catch (e) {
    _registrarError(e);
  } finally {
    authLoading.value = false;
  }
}

/// Cierra la sesión y limpia todo el estado derivado.
Future<void> signOut() async {
  authLoading.value = true;
  try {
    await getIt<SignOutUseCase>()();
  } catch (e) {
    _registrarError(e);
  } finally {
    // Se limpia incluso si el backend falló: dejar la app «con sesión» después
    // de que la usuaria pidió salir es peor que un logout solo local.
    currentSession.value = null;
    currentProfile.value = null;
    pendingConfirmationEmail.value = null;
    limpiarFormulariosDeAuth();
    // El onboarding de la usuaria que se va no puede quedar cargado para la que
    // entre después.
    cancelOnboardingTimers();
    resetOnboarding();
    resetRoadmap();
    authLoading.value = false;
  }
}

/// Guarda el mensaje traducido y el tipo del fallo.
///
/// El tipo lo necesita la UI para decidir *qué* ofrecer, no *qué decir*: hoy,
/// mostrar el reenvío del correo solo cuando la cuenta existe y falta
/// confirmarla.
void _limpiarError() {
  authError.value = null;
  authErrorKind.value = null;
}

void _registrarError(Object e) {
  authError.value = mensajeDeError(e);
  authErrorKind.value = e is AuthFailure ? e.kind : AuthFailureKind.unknown;
}

/// Corta la escucha del stream de sesión. Para los tests.
Future<void> disposeAuthListener() async {
  await _suscripcionSesion?.cancel();
  _suscripcionSesion = null;
}
