import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:kltn_sharing_app/data/models/message_model.dart';

/// WebSocket service for real-time messaging using STOMP protocol
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();

  factory WebSocketService() {
    return _instance;
  }

  WebSocketService._internal();

  // WebSocket connection
  IOWebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;

  // State
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentUserId;
  String? _accessToken;

  // Streams for real-time updates
  final StreamController<MessageModel> _messageStreamController =
      StreamController<MessageModel>.broadcast();
  final StreamController<TypingIndicator> _typingStreamController =
      StreamController<TypingIndicator>.broadcast();
  final StreamController<UserStatus> _statusStreamController =
      StreamController<UserStatus>.broadcast();
  final StreamController<bool> _connectionStreamController =
      StreamController<bool>.broadcast();

  // Subscriptions tracking
  final Map<String, bool> _subscriptions = {};

  // Getters
  Stream<MessageModel> get messageStream => _messageStreamController.stream;
  Stream<TypingIndicator> get typingStream => _typingStreamController.stream;
  Stream<UserStatus> get statusStream => _statusStreamController.stream;
  Stream<bool> get connectionStream => _connectionStreamController.stream;
  bool get isConnected => _isConnected;

  /// Connect to WebSocket server
  Future<void> connect({
    required String userId,
    required String accessToken,
  }) async {
    if (_isConnected) {
      print('[WebSocketService] ⚠️  Already connected');
      return;
    }

    if (_isConnecting) {
      print('[WebSocketService] ⚠️  Already connecting...');
      return;
    }

    _currentUserId = userId;
    _accessToken = accessToken;

    _isConnecting = true;

    try {
      // Ensure clean state before connecting
      if (_channel != null) {
        try {
          await _channel?.sink.close();
        } catch (e) {
          print('[WebSocketService] ⚠️  Error closing previous channel: $e');
        }
        _channel = null;
      }
      _channelSubscription?.cancel();
      _channelSubscription = null;

      print('[WebSocketService] 🔌 Connecting to: wss://api.shareo.studio/ws');

      // Connect to WebSocket endpoint using IOWebSocketChannel (use WSS for HTTPS backend)
      // Create URI with proper components instead of parsing string
      final uri = Uri(scheme: 'wss', host: 'api.shareo.studio', path: '/ws');
      _channel = IOWebSocketChannel.connect(uri);

      // Listen to WebSocket messages
      _channelSubscription = _channel!.stream.listen(
        _onWebSocketMessage,
        onError: (error) {
          print('[WebSocketService] ❌ WebSocket error: $error');
          _isConnected = false;
          _isConnecting = false;
          _connectionStreamController.add(false);
        },
        onDone: () {
          print('[WebSocketService] ⚠️  WebSocket closed');
          _isConnected = false;
          _isConnecting = false;
          _connectionStreamController.add(false);
        },
      );

      print('[WebSocketService] 📤 STOMP frame sent: CONNECT');
      // Send STOMP CONNECT frame
      _sendStompFrame(
        command: 'CONNECT',
        headers: {
          'accept-version': '1.0,1.1,1.2',
          'heart-beat': '0,0',
          'authorization': 'Bearer $accessToken',
        },
        body: '',
      );

      print('[WebSocketService] ✅ WebSocket connected');
      _isConnected = true;
      _isConnecting = false;
      _connectionStreamController.add(true);

      // Subscribe to topics
      if (_currentUserId != null) {
        _subscribeToMessages(_currentUserId!);
        _subscribeToStatus(_currentUserId!);
        _subscribeToTyping(_currentUserId!);
      }

      // Send online status
      await sendStatus(status: 'online');
    } catch (e) {
      print('[WebSocketService] ❌ Connection failed: $e');
      _isConnected = false;
      _isConnecting = false;
      _connectionStreamController.add(false);
    }
  }

  /// Handle incoming WebSocket messages
  void _onWebSocketMessage(dynamic message) {
    try {
      String data = message.toString();
      print('[WebSocketService] 📨 Raw message received');

      // Parse STOMP frame
      final lines = data.split('\n');
      if (lines.isEmpty) return;

      final command = lines[0].trim();
      print('[WebSocketService] 🔍 STOMP command: $command');

      // Parse headers
      final headers = <String, String>{};
      int bodyStartIndex = 1;
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) {
          bodyStartIndex = i + 1;
          break;
        }
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            headers[parts[0].trim()] = parts.sublist(1).join(':').trim();
          }
        }
      }

      // Extract body
      String body = '';
      if (bodyStartIndex < lines.length) {
        body = lines
            .sublist(bodyStartIndex)
            .join('\n')
            .replaceAll('\u0000', '')
            .trim();
      }

      // Handle different STOMP commands
      switch (command) {
        case 'CONNECTED':
          print('[WebSocketService] ✅ STOMP CONNECTED');
          break;
        case 'MESSAGE':
          _handleInboxMessage(headers, body);
          break;
        case 'RECEIPT':
          print(
              '[WebSocketService] ✅ Message receipt: ${headers['receipt-id']}');
          break;
        case 'ERROR':
          print('[WebSocketService] ❌ STOMP error: $body');
          break;
      }
    } catch (e) {
      print('[WebSocketService] ❌ Error handling message: $e');
    }
  }

  /// Handle inbox message
  void _handleInboxMessage(Map<String, String> headers, String body) {
    try {
      if (body.isEmpty) {
        print('[WebSocketService] ⚠️  Empty message body');
        return;
      }

      final Map<String, dynamic> json = jsonDecode(body);
      final message = MessageModel.fromJson(json);

      print('[WebSocketService] 📬 Message received: ${message.id}');
      _messageStreamController.add(message);
    } catch (e) {
      print('[WebSocketService] ❌ Error parsing message: $e');
      print('[WebSocketService] ❌ Message body: $body');
    }
  }

  /// Handle typing indicator
  void _handleTypingMessage(Map<String, String> headers, String body) {
    try {
      if (body.isEmpty) return;

      final Map<String, dynamic> json = jsonDecode(body);
      final typing = TypingIndicator.fromJson(json);

      print('[WebSocketService] ⌨️  Typing indicator: ${typing.senderId}');
      _typingStreamController.add(typing);
    } catch (e) {
      print('[WebSocketService] ❌ Error parsing typing: $e');
    }
  }

  /// Handle status message
  void _handleStatusMessage(Map<String, String> headers, String body) {
    try {
      if (body.isEmpty) return;

      final Map<String, dynamic> json = jsonDecode(body);
      final status = UserStatus.fromJson(json);

      print('[WebSocketService] 📶 Status update: ${status.userId}');
      _statusStreamController.add(status);
    } catch (e) {
      print('[WebSocketService] ❌ Error parsing status: $e');
    }
  }

  /// Subscribe to message inbox
  void _subscribeToMessages(String userId) {
    final destination = '/topic/user/$userId/inbox';
    print('[WebSocketService] 📬 Subscribing to: $destination');

    _sendStompFrame(
      command: 'SUBSCRIBE',
      headers: {
        'id': 'sub-messages-$userId',
        'destination': destination,
        'ack': 'auto',
      },
      body: '',
    );

    _subscriptions[destination] = true;
  }

  /// Subscribe to status updates
  void _subscribeToStatus(String userId) {
    final destination = '/topic/user/$userId/status';
    print('[WebSocketService] 📶 Subscribing to: $destination');

    _sendStompFrame(
      command: 'SUBSCRIBE',
      headers: {
        'id': 'sub-status-$userId',
        'destination': destination,
        'ack': 'auto',
      },
      body: '',
    );

    _subscriptions[destination] = true;
  }

  /// Subscribe to typing indicators
  void _subscribeToTyping(String userId) {
    final destination = '/topic/user/$userId/typing';
    print('[WebSocketService] ⌨️  Subscribing to: $destination');

    _sendStompFrame(
      command: 'SUBSCRIBE',
      headers: {
        'id': 'sub-typing-$userId',
        'destination': destination,
        'ack': 'auto',
      },
      body: '',
    );

    _subscriptions[destination] = true;
  }

  /// Send typing indicator
  Future<void> sendTypingIndicator({
    required String conversationId,
    required bool isTyping,
  }) async {
    if (!_isConnected || _currentUserId == null) {
      print(
          '[WebSocketService] ⚠️  Not connected, cannot send typing indicator');
      return;
    }

    try {
      final body = jsonEncode({
        'senderId': _currentUserId,
        'conversationId': conversationId,
        'isTyping': isTyping,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _sendStompFrame(
        command: 'SEND',
        headers: {
          'destination': '/app/chat/typing/$conversationId',
          'content-type': 'application/json',
        },
        body: body,
      );

      print('[WebSocketService] ⌨️  Typing indicator sent: $isTyping');
    } catch (e) {
      print('[WebSocketService] ❌ Error sending typing indicator: $e');
    }
  }

  /// Send user status
  Future<void> sendStatus({required String status}) async {
    if (!_isConnected || _currentUserId == null) {
      print('[WebSocketService] ⚠️  Not connected, cannot send status');
      return;
    }

    try {
      final body = jsonEncode({
        'userId': _currentUserId,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _sendStompFrame(
        command: 'SEND',
        headers: {
          'destination': '/app/chat/status',
          'content-type': 'application/json',
        },
        body: body,
      );

      print('[WebSocketService] 📶 Status sent: $status');
    } catch (e) {
      print('[WebSocketService] ❌ Error sending status: $e');
    }
  }

  /// Send raw STOMP frame
  void _sendStompFrame({
    required String command,
    required Map<String, String> headers,
    required String body,
  }) {
    if (_channel == null) {
      print('[WebSocketService] ❌ Channel not initialized');
      return;
    }

    try {
      // Build STOMP frame
      StringBuffer frame = StringBuffer();
      frame.writeln(command);

      for (final entry in headers.entries) {
        frame.writeln('${entry.key}:${entry.value}');
      }

      frame.writeln(); // Empty line to separate headers from body
      frame.write(body);
      frame.write('\u0000'); // Null byte terminator

      _channel!.sink.add(frame.toString());
      print('[WebSocketService] 📤 STOMP frame sent: $command');
    } catch (e) {
      print('[WebSocketService] ❌ Error sending frame: $e');
    }
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    print('[WebSocketService] 🔌 Disconnecting...');
    try {
      // Send offline status before disconnecting
      if (_isConnected) {
        try {
          await sendStatus(status: 'offline');
        } catch (e) {
          print('[WebSocketService] ⚠️  Could not send offline status: $e');
        }
      }

      // Unsubscribe from all topics
      _subscriptions.clear();

      // Close channel and subscription properly
      _isConnected = false;
      _isConnecting = false;

      try {
        _channelSubscription?.cancel();
        _channelSubscription = null;
      } catch (e) {
        print('[WebSocketService] ⚠️  Error cancelling subscription: $e');
      }

      try {
        await _channel?.sink.close();
      } catch (e) {
        print('[WebSocketService] ⚠️  Error closing sink: $e');
      }

      _channel = null; // Clear reference to allow reconnection

      _connectionStreamController.add(false);
      print('[WebSocketService] ✅ Disconnected');
    } catch (e) {
      print('[WebSocketService] ⚠️  Error disconnecting: $e');
      // Reset state even if error occurs
      _isConnected = false;
      _isConnecting = false;
      _channel = null;
      _channelSubscription = null;
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageStreamController.close();
    _typingStreamController.close();
    _statusStreamController.close();
    _connectionStreamController.close();
  }
}

/// Model for typing indicator
class TypingIndicator {
  final String senderId;
  final String conversationId;
  final bool isTyping;
  final DateTime timestamp;

  TypingIndicator({
    required this.senderId,
    required this.conversationId,
    required this.isTyping,
    required this.timestamp,
  });

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      senderId: json['senderId'] ?? '',
      conversationId: json['conversationId'] ?? '',
      isTyping: json['isTyping'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

/// Model for user status
class UserStatus {
  final String userId;
  final String status; // 'online', 'offline', 'away'
  final DateTime timestamp;

  UserStatus({
    required this.userId,
    required this.status,
    required this.timestamp,
  });

  factory UserStatus.fromJson(Map<String, dynamic> json) {
    return UserStatus(
      userId: json['userId'] ?? '',
      status: json['status'] ?? 'offline',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}
