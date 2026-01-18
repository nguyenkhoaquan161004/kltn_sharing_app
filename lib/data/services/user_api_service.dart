import 'package:dio/dio.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';
import 'package:kltn_sharing_app/core/utils/token_refresh_interceptor.dart';
import 'package:kltn_sharing_app/data/models/user_response_model.dart';
import 'package:kltn_sharing_app/data/models/update_profile_request.dart';

class UserApiService {
  late Dio _dio;
  late TokenRefreshInterceptor _tokenRefreshInterceptor;

  UserApiService() {
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
          print('[UserAPI] REQUEST[${options.method}] => ${options.path}');
          print('[UserAPI] URL: ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '[UserAPI] RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (e, handler) {
          print(
              '[UserAPI] ERROR[${e.response?.statusCode}] => ${e.requestOptions.path}');
          print('[UserAPI] ERROR MESSAGE: ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  /// Set callback to get valid access token from AuthProvider
  void setGetValidTokenCallback(
      Future<void> Function() onTokenExpiredCallback) {
    try {
      _tokenRefreshInterceptor.setCallbacks(
        getValidTokenCallback: () async => null, // Not needed
        onTokenExpiredCallback: onTokenExpiredCallback,
      );
    } catch (e) {
      print('[UserAPI] Error setting token refresh callback: $e');
    }
  }

  /// Set authorization header with bearer token
  void setAuthToken(String accessToken) {
    _dio.options.headers['Authorization'] = 'Bearer $accessToken';
    print('[UserAPI] Token set: Bearer ${accessToken.substring(0, 20)}...');
  }

  /// Remove authorization header
  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Get current user profile
  Future<UserDto> getCurrentUser() async {
    try {
      print('[UserAPI] Fetching current user profile');
      final response = await _dio.get('/api/v2/users/me').timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw Exception('Get current user request timeout'),
          );

      print('[UserAPI] Response status: ${response.statusCode}');
      print('[UserAPI] Response data type: ${response.data.runtimeType}');
      print('[UserAPI] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Check if data is String (means error or non-JSON response)
        if (data is String) {
          print('[UserAPI] Response data is String, trying to parse as JSON');
          throw Exception('Response is String, not JSON: $data');
        }

        if (data is Map<String, dynamic>) {
          print('[UserAPI] Response data is Map');
          if (data.containsKey('data')) {
            final userData = data['data'];
            if (userData is Map<String, dynamic>) {
              return UserDto.fromJson(userData);
            }
          }
        }

        throw Exception(
            'Invalid response format: $data (type: ${data.runtimeType})');
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get user by ID
  Future<UserDto> getUserById(String userId) async {
    try {
      final response = await _dio.get('/api/v2/users/$userId');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            final userData = data['data'];
            if (userData is Map<String, dynamic>) {
              return UserDto.fromJson(userData);
            }
          }
        }

        throw Exception('Invalid response format: $data');
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Update current user profile
  Future<UserDto> updateProfile(UpdateProfileRequest request) async {
    try {
      print('[UserAPI] Updating user profile');
      print('[UserAPI] Request data: ${request.toJson()}');

      final response = await _dio.put(
        '/api/v2/users/me',
        data: request.toJson(),
      );

      print('[UserAPI] Response status: ${response.statusCode}');
      print('[UserAPI] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            final userData = data['data'];
            if (userData is Map<String, dynamic>) {
              return UserDto.fromJson(userData);
            }
          }
        }

        throw Exception('Invalid response format: $data');
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Send FCM token to backend after login
  /// Endpoint: POST /api/v2/users/fcm-token
  Future<void> updateFCMToken({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      print('[UserAPI] 📤 Updating FCM token - userId: $userId');
      print('[UserAPI] FCM Token: ${fcmToken.substring(0, 50)}...');

      final response = await _dio.post(
        '/api/v2/users/fcm-token',
        data: {
          'userId': userId,
          'fcmToken': fcmToken,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[UserAPI] ✅ FCM token updated successfully');
      } else {
        throw Exception('Failed to update FCM token: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Delete FCM token from backend on logout
  /// Endpoint: DELETE /api/v2/users/fcm-token
  Future<void> deleteFCMToken() async {
    try {
      print('[UserAPI] 🗑️  Deleting FCM token from backend');

      final response = await _dio.delete('/api/v2/users/fcm-token');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('[UserAPI] ✅ FCM token deleted successfully');
      } else {
        throw Exception('Failed to delete FCM token: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('[UserAPI] ⚠️  Error deleting FCM token: $e');
      // Don't throw - logout should succeed even if FCM token delete fails
    }
  }

  Exception _handleDioException(DioException e) {
    String message;

    if (e.response != null) {
      final responseData = e.response!.data;
      Map<String, dynamic>? data;

      // Safely parse data if it's a Map
      if (responseData is Map<String, dynamic>) {
        data = responseData;
      }

      switch (e.response!.statusCode) {
        case 401:
          message = 'Token hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.';
          break;
        case 403:
          message =
              'Bạn không có quyền thực hiện hành động này. Token có thể hết hạn.';
          break;
        case 404:
          message = 'Không tìm thấy người dùng.';
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
          message =
              data?['message'] ?? 'Đã xảy ra lỗi (${e.response!.statusCode})';
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
