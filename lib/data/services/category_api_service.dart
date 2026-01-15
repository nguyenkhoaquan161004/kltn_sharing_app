import 'package:dio/dio.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';
import 'package:kltn_sharing_app/data/models/category_response_model.dart';

class CategoryApiService {
  late Dio _dio;

  CategoryApiService() {
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

    // Add logging interceptor only (categories are public API)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('[CategoryAPI] REQUEST[${options.method}] => ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '[CategoryAPI] RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (e, handler) {
          print(
              '[CategoryAPI] ERROR[${e.response?.statusCode}] => ${e.requestOptions.path}');
          return handler.next(e);
        },
      ),
    );
  }

  /// Set callback - not needed for public categories API
  void setGetValidTokenCallback(
      Future<void> Function() onTokenExpiredCallback) {
    print(
        '[CategoryAPI] setGetValidTokenCallback called (not needed for public API)');
  }

  /// Update Dio baseUrl when backend switches
  void _updateDioBaseUrl() {
    _dio.options.baseUrl = AppConfig.baseUrl;
  }

  /// Get all categories
  Future<List<CategoryDto>> getAllCategories() async {
    try {
      final response = await _dio.get('/api/v2/categories/all');

      print('[CategoryAPI] Response status: ${response.statusCode}');
      print('[CategoryAPI] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('[CategoryAPI] Data type: ${data.runtimeType}');
        print(
            '[CategoryAPI] Data keys: ${data is Map ? (data as Map).keys : 'N/A'}');

        if (data is Map<String, dynamic>) {
          print('[CategoryAPI] Response is Map: $data');

          // Try different possible response structures
          List<CategoryDto> categories = [];

          // Structure 1: {data: [...]}
          if (data.containsKey('data')) {
            final dataValue = data['data'];
            print(
                '[CategoryAPI] Found "data" key, type: ${dataValue.runtimeType}');

            if (dataValue is List) {
              categories = (dataValue as List<dynamic>)
                  .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
                  .toList();
            } else if (dataValue is Map<String, dynamic>) {
              if (dataValue.containsKey('content')) {
                // Might be paginated
                categories = ((dataValue['content'] ?? []) as List<dynamic>)
                    .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
                    .toList();
              }
            }
          }
          // Structure 2: Direct list
          else if (data is List) {
            categories = (data as List<dynamic>)
                .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          // Structure 3: Check for other common keys
          else {
            final commonKeys = ['content', 'items', 'categories'];
            for (final key in commonKeys) {
              if (data.containsKey(key)) {
                final value = data[key];
                if (value is List) {
                  categories = (value as List<dynamic>)
                      .map((e) =>
                          CategoryDto.fromJson(e as Map<String, dynamic>))
                      .toList();
                  break;
                }
              }
            }
          }

          print('[CategoryAPI] Parsed ${categories.length} categories');
          if (categories.isNotEmpty) {
            print('[CategoryAPI] First category: ${categories[0].name}');
          }
          return categories;
        }

        throw Exception('Unexpected response format: $data');
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('[CategoryAPI] DioException: ${e.message}');
      print('[CategoryAPI] Exception type: ${e.type}');
      print('[CategoryAPI] Response: ${e.response?.data}');
      print('[CategoryAPI] Error: ${e.message}');
      print('[CategoryAPI] Response status: ${e.response?.statusCode}');
      throw Exception('Failed to load categories: ${e.message}');
    } catch (e) {
      print('[CategoryAPI] Unexpected error: $e');
      throw Exception('Failed to load categories: $e');
    }
  }
}
