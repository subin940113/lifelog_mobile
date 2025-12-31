class ApiConfig {
  /// Base URL for all API calls
  ///
  /// Override with:
  /// flutter run --dart-define=API_BASE_URL=http://<host>:8080
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}