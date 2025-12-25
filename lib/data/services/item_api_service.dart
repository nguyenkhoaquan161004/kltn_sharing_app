import 'package:dio/dio.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';
import 'package:kltn_sharing_app/core/utils/token_refresh_interceptor.dart';
import 'package:kltn_sharing_app/data/models/item_response_model.dart';

class ItemApiService {
  late Dio _dio;
  Future<String?> Function()? _getValidTokenCallback;

  ItemApiService({Future<String?> Function()? getValidTokenCallback})
      : _getValidTokenCallback = getValidTokenCallback {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl, // Use base URL, not authBaseUrl
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
          print('[ItemAPI] REQUEST[${options.method}] => ${options.path}');
          print('[ItemAPI] URL: ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '[ItemAPI] RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (e, handler) {
          print(
              '[ItemAPI] ERROR[${e.response?.statusCode}] => ${e.requestOptions.path}');
          print('[ItemAPI] ERROR MESSAGE: ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  /// Set getValidToken callback (from AuthProvider)
  void setGetValidTokenCallback(Future<String?> Function() callback) {
    _getValidTokenCallback = callback;
  }

  /// Also support setAuthToken for backward compatibility
  void setAuthToken(String accessToken) {
    _dio.options.headers['Authorization'] = 'Bearer $accessToken';
    print('[ItemAPI] Token set: Bearer ${accessToken.substring(0, 20)}...');
  }

  /// Remove authorization header
  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Update Dio baseUrl when backend switches
  void _updateDioBaseUrl() {
    _dio.options.baseUrl = AppConfig.baseUrl;
  }

  Future<PageResponse<ItemDto>> searchItems({
    int page = 0,
    int size = 10,
    String? search,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? sortBy = 'createdAt',
    String? sortDirection = 'DESC',
  }) async {
    try {
      // Ensure token is valid before making request
      if (_getValidTokenCallback != null) {
        final validToken = await _getValidTokenCallback!();
        if (validToken != null) {
          _dio.options.headers['Authorization'] = 'Bearer $validToken';
        }
      }

      final queryParams = {
        'page': page,
        'size': size,
        if (search != null) 'search': search,
        if (category != null) 'category': category,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        'sortBy': sortBy,
        'sortDirection': sortDirection,
      };

      final response = await _dio.get(
        '/api/v2/items',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle case where response is already a Map (API returns ApiResponse<PageResponse>)
        if (data is Map<String, dynamic>) {
          print('[ItemAPI] Response is Map: $data');

          if (data.containsKey('data')) {
            final pageData = data['data'];
            if (pageData is Map<String, dynamic>) {
              return PageResponse<ItemDto>.fromJson(
                pageData,
                (json) => ItemDto.fromJson(json),
              );
            }
          }
        }

        throw Exception('Unexpected response format: $data');
      } else {
        throw Exception('Failed to load items: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get single item by ID
  Future<ItemDto> getItem(String itemId) async {
    try {
      final response = await _dio.get('/api/v2/items/$itemId');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic> && data.containsKey('data')) {
          return ItemDto.fromJson(data['data'] as Map<String, dynamic>);
        }

        throw Exception('Invalid response format: $data');
      } else {
        throw Exception('Failed to load item: ${response.statusCode}');
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
        case 401:
          message = 'Token hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.';
          break;
        case 403:
          message = 'Bạn không có quyền thực hiện hành động này.';
          break;
        case 404:
          message = 'Không tìm thấy sản phẩm.';
          break;
        case 422:
          message = data?['message'] ?? 'Dữ liệu không hợp lệ.';
          break;
        case 500:
        case 502:
        case 503:
          message = 'Máy chủ bị lỗi. Vui lòng thử lại sau.';
          break;
        default:
          message = data?['message'] ?? 'Đã xảy ra lỗi';
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Kết nối bị hết thời gian. Vui lòng kiểm tra kết nối internet.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      message = 'Máy chủ không phản hồi. Vui lòng thử lại.';
    } else if (e.type == DioExceptionType.unknown) {
      message = 'Lỗi kết nối. Vui lòng kiểm tra kết nối internet.';
    } else {
      message = e.message ?? 'Đã xảy ra lỗi';
    }

    return Exception(message);
  }
}
