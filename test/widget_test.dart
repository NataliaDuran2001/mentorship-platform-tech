// Pruebas de widget de la app: pantallas de autenticación, route guards y
// shell de navegación (issues #1, #5, #9).
//
// Los signals de auth_state son globales al proceso y el GoRouter de AppRouter
// es una instancia única, así que cada prueba reinicia ambos en setUp para no
// heredar el estado de la anterior.
//
// La autenticación se ejercita contra dobles de los repositorios registrados en
// getIt: no se toca Supabase ni la red. Es lo que permite probar el login, el
// registro, el logout y los tres guards en la suite normal, que corre en
// segundos.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/core/di/injection.dart';
import 'package:aspire_app/core/router/app_router.dart';
import 'package:aspire_app/domain/entities/auth_session.dart';
import 'package:aspire_app/domain/entities/experience_level.dart';
import 'package:aspire_app/domain/entities/learning_goal.dart';
import 'package:aspire_app/domain/entities/onboarding_answer.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/domain/entities/user_profile.dart';
import 'package:aspire_app/domain/failures/auth_failure.dart';
import 'package:aspire_app/domain/repositories/auth_repository.dart';
import 'package:aspire_app/domain/repositories/onboarding_repository.dart';
import 'package:aspire_app/domain/usecases/sign_in_usecase.dart';
import 'package:aspire_app/domain/usecases/sign_out_usecase.dart';
import 'package:aspire_app/domain/usecases/sign_up_usecase.dart';
import 'package:aspire_app/main.dart';
import 'package:aspire_app/presentation/state/auth_state.dart';
import 'package:aspire_app/presentation/widgets/pages/chat_page.dart';
import 'package:aspire_app/presentation/widgets/pages/dashboard_page.dart';
import 'package:aspire_app/presentation/widgets/pages/login_page.dart';
import 'package:aspire_app/presentation/widgets/pages/onboarding_page.dart';
import 'package:aspire_app/presentation/widgets/pages/sign_up_page.dart';

// ---------------------------------------------------------------------------
// Dobles de prueba
// ---------------------------------------------------------------------------

/// Repositorio de autenticación en memoria.
///
/// Devuelve lo que se le configure y registra qué se le pidió. Lanza
/// `AuthFailure` igual que el real, porque parte de lo que se prueba es que la
/// UI traduzca esos fallos a mensajes en español.
class FakeAuthRepository implements AuthRepository {
  AuthSession? sesionAlIngresar;
  AuthFailure? falloAlIngresar;
  AuthFailure? falloAlRegistrar;
  bool registroExigeConfirmacion = true;

  int reenvios = 0;
  int cierresDeSesion = 0;
  String? ultimoCorreoDeReenvio;

  final StreamController<AuthSession?> _cambios =
      StreamController<AuthSession?>.broadcast();

  @override
  AuthSession? currentSession;

  @override
  Stream<AuthSession?> get sessionChanges => _cambios.stream;

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (falloAlIngresar != null) throw falloAlIngresar!;
    currentSession = sesionAlIngresar;
    return AuthResult(session: sesionAlIngresar);
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (falloAlRegistrar != null) throw falloAlRegistrar!;
    return AuthResult(
      requiresEmailConfirmation: registroExigeConfirmacion,
      session: registroExigeConfirmacion ? null : sesionAlIngresar,
    );
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    throw UnimplementedError('issue #15');
  }

  @override
  Future<void> signOut() async {
    cierresDeSesion++;
    currentSession = null;
  }

  @override
  Future<void> resendConfirmationEmail({required String email}) async {
    reenvios++;
    ultimoCorreoDeReenvio = email;
  }

  void cerrar() => _cambios.close();
}

/// Repositorio de onboarding en memoria. Solo devuelve el perfil configurado.
class FakeOnboardingRepository implements OnboardingRepository {
  UserProfile? perfil;

  @override
  Future<UserProfile?> loadProfile() async => perfil;

