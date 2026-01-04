/// Application configuration constants
class AppConfig {
  /// Production backend API URL
  static const String productionUrl = 'https://shareo.studio';

  /// Development/Local backend API URL
  /// Change this to your local machine IP or server URL
  /// Example: 'http://192.168.1.100:8080' or 'http://10.0.2.2:8080' (for emulator)
  static const String developmentUrl =
      'http://10.0.2.2:8080'; // Android emulator localhost

  /// Get current base URL
  /// Set to developmentUrl for testing, productionUrl for production
  static const String baseUrl =
      productionUrl; // ← Using production URL (which is develop server)

  /// Initialize - call this once at app startup
  static void initialize() {
    print('[AppConfig] Initialized with baseUrl: $baseUrl');
  }

  /// API version
  static const String apiVersion = 'v2';

  /// Auth endpoint
  static const String authEndpoint = '/api/public/$apiVersion/auth';

  /// Full auth base URL
  static const String authBaseUrl = '$baseUrl$authEndpoint';

  /// Timeout duration for API requests (in seconds)
  /// Increased to 60s due to production server latency
  static const int requestTimeoutSeconds = 60;
}
