import 'package:dio/dio.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';
import 'package:kltn_sharing_app/data/services/token_refresh_interceptor.dart';

/// Base API Service with common functionality
abstract class BaseApiService {
  late Dio _dio;

  Dio get dio => _dio;

  BaseApiService({
    required String baseUrl,
    Future<String?> Function()? getValidTokenCallback,
    Future<void> Function()? onTokenExpiredCallback,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(seconds: AppConfig.requestTimeoutSeconds),
        receiveTimeout: Duration(seconds: AppConfig.requestTimeoutSeconds),
        contentType: 'application/json',
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print(
              '[${runtimeType}] REQUEST[${options.method}] => ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '[${runtimeType}] RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (e, handler) {
          print(
              '[${runtimeType}] ERROR[${e.response?.statusCode}] => ${e.requestOptions.path}');
          return handler.next(e);
        },
      ),
    );

    // Add token refresh interceptor if callbacks provided
    if (getValidTokenCallback != null && onTokenExpiredCallback != null) {
      _dio.interceptors.add(
        TokenRefreshInterceptor(
          getValidTokenCallback: getValidTokenCallback,
          onTokenExpiredCallback: onTokenExpiredCallback,
        ),
      );
    }
  }

  /// Update Dio baseUrl when backend switches
  void updateDioBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  /// Set authorization header with bearer token
  void setAuthToken(String accessToken) {
    _dio.options.headers['Authorization'] = 'Bearer $accessToken';
  }

  /// Remove authorization header
  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}
