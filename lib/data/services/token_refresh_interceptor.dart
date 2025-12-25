import 'package:dio/dio.dart';

/// Interceptor to handle token refresh on 401 responses
class TokenRefreshInterceptor extends Interceptor {
  final Future<String?> Function() getValidTokenCallback;
  final Future<void> Function() onTokenExpiredCallback;

  TokenRefreshInterceptor({
    required this.getValidTokenCallback,
    required this.onTokenExpiredCallback,
  });

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      print('[TokenRefreshInterceptor] Got 401 Unauthorized');

      try {
        // Try to refresh token
        final validToken = await getValidTokenCallback();

        if (validToken != null) {
          print('[TokenRefreshInterceptor] Token refreshed, retrying request');

          // Update authorization header and retry
          err.requestOptions.headers['Authorization'] = 'Bearer $validToken';

          final response = await Dio().request(
            err.requestOptions.path,
            options: Options(
              method: err.requestOptions.method,
              headers: err.requestOptions.headers,
              responseType: err.requestOptions.responseType,
              contentType: err.requestOptions.contentType,
            ),
            data: err.requestOptions.data,
            queryParameters: err.requestOptions.queryParameters,
          );

          return handler.resolve(response);
        } else {
          print(
              '[TokenRefreshInterceptor] Token refresh failed, user needs to login');
          await onTokenExpiredCallback();
          return handler.next(err);
        }
      } catch (e) {
        print('[TokenRefreshInterceptor] Error during token refresh: $e');
        await onTokenExpiredCallback();
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
