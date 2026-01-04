import 'package:dio/dio.dart';
import 'package:kltn_sharing_app/data/models/auth_request_model.dart';
import 'package:kltn_sharing_app/data/models/auth_response_model.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';

/// API Service for Authentication endpoints
class AuthApiService {
  late Dio _dio;

  AuthApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.authBaseUrl,
        connectTimeout: Duration(seconds: AppConfig.requestTimeoutSeconds),
        receiveTimeout: Duration(seconds: AppConfig.requestTimeoutSeconds),
        contentType: 'application/json',
      ),
    );

    // Add interceptors for logging and error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('REQUEST[${options.method}] => PATH: ${options.path}');
          print('URL: ${options.uri}');
          if (options.data != null) {
            print('REQUEST DATA: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          print('RESPONSE DATA: ${response.data}');
          return handler.next(response);
        },
        onError: (e, handler) {
          print(
              'ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
          print('ERROR MESSAGE: ${e.message}');
          if (e.response?.data != null) {
            print('ERROR DATA: ${e.response!.data}');
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// Login endpoint
  Future<TokenResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        '/login',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data['success'] == true && data['data'] != null) {
            return TokenResponse.fromJson(data['data']);
          } else {
            throw Exception(data['message'] ?? 'Login failed');
          }
        } else {
          throw Exception('Invalid login response format');
        }
      } else {
        throw Exception(
            'Login failed with status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Register endpoint - sends OTP to email
  Future<String> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        '/register',
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;

          // Check for success field
          if (data.containsKey('success')) {
            if (data['success'] == true) {
              return data['message'] ??
                  'Registration request sent. Please verify OTP.';
            } else {
              throw Exception(data['message'] ?? 'Registration failed');
            }
          }

          // Check for message field (alternative response format)
          if (data.containsKey('message')) {
            return data['message'];
          }

          // Default success for 201 response
          return 'Registration request sent. Please verify OTP.';
        } else {
          // Response is not a map (might be empty or string)
          return 'Registration request sent. Please verify OTP.';
        }
      } else {
        throw Exception(
            'Registration failed with status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Verify registration OTP
  Future<String> verifyRegistration(VerifyRegistrationRequest request) async {
    try {
      final requestData = request.toJson();
      print('[verifyRegistration] Sending request: $requestData');
      final response = await _dio.post(
        '/verify-registration',
        data: requestData,
      );
      print('[verifyRegistration] Response status: ${response.statusCode}');
      print('[verifyRegistration] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle different response formats
        if (data is Map<String, dynamic>) {
          // Check for success field
          if (data.containsKey('success')) {
            if (data['success'] == true) {
              return data['message'] ?? 'Registration verified successfully';
            } else {
              throw Exception(data['message'] ?? 'Verification failed');
            }
          } else if (data.containsKey('message')) {
            // Message-only format
            return data['message'];
          } else if (data.containsKey('verified') && data['verified'] == true) {
            // Alternative format with 'verified' instead of 'success'
            return data['message'] ?? 'Registration verified successfully';
          } else {
            // Generic success response
            return 'Registration verified successfully';
          }
        } else {
          // Response is not a map (might be empty)
          return 'Registration verified successfully';
        }
      } else {
        throw Exception(
            'Verification failed with status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Send OTP to email
  Future<void> sendOtp(SendOtpRequest request) async {
    try {
      final response = await _dio.post(
        '/send-otp',
        data: request.toJson(),
      );

      if (response.statusCode != 200) {
        String errorMessage = 'Failed to send OTP';
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          errorMessage = data['message'] ?? errorMessage;
        }
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Refresh access token
  Future<TokenResponse> refreshToken(RefreshTokenRequest request) async {
    try {
      final response = await _dio.post(
        '/refresh-token',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data['success'] == true && data['data'] != null) {
            return TokenResponse.fromJson(data['data']);
          } else {
            throw Exception(data['message'] ?? 'Token refresh failed');
          }
        } else {
          throw Exception('Invalid token refresh response format');
        }
      } else {
        throw Exception(
            'Token refresh failed with status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Step 1: Request password reset OTP
  Future<void> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Forgot password request failed with status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Step 2: Verify password reset OTP and get reset token
  Future<String> verifyPasswordResetOtp(String email, String otpCode) async {
    try {
      final response = await _dio.post(
        '/verify-password-reset-otp',
        data: {
          'email': email,
          'otpCode': otpCode,
        },
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data['success'] == true && data['data'] != null) {
            final resetData = data['data'] as Map<String, dynamic>;
            return resetData['resetToken'] ?? '';
          } else {
            throw Exception(data['message'] ?? 'OTP verification failed');
          }
        } else {
          throw Exception('Invalid OTP verification response format');
        }
      } else {
        throw Exception(
            'OTP verification failed with status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Step 3: Reset password using reset token
  Future<String> resetPassword(String resetToken, String newPassword) async {
    try {
      final response = await _dio.post(
        '/reset-password',
        data: {
          'resetToken': resetToken,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data['success'] == true) {
            return data['message'] ?? 'Password reset successfully';
          } else {
            throw Exception(data['message'] ?? 'Password reset failed');
          }
        } else {
          throw Exception('Invalid reset password response format');
        }
      } else {
        throw Exception(
            'Password reset failed with status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Logout endpoint
  Future<void> logout(String? refreshToken) async {
    try {
      final data = refreshToken != null ? {'refreshToken': refreshToken} : {};
      await _dio.post('/logout', data: data);
    } on DioException catch (e) {
      // Don't throw on logout errors, just log them
      print('Logout error: ${e.message}');
    }
  }

  /// Google login endpoint
  Future<TokenResponse> googleLogin({
    String? idToken,
    String? code,
    String? redirectUri,
    String? codeVerifier,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (idToken != null) data['idToken'] = idToken;
      if (code != null) data['code'] = code;
      if (redirectUri != null) data['redirectUri'] = redirectUri;
      if (codeVerifier != null) data['codeVerifier'] = codeVerifier;

      final response = await _dio.post(
        '/google',
        data: data,
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          if (responseData['success'] == true && responseData['data'] != null) {
            return TokenResponse.fromJson(responseData['data']);
          } else {
            throw Exception(responseData['message'] ?? 'Google login failed');
          }
        } else {
          throw Exception('Invalid google login response format');
        }
      } else {
        throw Exception(
            'Google login failed with status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Set authorization header with access token
  void setAuthToken(String accessToken) {
    _dio.options.headers['Authorization'] = 'Bearer $accessToken';
  }

  /// Remove authorization header
  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Handle DioException
  Exception _handleDioException(DioException e) {
    String message;

    if (e.response != null) {
      Map<String, dynamic>? data;
      if (e.response!.data is Map<String, dynamic>) {
        data = e.response!.data as Map<String, dynamic>;
      }

      print('[AuthAPI] Error response status: ${e.response!.statusCode}');
      print('[AuthAPI] Error response data: ${e.response!.data}');

      // Handle specific HTTP status codes
      switch (e.response!.statusCode) {
        case 401:
          message =
              'Thông tin không đúng hoặc không hợp lệ. Vui lòng đăng nhập lại.';
          break;
        case 403:
          message = 'Bạn không có quyền thực hiện hành động này.';
          break;
        case 422:
          message = data?['message'] ??
              'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';
          break;
        case 429:
          message = 'Quá nhiều yêu cầu. Vui lòng đợi một lúc.';
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
