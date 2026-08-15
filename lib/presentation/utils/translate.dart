// Presentation layer (Util): The app's translation mechanism.
//
// No flutter_localizations/ARB/codegen: this app is StatelessWidget +
// global signals everywhere, so the translation lookup is the same shape —
// a plain function reading the global `appLanguage` signal. Call sites read
// both languages at once (`tr('Continue', 'Continuar')`), so there is no
// separate catalog file to keep in sync, and no key to look up.
//
// Reads a signal, so it must be called from inside a reactive scope
// (a `SignalBuilder`) to repaint when the language changes.

import '../state/language_state.dart';
import '../../domain/entities/app_language.dart';

String tr(String en, String es) =>
    appLanguage.value == AppLanguage.es ? es : en;
