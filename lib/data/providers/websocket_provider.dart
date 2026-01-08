import 'package:flutter/material.dart';
import 'package:kltn_sharing_app/data/services/websocket_service.dart';
import 'package:kltn_sharing_app/data/models/message_model.dart';

/// Provider để quản lý WebSocket connection
class WebSocketProvider extends ChangeNotifier {
  final WebSocketService _webSocketService = WebSocketService();

  bool _isConnected = false;
  bool _isTyping = false;
  String? _otherUserTyping;

  // Getters
  bool get isConnected => _isConnected;
  bool get isTyping => _isTyping;
  String? get otherUserTyping => _otherUserTyping;
  Stream<MessageModel> get messageStream => _webSocketService.messageStream;
  Stream<bool> get connectionStream => _webSocketService.connectionStream;

  /// Kết nối WebSocket
  void connect({required String userId, required String accessToken}) {
    if (_isConnected) {
      print('[WebSocketProvider] ⚠️  Already connected');
      return;
    }

    print('[WebSocketProvider] 🔌 Connecting...');
    _webSocketService.connect(userId: userId, accessToken: accessToken);

    // Listen to connection status
    _webSocketService.connectionStream.listen((isConnected) {
      _isConnected = isConnected;
      notifyListeners();

      if (isConnected) {
        print('[WebSocketProvider] ✅ Connected');
        _sendOnlineStatus();
      } else {
        print('[WebSocketProvider] ❌ Disconnected');
      }
    });

    // Listen to typing indicators
    _webSocketService.typingStream.listen((typing) {
      if (typing.isTyping) {
        _otherUserTyping = typing.senderId;
      } else {
        _otherUserTyping = null;
      }
      notifyListeners();
    });
  }

  /// Ngắt kết nối WebSocket
  Future<void> disconnect() async {
    if (!_isConnected) {
      print('[WebSocketProvider] ⚠️  Not connected');
      return;
    }

    print('[WebSocketProvider] 🔌 Disconnecting...');
    await _sendOfflineStatus();
    await _webSocketService.disconnect();
    _isConnected = false;
    notifyListeners();
  }

  /// Gửi typing indicator
  Future<void> sendTypingIndicator({
    required String conversationId,
    required bool isTyping,
  }) async {
    if (!_isConnected) {
      print('[WebSocketProvider] ⚠️  Not connected, cannot send typing');
      return;
    }

    _isTyping = isTyping;
    notifyListeners();

    await _webSocketService.sendTypingIndicator(
      conversationId: conversationId,
      isTyping: isTyping,
    );
  }

  /// Gửi trạng thái online
  Future<void> _sendOnlineStatus() async {
    await _webSocketService.sendStatus(status: 'online');
  }

  /// Gửi trạng thái offline
  Future<void> _sendOfflineStatus() async {
    await _webSocketService.sendStatus(status: 'offline');
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }
}