  @override
  Future<List<OnboardingAnswer>> loadAnswers() async =>
      const <OnboardingAnswer>[];

  @override
  Future<void> saveAnswer(OnboardingAnswer answer) async {}

  @override
  Future<UserProfile> completeOnboarding({
    required ExperienceLevel experienceLevel,
    required RoadmapTrack track,
    required LearningGoal learningGoal,
  }) async {
    throw UnimplementedError();
  }
}

// ---------------------------------------------------------------------------
// Utilidades
// ---------------------------------------------------------------------------

const _sesion = AuthSession(userId: 'u1', email: 'ana@example.com');

/// Perfil recién creado por el trigger: sin nada del onboarding.
const _perfilIncompleto = UserProfile(id: 'u1', email: 'ana@example.com');

/// Perfil con el onboarding terminado. Necesita track y marca de tiempo.
final _perfilCompleto = UserProfile(
  id: 'u1',
  email: 'ana@example.com',
  experienceLevel: ExperienceLevel.juniorDeveloper,
  track: RoadmapTrack.frontend,
  learningGoal: LearningGoal.firstJob,
  onboardingCompletedAt: DateTime(2026, 7, 26),
);

/// Fija el tamaño lógico de la ventana de prueba (devicePixelRatio 1).
void _fijarVentana(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Amplía la ventana: el formulario completo no cabe en los 800x600 por
/// defecto y el desborde ensuciaría las aserciones.
void _ampliarVentana(WidgetTester tester) =>
    _fijarVentana(tester, const Size(1200, 2000));

/// Deja la app con sesión y onboarding terminado.
void _conSesionCompleta() {
  currentSession.value = _sesion;
  currentProfile.value = _perfilCompleto;
}

void main() {
  late FakeAuthRepository auth;
  late FakeOnboardingRepository onboarding;

  setUp(() {
    auth = FakeAuthRepository();
    onboarding = FakeOnboardingRepository();

    overrideDependency<AuthRepository>(auth);
    overrideDependency<OnboardingRepository>(onboarding);
    overrideDependency(SignInUseCase(auth));
    overrideDependency(SignUpUseCase(auth));
    overrideDependency(SignOutUseCase(auth));

    currentSession.value = null;
    currentProfile.value = null;
    authLoading.value = false;
    pendingConfirmationEmail.value = null;
    limpiarFormulariosDeAuth();
    AppRouter.router.go('/login');
  });

  tearDown(() => auth.cerrar());

  group('LoginPage', () {
    testWidgets('monta y renderiza sus textos en español', (tester) async {
      _ampliarVentana(tester);

      await tester.pumpWidget(const MyApp());

      expect(find.text('Bienvenida'), findsOneWidget);
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Ingresar'), findsOneWidget);
      expect(find.text('O'), findsOneWidget);
      // El registro tiene que estar a un toque: antes no había forma de crear
      // una cuenta.
      expect(find.text('Registrate'), findsOneWidget);
    });

    testWidgets('el botón de Google está visible pero deshabilitado (#15)',
        (tester) async {
      _ampliarVentana(tester);

      await tester.pumpWidget(const MyApp());

      final boton = find.widgetWithText(OutlinedButton, 'Iniciar con Google');
      expect(boton, findsOneWidget);
      // Visible pero sin cablear: ni siquiera a un stub que falla.
      expect(tester.widget<OutlinedButton>(boton).onPressed, isNull);
    });

    testWidgets('con authLoading activo se muestra el indicador',
        (tester) async {
      _ampliarVentana(tester);
      authLoading.value = true;

      await tester.pumpWidget(const MyApp());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Iniciar con Google'),
        findsNothing,
      );
    });

    testWidgets('sin completar los campos avisa en español y no llama al '
        'backend', (tester) async {
      _ampliarVentana(tester);
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();

      expect(find.text('Completá tu correo y tu contraseña.'), findsOneWidget);
      expect(currentSession.value, isNull);
    });
  });

  group('Login contra el repositorio', () {
    testWidgets('credenciales correctas abren sesión y el guard mueve al '
        'onboarding', (tester) async {
      _ampliarVentana(tester);
      auth.sesionAlIngresar = _sesion;
      onboarding.perfil = _perfilIncompleto;

      await tester.pumpWidget(const MyApp());

      await tester.enterText(find.byType(TextField).first, 'ana@example.com');
      await tester.enterText(find.byType(TextField).last, 'secreta123');
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();

      expect(currentSession.value, isNotNull);
      expect(isAuthenticated.value, isTrue);
      // Perfil sin onboarding: el guard manda al onboarding, no al dashboard.
      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.path,
        '/onboarding',
      );
    });

    testWidgets('una cuenta sin confirmar falla en español y ofrece reenviar',
        (tester) async {
      _ampliarVentana(tester);
      auth.falloAlIngresar =
          const AuthFailure(AuthFailureKind.emailNotConfirmed);

      await tester.pumpWidget(const MyApp());

      await tester.enterText(find.byType(TextField).first, 'ana@example.com');
      await tester.enterText(find.byType(TextField).last, 'secreta123');
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Tu cuenta todavía no está confirmada'),
        findsOneWidget,
      );
      // Sin sesión, y sin ningún texto crudo del backend a la vista.
      expect(currentSession.value, isNull);
      expect(find.textContaining('Email not confirmed'), findsNothing);

      // El reenvío se ofrece solo en este caso.
      final reenviar = find.text('Reenviar el correo de confirmación');
      expect(reenviar, findsOneWidget);

      await tester.tap(reenviar);
      await tester.pumpAndSettle();

      expect(auth.reenvios, 1);
      expect(auth.ultimoCorreoDeReenvio, 'ana@example.com');
    });

    testWidgets('credenciales inválidas no ofrecen reenviar el correo',
        (tester) async {
      _ampliarVentana(tester);
      auth.falloAlIngresar =
          const AuthFailure(AuthFailureKind.invalidCredentials);

      await tester.pumpWidget(const MyApp());

      await tester.enterText(find.byType(TextField).first, 'ana@example.com');
      await tester.enterText(find.byType(TextField).last, 'incorrecta');
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();

      expect(
        find.text('El correo o la contraseña no son correctos.'),
        findsOneWidget,
      );
      expect(find.text('Reenviar el correo de confirmación'), findsNothing);
    });

    testWidgets('un error de red se muestra traducido', (tester) async {
      _ampliarVentana(tester);
      auth.falloAlIngresar = const AuthFailure(
        AuthFailureKind.network,
        technicalDetail: 'SocketException: Failed host lookup',
      );

      await tester.pumpWidget(const MyApp());

      await tester.enterText(find.byType(TextField).first, 'ana@example.com');
      await tester.enterText(find.byType(TextField).last, 'secreta123');
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No pudimos conectarnos'), findsOneWidget);
      expect(find.textContaining('SocketException'), findsNothing);
    });
  });

  group('Registro', () {
    testWidgets('un registro exitoso muestra «revisá tu correo», no una sesión',
        (tester) async {
      _ampliarVentana(tester);
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('Registrate'));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpPage), findsOneWidget);
      expect(find.text('Crear cuenta'), findsOneWidget);

      // Nombre, correo y contraseña, en ese orden.
      final campos = find.byType(TextField);
      await tester.enterText(campos.at(1), 'nueva@example.com');
      await tester.enterText(campos.at(2), 'secreta123');
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();

      // Con mailer_autoconfirm en false no hay sesión: hay que confirmar.
      expect(currentSession.value, isNull);
      expect(find.text('Revisá tu correo'), findsOneWidget);
      expect(
        find.textContaining('Te enviamos un correo a nueva@example.com'),
        findsOneWidget,
      );

      await tester.tap(find.text('No me llegó, reenviar el correo'));
      await tester.pumpAndSettle();

      expect(auth.reenvios, 1);
      expect(find.text('Correo reenviado.'), findsOneWidget);
    });

    testWidgets('un correo ya registrado avisa en español', (tester) async {
      _ampliarVentana(tester);
      auth.falloAlRegistrar =
          const AuthFailure(AuthFailureKind.emailAlreadyRegistered);

      await tester.pumpWidget(const MyApp());
      await tester.tap(find.text('Registrate'));
      await tester.pumpAndSettle();

      final campos = find.byType(TextField);
      await tester.enterText(campos.at(1), 'ana@example.com');
      await tester.enterText(campos.at(2), 'secreta123');
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Ya existe una cuenta con ese correo'),
        findsOneWidget,
      );
      expect(find.text('Revisá tu correo'), findsNothing);
    });
  });

  group('Route guards', () {
    testWidgets('sin sesión, el acceso directo por URL a una ruta protegida '
        'cae en el login', (tester) async {
      _ampliarVentana(tester);

      AppRouter.router.go('/dashboard');
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.path,
        '/login',
      );
      // El login vive fuera del shell: sin bottom nav ni sidebar.
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('con sesión y onboarding incompleto, cualquier ruta cae en el '
        'onboarding', (tester) async {
      _ampliarVentana(tester);
      currentSession.value = _sesion;
      currentProfile.value = _perfilIncompleto;

      AppRouter.router.go('/dashboard');
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsOneWidget);
      // El onboarding también vive fuera del shell.
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byIcon(Icons.menu), findsNothing);
    });

    testWidgets('con el onboarding completo, login y onboarding redirigen al '
        'dashboard', (tester) async {
      _ampliarVentana(tester);
      _conSesionCompleta();

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(DashboardPage), findsOneWidget);

      AppRouter.router.go('/onboarding');
      await tester.pumpAndSettle();

      expect(find.byType(DashboardPage), findsOneWidget);
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.path,
        '/dashboard',
      );
    });

    testWidgets('un perfil con marca de tiempo pero sin track no cuenta como '
        'completo', (tester) async {
      _ampliarVentana(tester);
      currentSession.value = _sesion;
      // Es el estado que la política del #14 prohíbe dejar pasar al dashboard.
      currentProfile.value = _perfilIncompleto.copyWith(
        onboardingCompletedAt: DateTime(2026, 7, 26),
      );

      AppRouter.router.go('/dashboard');
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsOneWidget);
    });
  });

  group('Logout', () {
    testWidgets('cerrar sesión desde el shell vuelve al login y limpia el '
        'estado', (tester) async {
      _ampliarVentana(tester); // escritorio: la sidebar tiene la acción
      _conSesionCompleta();

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(DashboardPage), findsOneWidget);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(auth.cierresDeSesion, 1);
      expect(currentSession.value, isNull);
      expect(currentProfile.value, isNull);
      expect(isAuthenticated.value, isFalse);
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });

  group('Shell de navegación', () {
    testWidgets('se navega entre los destinos y la URL lo refleja',
        (tester) async {
      _ampliarVentana(tester); // 1200 lógicos: modo escritorio con sidebar
      _conSesionCompleta();

      AppRouter.router.go('/dashboard');
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(DashboardPage), findsOneWidget);

      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      expect(find.byType(ChatPage), findsOneWidget);
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.path,
        '/chat',
      );
    });

    testWidgets('cambia de forma en los breakpoints 480 y 768', (tester) async {
      _conSesionCompleta();

      // Móvil (≤480): bottom nav, sin drawer ni sidebar.
      _fijarVentana(tester, const Size(440, 900));
      AppRouter.router.go('/dashboard');
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsNothing);

      // Rango intermedio (481–768): bottom nav + drawer (hamburguesa).
      tester.view.physicalSize = const Size(600, 900);
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);

      // Escritorio (>768): sidebar fija, sin bottom nav ni hamburguesa.
      tester.view.physicalSize = const Size(1200, 900);
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byIcon(Icons.menu), findsNothing);
      expect(find.text('Dashboard'), findsWidgets); // sidebar + placeholder
    });
  });
}
