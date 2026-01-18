import 'package:dio/dio.dart';
import 'dart:async';

/// Interceptor to handle token refresh on 401/403 responses with proper retry logic
///
/// Pattern:
/// 1. Request → 401/403
/// 2. Interceptor chặn
/// 3. Nếu đang refresh → chờ refresh xong
/// 4. Nếu chưa refresh → thực hiện refresh
/// 5. Cập nhật token → RETRY request cũ
/// 6. Nếu refresh fail → logout
class TokenRefreshInterceptor extends Interceptor {
  final Dio dio;
  final Future<String?> Function() getValidTokenCallback;
  final Future<void> Function() onTokenExpiredCallback;

  // Prevent multiple simultaneous refresh attempts
  bool _isRefreshing = false;
  late Completer<bool> _refreshCompleter;

  TokenRefreshInterceptor({
    required this.dio,
    required this.getValidTokenCallback,
    required this.onTokenExpiredCallback,
  });

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;

    // Handle 401 Unauthorized or 403 Forbidden
    if (statusCode == 401 || statusCode == 403) {
      print(
          '[TokenRefresh] 🔥 $statusCode error - Token expired/invalid. Request: ${err.requestOptions.path}');

      // If already refreshing, wait for it to complete
      if (_isRefreshing) {
        print('[TokenRefresh] ⏳ Already refreshing, waiting...');
        try {
          final success = await _refreshCompleter.future;
          if (success) {
            print('[TokenRefresh] ✅ Refresh completed, retrying request');
            return _retryRequest(err, handler);
          } else {
            print('[TokenRefresh] ❌ Refresh failed, logging out');
            return handler.reject(err);
          }
        } catch (e) {
          print('[TokenRefresh] ❌ Error waiting for refresh: $e');
          return handler.reject(err);
        }
      }

      // Start refreshing
      _isRefreshing = true;
      _refreshCompleter = Completer<bool>();

      try {
        print('[TokenRefresh] 🔄 Attempting to refresh token...');
        final newToken = await getValidTokenCallback();

        if (newToken != null && newToken.isNotEmpty) {
          print('[TokenRefresh] ✅ Token refreshed successfully');
          _refreshCompleter.complete(true);
          _isRefreshing = false;

          // Retry the failed request with new token
          return _retryRequest(err, handler);
        } else {
          print('[TokenRefresh] ❌ Token refresh returned null/empty');
          await onTokenExpiredCallback();
          _refreshCompleter.complete(false);
          _isRefreshing = false;
          return handler.reject(err);
        }
      } catch (e) {
        print('[TokenRefresh] ❌ Error during token refresh: $e');
        try {
          await onTokenExpiredCallback();
        } catch (_) {}
        _refreshCompleter.complete(false);
        _isRefreshing = false;
        return handler.reject(err);
      }
    }

    return handler.next(err);
  }

  /// Retry the original request with updated authorization header
  Future<void> _retryRequest(
      DioException err, ErrorInterceptorHandler handler) async {
    try {
      final validToken = await getValidTokenCallback().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('[TokenRefresh] ⏱️  Timeout getting valid token');
          return null;
        },
      );
      final requestOptions = err.requestOptions;

      if (validToken != null) {
        requestOptions.headers['Authorization'] = 'Bearer $validToken';
      }

      print(
          '[TokenRefresh] 🔁 Retrying request: ${requestOptions.method} ${requestOptions.path}');
      final response = await dio
          .request<dynamic>(
            requestOptions.path,
            options: Options(
              method: requestOptions.method,
              headers: requestOptions.headers,
              responseType: requestOptions.responseType,
              contentType: requestOptions.contentType,
            ),
            data: requestOptions.data,
            queryParameters: requestOptions.queryParameters,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Retry request timeout'),
          );

      print('[TokenRefresh] ✅ Retry successful');
      return handler.resolve(response);
    } catch (e) {
      print('[TokenRefresh] ❌ Retry failed: $e');
      return handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: e,
        type: DioExceptionType.unknown,
      ));
    }
  }
}
