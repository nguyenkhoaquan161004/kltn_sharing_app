import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_api_service.dart';

/// Service để quản lý Firebase Cloud Messaging (FCM) token
/// Được dùng để gửi push notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();

  factory FCMService() {
    return _instance;
  }

  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final UserApiService _userApiService = UserApiService();
  late SharedPreferences _prefs;
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  static const String _fcmTokenKey = 'fcm_token';
  static const String _androidChannelId = 'shareo_notifications';
  static const String _androidChannelName = 'Shareo Notifications';

  /// Initialize FCM service
  /// Gọi cái này một lần khi ứng dụng khởi động
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // Setup local notifications plugin for Android
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      // Setup Android notification channel
      final AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        onDidReceiveLocalNotification: (id, title, body, payload) {
          print('[FCMService] iOS notification received: $title');
        },
      );

      final InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(initSettings);

      // Create Android notification channel
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            AndroidNotificationChannel(
              _androidChannelId,
              _androidChannelName,
              description: 'Shareo push notifications',
              importance: Importance.max,
              enableVibration: true,
              enableLights: true,
            ),
          );

      // Request notification permission (iOS + Android 13+)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print(
          '[FCMService] User notification permission: ${settings.authorizationStatus}');

      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('[FCMService] ✅ FCM Token: ${token.substring(0, 50)}...');
        await _prefs.setString(_fcmTokenKey, token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print(
            '[FCMService] 🔄 FCM Token refreshed: ${newToken.substring(0, 50)}...');
        _prefs.setString(_fcmTokenKey, newToken);
        // Cập nhật token mới lên backend
        _updateTokenOnBackend(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('[FCMService] 📨 Message received in foreground!');
        print('[FCMService] Message data: ${message.data}');

        if (message.notification != null) {
          print(
              '[FCMService] Notification title: ${message.notification!.title}');
          print(
              '[FCMService] Notification body: ${message.notification!.body}');

          // Display notification when app is in foreground
          _displayNotification(message);
        }
      });

      print('[FCMService] ✅ FCM service initialized successfully');
    } catch (e) {
      print('[FCMService] Error initializing FCM: $e');
    }
  }

  /// Display notification for foreground messages
  Future<void> _displayNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      final androidDetails = AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: 'Shareo push notifications',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        enableLights: true,
        ticker: 'ticker',
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('notification'),
      );

      final iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title ?? 'Shareo',
        notification.body ?? 'You have a new message',
        details,
        payload: message.data.toString(),
      );

      print('[FCMService] ✅ Notification displayed');
    } catch (e) {
      print('[FCMService] Error displaying notification: $e');
    }
  }

  /// Get FCM token từ local storage
  String? getFCMToken() {
    try {
      return _prefs.getString(_fcmTokenKey);
    } catch (e) {
      print('[FCMService] Error getting FCM token: $e');
      return null;
    }
  }

  /// Get FCM token từ Firebase với retry logic
  Future<String?> getFCMTokenFromFirebase() async {
    try {
      // Retry logic - Firebase có thể chưa sẵn sàng ngay
      int retries = 3;
      while (retries > 0) {
        try {
          final token = await _firebaseMessaging.getToken();
          if (token != null && token.isNotEmpty) {
            return token;
          }
        } catch (e) {
          retries--;
          if (retries > 0) {
            print(
                '[FCMService] ⏳ Firebase not ready, retrying... (${3 - retries}/3)');
            await Future.delayed(Duration(milliseconds: 500));
          } else {
            throw e;
          }
        }
      }
      return null;
    } catch (e) {
      print('[FCMService] ❌ Error getting FCM token from Firebase: $e');
      return null;
    }
  }

  /// Update FCM token trên backend
  /// Gọi cái này sau khi login thành công
  Future<void> updateTokenOnBackend(String? accessToken) async {
    try {
      if (accessToken != null) {
        _userApiService.setAuthToken(accessToken);
      }

      final token = getFCMToken();
      if (token == null || token.isEmpty) {
        print('[FCMService] ⚠️  FCM token is empty, getting new one...');
        final newToken = await getFCMTokenFromFirebase();
        if (newToken == null) {
          print('[FCMService] ❌ Could not get FCM token');
          return;
        }
      }

      await _updateTokenOnBackend(token!);
    } catch (e) {
      print('[FCMService] Error updating token on backend: $e');
    }
  }

  /// Internal method để update token trên backend
  Future<void> _updateTokenOnBackend(String token) async {
    try {
      print(
          '[FCMService] 📤 Updating FCM token on backend: ${token.substring(0, 50)}...');

      // Gửi token lên backend qua UserApiService
      await _userApiService.updateFCMToken(
        userId: '', // userId có thể rỗng, backend sẽ lấy từ auth context
        fcmToken: token,
      );

      print('[FCMService] ✅ FCM token updated on backend');
    } catch (e) {
      print('[FCMService] ❌ Failed to update FCM token on backend: $e');
    }
  }

  /// Delete FCM token (call on logout)
  Future<void> deleteFCMToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      await _prefs.remove(_fcmTokenKey);
      print('[FCMService] ✅ FCM token deleted');
    } catch (e) {
      print('[FCMService] Error deleting FCM token: $e');
    }
  }
}

/// Background message handler - MUST be a top-level function
@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(RemoteMessage message) async {
  print('[FCMService] 📨 Background message received!');
  print('[FCMService] Message data: ${message.data}');

  if (message.notification != null) {
    print(
        '[FCMService] Background notification title: ${message.notification!.title}');
    print(
        '[FCMService] Background notification body: ${message.notification!.body}');

    // Display notification even when app is in background
    try {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      final androidDetails = AndroidNotificationDetails(
        'shareo_notifications',
        'Shareo Notifications',
        channelDescription: 'Shareo push notifications',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      );

      final iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        message.notification.hashCode,
        message.notification!.title ?? 'Shareo',
        message.notification!.body ?? 'You have a new message',
        details,
        payload: message.data.toString(),
      );

      print('[FCMService] ✅ Background notification displayed');
    } catch (e) {
      print('[FCMService] Error displaying background notification: $e');
    }
  }
}
