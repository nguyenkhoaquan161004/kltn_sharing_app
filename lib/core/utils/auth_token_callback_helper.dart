import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/constants/app_routes.dart';

/// Helper function to create a consistent token expired callback for all screens
/// When token refresh fails or 403 is returned, this callback:
/// 1. Logs out the user
/// 2. Redirects to login screen
/// 3. Shows a message to the user
Future<void> Function() createTokenExpiredCallback(BuildContext context) {
  return () async {
    print(
        '[TokenExpiredCallback] 🚫 Token expired - logging out and redirecting to login');

    if (!context.mounted) {
      print(
          '[TokenExpiredCallback] Context is no longer mounted, skipping callback');
      return;
    }

    try {
      // Get auth provider and logout
      final authProvider = context.read<AuthProvider>();
      print('[TokenExpiredCallback] Calling logout...');
      await authProvider.logout();

      if (!context.mounted) {
        print('[TokenExpiredCallback] Context unmounted after logout');
        return;
      }

      // Show message to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Phiên đăng nhập của bạn đã hết hạn. Vui lòng đăng nhập lại.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

      // Redirect to login
      print('[TokenExpiredCallback] Redirecting to login screen');
      context.go(AppRoutes.login);
    } catch (e) {
      print('[TokenExpiredCallback] Error during logout: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        // Still try to redirect
        try {
          context.go(AppRoutes.login);
        } catch (e2) {
          print('[TokenExpiredCallback] Failed to redirect to login: $e2');
        }
      }
    }
  };
}
