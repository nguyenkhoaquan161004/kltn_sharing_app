import 'package:dio/dio.dart';

/// Helper to manage token before API calls
class TokenManager {
  static Future<void> ensureValidToken(
    Future<String?> Function() getValidTokenCallback,
    Dio dio,
  ) async {
    try {
      final validToken = await getValidTokenCallback();
      if (validToken != null) {
        dio.options.headers['Authorization'] = 'Bearer $validToken';
      }
    } catch (e) {
      print('[TokenManager] Error getting valid token: $e');
    }
  }
}
