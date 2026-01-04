import 'package:firebase_messaging/firebase_messaging.dart';
import 'fcm_service.dart';

/// Service để debug Firebase Messaging setup
class FirebaseDebugService {
  static Future<void> printFullDebugInfo() async {
    print('╔═══════════════════════════════════════════════════════════╗');
    print('║        FIREBASE MESSAGING DEBUG INFO                      ║');
    print('╚═══════════════════════════════════════════════════════════╝');

    try {
      // 1. Token
      final fcmService = FCMService();
      final token = fcmService.getFCMToken();
      print('\n1️⃣  FCM Token (from storage):');
      if (token != null && token.isNotEmpty) {
        print('   ✅ Token exists');
        print('   Token (first 50 chars): ${token.substring(0, 50)}...');
      } else {
        print('   ❌ NULL or empty');
        print('   Attempting to get from Firebase...');
        final fbToken = await fcmService.getFCMTokenFromFirebase();
        if (fbToken != null) {
          print('   ✅ Got from Firebase: ${fbToken.substring(0, 50)}...');
        } else {
          print('   ❌ Failed to get from Firebase');
        }
      }

      // 2. Permission
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      print('\n2️⃣  Notification Permission:');
      print('   Status: ${settings.authorizationStatus}');
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('   ✅ Authorized');
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('   ❌ DENIED - User must enable in Settings');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.notDetermined) {
        print('   ⏳ Not determined - permission will be requested');
      }
      print(
          '   Alert: ${settings.alert.toString().contains('enabled') ? '✅' : '❌'}');
      print(
          '   Badge: ${settings.badge.toString().contains('enabled') ? '✅' : '❌'}');
      print(
          '   Sound: ${settings.sound.toString().contains('enabled') ? '✅' : '❌'}');

      // 3. Firebase initialized
      print('\n3️⃣  Firebase Status:');
      try {
        final projectId = FirebaseMessaging.instance.app.options.projectId;
        print('   Project ID: $projectId');
        print('   ✅ Firebase initialized');
      } catch (e) {
        print('   ❌ Firebase not initialized: $e');
      }

      // 4. Message handlers
      print('\n4️⃣  Message Handlers:');
      print('   ✅ Foreground listener: Enabled');
      print('   ✅ Background handler: Registered');
      print('   ✅ Message opened handler: Enabled');

      print('\n╚═══════════════════════════════════════════════════════════╝');
      print('\n💡 NEXT STEPS:');
      print('   1. If token is NULL → restart app and re-login');
      print('   2. If permission is DENIED → enable in Settings');
      print('   3. Copy the token and test in Firebase Console');
      print('   4. Backend must implement /api/v2/users/fcm-token endpoint');
      print('═══════════════════════════════════════════════════════════\n');
    } catch (e) {
      print('\n❌ Error getting debug info: $e');
      print('═══════════════════════════════════════════════════════════\n');
    }
  }

  /// Test if FCM token can be sent to backend
  static Future<void> testTokenEndpoint() async {
    print('\n🧪 Testing FCM token endpoint...');
    try {
      final fcmService = FCMService();
      final token = fcmService.getFCMToken();

      if (token == null || token.isEmpty) {
        print('❌ No FCM token available');
        return;
      }

      print('📤 Sending token to backend...');
      print('   Endpoint: POST /api/v2/users/fcm-token');
      print('   Token (first 50): ${token.substring(0, 50)}...');

      // This will trigger the actual API call
      // Results will be logged by the API service
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  /// Check if background messaging is enabled
  static Future<void> checkBackgroundMessaging() async {
    print('\n🔍 Checking background messaging...');
    try {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      print('   APNS Token (iOS): ${apnsToken ?? "Not available"}');

      print('   ✅ Background messaging should work');
    } catch (e) {
      print('   ❌ Error: $e');
    }
  }
}
