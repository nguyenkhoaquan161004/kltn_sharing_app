import 'package:dio/dio.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';
import 'package:kltn_sharing_app/core/utils/token_refresh_interceptor.dart';
import 'package:kltn_sharing_app/data/models/notification_model.dart';

/// API Service for Notifications endpoints
class NotificationApiService {
  late Dio _dio;
  late TokenRefreshInterceptor _tokenRefreshInterceptor;

  NotificationApiService() {
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

    // Add logging interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print(
              '[NotificationAPI] REQUEST[${options.method}] => ${options.path}');
          print('[NotificationAPI] Headers: ${options.headers}');
          print('[NotificationAPI] QueryParams: ${options.queryParameters}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '[NotificationAPI] RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (e, handler) {
          print(
              '[NotificationAPI] ERROR[${e.response?.statusCode}] => ${e.requestOptions.path}');
          if (e.response != null) {
            print('[NotificationAPI] ERROR Response body: ${e.response!.data}');
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// Set callback to get valid access token from AuthProvider
  void setGetValidTokenCallback(Future<String?> Function() callback) {
    try {
      _tokenRefreshInterceptor.setCallbacks(
        getValidTokenCallback: callback,
        onTokenExpiredCallback: () async {
          print('[NotificationAPI] Token refresh failed, user session expired');
        },
      );
    } catch (e) {
      print('[NotificationAPI] Error setting token refresh callback: $e');
    }
  }

  /// Set authorization header with bearer token
  void setAuthToken(String accessToken) {
    _dio.options.headers['Authorization'] = 'Bearer $accessToken';
    print('[NotificationAPI] Token set');
  }

  /// Remove authorization header
  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Get paginated notifications
  /// Returns: {"data": {"data": [...], "page": 1, "limit": 20, "total": 100}}
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v2/notifications',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          print('[NotificationAPI] Notifications retrieved successfully');
          // Handle ApiResponse<PageResponse> structure
          if (data.containsKey('data')) {
            return data['data'] as Map<String, dynamic>;
          }
          return data;
        }

        throw Exception('Unexpected response format: $data');
      } else {
        throw Exception('Failed to get notifications: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get unread notifications
  Future<List<NotificationModel>> getUnreadNotifications() async {
    try {
      final response = await _dio.get('/api/v2/notifications/unread');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          final notificationsList = data['data'] as List? ?? [];
          final notifications = notificationsList
              .map((item) =>
                  NotificationModel.fromJson(item as Map<String, dynamic>))
              .toList();
          print(
              '[NotificationAPI] Unread notifications retrieved: ${notifications.length}');
          return notifications;
        }

        throw Exception('Unexpected response format: $data');
      } else {
        throw Exception(
            'Failed to get unread notifications: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/api/v2/notifications/unread/count');

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle both Map and direct number responses
        if (data is Map<String, dynamic>) {
          final count = (data['data'] as num?)?.toInt() ?? 0;
          print('[NotificationAPI] Unread count: $count');
          return count;
        } else if (data is num) {
          final count = data.toInt();
          print('[NotificationAPI] Unread count (direct): $count');
          return count;
        }

        print(
            '[NotificationAPI] Unexpected response format for unread count: $data (type: ${data.runtimeType})');
        throw Exception('Unexpected response format: $data');
      } else {
        throw Exception('Failed to get unread count: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await _dio.put(
        '/api/v2/notifications/$notificationId/read',
      );

      if (response.statusCode == 200) {
        print('[NotificationAPI] Notification marked as read');
      } else {
        throw Exception(
            'Failed to mark notification as read: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final response = await _dio.put('/api/v2/notifications/read-all');

      if (response.statusCode == 200) {
        print('[NotificationAPI] All notifications marked as read');
      } else {
        throw Exception('Failed to mark all as read: ${response.statusCode}');
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
          message = 'Không tìm thấy thông báo.';
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
