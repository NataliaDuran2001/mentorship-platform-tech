// Capa Presentation (Utils): Constantes globales de la interfaz según el
// frontmatter de DESIGN.md (Luminous Clarity): escala de spacing en grid de
// 4px, radios de borde, anchos de layout y breakpoints responsivos.

class AppConstants {
  // Escala de spacing (grid de 4px)
  static const double spacingUnit = 4.0;
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 40.0;

  // Alias histórico del paso base de padding; los widgets existentes lo
  // multiplican para huecos mayores.
  static const double defaultPadding = spacingMd;

  // Radios de borde
  static const double radiusSm = 4.0;
  static const double radiusDefault = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 9999.0;

  // Alias histórico del radio por defecto.
  static const double borderRadius = radiusDefault;

  // Layout
  static const double containerMax = 1200.0;
  static const double sidebarWidth = 260.0;
  // Ancho máximo legible para vistas con mucho texto.
  static const double maxReadableWidth = 800.0;

  // Breakpoints responsivos
  // ≤768: la sidebar colapsa a drawer. ≤480: los márgenes bajan a 16.
  static const double breakpointTablet = 768.0;
  static const double breakpointMobile = 480.0;

  // Grosores de borde
  static const double borderWidth = 1.0;
  static const double borderWidthThick = 2.0;

  // Tamaños de componentes del onboarding (issue #10). Viven acá y no en los
  // widgets para que la regla «cero valores literales en widgets» se sostenga
  // también para dimensiones, no solo para colores y spacing.
  static const double progressBarHeight = 4.0;
  static const double iconTileSize = 48.0;
  /// Ícono chico, el de los estados del árbol de tópicos.
  static const double iconSizeSm = 20.0;

  static const double radioSize = 24.0;
  static const double radioDotSize = 12.0;

  /// Ancho por debajo del cual el pie del onboarding se apila en vez de poner
  /// sus tres botones en una fila. No es un breakpoint de pantalla: es el ancho
  /// del propio pie, que en móvil queda mucho más angosto que la ventana.
  static const double footerCompactWidth = 360.0;

  // Duraciones de transición del prototipo.
  // fast: cambios de color y opacidad. medium: transición entre pasos.
  // slow: la barra de progreso, que es la más lenta a propósito.
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 400);
  static const Duration durationSlow = Duration(milliseconds: 600);
}
