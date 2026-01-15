import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';
import 'package:kltn_sharing_app/core/utils/token_refresh_interceptor.dart';
import 'package:kltn_sharing_app/data/models/cart_request_model.dart';

/// API Service for Cart endpoints
class CartApiService {
  late Dio _dio;
  late TokenRefreshInterceptor _tokenRefreshInterceptor;

  CartApiService() {
    // Initialize token refresh interceptor FIRST before creating Dio
    _tokenRefreshInterceptor = TokenRefreshInterceptor();

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
    _dio.interceptors.add(_tokenRefreshInterceptor);

    // Set main Dio reference so TokenRefreshInterceptor can retry original requests
    _tokenRefreshInterceptor.setMainDio(_dio);

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

  /// Set callback when token refresh fails or 403 occurs
  void setGetValidTokenCallback(
      Future<void> Function() onTokenExpiredCallback) {
    try {
      _tokenRefreshInterceptor.setCallbacks(
        getValidTokenCallback: () async =>
            null, // Not needed, interceptor handles it
        onTokenExpiredCallback: onTokenExpiredCallback,
      );
    } catch (e) {
      print('[CartAPI] Error setting token refresh callback: $e');
    }
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

  /// Ensure token is loaded from SharedPreferences before making API calls
  /// This prevents "No refresh token available" errors when token was set earlier
  Future<void> _ensureTokenLoaded() async {
    try {
      // Check if we already have a token set
      final currentAuth = _dio.options.headers['Authorization'];
      if (currentAuth != null && currentAuth.toString().isNotEmpty) {
        return;
      }

      // Load token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('access_token');

      if (savedToken != null && savedToken.isNotEmpty) {
        setAuthToken(savedToken);
        print('[CartAPI] ✅ Token loaded from SharedPreferences');
      } else {
        print('[CartAPI] ⚠️  No saved token found in SharedPreferences');
      }
    } catch (e) {
      print('[CartAPI] ⚠️  Error loading token from SharedPreferences: $e');
    }
  }

  /// Add item to cart
  Future<Map<String, dynamic>> addToCart(CartRequest request) async {
    try {
      // Ensure token is loaded from SharedPreferences before making the request
      await _ensureTokenLoaded();

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

  /// Get all cart items for current user
  Future<List<dynamic>> getCart({int page = 1, int limit = 20}) async {
    try {
      // Ensure token is loaded from SharedPreferences before making the request
      await _ensureTokenLoaded();

      final response = await _dio.get(
        '/api/v2/cart',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final apiResponse = response.data;

        if (apiResponse is Map<String, dynamic>) {
          // ApiResponse structure:
          // {
          //   success, status, code, message,
          //   data: {
          //     page, limit, totalItems, totalPages,
          //     data: [...]  // Actual cart items list
          //   }
          // }

          final pageResponse = apiResponse['data'];

          if (pageResponse is Map<String, dynamic>) {
            final itemsList =
                pageResponse['data'] ?? pageResponse['items'] ?? [];
            print(
                '[CartAPI] Cart items retrieved: ${itemsList is List ? itemsList.length : 0} items');
            return itemsList is List ? itemsList : [];
          } else {
            print(
                '[CartAPI] Warning: apiResponse["data"] is not a Map, got: ${pageResponse.runtimeType}');
            return [];
          }
        }

        throw Exception('Unexpected response format: $apiResponse');
      } else {
        throw Exception('Failed to get cart: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(String itemId) async {
    try {
      // Ensure token is loaded from SharedPreferences before making the request
      await _ensureTokenLoaded();

      print('[CartAPI] Removing item from cart: $itemId');
      final response = await _dio.delete(
        '/api/v2/cart/items/$itemId',
      );

      print('[CartAPI] Delete response status: ${response.statusCode}');
      print('[CartAPI] Delete response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('[CartAPI] Item removed from cart successfully: $itemId');
      } else {
        throw Exception('Failed to remove from cart: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print(
          '[CartAPI] DioException removing from cart: ${e.response?.statusCode} - ${e.message}');
      throw _handleDioException(e);
    }
  }

  /// Delete item from cart (alias for removeFromCart)
  Future<void> deleteCartItem(String itemId) async {
    return removeFromCart(itemId);
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
