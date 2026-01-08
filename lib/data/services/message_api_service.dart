import 'package:dio/dio.dart';
import 'package:kltn_sharing_app/data/models/message_model.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';
import 'package:kltn_sharing_app/core/utils/token_refresh_interceptor.dart';

class MessageApiService {
  late Dio _dio;
  late TokenRefreshInterceptor _tokenRefreshInterceptor;

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
  void setGetValidTokenCallback(
      Future<void> Function() onTokenExpiredCallback) {
    try {
      _tokenRefreshInterceptor.setCallbacks(
        getValidTokenCallback: () async => null, // Not needed
        onTokenExpiredCallback: onTokenExpiredCallback,
      );
    } catch (e) {
      print('[MessageAPI] Error setting token refresh callback: $e');
    }
  }

  /// Set authorization header with bearer token
  void setAuthToken(String accessToken) {
    _dio.options.headers['Authorization'] = 'Bearer $accessToken';
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
      final requestBody = {
        'receiverId': receiverId,
        'content': content,
        'messageType': messageType,
        'itemId': itemId,
      };

      // Log auth header and request details
      final authHeader =
          _dio.options.headers['Authorization']?.toString() ?? 'NOT SET';
      final headerPreview = authHeader.length > 50
          ? '${authHeader.substring(0, 50)}...'
          : authHeader;

      print('[MessageAPI] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('[MessageAPI] 📤 SENDING MESSAGE');
      print('[MessageAPI] Authorization: $headerPreview');
      print('[MessageAPI] ReceiverID: $receiverId');
      print('[MessageAPI] Request Body: $requestBody');
      print('[MessageAPI] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final response = await _dio.post(
        '/api/v2/messages',
        data: requestBody,
      );

      print('[MessageAPI] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('[MessageAPI] 📥 RESPONSE RECEIVED (${response.statusCode})');
      print('[MessageAPI] Response Data: ${response.data}');
      print('[MessageAPI] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final responseData = response.data;
      dynamic data;

      // Handle different response structures
      if (responseData is Map) {
        // Try to get data from nested structure
        if (responseData.containsKey('data')) {
          data = responseData['data'];

          // If data is still a Map with 'data' inside, dig deeper
          if (data is Map && data.containsKey('data')) {
            var innerData = data['data'];
            // Only dig deeper if it's still a Map
            if (innerData is Map) {
              data = innerData;
            }
          }
        } else {
          data = responseData;
        }
      } else {
        data = responseData;
      }

      // Ensure data is a Map before casting
      if (data is! Map) {
        throw Exception(
            'Invalid response format: expected Map, got ${data.runtimeType}. Value: $data');
      }

      // Safe cast to Map<String, dynamic>
      final dataMap = Map<String, dynamic>.from(data as Map);
      final message = MessageModel.fromJson(dataMap);

      print(
          '[MessageAPI] ✅ Message parsed - ID: ${message.id}, itemId: ${message.itemId}');

      return message;
    } on DioException catch (e) {
      print('[MessageAPI] ❌ ERROR: ${e.response?.statusCode} - ${e.message}');
      print('[MessageAPI] Error Response Body: ${e.response?.data}');

      // Log full response headers for 403
      if (e.response?.statusCode == 403) {
        print('[MessageAPI] 🔒 403 Forbidden - Request Headers:');
        print(
            '[MessageAPI]   Authorization: ${_dio.options.headers['Authorization']?.toString().substring(0, 50) ?? 'NOT SET'}');
        print('[MessageAPI]   ContentType: ${_dio.options.contentType}');
      }

      // Try to extract error message from response
      String errorMessage = 'Failed to send message: ${e.response?.statusCode}';
      if (e.response?.data is Map) {
        final errorData = e.response!.data as Map;
        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'].toString();
        } else if (errorData.containsKey('error')) {
          errorMessage = errorData['error'].toString();
        } else if (errorData.containsKey('errors')) {
          // Check nested errors array
          final errors = errorData['errors'];
          if (errors is List && errors.isNotEmpty) {
            errorMessage = errors[0].toString();
          }
        }
      }

      throw Exception(errorMessage);
    } catch (e) {
      print('[MessageAPI] 💥 UNEXPECTED ERROR: $e');
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
      final response = await _dio.get(
        '/api/v2/messages/conversation/$otherUserId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

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
      // Temporary fallback: If 404, return mock conversation for testing
      if (e.response?.statusCode == 404) {
        return [];
      }

      throw Exception(
        'Failed to get conversation: ${e.response?.statusCode} - ${e.message}',
      );
    }
  }

  /// Get all conversations for current user
  /// GET /api/v2/messages/conversations
  Future<List<ConversationModel>> getAllConversations() async {
    try {
      final response = await _dio.get(
        '/api/v2/messages/conversations',
      );

      final data = response.data['data'] as List<dynamic>;

      return data
          .map((conv) =>
              ConversationModel.fromJson(conv as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        'Failed to get conversations: ${e.response?.statusCode} - ${e.message}',
      );
    }
  }

  /// Get unread message count
  /// GET /api/v2/messages/unread/count
  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get(
        '/api/v2/messages/unread/count',
      );

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
      await _dio.put(
        '/api/v2/messages/$messageId/read',
      );
    } on DioException catch (e) {
      throw Exception(
        'Failed to mark message as read: ${e.response?.statusCode} - ${e.message}',
      );
    }
  }

  /// Mark entire conversation as read
  /// PUT /api/v2/messages/conversation/{otherUserId}/read
  Future<void> markConversationAsRead(String otherUserId) async {
    try {
      await _dio.put(
        '/api/v2/messages/conversation/$otherUserId/read',
      );
    } on DioException catch (e) {
      throw Exception(
        'Failed to mark conversation as read: ${e.response?.statusCode} - ${e.message}',
      );
    }
  }

  /// Send message to chatbot
  /// POST /api/v2/chat
  Future<Map<String, dynamic>> sendChatbotMessage({
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v2/chat',
        data: {
          'message': message,
        },
      );

      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        'Failed to send chatbot message: ${e.response?.statusCode} - ${e.message}',
      );
    }
  }
}
