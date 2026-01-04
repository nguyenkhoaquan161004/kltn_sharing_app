import 'package:dio/dio.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';
import 'package:kltn_sharing_app/core/utils/token_refresh_interceptor.dart';
import 'package:kltn_sharing_app/data/models/item_response_model.dart';
import 'package:kltn_sharing_app/data/models/transaction_model.dart';

class ItemApiService {
  late Dio _dio;
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

  /// Set token refresh callback (delegates to TokenRefreshInterceptor)
  void setGetValidTokenCallback(Future<void> Function() onTokenExpiredCallback) {
    try {
      _tokenRefreshInterceptor.setCallbacks(
        getValidTokenCallback: () async => null, // Not needed, interceptor handles it
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

  /// Update Dio baseUrl when backend switches
  void _updateDioBaseUrl() {
    _dio.options.baseUrl = AppConfig.baseUrl;
  }

  /// Search nearby items based on user location
  /// Requires [latitude], [longitude], and optionally [radiusKm] (default 50km)
  Future<PageResponse<ItemDto>> searchNearbyItems({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
    int page = 0,
    int size = 10,
    String? status = 'AVAILABLE',
    String? sortBy = 'createdAt',
    String? sortDirection = 'DESC',
  }) async {
    try {
      print(
          '[ItemAPI.searchNearbyItems] Starting - lat: $latitude, lon: $longitude, page: $page');

      final queryParams = {
        'page': page + 1, // BE expects 1-based page numbering
        'limit': size,
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm,
        if (status != null && status.isNotEmpty) 'status': status,
        'sortBy': sortBy,
        'sortOrder': sortDirection,
      };
      print('[ItemAPI] searchNearbyItems called with:');
      print('[ItemAPI]   latitude: $latitude, longitude: $longitude');
      print('[ItemAPI]   radiusKm: $radiusKm');
      print('[ItemAPI]   Final queryParams: $queryParams');

      final response = await _dio.get(
        '/api/v2/items',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            final pageData = data['data'];
            if (pageData is Map<String, dynamic>) {
              print(
                  '[ItemAPI.searchNearbyItems] Successfully parsed response, got ${pageData['content']?.length ?? 0} items');
              return PageResponse<ItemDto>.fromJson(
                pageData,
                (json) => ItemDto.fromJson(json),
              );
            }
          } else {
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
        throw Exception('Failed to load nearby items: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print(
          '[ItemAPI.searchNearbyItems] DioException: ${e.response?.statusCode} - ${e.message}');
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
    String? sortDirection = 'DESC',
  }) async {
    try {
      final queryParams = {
        'page': page + 1, // BE expects 1-based page numbering
        'limit': size,
        if (keyword != null && keyword.isNotEmpty) 'name': keyword,
        if (categoryId != null && categoryId.isNotEmpty)
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

  /// Get interested users for items user shared (as sharer)
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

          // Count transactions by itemId
          Map<String, int> itemInterestCount = {};
          for (final transaction in transactions) {
            final itemId = transaction['itemId']?.toString() ??
                transaction['itemIdUuid']?.toString();
            if (itemId != null) {
              itemInterestCount[itemId] = (itemInterestCount[itemId] ?? 0) + 1;
              print('[ItemAPI] Transaction itemId: $itemId');
            }
          }

          print(
              '[ItemAPI] Loaded ${transactions.length} transactions, ${itemInterestCount.length} unique items');
          print('[ItemAPI] itemInterestCount map: $itemInterestCount');
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
}
