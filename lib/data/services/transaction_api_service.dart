import 'package:dio/dio.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';
import 'package:kltn_sharing_app/core/utils/token_refresh_interceptor.dart';
import 'package:kltn_sharing_app/data/models/transaction_request_model.dart';
import 'package:kltn_sharing_app/data/models/transaction_model.dart';

/// API Service for Transactions endpoints
class TransactionApiService {
  late Dio _dio;
  late TokenRefreshInterceptor _tokenRefreshInterceptor;
  Future<String?> Function()? _getValidTokenCallback;

  TransactionApiService() {
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
              '[TransactionAPI] REQUEST[${options.method}] => ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '[TransactionAPI] RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (e, handler) {
          print(
              '[TransactionAPI] ERROR[${e.response?.statusCode}] => ${e.requestOptions.path}');
          return handler.next(e);
        },
      ),
    );
  }

  /// Set callback to get valid access token from AuthProvider
  void setGetValidTokenCallback(Future<String?> Function() callback) {
    _getValidTokenCallback = callback;
    try {
      _tokenRefreshInterceptor.setCallbacks(
        getValidTokenCallback: callback,
        onTokenExpiredCallback: () async {
          print('[TransactionAPI] Token refresh failed, user session expired');
        },
      );
    } catch (e) {
      print('[TransactionAPI] Error setting token refresh callback: $e');
    }
  }

  /// Set authorization header with bearer token
  void setAuthToken(String accessToken) {
    _dio.options.headers['Authorization'] = 'Bearer $accessToken';
    print('[TransactionAPI] Token set');
  }

  /// Remove authorization header
  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Create a transaction (request to receive item)
  Future<Map<String, dynamic>> createTransaction(
      TransactionRequest request) async {
    try {
      // Ensure token is valid before making request
      if (_getValidTokenCallback != null) {
        final validToken = await _getValidTokenCallback!();
        if (validToken != null) {
          _dio.options.headers['Authorization'] = 'Bearer $validToken';
        }
      }

      final response = await _dio.post(
        '/api/v2/transactions',
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          print('[TransactionAPI] Transaction created successfully');
          return data;
        }

        throw Exception('Unexpected response format: $data');
      } else {
        throw Exception('Failed to create transaction: ${response.statusCode}');
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
          message = 'Sản phẩm không tìm thấy.';
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

  /// Get all transactions for current user
  Future<List<TransactionModel>> getMyTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v2/transactions/me',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final apiResponse = response.data;
        print('[TransactionAPI] API Response type: ${apiResponse.runtimeType}');

        if (apiResponse is Map<String, dynamic>) {
          print(
              '[TransactionAPI] API Response keys: ${apiResponse.keys.toList()}');

          // The response structure is:
          // {
          //   success, status, code, message,
          //   data: {
          //     page, limit, totalItems, totalPages,
          //     data: [...]  // Actual transactions list
          //   }
          // }

          // First, extract the PageResponse from ApiResponse.data
          final pageResponse = apiResponse['data'];
          print(
              '[TransactionAPI] PageResponse type: ${pageResponse.runtimeType}');

          if (pageResponse is Map<String, dynamic>) {
            // Now extract the transactions list from PageResponse.data
            final transactionsList = pageResponse['data'];
            print(
                '[TransactionAPI] Transactions array type: ${transactionsList.runtimeType}');

            if (transactionsList is List) {
              if (transactionsList.isEmpty) {
                print('[TransactionAPI] Retrieved 0 transactions (empty list)');
                return [];
              }

              final transactions = transactionsList.map((json) {
                try {
                  final jsonStr = json.toString();
                  final preview = jsonStr.length > 500
                      ? jsonStr.substring(0, 500)
                      : jsonStr;
                  print('[TransactionAPI] Parsing transaction JSON: $preview');
                  final transaction =
                      TransactionModel.fromJson(json as Map<String, dynamic>);
                  print(
                      '[TransactionAPI] Parsed transaction - itemName: ${transaction.itemName}, itemImageUrl: ${transaction.itemImageUrl}');
                  return transaction;
                } catch (e) {
                  print('[TransactionAPI] Error parsing transaction: $e');
                  rethrow;
                }
              }).toList();
              print(
                  '[TransactionAPI] Retrieved ${transactions.length} transactions');
              return transactions;
            } else {
              throw Exception(
                  'pageResponse["data"] is not a List, got: ${transactionsList.runtimeType}');
            }
          } else {
            throw Exception(
                'apiResponse["data"] is not a PageResponse Map, got: ${pageResponse.runtimeType}');
          }
        }

        throw Exception(
            'Unexpected API response type: ${apiResponse.runtimeType}');
      } else {
        throw Exception('Failed to get transactions: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get transaction details by ID (UUID string)
  Future<TransactionModel> getTransactionDetail(String transactionId) async {
    try {
      final response = await _dio.get(
        '/api/v2/transactions/$transactionId',
      );

      if (response.statusCode == 200) {
        final apiResponse = response.data;

        if (apiResponse is Map<String, dynamic>) {
          // Extract transaction from ApiResponse
          final transactionData = apiResponse['data'];

          if (transactionData is Map<String, dynamic>) {
            print(
                '[TransactionAPI] Transaction detail JSON: ${transactionData.toString().substring(0, transactionData.toString().length > 500 ? 500 : transactionData.toString().length)}');
            final transaction = TransactionModel.fromJson(transactionData);
            print(
                '[TransactionAPI] Retrieved transaction detail - itemName: ${transaction.itemName}, itemImageUrl: ${transaction.itemImageUrl}');
            return transaction;
          }

          throw Exception(
              'Transaction data is not a Map, got: ${transactionData.runtimeType}');
        }

        throw Exception(
            'Unexpected API response type: ${apiResponse.runtimeType}');
      } else {
        throw Exception(
            'Failed to get transaction detail: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Cancel a transaction by ID
  Future<void> cancelTransaction(String transactionId, {String? reason}) async {
    try {
      final url = '/api/v2/transactions/$transactionId/cancel';
      final requestBody = reason != null ? {'reason': reason} : {};

      final response = await _dio.put(
        url,
        data: requestBody,
      );

      if (response.statusCode == 200) {
        print(
            '[TransactionAPI] Transaction $transactionId cancelled successfully');
        return;
      } else {
        throw Exception('Failed to cancel transaction: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Accept a transaction request
  Future<void> acceptTransaction(String transactionId) async {
    try {
      print(
          '[TransactionAPI] REQUEST[PUT] => /api/v2/transactions/$transactionId/accept');
      final response = await _dio.put(
        '/api/v2/transactions/$transactionId/accept',
        data: {},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print(
            '[TransactionAPI] Transaction $transactionId accepted successfully');
        return;
      } else {
        throw Exception('Failed to accept transaction: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Reject a transaction request
  Future<void> rejectTransaction(String transactionId) async {
    try {
      print(
          '[TransactionAPI] REQUEST[PUT] => /api/v2/transactions/$transactionId/reject');
      final response = await _dio.put(
        '/api/v2/transactions/$transactionId/reject',
        data: {},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print(
            '[TransactionAPI] Transaction $transactionId rejected successfully');
        return;
      } else {
        throw Exception('Failed to reject transaction: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Mark a transaction as completed
  Future<void> completeTransaction(String transactionId) async {
    try {
      print(
          '[TransactionAPI] REQUEST[PUT] => /api/v2/transactions/$transactionId/complete');
      final response = await _dio.put(
        '/api/v2/transactions/$transactionId/complete',
        data: {},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print(
            '[TransactionAPI] Transaction $transactionId completed successfully');
        return;
      } else {
        throw Exception(
            'Failed to complete transaction: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }
}
