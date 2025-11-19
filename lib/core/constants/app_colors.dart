import 'package:flutter/material.dart';

class AppColors {
  // Primary gradient: Teal → Green → Yellow
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF4DB6AC), // Teal
      Color(0xFF81C784), // Green
      Color(0xFFFFF176), // Yellow
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Main colors
  static const Color primaryTeal = Color(0xFF4DB6AC);
  static const Color primaryGreen = Color(0xFF81C784);
  static const Color primaryYellow = Color(0xFFFFF176);
  static const Color primaryCyan = Color(0xFF00BFA5);

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

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Background
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF263238);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Border
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFBDBDBD);

  // Shadow
  static Color shadow = Colors.black.withOpacity(0.1);
  static Color shadowDark = Colors.black.withOpacity(0.2);
}
