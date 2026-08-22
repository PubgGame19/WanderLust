class AppConfig {
  /// Base host/URL configurable via --dart-define=API_BASE_URL=...
  ///
  /// For Chrome/Web (default): http://localhost:8000
  /// For Android Emulator: --dart-define=API_BASE_URL=http://10.0.2.2:8000
  /// For Physical Android Device: --dart-define=API_BASE_URL=http://10.215.87.56:8000
  static const String rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000', // Chrome/Web default
  );

  /// Optional Google Web / Server Client ID for token exchange
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '316021706414-3rpo04ec89a9f36g28h0trqg92stkkps.apps.googleusercontent.com',
  );

  /// Normalized API v1 base URL for all mobile service calls.
  static String get apiBaseUrl {
    final trimmed = rawBaseUrl.trim();
    final sanitized = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;

    if (sanitized.endsWith('/api/v1')) {
      return sanitized;
    }
    return '$sanitized/api/v1';
  }
}
