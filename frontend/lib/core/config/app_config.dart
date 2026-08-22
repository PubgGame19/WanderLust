class AppConfig {
  /// Base host/URL configurable via --dart-define=API_BASE_URL=http://192.168.1.5:8000
  /// Defaults to http://192.168.1.5:8000 for LAN/physical device development.
  static const String rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.5:8000',
  );

  /// Optional Google Web / Server Client ID for token exchange
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
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
