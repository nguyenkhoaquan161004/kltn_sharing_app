import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';
import 'package:kltn_sharing_app/core/utils/token_refresh_interceptor.dart';
import 'package:kltn_sharing_app/data/models/recommendation_response_model.dart';

/// API Service for Recommendations endpoints
class RecommendationApiService {
  late Dio _dio;
  late TokenRefreshInterceptor _tokenRefreshInterceptor;

  RecommendationApiService() {
    // Initialize token refresh interceptor FIRST
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

    // Add token refresh interceptor (recommendations require authentication)
    _dio.interceptors.add(_tokenRefreshInterceptor);

    // Add logging interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print(
              '[RecommendationAPI] REQUEST[${options.method}] => ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '[RecommendationAPI] RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (e, handler) {
          print(
              '[RecommendationAPI] ERROR[${e.response?.statusCode}] => ${e.requestOptions.path}');
          return handler.next(e);
        },
      ),
    );
  }

  /// Set callback to get valid access token from AuthProvider
  void setGetValidTokenCallback(Future<String?> Function() callback) {
    try {
      _tokenRefreshInterceptor.setCallbacks(
        getValidTokenCallback: () async => null,
        onTokenExpiredCallback: callback,
      );
    } catch (e) {
      print('[RecommendationAPI] Error setting token refresh callback: $e');
    }
  }

  /// Set authorization header with bearer token
  void setAuthToken(String accessToken) {
    _dio.options.headers['Authorization'] = 'Bearer $accessToken';
    print('[RecommendationAPI] Token set');
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
        print('[RecommendationAPI] ✅ Token loaded from SharedPreferences');
      } else {
        print(
            '[RecommendationAPI] ⚠️  No saved token found in SharedPreferences');
      }
    } catch (e) {
      print(
          '[RecommendationAPI] ⚠️  Error loading token from SharedPreferences: $e');
    }
  }

  /// Get recommendations (Đề xuất)
  Future<RecommendationsResponse> getRecommendations({
    int page = 0,
    int size = 20,
  }) async {
    try {
      // Ensure token is loaded from SharedPreferences before making the request
      await _ensureTokenLoaded();

      final response = await _dio.get(
        '/api/v2/recommendations',
        queryParameters: {
          'page': page,
          'limit': size,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print(
            '[RecommendationAPI] getRecommendations response type: ${data.runtimeType}');
        print('[RecommendationAPI] getRecommendations response: $data');

        if (data is Map<String, dynamic>) {
          final result = RecommendationsResponse.fromJson(data);
          print(
              '[RecommendationAPI] getRecommendations: Loaded ${result.data.data.length} items');
          return result;
        }

        throw Exception('Unexpected response format: ${data.runtimeType}');
      } else {
        throw Exception(
            'Failed to load recommendations: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get trending recommendations (Gầy đây)
  Future<RecommendationsResponse> getTrendingRecommendations({
    int page = 0,
    int size = 20,
  }) async {
    try {
      // Ensure token is loaded from SharedPreferences before making the request
      await _ensureTokenLoaded();

      final response = await _dio.get(
        '/api/v2/recommendations/trending',
        queryParameters: {
          'page': page,
          'limit': size,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print(
            '[RecommendationAPI] getTrendingRecommendations response type: ${data.runtimeType}');
        print('[RecommendationAPI] getTrendingRecommendations response: $data');

        if (data is Map<String, dynamic>) {
          final result = RecommendationsResponse.fromJson(data);
          print(
              '[RecommendationAPI] getTrendingRecommendations: Loaded ${result.data.data.length} items');
          return result;
        }

        throw Exception('Unexpected response format: ${data.runtimeType}');
      } else {
        throw Exception(
            'Failed to load trending recommendations: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Handle DioException
  Exception _handleDioException(DioException e) {
    String message;

    if (e.response != null) {
      Map<String, dynamic>? data;
      if (e.response!.data is Map<String, dynamic>) {
        data = e.response!.data as Map<String, dynamic>;
      }

      switch (e.response!.statusCode) {
        case 401:
          message = 'Token hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.';
          break;
        case 403:
          message = 'Bạn không có quyền thực hiện hành động này.';
          break;
        case 404:
          message = 'Không tìm thấy dữ liệu.';
          break;
        case 500:
        case 502:
        case 503:
          message = data?['message'] ??
              'Máy chủ bị lỗi (${e.response!.statusCode}). Vui lòng thử lại sau.';
          break;
        default:
          message = data?['message'] ?? e.message ?? 'Đã xảy ra lỗi';
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Kết nối bị hết thời gian. Vui lòng kiểm tra kết nối internet.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      message = 'Máy chủ không phản hồi. Vui lòng thử lại.';
    } else if (e.type == DioExceptionType.unknown) {
      message =
          'Lỗi kết nối. Vui lòng kiểm tra kết nối internet và URL máy chủ.';
    } else {
      message = e.message ?? 'Đã xảy ra lỗi';
    }

    return Exception(message);
  }
}
