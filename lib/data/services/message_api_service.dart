import 'package:dio/dio.dart';
import 'package:kltn_sharing_app/data/models/message_model.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';
import 'package:kltn_sharing_app/core/utils/token_refresh_interceptor.dart';

class MessageApiService {
  late Dio _dio;
  late TokenRefreshInterceptor _tokenRefreshInterceptor;
  Future<String?> Function()? _getValidTokenCallback;

  MessageApiService({Dio? dio}) {
    if (dio != null) {
      // Use provided Dio instance (from Provider)
      _dio = dio;
    } else {
      // Create a new instance with proper interceptors
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

      // Add token refresh interceptor
      _dio.interceptors.add(_tokenRefreshInterceptor);

      // Add logging interceptor
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            print('[MessageAPI] REQUEST[${options.method}] => ${options.path}');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            print(
                '[MessageAPI] SUCCESS[${response.statusCode}] => ${response.requestOptions.path}');
            return handler.next(response);
          },
          onError: (error, handler) {
            print(
                '[MessageAPI] ERROR[${error.response?.statusCode}] => ${error.message}');
            return handler.next(error);
          },
        ),
      );
    }
  }

  /// Set callback to get valid access token
  void setGetValidTokenCallback(Future<String?> Function() callback) {
    _getValidTokenCallback = callback;
    try {
      _tokenRefreshInterceptor.setCallbacks(
        getValidTokenCallback: callback,
        onTokenExpiredCallback: () async {
          print('[MessageAPI] Token refresh failed, user session expired');
        },
      );
    } catch (e) {
      print('[MessageAPI] Error setting token refresh callback: $e');
    }
  }

  /// Set authorization header with bearer token
  void setAuthToken(String accessToken) {
    _dio.options.headers['Authorization'] = 'Bearer $accessToken';
    print('[MessageAPI] Token set');
  }

  /// Remove authorization header
  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Send a message to another user
  /// POST /api/v2/messages
  Future<MessageModel> sendMessage({
    required String receiverId,
    required String content,
    String messageType = 'TEXT',
    String? itemId,
  }) async {
    try {
      print('[MessageAPI] REQUEST[POST] => /api/v2/messages');
      print('[MessageAPI] Body: {receiverId: $receiverId, content: $content}');

      final response = await _dio.post(
        '/api/v2/messages',
        data: {
          'receiverId': receiverId,
          'content': content,
          'messageType': messageType,
          if (itemId != null) 'itemId': itemId,
        },
      );

      print('[MessageAPI] SUCCESS[${response.statusCode}] => Message sent');
      print('[MessageAPI] Response data: ${response.data}');
      print('[MessageAPI] Response data type: ${response.data.runtimeType}');

      final responseData = response.data;
      dynamic data;

      // Handle different response structures
      if (responseData is Map) {
        // Try to get data from nested structure
        if (responseData.containsKey('data')) {
          data = responseData['data'];
          print('[MessageAPI] First level data type: ${data.runtimeType}');

          // If data is still a Map with 'data' inside, dig deeper
          if (data is Map && data.containsKey('data')) {
            var innerData = data['data'];
            print('[MessageAPI] Inner data type: ${innerData.runtimeType}');
            // Only dig deeper if it's still a Map
            if (innerData is Map) {
              data = innerData;
            }
          }
        } else {
          data = responseData;
        }
      } else {
        print(
            '[MessageAPI] Response data is not a Map: ${responseData.runtimeType}');
        data = responseData;
      }

      print(
          '[MessageAPI] Final data type before parsing: ${data.runtimeType}, value: $data');

      // Ensure data is a Map before casting
      if (data is! Map) {
        print('[MessageAPI] ERROR: data is not Map, got ${data.runtimeType}');
        throw Exception(
            'Invalid response format: expected Map, got ${data.runtimeType}. Value: $data');
      }

      // Safe cast to Map<String, dynamic>
      final dataMap = Map<String, dynamic>.from(data as Map);
      return MessageModel.fromJson(dataMap);
    } on DioException catch (e) {
      print('[MessageAPI] ERROR[${e.response?.statusCode}] => ${e.message}');
      throw Exception(
        'Failed to send message: ${e.response?.statusCode} - ${e.message}',
      );
    } catch (e) {
      print('[MessageAPI] UNEXPECTED ERROR: $e');
      rethrow;
    }
  }

  /// Get conversation with another user
  /// GET /api/v2/messages/conversation/{otherUserId}
  Future<List<MessageModel>> getConversation({
    required String otherUserId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      print(
          '[MessageAPI] REQUEST[GET] => /api/v2/messages/conversation/$otherUserId');

      final response = await _dio.get(
        '/api/v2/messages/conversation/$otherUserId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      print(
          '[MessageAPI] SUCCESS[${response.statusCode}] => Messages retrieved');
      print('[MessageAPI] Response data: ${response.data}');

      final data = response.data;

      // Extract messages from nested PageResponse structure
      if (data is Map) {
        final pageData = data['data'];
        if (pageData is Map) {
          // Check for nested data.data (messages array)
          final messagesList = pageData['data'];
          if (messagesList is List) {
            final messages = messagesList
                .map(
                    (msg) => MessageModel.fromJson(msg as Map<String, dynamic>))
                .toList();

            // Sort messages by createdAt in ascending order (oldest first)
            messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            return messages;
          }
          // Check for content field
          if (pageData.containsKey('content') && pageData['content'] is List) {
            final contentList = pageData['content'] as List<dynamic>;
            return contentList
                .map(
                    (msg) => MessageModel.fromJson(msg as Map<String, dynamic>))
                .toList();
          }
        }
      }

      return [];
    } on DioException catch (e) {
      print('[MessageAPI] ERROR[${e.response?.statusCode}] => ${e.message}');
      throw Exception(
        'Failed to get conversation: ${e.response?.statusCode} - ${e.message}',
      );
    }
  }

  /// Get all conversations for current user
  /// GET /api/v2/messages/conversations
  Future<List<ConversationModel>> getAllConversations() async {
    try {
      print('[MessageAPI] REQUEST[GET] => /api/v2/messages/conversations');

      final response = await _dio.get(
        '/api/v2/messages/conversations',
      );

      print(
          '[MessageAPI] SUCCESS[${response.statusCode}] => Conversations retrieved');
      final data = response.data['data'] as List<dynamic>;

      return data
          .map((conv) =>
              ConversationModel.fromJson(conv as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('[MessageAPI] ERROR[${e.response?.statusCode}] => ${e.message}');
      throw Exception(
        'Failed to get conversations: ${e.response?.statusCode} - ${e.message}',
      );
    }
  }

  /// Get unread message count
  /// GET /api/v2/messages/unread/count
  Future<int> getUnreadCount() async {
    try {
      print('[MessageAPI] REQUEST[GET] => /api/v2/messages/unread/count');

      final response = await _dio.get(
        '/api/v2/messages/unread/count',
      );

      print(
          '[MessageAPI] SUCCESS[${response.statusCode}] => Unread count retrieved');
      return response.data['data'] as int;
    } on DioException catch (e) {
      print('[MessageAPI] ERROR[${e.response?.statusCode}] => ${e.message}');
      throw Exception(
        'Failed to get unread count: ${e.response?.statusCode} - ${e.message}',
      );
    }
  }

  /// Mark a single message as read
  /// PUT /api/v2/messages/{messageId}/read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      print('[MessageAPI] REQUEST[PUT] => /api/v2/messages/$messageId/read');

      await _dio.put(
        '/api/v2/messages/$messageId/read',
      );

      print('[MessageAPI] SUCCESS[200] => Message marked as read');
    } on DioException catch (e) {
      print('[MessageAPI] ERROR[${e.response?.statusCode}] => ${e.message}');
      throw Exception(
        'Failed to mark message as read: ${e.response?.statusCode} - ${e.message}',
      );
    }
  }

  /// Mark entire conversation as read
  /// PUT /api/v2/messages/conversation/{otherUserId}/read
  Future<void> markConversationAsRead(String otherUserId) async {
    try {
      print(
          '[MessageAPI] REQUEST[PUT] => /api/v2/messages/conversation/$otherUserId/read');

      await _dio.put(
        '/api/v2/messages/conversation/$otherUserId/read',
      );

      print('[MessageAPI] SUCCESS[200] => Conversation marked as read');
    } on DioException catch (e) {
      print('[MessageAPI] ERROR[${e.response?.statusCode}] => ${e.message}');
      throw Exception(
        'Failed to mark conversation as read: ${e.response?.statusCode} - ${e.message}',
      );
    }
  }
}
