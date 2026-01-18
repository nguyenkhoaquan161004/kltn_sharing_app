import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:kltn_sharing_app/core/config/app_config.dart';
import 'package:kltn_sharing_app/core/utils/token_refresh_interceptor.dart';
import 'package:kltn_sharing_app/data/models/item_response_model.dart';
import 'package:kltn_sharing_app/data/models/item_model.dart';
import 'package:kltn_sharing_app/data/models/transaction_model.dart';

class ItemApiService {
  late Dio _dio;
  late Dio
      _dioNoAuth; // Dio instance without token refresh for public endpoints
  late TokenRefreshInterceptor _tokenRefreshInterceptor;

  ItemApiService() {
    // Initialize token refresh interceptor FIRST before creating Dio
    _tokenRefreshInterceptor = TokenRefreshInterceptor();

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
    _dio.interceptors.add(_tokenRefreshInterceptor);

    // Set main Dio reference so TokenRefreshInterceptor can retry original requests
    _tokenRefreshInterceptor.setMainDio(_dio);

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

    // Create a separate Dio instance for public endpoints (no token refresh)
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
              '[ItemAPI-NoAuth] REQUEST[${options.method}] => ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '[ItemAPI-NoAuth] RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (e, handler) {
          print(
              '[ItemAPI-NoAuth] ERROR[${e.response?.statusCode}] => ${e.requestOptions.path}');
          return handler.next(e);
        },
      ),
    );
  }

  /// Set token refresh callback (delegates to TokenRefreshInterceptor)
  void setGetValidTokenCallback(
      Future<void> Function() onTokenExpiredCallback) {
    try {
      _tokenRefreshInterceptor.setCallbacks(
        getValidTokenCallback: () async =>
            null, // Not needed, interceptor handles it
        onTokenExpiredCallback: onTokenExpiredCallback,
      );
    } catch (e) {
      print('[ItemAPI] Error setting token refresh callback: $e');
    }
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

  /// Ensure token is loaded from SharedPreferences before making API calls
  /// This prevents "No refresh token available" errors when token was set earlier
  Future<void> _ensureTokenLoaded() async {
    try {
      // Check if we already have a token set
      final currentAuth = _dio.options.headers['Authorization'];
      if (currentAuth != null && currentAuth.toString().isNotEmpty) {
        print(
            '[ItemAPI] Token already set: ${currentAuth.toString().substring(0, 30)}...');
        return;
      }

      // Load token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('access_token');

      if (savedToken != null && savedToken.isNotEmpty) {
        setAuthToken(savedToken);
        print('[ItemAPI] ✅ Token loaded from SharedPreferences');
      } else {
        print('[ItemAPI] ⚠️  No saved token found in SharedPreferences');
      }
    } catch (e) {
      print('[ItemAPI] ⚠️  Error loading token from SharedPreferences: $e');
    }
  }

  /// Update Dio baseUrl when backend switches
  void _updateDioBaseUrl() {
    _dio.options.baseUrl = AppConfig.baseUrl;
  }

  /// Search nearby items based on user location
  /// Requires [latitude] and [longitude], optionally [maxDistanceKm] (default 50km)
  /// If server returns 500 error, automatically retries without maxDistanceKm
  Future<PageResponse<ItemDto>> searchNearbyItems({
    required double latitude,
    required double longitude,
    double maxDistanceKm = 50,
    int page = 0,
    int size = 10,
    String? keyword,
    String? categoryId,
    String? status = 'AVAILABLE',
    String? sortBy = 'createdAt',
    String? sortDirection = 'ASC',
  }) async {
    try {
      // Validate coordinates
      if (latitude.isNaN ||
          latitude.isInfinite ||
          longitude.isNaN ||
          longitude.isInfinite) {
        throw Exception('Invalid coordinates: lat=$latitude, lon=$longitude');
      }
      if (latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        throw Exception(
            'Coordinates out of range: lat=$latitude, lon=$longitude');
      }

      // Ensure token is loaded from SharedPreferences before making the request
      await _ensureTokenLoaded();

      print(
          '[ItemAPI.searchNearbyItems] Starting - lat: $latitude, lon: $longitude, page: $page');

      final queryParams = {
        'page': page + 1, // BE expects 1-based page numbering
        'limit': size,
        'userLat': latitude,
        'userLon': longitude,
        'maxDistanceKm': maxDistanceKm,
        if (keyword != null && keyword.isNotEmpty) 'name': keyword,
        if (categoryId != null && categoryId.isNotEmpty && categoryId != 'null')
          'categoryId': categoryId,
        if (status != null && status.isNotEmpty) 'status': status,
        // TODO: Backend may not support sort + geo filter together
        // 'sortBy': sortBy,
        // 'sortOrder': sortDirection,
      };
      print('[ItemAPI] searchNearbyItems called with:');
      print(
          '[ItemAPI]   latitude: $latitude, longitude: $longitude, maxDistanceKm: $maxDistanceKm');
      print('[ItemAPI]   keyword: "$keyword" (isEmpty: ${keyword?.isEmpty})');
      print(
          '[ItemAPI]   categoryId: "$categoryId" (isEmpty: ${categoryId?.isEmpty}, isNullString: ${categoryId == 'null'})');
      print('[ItemAPI]   Final queryParams: $queryParams');

      final response = await _dio.get(
        '/api/v2/items',
        queryParameters: queryParams,
      );

      print('[ItemAPI] searchNearbyItems URL: ${response.requestOptions.uri}');

      if (response.statusCode == 200) {
        final data = response.data;
        print(
            '[ItemAPI.searchNearbyItems] Response data type: ${data.runtimeType}');
        print(
            '[ItemAPI.searchNearbyItems] Response keys: ${data is Map ? data.keys : 'N/A'}');
        print('[ItemAPI.searchNearbyItems] Full response: $data');

        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            final pageData = data['data'];
            print(
                '[ItemAPI.searchNearbyItems] pageData type: ${pageData.runtimeType}');
            print(
                '[ItemAPI.searchNearbyItems] pageData keys: ${pageData is Map ? pageData.keys : 'N/A'}');

            if (pageData is Map<String, dynamic>) {
              final contentLength = pageData['content']?.length ?? 0;
              final itemsLength = pageData['items']?.length ?? 0;
              final dataLength = pageData['data']?.length ?? 0;
              final totalElements = pageData['totalItems'] ??
                  pageData['totalElements'] ??
                  pageData['total'] ??
                  0;
              print(
                  '[ItemAPI.searchNearbyItems] Response structure - content: $contentLength, items: $itemsLength, data: $dataLength, totalItems: $totalElements');
              final actualItemCount = dataLength > 0
                  ? dataLength
                  : (contentLength > 0 ? contentLength : itemsLength);
              print(
                  '[ItemAPI.searchNearbyItems] Successfully parsed response, got $actualItemCount items (total: $totalElements)');
              return PageResponse<ItemDto>.fromJson(
                pageData,
                (json) => ItemDto.fromJson(json),
              );
            }
          } else {
            try {
              final contentLength = data['content']?.length ?? 0;
              print(
                  '[ItemAPI.searchNearbyItems] Direct parse - got $contentLength items');
              return PageResponse<ItemDto>.fromJson(
                data,
                (json) => ItemDto.fromJson(json),
              );
            } catch (e) {
              print('[ItemAPI] Failed to parse response: $e');
            }
          }
        }

        throw Exception('Unexpected response format: $data');
      } else {
        throw Exception('Failed to load nearby items: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print(
          '[ItemAPI.searchNearbyItems] DioException: ${e.response?.statusCode} - ${e.message}');
      // Print error response for debugging
      if (e.response?.statusCode == 500) {
        print(
            '[ItemAPI.searchNearbyItems] Server error response: ${e.response?.data}');
        print('[ItemAPI.searchNearbyItems] Retrying without maxDistanceKm...');

        // Retry without maxDistanceKm parameter to bypass server issue
        try {
          final retryQueryParams = {
            'page': page + 1,
            'limit': size,
            'userLat': latitude,
            'userLon': longitude,
            // maxDistanceKm removed for retry
            if (keyword != null && keyword.isNotEmpty) 'name': keyword,
            if (categoryId != null &&
                categoryId.isNotEmpty &&
                categoryId != 'null')
              'categoryId': categoryId,
            if (status != null && status.isNotEmpty) 'status': status,
          };

          print('[ItemAPI] Retry queryParams: $retryQueryParams');
          final retryResponse = await _dio.get(
            '/api/v2/items',
            queryParameters: retryQueryParams,
          );

          if (retryResponse.statusCode == 200) {
            final data = retryResponse.data;
            print(
                '[ItemAPI.searchNearbyItems] Retry successful! Got ${data['data']?['content']?.length ?? 0} items');

            if (data is Map<String, dynamic>) {
              if (data.containsKey('data')) {
                final pageData = data['data'];
                if (pageData is Map<String, dynamic>) {
                  return PageResponse<ItemDto>.fromJson(
                    pageData,
                    (json) => ItemDto.fromJson(json),
                  );
                }
              } else {
                return PageResponse<ItemDto>.fromJson(
                  data,
                  (json) => ItemDto.fromJson(json),
                );
              }
            }
          }
        } catch (retryError) {
          print('[ItemAPI.searchNearbyItems] Retry also failed: $retryError');
          throw _handleDioException(e); // Throw original error
        }
      }
      throw _handleDioException(e);
    }
  }

  /// Search items with simplified parameters
  /// Supports:
  /// 1. Keyword search: provide [keyword]
  /// 2. Category search: provide [categoryId]
  /// 3. Combined search: provide both [keyword] and [categoryId]
  Future<PageResponse<ItemDto>> searchItems({
    int page = 0,
    int size = 10,
    String? keyword,
    String? categoryId,
    String? status = 'AVAILABLE',
    String? sortBy = 'createdAt',
    String? sortDirection = 'ASC',
  }) async {
    try {
      // Ensure token is loaded from SharedPreferences before making the request
      await _ensureTokenLoaded();

      final queryParams = {
        'page': page + 1, // BE expects 1-based page numbering
        'limit': size,
        if (keyword != null && keyword.isNotEmpty) 'name': keyword,
        if (categoryId != null && categoryId.isNotEmpty && categoryId != 'null')
          'categoryId': categoryId,
        if (status != null && status.isNotEmpty) 'status': status,
        'sortBy': sortBy,
        'sortOrder':
            sortDirection, // BE expects 'sortOrder' not 'sortDirection'
      };
      print('[ItemAPI] searchItems called with:');
      print('[ItemAPI]   keyword: "$keyword" (isEmpty: ${keyword?.isEmpty})');
      print(
          '[ItemAPI]   categoryId: "$categoryId" (isEmpty: ${categoryId?.isEmpty})');
      print('[ItemAPI]   status: "$status"');
      print('[ItemAPI]   Final queryParams: $queryParams');

      final response = await _dio.get(
        '/api/v2/items',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle case where response is already a Map (API returns ApiResponse<PageResponse>)
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            final pageData = data['data'];
            if (pageData is Map<String, dynamic>) {
              return PageResponse<ItemDto>.fromJson(
                pageData,
                (json) => ItemDto.fromJson(json),
              );
            }
          } else {
            // Try to parse directly if no "data" wrapper
            try {
              return PageResponse<ItemDto>.fromJson(
                data,
                (json) => ItemDto.fromJson(json),
              );
            } catch (e) {
              print('[ItemAPI] Failed to parse response: $e');
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
      // Ensure token is loaded from SharedPreferences before making the request
      await _ensureTokenLoaded();

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

  /// Get all items owned by the authenticated user
  Future<PageResponse<ItemDto>> getUserItems({
    int page = 1, // Backend uses 1-indexed pages, not 0
    int size = 10,
    String? status,
    String? sortBy = 'createdAt',
    String? sortOrder = 'DESC',
  }) async {
    try {
      // Ensure token is loaded from SharedPreferences before making the request
      await _ensureTokenLoaded();

      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': size,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _dio.get(
        '/api/v2/items/me',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('[ItemAPI] getUserItems response data: $data');

        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final pageData = data['data'] as Map<String, dynamic>;
          print('[ItemAPI] pageData keys: ${pageData.keys.toList()}');
          print('[ItemAPI] pageData: $pageData');
          final contentList = pageData['data'];
          print(
              '[ItemAPI] contentList type: ${contentList.runtimeType}, value: $contentList');
          final content = (contentList is List<dynamic> ? contentList : [])
              .map((item) => ItemDto.fromJson(item as Map<String, dynamic>))
              .toList();

          final currentPage = pageData['page'] ?? page;
          final totalPages = pageData['totalPages'] ?? 0;

          return PageResponse<ItemDto>(
            content: content,
            totalElements: pageData['totalItems'] ??
                0, // ✅ Use 'totalItems' instead of 'totalElements'
            totalPages: totalPages,
            currentPage: currentPage,
            pageSize: pageData['limit'] ?? size,
            isFirst: currentPage == 1, // First page is 1
            isLast: currentPage >= totalPages, // Compare with total pages
            isEmpty: content.isEmpty,
          );
        }

        throw Exception('Invalid response format: $data');
      } else {
        throw Exception('Failed to load user items: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Create a new item (product)
  Future<bool> createItem({
    required String name,
    required String description,
    required int quantity,
    required String imageUrl,
    required DateTime expiryDate,
    required String categoryId,
    required double latitude,
    required double longitude,
    required double price,
  }) async {
    try {
      final requestBody = {
        'name': name,
        'description': description,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'expiryDate': expiryDate.toIso8601String(),
        'categoryId': categoryId,
        'latitude': latitude,
        'longitude': longitude,
        'price': price,
      };

      print('[ItemAPI] Creating item with body: $requestBody');

      final response = await _dio.post(
        '/api/v2/items',
        data: requestBody,
      );

      if (response.statusCode == 201) {
        print('[ItemAPI] Item created successfully');
        return true;
      } else {
        throw Exception('Failed to create item: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get interested users for items user shared (as sharer) - Only count PENDING transactions
  Future<Map<String, int>> getSharerTransactions({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v2/transactions/as-sharer',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final pageData = data['data'] as Map<String, dynamic>;
          final contentList = pageData['content'] ?? pageData['data'];
          final transactions = (contentList is List<dynamic> ? contentList : [])
              .cast<Map<String, dynamic>>();

          print('[ItemAPI] pageData keys: ${pageData.keys.toList()}');
          print('[ItemAPI] Found ${transactions.length} total transactions');

          // Count only PENDING transactions by itemId
          Map<String, int> itemInterestCount = {};
          for (final transaction in transactions) {
            // Only count PENDING transactions (people who want to receive)
            final status = transaction['status']?.toString() ?? '';
            if (status.toUpperCase() == 'PENDING') {
              final itemId = transaction['itemId']?.toString() ??
                  transaction['itemIdUuid']?.toString();
              if (itemId != null) {
                itemInterestCount[itemId] =
                    (itemInterestCount[itemId] ?? 0) + 1;
                print('[ItemAPI] PENDING Transaction itemId: $itemId');
              }
            } else {
              print(
                  '[ItemAPI] Skipping non-PENDING transaction with status: $status');
            }
          }

          print(
              '[ItemAPI] Loaded ${transactions.length} transactions, ${itemInterestCount.length} unique items with PENDING requests');
          print(
              '[ItemAPI] itemInterestCount map (PENDING only): $itemInterestCount');
          return itemInterestCount;
        }

        throw Exception('Invalid response format: $data');
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get all requesters (transactions) for a specific item where user is sharer
  Future<List<TransactionModel>> getSharerTransactionsForItem(
      String itemId) async {
    try {
      final response = await _dio.get(
        '/api/v2/transactions/as-sharer',
        queryParameters: {
          'page': 1,
          'limit': 100,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final pageData = data['data'] as Map<String, dynamic>;
          final contentList = pageData['content'] ?? pageData['data'];
          final transactionsList =
              (contentList is List<dynamic> ? contentList : [])
                  .cast<Map<String, dynamic>>();

          // Filter transactions for this specific item
          final filteredTransactions = transactionsList
              .where((tx) {
                final txItemId =
                    tx['itemId']?.toString() ?? tx['itemIdUuid']?.toString();
                return txItemId == itemId;
              })
              .map((json) {
                try {
                  return TransactionModel.fromJson(json);
                } catch (e) {
                  print('[ItemAPI] Error parsing transaction: $e');
                  return null;
                }
              })
              .whereType<TransactionModel>()
              .toList();

          print(
              '[ItemAPI] Found ${filteredTransactions.length} requesters for item $itemId');
          return filteredTransactions;
        }

        throw Exception('Invalid response format: $data');
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Exception _handleDioException(DioException e) {
    String message;

    if (e.response != null) {
      // Response data might be Map, String, or other types
      final data = e.response!.data;
      final Map<String, dynamic>? dataAsMap =
          data is Map<String, dynamic> ? data : null;

      // Debug log for all error responses
      print('[ItemAPI] ERROR RESPONSE[${e.response!.statusCode}]: $data');

      switch (e.response!.statusCode) {
        case 400:
          message = dataAsMap?['message'] ?? 'Yêu cầu không hợp lệ.';
          break;
        case 401:
          message = 'Token hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.';
          break;
        case 403:
          message = 'Bạn không có quyền thực hiện hành động này (403).';
          break;
        case 404:
          message = 'Không tìm thấy sản phẩm.';
          break;
        case 422:
          message = dataAsMap?['message'] ?? 'Dữ liệu không hợp lệ.';
          break;
        case 500:
        case 502:
        case 503:
          message = 'Máy chủ bị lỗi. Vui lòng thử lại sau.';
          break;
        default:
          message = dataAsMap?['message'] ?? 'Đã xảy ra lỗi';
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

  /// Update item description (for storing recipient info when accepted)
  Future<void> updateItemDescription(
    String itemId,
    String newDescription,
  ) async {
    try {
      final requestBody = {
        'description': newDescription,
      };

      print('[ItemAPI] Updating item $itemId description');

      final response = await _dio.put(
        '/api/v2/items/$itemId',
        data: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('[ItemAPI] Item description updated successfully');
      } else {
        throw Exception('Failed to update item: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Update item quantity
  Future<void> updateItemQuantity(
    String itemId,
    int newQuantity,
  ) async {
    try {
      final requestBody = {
        'quantity': newQuantity,
      };

      print('[ItemAPI] Updating item $itemId quantity to $newQuantity');

      final response = await _dio.put(
        '/api/v2/items/$itemId',
        data: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('[ItemAPI] Item quantity updated successfully');
      } else {
        throw Exception(
            'Failed to update item quantity: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _dio.get('/api/v2/categories/all');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final categoriesList = data['data'];
          if (categoriesList is List) {
            return categoriesList.cast<Map<String, dynamic>>();
          }
        }

        throw Exception('Unexpected response format: $data');
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Search items by image
  /// POST /api/v2/items/search-by-image
  /// body: { "imageUrl": "string" }
  Future<List<ItemModel>> searchByImage(String imageUrl) async {
    try {
      print('[ItemAPI] Searching items by image: $imageUrl');

      final response = await _dio.post(
        '/api/v2/items/search-by-image',
        data: {
          'imageUrl': imageUrl,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('[ItemAPI] Search by image response: $data');

        if (data is Map<String, dynamic>) {
          // Check if response has 'data' field with items
          if (data.containsKey('data')) {
            final itemsList = data['data'];
            if (itemsList is List) {
              return itemsList
                  .map((item) =>
                      ItemModel.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
          }
        }

        // If response is a direct List
        if (data is List) {
          return data
              .map((item) => ItemModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        return [];
      } else {
        throw Exception('Failed to search by image: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get search history for a user
  /// GET /api/v2/admin/redis/search-history/{userId}
  Future<List<String>> getSearchHistory({
    required String userId,
    int limit = 5,
  }) async {
    try {
      print(
          '[ItemAPI] REQUEST[GET] => /api/v2/admin/redis/search-history/$userId?limit=$limit');

      final response = await _dio.get(
        '/api/v2/admin/redis/search-history/$userId',
        queryParameters: {
          'limit': limit,
        },
      );

      print(
          '[ItemAPI] RESPONSE[${response.statusCode}] => Search history retrieved');

      // Parse response
      if (response.data is Map) {
        final data = response.data['data'];

        if (data is List) {
          // Convert list items to strings
          return data.map((item) {
            if (item is String) {
              return item;
            } else if (item is Map) {
              return item['term']?.toString() ?? item.toString();
            }
            return item.toString();
          }).toList();
        }
      }

      return [];
    } on DioException catch (e) {
      print(
          '[ItemAPI] ERROR[${e.response?.statusCode}] => Failed to get search history');
      // Return empty list on error instead of throwing
      return [];
    }
  }

  /// Get recent search history
  /// GET /api/v2/search/history/recent (Requires authentication)
  Future<List<String>> getRecentSearchHistory({int limit = 5}) async {
    try {
      print(
          '[ItemAPI] REQUEST[GET] => /api/v2/search/history/recent?limit=$limit');

      final response = await _dio.get(
        '/api/v2/search/history/recent',
        queryParameters: {
          'limit': limit,
        },
      );

      print(
          '[ItemAPI] RESPONSE[${response.statusCode}] => Recent search history retrieved');

      // Parse response
      if (response.data is Map) {
        var data = response.data['data'];
        print('[ItemAPI] DATA TYPE: ${data.runtimeType}');
        print('[ItemAPI] DATA VALUE: $data');

        if (data is List) {
          print('[ItemAPI] Processing List with ${data.length} items');
          final result = <String>[];

          for (var item in data) {
            print('[ItemAPI] Item type: ${item.runtimeType}, value: $item');

            Map<String, dynamic> itemMap;

            // If item is a String, parse it as JSON
            if (item is String) {
              itemMap = jsonDecode(item);
            } else if (item is Map) {
              itemMap = Map<String, dynamic>.from(item);
            } else {
              continue;
            }

            final query = itemMap['query']?.toString();
            if (query != null && query.isNotEmpty) {
              print('[ItemAPI] Extracted query: $query');
              result.add(query);
            }
          }

          print('[ItemAPI] Final result: $result');
          return result;
        }
      }

      return [];
    } on DioException catch (e) {
      print(
          '[ItemAPI] ERROR[${e.response?.statusCode}] => Failed to get recent search history');
      print('[ItemAPI] ERROR MESSAGE: ${e.message}');
      return [];
    }
  }

  /// Delete all search history
  /// DELETE /api/v2/search/history
  Future<bool> deleteSearchHistory() async {
    try {
      print('[ItemAPI] REQUEST[DELETE] => /api/v2/search/history');

      final response = await _dio.delete(
        '/api/v2/search/history',
      );

      print(
          '[ItemAPI] RESPONSE[${response.statusCode}] => Search history deleted');
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      print(
          '[ItemAPI] ERROR[${e.response?.statusCode}] => Failed to delete search history');
      print('[ItemAPI] ERROR MESSAGE: ${e.message}');
      return false;
    }
  }

  /// Delete an item by ID
  /// DELETE /api/v2/items/{id}
  Future<bool> deleteItem(String itemId) async {
    try {
      print('[ItemAPI] REQUEST[DELETE] => /api/v2/items/$itemId');

      final response = await _dio.delete(
        '/api/v2/items/$itemId',
      );

      print(
          '[ItemAPI] RESPONSE[${response.statusCode}] => Item $itemId deleted');
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      print(
          '[ItemAPI] ERROR[${e.response?.statusCode}] => Failed to delete item $itemId');
      print('[ItemAPI] ERROR MESSAGE: ${e.message}');
      return false;
    }
  }
}
