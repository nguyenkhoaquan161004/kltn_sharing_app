import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primaryGreen = Color(0xFF1ABC9C);
  static const Color primaryYellow = Color(0xFFF9CA24);
  static const Color primaryTeal = Color(0xFF4DB6AC);
  static const Color primaryCyan = Color(0xFF00BFA5);
  static const Color primaryDarkTeal = Color(0xFF1B7B70);
  static const Color primaryDark = Color(0xFF34495E);

  // Secondary colors
  static const Color primaryGreen2 = Color(0xFF81C784);

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color darkGray = Color(0xFF2C2C2C);
  static const Color mediumGray = Color(0xFF808080);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color borderGray = Color(0xFFE0E0E0);

  // Text colors
  static const Color textPrimary = Color(0xFF1C1C1C);
  static const Color textSecondary = Color(0xFF808080);
  static const Color textHint = Color(0xFFBBBBBB);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Background colors
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF263238);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Border colors
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFBDBDBD);

  // Achievement colors
  static const Color achievementGold = Color(0xFFFDD835);
  static const Color achievementSilver = Color(0xFFBDBDBD);
  static const Color achievementBronze = Color(0xFFFF8A65);
  static const Color achievementLocked = Color(0xFFE0E0E0);

  // Chat colors
  static const Color chatSender = Color(0xFF455A64);
  static const Color chatReceiver = Color(0xFFF5F5F5);

  // Badge
  static const Color badgePink = Color(0xFFEC407A);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      primaryGreen,
      primaryYellow,
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryGreen, primaryYellow],
  );

  static const LinearGradient triangleGradient = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [
      Color(0xFF34495E), // 19.09%
      Color(0x3834495E), // 22% opacity
      Color(0x0034495E), // 0% opacity
    ],
    stops: [
      0.1909,
      0.8345,
      1.0,
    ],
  );

  // Shadow
  static Color shadow = Colors.black.withOpacity(0.1);
  static Color shadowDark = Colors.black.withOpacity(0.2);
}
