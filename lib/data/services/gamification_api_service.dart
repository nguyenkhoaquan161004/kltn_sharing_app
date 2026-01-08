import 'package:dio/dio.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';
import 'package:kltn_sharing_app/core/utils/token_refresh_interceptor.dart';
import 'package:kltn_sharing_app/data/models/gamification_response_model.dart';

class GamificationApiService {
  late Dio _dio;
  late Dio _dioNoAuth; // For public leaderboard endpoints
  late TokenRefreshInterceptor _tokenRefreshInterceptor;
  Future<String?> Function()? _getValidTokenCallback;

  GamificationApiService() {
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

    // Add token interceptor - adds token to every request
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get fresh token before every request
          if (_getValidTokenCallback != null) {
            try {
              final token = await _getValidTokenCallback!();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            } catch (e) {
              print('[GamificationAPI] Error getting token: $e');
            }
          }
          return handler.next(options);
        },
      ),
    );

    // Add logging interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print(
              '[GamificationAPI] REQUEST[${options.method}] => ${options.path}');
          print('[GamificationAPI] Headers: ${options.headers}');
          print('[GamificationAPI] QueryParams: ${options.queryParameters}');
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
          if (e.response != null) {
            print('[GamificationAPI] ERROR Response body: ${e.response!.data}');
          }
          return handler.next(e);
        },
      ),
    );

    // Create Dio instance for public endpoints (no token refresh)
    _dioNoAuth = Dio(
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

    // Add logging interceptor to _dioNoAuth
    _dioNoAuth.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print(
              '[GamificationAPI-NoAuth] REQUEST[${options.method}] => ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '[GamificationAPI-NoAuth] RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (e, handler) {
          print(
              '[GamificationAPI-NoAuth] ERROR[${e.response?.statusCode}] => ${e.requestOptions.path}');
          return handler.next(e);
        },
      ),
    );
  }

  /// Set callback to get valid access token from AuthProvider
  void setGetValidTokenCallback(Future<String?> Function() callback) {
    try {
      _getValidTokenCallback = callback;
      _tokenRefreshInterceptor.setCallbacks(
        getValidTokenCallback: callback,
        onTokenExpiredCallback: () async {
          print('[GamificationAPI] Token refresh failed, user session expired');
        },
      );
    } catch (e) {
      print('[GamificationAPI] Error setting token refresh callback: $e');
    }
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
        'scope': 'GLOBAL',
        'timeFrame': 'ALL_TIME',
        if (sortBy != null) 'sortBy': sortBy,
        if (sortDirection != null) 'sortDirection': sortDirection,
      };

      final response = await _dio.get(
        '/api/v2/gamification/leaderboard',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle ApiResponse<NewLeaderboardResponse>
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            final leaderboardData = data['data'];
            if (leaderboardData is Map<String, dynamic>) {
              // Convert NewLeaderboardResponse to LeaderboardResponse format
              final newResponse =
                  NewLeaderboardResponse.fromJson(leaderboardData);
              return LeaderboardResponse(
                content: newResponse.entries
                    .map((entry) => GamificationDto(
                          id: entry.userId,
                          userId: entry.userId,
                          username: entry.username,
                          avatarUrl: entry.avatarUrl,
                          points: entry.totalPoints,
                          rank: entry.rank,
                          itemsShared: 0,
                          itemsReceived: 0,
                          badge: null,
                        ))
                    .toList(),
                totalElements: newResponse.totalUsers,
                totalPages: newResponse.totalPages,
                currentPage: newResponse.page,
                pageSize: newResponse.size,
              );
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

  /// Get top N users for podium
  Future<List<GamificationDto>> getTopUsers({
    int limit = 3,
    String timeFrame = 'ALL_TIME',
  }) async {
    try {
      final response = await _dio.get(
        '/api/v2/gamification/leaderboard',
        queryParameters: {
          'page': 0,
          'size': limit,
          'scope': 'GLOBAL',
          'timeFrame': timeFrame,
          'sortBy': 'points',
          'sortDirection': 'DESC',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            final leaderboardData = data['data'];
            if (leaderboardData is Map<String, dynamic>) {
              final newResponse =
                  NewLeaderboardResponse.fromJson(leaderboardData);
              return newResponse.entries
                  .map((entry) => GamificationDto(
                        id: entry.userId,
                        userId: entry.userId,
                        username: entry.username,
                        avatarUrl: entry.avatarUrl,
                        points: entry.totalPoints,
                        rank: entry.rank,
                        itemsShared: 0,
                        itemsReceived: 0,
                        badge: null,
                      ))
                  .toList();
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

  /// Get current user's gamification stats (points, level, etc.)
  Future<GamificationDto> getCurrentUserStats() async {
    try {
      final response = await _dio.get('/api/v2/gamification/me');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            final userData = data['data'] as Map<String, dynamic>;
            // Map the response to GamificationDto
            return GamificationDto(
              id: userData['id'] ?? '',
              userId: userData['userId'] ?? userData['user_id'] ?? '',
              username: userData['username'] ?? '',
              avatarUrl: userData['avatarUrl'] ?? userData['avatar_url'],
              points: userData['points'] ?? 0,
              rank: userData['level'] ?? userData['rank'] ?? 0,
              itemsShared:
                  userData['totalShares'] ?? userData['items_shared'] ?? 0,
              itemsReceived:
                  userData['totalReceives'] ?? userData['items_received'] ?? 0,
              badge: null,
            );
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

  /// Get current user stats without triggering token refresh (public endpoint)
  Future<GamificationDto> getCurrentUserStatsNoAuth() async {
    try {
      final response = await _dioNoAuth.get('/api/v2/gamification/me');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            final userData = data['data'] as Map<String, dynamic>;
            // Map the response to GamificationDto
            return GamificationDto(
              id: userData['id'] ?? '',
              userId: userData['userId'] ?? userData['user_id'] ?? '',
              username: userData['username'] ?? '',
              avatarUrl: userData['avatarUrl'] ?? userData['avatar_url'],
              points: userData['points'] ?? 0,
              rank: userData['level'] ?? userData['rank'] ?? 0,
              itemsShared:
                  userData['totalShares'] ?? userData['items_shared'] ?? 0,
              itemsReceived:
                  userData['totalReceives'] ?? userData['items_received'] ?? 0,
              badge: null,
            );
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

  /// Get all badges in the system
  Future<List<Map<String, dynamic>>> getAllBadges() async {
    try {
      final response = await _dio.get('/api/v2/gamification/badges');

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle ApiResponse<List<Badge>>
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            final badgeList = data['data'];
            if (badgeList is List) {
              return badgeList
                  .map((badge) => badge as Map<String, dynamic>)
                  .toList();
            }
          }
        } else if (data is List) {
          // Direct list response
          return data.map((badge) => badge as Map<String, dynamic>).toList();
        }

        throw Exception('Unexpected response format: $data');
      } else {
        throw Exception('Failed to load badges: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get current user's earned badges
  Future<List<Map<String, dynamic>>> getUserBadges() async {
    try {
      final response = await _dio.get('/api/v2/gamification/me/badges');

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle ApiResponse<List<UserBadge>>
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            final badgeList = data['data'];
            if (badgeList is List) {
              return badgeList
                  .map((badge) => badge as Map<String, dynamic>)
                  .toList();
            }
          }
        } else if (data is List) {
          // Direct list response
          return data.map((badge) => badge as Map<String, dynamic>).toList();
        }

        throw Exception('Unexpected response format: $data');
      } else {
        throw Exception('Failed to load user badges: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get all achievements in the system
  Future<List<Map<String, dynamic>>> getAllAchievements() async {
    try {
      final response = await _dio.get('/api/v2/gamification/achievements');

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle ApiResponse<List<Achievement>>
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            final achievementList = data['data'];
            if (achievementList is List) {
              return achievementList
                  .map((achievement) => achievement as Map<String, dynamic>)
                  .toList();
            }
          }
        } else if (data is List) {
          // Direct list response
          return data
              .map((achievement) => achievement as Map<String, dynamic>)
              .toList();
        }

        throw Exception('Unexpected response format: $data');
      } else {
        throw Exception('Failed to load achievements: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get current user's earned achievements
  Future<List<Map<String, dynamic>>> getUserAchievements() async {
    try {
      final response = await _dio.get('/api/v2/gamification/me/achievements');

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle ApiResponse<List<UserAchievement>>
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            final achievementList = data['data'];
            if (achievementList is List) {
              return achievementList
                  .map((achievement) => achievement as Map<String, dynamic>)
                  .toList();
            }
          }
        } else if (data is List) {
          // Direct list response
          return data
              .map((achievement) => achievement as Map<String, dynamic>)
              .toList();
        }

        throw Exception('Unexpected response format: $data');
      } else {
        throw Exception(
            'Failed to load user achievements: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get leaderboard with scope filter (GLOBAL or NEARBY)
  /// For NEARBY scope, requires: currentUserLat, currentUserLon, radiusKm
  Future<NewLeaderboardResponse> getLeaderboardWithScope({
    required String scope, // 'GLOBAL' or 'NEARBY'
    String timeFrame = 'ALL_TIME', // 'ALL_TIME', 'MONTHLY', 'WEEKLY'
    double? currentUserLat,
    double? currentUserLon,
    double radiusKm = 50.0,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = {
        'scope': scope,
        'timeFrame': timeFrame,
        'page': page,
        'size': size,
        if (scope == 'NEARBY') ...{
          'radiusKm': radiusKm,
          'currentUserLat': currentUserLat,
          'currentUserLon': currentUserLon,
        }
      };

      print(
          '[GamificationAPI] Fetching leaderboard with scope=$scope, lat=$currentUserLat, lon=$currentUserLon, radius=$radiusKm');

      final response = await _dio.get(
        '/api/v2/gamification/leaderboard',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle ApiResponse<NewLeaderboardResponse>
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            final leaderboardData = data['data'];
            if (leaderboardData is Map<String, dynamic>) {
              return NewLeaderboardResponse.fromJson(leaderboardData);
            }
          }
          // Direct response format
          return NewLeaderboardResponse.fromJson(data);
        }

        throw Exception('Unexpected response format: $data');
      } else {
        throw Exception('Failed to load leaderboard: ${response.statusCode}');
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
