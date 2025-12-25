import 'package:dio/dio.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';
import 'package:kltn_sharing_app/core/utils/token_refresh_interceptor.dart';
import 'package:kltn_sharing_app/data/models/gamification_response_model.dart';

class GamificationApiService {
  late Dio _dio;

  GamificationApiService() {
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
          print(
              '[GamificationAPI] REQUEST[${options.method}] => ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '[GamificationAPI] RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (e, handler) {
          print(
              '[GamificationAPI] ERROR[${e.response?.statusCode}] => ${e.requestOptions.path}');
          return handler.next(e);
        },
      ),
    );
  }

  /// Set authorization header with bearer token
  void setAuthToken(String accessToken) {
    _dio.options.headers['Authorization'] = 'Bearer $accessToken';
    print('[GamificationAPI] Token set');
  }

  /// Remove authorization header
  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Get leaderboard with pagination
  Future<LeaderboardResponse> getLeaderboard({
    int page = 0,
    int size = 10,
    String? sortBy = 'points',
    String? sortDirection = 'DESC',
  }) async {
    try {
      final queryParams = {
        'page': page,
        'size': size,
        if (sortBy != null) 'sortBy': sortBy,
        if (sortDirection != null) 'sortDirection': sortDirection,
      };

      final response = await _dio.get(
        '/api/v2/gamifications/leaderboard',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle ApiResponse<PageResponse<Gamification>>
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            final pageData = data['data'];
            if (pageData is Map<String, dynamic>) {
              return LeaderboardResponse.fromJson(pageData);
            }
          }
          // Direct response format
          return LeaderboardResponse.fromJson(data);
        }

        throw Exception('Unexpected response format: $data');
      } else {
        throw Exception('Failed to load leaderboard: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get top 3 users for podium
  Future<List<GamificationDto>> getTopUsers({int limit = 3}) async {
    try {
      final response = await _dio.get(
        '/api/v2/gamifications/leaderboard',
        queryParameters: {
          'page': 0,
          'size': limit,
          'sortBy': 'points',
          'sortDirection': 'DESC',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            final pageData = data['data'];
            if (pageData is Map<String, dynamic>) {
              final response = LeaderboardResponse.fromJson(pageData);
              return response.content;
            }
          }
          final response = LeaderboardResponse.fromJson(data);
          return response.content;
        }

        throw Exception('Unexpected response format');
      } else {
        throw Exception('Failed to load top users: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get current user's rank and stats
  Future<GamificationDto> getCurrentUserStats() async {
    try {
      final response = await _dio.get('/api/v2/gamifications/me');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            return GamificationDto.fromJson(
                data['data'] as Map<String, dynamic>);
          }
          return GamificationDto.fromJson(data);
        }

        throw Exception('Unexpected response format');
      } else {
        throw Exception('Failed to load user stats: ${response.statusCode}');
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
          message = 'Máy chủ bị lỗi. Vui lòng thử lại sau.';
          break;
        default:
          message = data?['message'] ?? 'Đã xảy ra lỗi';
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Kết nối bị hết thời gian. Vui lòng kiểm tra kết nối internet.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      message = 'Máy chủ không phản hồi. Vui lòng thử lại.';
    } else {
      message = 'Lỗi kết nối. Vui lòng kiểm tra kết nối internet.';
    }

    return Exception(message);
  }
}
