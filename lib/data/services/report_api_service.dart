import 'package:dio/dio.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';
import 'package:kltn_sharing_app/core/utils/token_refresh_interceptor.dart';

/// API Service for Report endpoints
class ReportApiService {
  late Dio _dio;
  late TokenRefreshInterceptor _tokenRefreshInterceptor;

  ReportApiService() {
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
          print('[ReportAPI] REQUEST[${options.method}] => ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '[ReportAPI] RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (e, handler) {
          print(
              '[ReportAPI] ERROR[${e.response?.statusCode}] => ${e.requestOptions.path}');
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
      print('[ReportAPI] Error setting token refresh callback: $e');
    }
  }

  /// Set authorization header with bearer token
  void setAuthToken(String accessToken) {
    _dio.options.headers['Authorization'] = 'Bearer $accessToken';
    print('[ReportAPI] Token set');
  }

  /// Remove authorization header
  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Create a new report
  /// POST /api/v2/reports
  Future<Map<String, dynamic>> createReport({
    required String type, // ITEM, USER, TRANSACTION, GENERAL
    required String
        category, // Specific category (e.g., ITEM_NOT_RECEIVED, HARASSMENT, etc.)
    required String description, // Report description (10-2000 chars)
    String?
        targetId, // For ITEM: item UUID, USER: user ID, TRANSACTION: transaction UUID, GENERAL: null
    List<String>? evidenceUrls, // Optional evidence image URLs
  }) async {
    try {
      final Map<String, dynamic> data = {
        'type': type,
        'category': category,
        'description': description,
      };

      if (targetId != null) {
        data['targetId'] = targetId;
      }

      if (evidenceUrls != null && evidenceUrls.isNotEmpty) {
        data['evidenceUrls'] = evidenceUrls;
      }

      final response = await _dio.post(
        '/api/v2/reports',
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          print('[ReportAPI] Report created successfully');
          return responseData;
        }

        throw Exception('Unexpected response format: $responseData');
      } else {
        throw Exception('Failed to create report: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error creating report: $e');
    }
  }

  /// Get current user's reports
  /// GET /api/v2/reports/my
  Future<Map<String, dynamic>> getMyReports({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v2/reports/my',
        queryParameters: {
          'page': page,
          'size': size,
          'sort': 'createdAt,desc',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          print('[ReportAPI] Reports retrieved successfully');
          return data;
        }

        throw Exception('Unexpected response format: $data');
      } else {
        throw Exception('Failed to get reports: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error getting reports: $e');
    }
  }

  /// Handle DioException and convert to user-friendly messages
  String _handleDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Receive timeout. Please try again.';
    } else if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final errorData = e.response!.data;

      print('[ReportAPI] Error response: $errorData');

      // Check for API error message
      if (errorData is Map<String, dynamic>) {
        if (errorData.containsKey('message')) {
          return errorData['message'] as String;
        }
      }

      switch (statusCode) {
        case 400:
          return 'Invalid report information. Please check your input.';
        case 401:
          return 'Unauthorized. Please log in again.';
        case 403:
          return 'Forbidden. You do not have permission to perform this action.';
        case 404:
          return 'Report not found.';
        case 409:
          return 'Duplicate report. You have already reported this item.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return 'Error: ${statusCode ?? 'Unknown error'}';
      }
    } else if (e.message != null) {
      return 'Error: ${e.message}';
    } else {
      return 'An unknown error occurred';
    }
  }
}
