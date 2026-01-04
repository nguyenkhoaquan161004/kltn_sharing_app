import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Service để xử lý tin nhắn real-time thông qua Firebase Cloud Messaging
class MessageNotificationService {
  static final MessageNotificationService _instance =
      MessageNotificationService._internal();

  late FirebaseMessaging _firebaseMessaging;
  final StreamController<Map<String, dynamic>> _messageStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  MessageNotificationService._internal() {
    _firebaseMessaging = FirebaseMessaging.instance;
  }

  factory MessageNotificationService() {
    return _instance;
  }

  /// Khởi tạo listening cho tin nhắn
  Future<void> initialize() async {
    try {
      // Xin quyền
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print(
          '[MessageNotification] Notification permission status: ${settings.authorizationStatus}');

      // Listen to foreground messages
      print(
          '[MessageNotification] 🔧 Setting up FirebaseMessaging.onMessage listener...');
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print(
            '[MessageNotification] 📨 ========== GOT FOREGROUND MESSAGE ==========');
        print('[MessageNotification] Message ID: ${message.messageId}');
        print('[MessageNotification] Sent time: ${message.sentTime}');
        print('[MessageNotification] Data keys: ${message.data.keys.toList()}');
        print('[MessageNotification] Full data: ${message.data}');
        print(
            '[MessageNotification] Has notification: ${message.notification != null}');
        if (message.notification != null) {
          print(
              '[MessageNotification] Notification Title: ${message.notification?.title}');
          print(
              '[MessageNotification] Notification Body: ${message.notification?.body}');
        }
        print(
            '[MessageNotification] Stream controller active: ${!_messageStreamController.isClosed}');
        print(
            '[MessageNotification] Stream has listeners: ${_messageStreamController.hasListener}');

        // Emit tin nhắn qua stream để các listener lắng nghe
        if (message.data.isNotEmpty) {
          print(
              '[MessageNotification] ✅ Emitting message to stream with ${message.data.length} fields');
          try {
            _messageStreamController.add(message.data);
            print(
                '[MessageNotification] ✅ Message added to stream successfully');
          } catch (streamError) {
            print(
                '[MessageNotification] ❌ Error adding message to stream: $streamError');
          }
        } else {
          print(
              '[MessageNotification] ⚠️  Message data is EMPTY - nothing to emit');
        }
        print('[MessageNotification] ======== END FOREGROUND MESSAGE ========');
      }, onError: (error) {
        print('[MessageNotification] ❌ ERROR in onMessage listener: $error');
      });

      // Xử lý message khi app được mở từ notification
      print(
          '[MessageNotification] 🔧 Setting up FirebaseMessaging.onMessageOpenedApp listener...');
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('[MessageNotification] 📲 Message opened from notification');
        print('[MessageNotification] Message data: ${message.data}');
        if (message.data.isNotEmpty) {
          _messageStreamController.add(message.data);
        }
      });

      print(
          '[MessageNotification] ✅ Messaging service initialized with Firebase listeners attached');
    } catch (e) {
      print('[MessageNotification] ❌ Error initializing messaging: $e');
      rethrow;
    }
  }

  /// Stream để lắng nghe tin nhắn mới
  Stream<Map<String, dynamic>> get messageStream {
    print(
        '[MessageNotification] 🔗 messageStream accessed - has listeners: ${_messageStreamController.hasListener}');
    return _messageStreamController.stream;
  }

  /// Lấy token FCM để backend có thể gửi tin nhắn
  Future<String?> getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      print('[MessageNotification] FCM Token: $token');
      return token;
    } catch (e) {
      print('[MessageNotification] Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe đến topic để nhận tin nhắn từ topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('[MessageNotification] Subscribed to topic: $topic');
    } catch (e) {
      print('[MessageNotification] Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe từ topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('[MessageNotification] Unsubscribed from topic: $topic');
    } catch (e) {
      print('[MessageNotification] Error unsubscribing from topic: $e');
    }
  }

  /// Dừng lắng nghe
  void dispose() {
    _messageStreamController.close();
  }
}
