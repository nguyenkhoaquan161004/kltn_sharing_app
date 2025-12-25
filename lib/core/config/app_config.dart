/// Application configuration constants
class AppConfig {
  /// Production backend API URL
  static const String productionUrl = 'https://shareo.studio';

  /// Get current base URL (always production)
  static const String baseUrl = productionUrl;

  /// Initialize - call this once at app startup
  static void initialize() {
    print('[AppConfig] Initialized with baseUrl: $baseUrl');
  }

  /// API version
  static const String apiVersion = 'v2';

  /// Auth endpoint
  static const String authEndpoint = '/public/$apiVersion/auth';

  /// Full auth base URL
  static const String authBaseUrl = '$baseUrl$authEndpoint';

  /// Timeout duration for API requests (in seconds)
  /// Increased to 60s due to production server latency
  static const int requestTimeoutSeconds = 60;
}
