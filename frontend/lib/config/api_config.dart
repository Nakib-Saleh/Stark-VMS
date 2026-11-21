/// Central API configuration for Stark Group VMS.
class ApiConfig {
  ApiConfig._();

  /// Base URL of the Spring Boot REST API. Set at build time (ADR-0008):
  /// `flutter build web --dart-define=API_BASE_URL=https://<api>/api`. Not a secret: everything in
  /// this app ships to the browser. Default: the local backend (`server.port=9001`).
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:9001/api');

  static const Duration connectTimeout = Duration(seconds: 30);
  // A sleeping free-tier API takes up to a minute to answer its first request; the waking notice
  // tells the user meanwhile. shortcut: one long timeout for all calls; split per call if a
  // request ever needs to fail fast.
  static const Duration receiveTimeout = Duration(seconds: 90);
  static const Duration sendTimeout = Duration(seconds: 15);

  static const int defaultPageSize = 10;
}
