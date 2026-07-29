// Domain layer: Failure vocabulary for AI features (pure Dart).
//
// The data layer (AiRepositoryImpl) translates Edge Function HTTP errors,
// network failures and JSON parsing errors into these typed cases so that
// the presentation layer never imports dart:io or supabase_flutter.
//
// The strategy for AI failures is graceful degradation: most AI features
// have a fallback (the vote-count rule for track recommendation, a generic
// message for the daily brief). The failure is surfaced to the caller so
// it can decide to fall back silently or show a UI hint.

/// Reason categories for an AI call failure.
enum AiFailureKind {
  /// The Kimi API key is missing or invalid.
  unauthorized,

  /// The Edge Function or the Moonshot AI API could not be reached.
  network,

  /// The AI returned a response that could not be parsed or is invalid.
  invalidResponse,

  /// The AI service is temporarily at capacity.
  serviceUnavailable,

  /// The request was rate-limited by the Moonshot AI API.
  rateLimited,

  /// Anything else.
  unknown,
}

class AiFailure implements Exception {
  const AiFailure(this.kind, {this.technicalDetail});

  final AiFailureKind kind;

  /// Original error message. For diagnostics and logs only.
  final String? technicalDetail;

  @override
  String toString() => 'AiFailure(${kind.name}): ${technicalDetail ?? '-'}';
}
