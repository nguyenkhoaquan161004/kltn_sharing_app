import 'package:dio/dio.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';
import 'package:kltn_sharing_app/core/utils/token_refresh_interceptor.dart';
import 'package:kltn_sharing_app/data/models/cart_request_model.dart';

/// API Service for Cart endpoints
class CartApiService {
  late Dio _dio;

  CartApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: Duration(seconds: AppConfig.requestTimeoutSeconds),
        receiveTimeout: Duration(seconds: AppConfig.requestTimeoutSeconds),
        contentType: 'application/json',
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    // Add token refresh interceptor for handling 401/403 errors
    _dio.interceptors.add(TokenRefreshInterceptor());

    // Add logging interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('[CartAPI] REQUEST[${options.method}] => ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '[CartAPI] RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (e, handler) {
          print(
              '[CartAPI] ERROR[${e.response?.statusCode}] => ${e.requestOptions.path}');
          return handler.next(e);
        },
      ),
    );
  }

  /// Set authorization header with bearer token
  void setAuthToken(String accessToken) {
    _dio.options.headers['Authorization'] = 'Bearer $accessToken';
    print('[CartAPI] Token set');
  }

  /// Remove authorization header
  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Add item to cart
  Future<Map<String, dynamic>> addToCart(CartRequest request) async {
    try {
      final response = await _dio.post(
        '/api/v2/cart',
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          print('[CartAPI] Item added to cart successfully');
          return data;
        }

        throw Exception('Unexpected response format: $data');
      } else {
        throw Exception('Failed to add to cart: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Exception _handleDioException(DioException e) {
    String message;

    if (e.response != null) {
      final data = e.response!.data as Map<String, dynamic>?;

      switch (e.response!.statusCode) {
        case 400:
          message = data?['message'] ?? 'Yêu cầu không hợp lệ';
          break;
        case 401:
          message = 'Token hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.';
          break;
        case 403:
          message = 'Bạn không có quyền thực hiện hành động này.';
          break;
        case 404:
          message = 'Sản phẩm không tìm thấy.';
          break;
        case 422:
          message = 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';
          break;
        case 500:
          message = 'Lỗi máy chủ. Vui lòng thử lại sau.';
          break;
        default:
          message = 'Có lỗi xảy ra: ${e.response!.statusCode}';
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Kết nối timeout. Vui lòng kiểm tra mạng.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      message = 'Nhận dữ liệu timeout. Vui lòng thử lại.';
    } else {
      message = e.message ?? 'Có lỗi xảy ra';
    }

    return Exception(message);
  }
}
