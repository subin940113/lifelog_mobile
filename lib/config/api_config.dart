class ApiConfig {
  /// Base URL for all API calls
  ///
  /// Override with:
  /// flutter run --dart-define=API_BASE_URL=http://<host>:8080
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '737064199460-uv468beoijmibisraq9vqb75nf78d1al.apps.googleusercontent.com',
  );
}