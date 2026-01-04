import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kltn_sharing_app/data/models/auth_response_model.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';

/// Interceptor for handling token refresh on 401 errors
class TokenRefreshInterceptor extends InterceptorsWrapper {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiresAtKey = 'token_expires_at';

  late Dio _authDio; // Separate Dio instance for auth endpoints
  late SharedPreferences _prefs;
  late Future<void> _prefsReady;
  bool _isRefreshing = false;
  final List<DioException> _failedRequests = [];

  // Callback when token refresh fails and user needs to re-login
  Future<void> Function()? _onTokenExpiredCallback;

  TokenRefreshInterceptor({
    Future<void> Function()? onTokenExpiredCallback,
  })  : _onTokenExpiredCallback = onTokenExpiredCallback {
    _authDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.authBaseUrl,
        connectTimeout: Duration(seconds: AppConfig.requestTimeoutSeconds),
        receiveTimeout: Duration(seconds: AppConfig.requestTimeoutSeconds),
        contentType: 'application/json',
      ),
    );
    // Initialize SharedPreferences
    _prefsReady = _initPrefs();
  }

  /// Set callbacks after initialization
  void setCallbacks({
    required Future<String?> Function() getValidTokenCallback,
    required Future<void> Function() onTokenExpiredCallback,
  }) {
    _onTokenExpiredCallback = onTokenExpiredCallback;
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Static method to easily add this interceptor to a Dio instance
  static TokenRefreshInterceptor create({
    Future<void> Function()? onTokenExpiredCallback,
  }) {
    return TokenRefreshInterceptor(
      onTokenExpiredCallback: onTokenExpiredCallback,
    );
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    // Only handle 401/403 errors
    if (err.response?.statusCode != 401 && err.response?.statusCode != 403) {
      return handler.next(err);
    }

    // Wait for SharedPreferences to be initialized
    try {
      await _prefsReady;
    } catch (e) {
      print(
          '[TokenRefreshInterceptor] Failed to initialize SharedPreferences: $e');
      return handler.next(err);
    }

    if (_isRefreshing) {
      // Already refreshing, queue this request
      _failedRequests.add(err);
      return;
    }

    _isRefreshing = true;

    try {
      // Get refresh token from preferences
      final refreshToken = _prefs.getString(_refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        print(
            '[TokenRefreshInterceptor] ❌ No refresh token available in SharedPreferences');
        await _clearTokens();
        _isRefreshing = false;

        // Notify callback about token expiration
        if (_onTokenExpiredCallback != null) {
          await _onTokenExpiredCallback!();
        }
        return handler.next(err);
      }

      print(
          '[TokenRefreshInterceptor] Attempting to refresh token after ${err.response?.statusCode} error');
      print(
          '[TokenRefreshInterceptor] Using refresh token from SharedPreferences: ${refreshToken.substring(0, 20)}...');

      // Call refresh token endpoint - MUST use refreshToken from storage
      final response = await _authDio.post(
        '/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          final tokenResponse = TokenResponse.fromJson(data['data']);

          // Verify we got new tokens back
          if (tokenResponse.refreshToken.isEmpty) {
            print(
                '[TokenRefreshInterceptor] ❌ Backend returned empty refresh token');
            throw Exception('Invalid token response from backend');
          }

          // Save new tokens - IMPORTANT: Save refreshToken!
          await _saveTokens(
            tokenResponse.accessToken,
            tokenResponse.refreshToken,
            tokenResponse.expiresIn,
          );

          print('[TokenRefreshInterceptor] ✅ Token refreshed successfully');
          print(
              '[TokenRefreshInterceptor] New refresh token saved: ${tokenResponse.refreshToken.substring(0, 20)}...');
          print(
              '[TokenRefreshInterceptor] New access token saved: ${tokenResponse.accessToken.substring(0, 20)}...');

          // Update original request with new token
          err.requestOptions.headers['Authorization'] =
              'Bearer ${tokenResponse.accessToken}';

          _isRefreshing = false;

          // Retry original request with properly configured Dio
          try {
            final retryDio = Dio(
              BaseOptions(
                baseUrl: AppConfig.baseUrl,
                connectTimeout:
                    Duration(seconds: AppConfig.requestTimeoutSeconds),
                receiveTimeout:
                    Duration(seconds: AppConfig.requestTimeoutSeconds),
                contentType: 'application/json',
                headers: {
                  'Accept': 'application/json',
                  'Authorization': 'Bearer ${tokenResponse.accessToken}',
                },
              ),
            );
            final retryResponse = await retryDio.request<dynamic>(
              err.requestOptions.path,
              options: Options(
                method: err.requestOptions.method,
                contentType: err.requestOptions.contentType,
              ),
              data: err.requestOptions.data,
              queryParameters: err.requestOptions.queryParameters,
            );
            return handler.resolve(retryResponse);
          } catch (retryErr) {
            print('[TokenRefreshInterceptor] ❌ Retry failed: $retryErr');
            return handler.next(err);
          }
        } else {
          print(
              '[TokenRefreshInterceptor] ❌ Invalid refresh response: success=${data['success']}, data=${data['data']}');
        }
      } else {
        print(
            '[TokenRefreshInterceptor] ❌ Refresh endpoint returned ${response.statusCode}');
      }

      // Refresh failed
      print('[TokenRefreshInterceptor] ❌ Token refresh failed');
      await _clearTokens();
      _isRefreshing = false;

      // Notify about token expiration so user can re-login
      if (_onTokenExpiredCallback != null) {
        await _onTokenExpiredCallback!();
      }
      return handler.next(err);
    } catch (e) {
      print('[TokenRefreshInterceptor] ❌ Token refresh error: $e');
      await _clearTokens();
      _isRefreshing = false;

      // Notify about token expiration so user can re-login
      if (_onTokenExpiredCallback != null) {
        await _onTokenExpiredCallback!();
      }
      return handler.next(err);
    }
  }

  /// Save tokens to shared preferences
  Future<void> _saveTokens(
    String accessToken,
    String refreshToken,
    int expiresInSeconds,
  ) async {
    final expiresAt = DateTime.now().add(Duration(seconds: expiresInSeconds));
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
    await _prefs.setString(_tokenExpiresAtKey, expiresAt.toIso8601String());

    print('[TokenRefreshInterceptor] ✅ Tokens saved to SharedPreferences');
    print(
        '[TokenRefreshInterceptor] - Access Token: ${accessToken.substring(0, 20)}...');
    print(
        '[TokenRefreshInterceptor] - Refresh Token: ${refreshToken.substring(0, 20)}...');
    print('[TokenRefreshInterceptor] - Expires At: $expiresAt');
  }

  /// Clear tokens from shared preferences
  Future<void> _clearTokens() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_tokenExpiresAtKey);
    print('[TokenRefreshInterceptor] Tokens cleared');
  }
}
