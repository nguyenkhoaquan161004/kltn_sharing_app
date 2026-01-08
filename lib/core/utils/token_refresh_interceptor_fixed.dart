import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kltn_sharing_app/data/models/auth_response_model.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';

/// Interceptor for handling token refresh on 401/403 errors
class TokenRefreshInterceptor extends InterceptorsWrapper {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiresAtKey = 'token_expires_at';

  late Dio _authDio;
  late SharedPreferences _prefs;
  late Future<void> _prefsReady;
  bool _isRefreshing = false;
  final List<DioException> _failedRequests = [];

  Future<void> Function()? _onTokenExpiredCallback;

  TokenRefreshInterceptor({
    Future<void> Function()? onTokenExpiredCallback,
  }) : _onTokenExpiredCallback = onTokenExpiredCallback {
    _authDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.authBaseUrl,
        connectTimeout: Duration(seconds: AppConfig.requestTimeoutSeconds),
        receiveTimeout: Duration(seconds: AppConfig.requestTimeoutSeconds),
        contentType: 'application/json',
      ),
    );
    _prefsReady = _initPrefs();
  }

  void setCallbacks({
    required Future<String?> Function() getValidTokenCallback,
    required Future<void> Function() onTokenExpiredCallback,
  }) {
    _onTokenExpiredCallback = onTokenExpiredCallback;
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static TokenRefreshInterceptor create({
    Future<void> Function()? onTokenExpiredCallback,
  }) {
    return TokenRefreshInterceptor(
      onTokenExpiredCallback: onTokenExpiredCallback,
    );
  }

  void setAuthToken(String token) {
    print('[TokenRefresh] Setting auth token');
  }

  void clearAuthToken() {
    print('[TokenRefresh] Clearing auth token');
  }

  Future<void> _saveTokens(AuthResponseModel authResponse) async {
    await _prefsReady;
    await _prefs.setString(_accessTokenKey, authResponse.accessToken);
    if (authResponse.refreshToken != null) {
      await _prefs.setString(_refreshTokenKey, authResponse.refreshToken!);
    }
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    print('[TokenRefresh] onError: ${err.response?.statusCode}');

    // 🔥 FIX 403: Token expired or invalid - logout immediately
    if (err.response?.statusCode == 403) {
      print('[TokenRefresh] ⚠️ 403 Forbidden - Token is INVALID/EXPIRED');
      print('[TokenRefresh] Triggering logout');
      _isRefreshing = false;
      _failedRequests.clear();
      await _onTokenExpiredCallback?.call();
      return handler.next(err);
    }

    // 401: Try to refresh token
    if (err.response?.statusCode == 401) {
      print('[TokenRefresh] 401 Unauthorized detected');

      if (_isRefreshing) {
        print('[TokenRefresh] Already refreshing, queuing request');
        _failedRequests.add(err);
        return handler.next(err);
      }

      _isRefreshing = true;

      try {
        await _prefsReady;
        final refreshToken = _prefs.getString(_refreshTokenKey);

        if (refreshToken == null) {
          print('[TokenRefresh] No refresh token available, logging out');
          _isRefreshing = false;
          await _onTokenExpiredCallback?.call();
          return handler.next(err);
        }

        print('[TokenRefresh] Attempting to refresh token');
        final response = await _authDio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        if (response.statusCode == 200) {
          final authResponse = AuthResponseModel.fromJson(response.data);
          await _saveTokens(authResponse);
          print('[TokenRefresh] ✅ Token refreshed successfully');

          _isRefreshing = false;

          for (var failedRequest in _failedRequests) {
            return handler.resolve(
              await _authDio.request(
                failedRequest.requestOptions.path,
                options: Options(
                  method: failedRequest.requestOptions.method,
                  headers: failedRequest.requestOptions.headers,
                ),
                data: failedRequest.requestOptions.data,
              ),
            );
          }
          _failedRequests.clear();
          return handler.next(err);
        }
      } catch (e) {
        print('[TokenRefresh] ❌ Token refresh failed: $e');
        _isRefreshing = false;
        await _onTokenExpiredCallback?.call();
      }
    }

    return handler.next(err);
  }

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    return handler.next(options);
  }

  @override
  Future<void> onResponse(
      Response response, ResponseInterceptorHandler handler) {
    return handler.next(response);
  }
}
