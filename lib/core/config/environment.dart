/// Environment configuration for API endpoints
enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  static Environment _currentEnvironment = Environment.production;

  /// Set the current environment
  static void setEnvironment(Environment env) {
    _currentEnvironment = env;
  }

  /// Get the current environment
  static Environment get currentEnvironment => _currentEnvironment;

  /// Get the base URL for the current environment
  static String get baseUrl {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'http://localhost:8080';
      case Environment.staging:
        return 'https://api.staging.shareo.studio';
      case Environment.production:
        return 'https://api.shareo.studio';
    }
  }

  /// Get the API version
  static const String apiVersion = 'v2';

  /// Get the auth endpoint
  static const String authEndpoint = '/public/v2/auth';

  /// Full auth base URL
  static String get authBaseUrl => '$baseUrl$authEndpoint';

  /// API request timeout in seconds
  static const int requestTimeoutSeconds = 30;

  /// Enable debug logging
  static bool get enableLogging {
    switch (_currentEnvironment) {
      case Environment.development:
      case Environment.staging:
        return true;
      case Environment.production:
        return false;
    }
  }
}
