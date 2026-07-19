// Capa Presentation (State): Manejo de estado de la UI usando la librería signals.
// Es un acercamiento reactivo, sencillo y directo.

import 'package:signals_flutter/signals_flutter.dart';

// Signals que guardan estado global o local relacionado a la autenticación.
final isAuthenticated = signal<bool>(false);
final authLoading = signal<bool>(false);
