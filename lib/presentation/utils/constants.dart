// Presentation layer (Utils): Global interface constants taken from the
// DESIGN.md frontmatter (Luminous Clarity): spacing scale on a 4px grid,
// border radii, layout widths and responsive breakpoints.

class AppConstants {
  // Spacing scale (4px grid)
  static const double spacingUnit = 4.0;
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 40.0;

  // Historical alias of the base padding step; the existing widgets multiply
  // it for larger gaps.
  static const double defaultPadding = spacingMd;

  // Border radii
  static const double radiusSm = 4.0;
  static const double radiusDefault = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 9999.0;

  // Historical alias of the default radius.
  static const double borderRadius = radiusDefault;

  // Layout
  static const double containerMax = 1200.0;
  static const double sidebarWidth = 260.0;
  // Maximum readable width for text-heavy views.
  static const double maxReadableWidth = 800.0;

  // Responsive breakpoints
  // ≤768: the sidebar collapses into a drawer. ≤480: margins drop to 16.
  static const double breakpointTablet = 768.0;
  static const double breakpointMobile = 480.0;

  // Border widths
  static const double borderWidth = 1.0;
  static const double borderWidthThick = 2.0;

  // Sizes of the onboarding components (issue #10). They live here and not in
  // the widgets so that the "no literal values in widgets" rule also holds for
  // dimensions, not just for colors and spacing.
  static const double progressBarHeight = 4.0;
  static const double iconTileSize = 48.0;
  /// Small icon, the one used by the states of the topic tree.
  static const double iconSizeSm = 20.0;

  /// Large icon, the one that carries the message on a full-screen outcome
  /// such as the email confirmation landing.
  static const double iconSizeLg = 48.0;

  /// Celebration icon, only for the screen that closes a completed lab.
  static const double iconSizeCelebration = 80.0;

  static const double radioSize = 24.0;
  static const double radioDotSize = 12.0;

  /// Width below which the onboarding footer stacks instead of putting its
  /// three buttons in a row. It is not a screen breakpoint: it is the width of
  /// the footer itself, which on mobile ends up much narrower than the window.
  static const double footerCompactWidth = 360.0;

  // Transition durations from the prototype.
  // fast: color and opacity changes. medium: transition between steps.
  // slow: the progress bar, the slowest one on purpose.
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 400);
  static const Duration durationSlow = Duration(milliseconds: 600);
}
