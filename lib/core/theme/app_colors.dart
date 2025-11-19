import 'package:flutter/material.dart';

class AppColors {
  // Primary gradient colors
  static const Color primaryGreen = Color(0xFF76C76E);
  static const Color primaryYellow = Color(0xFFC6D549);
  static const Color primaryTeal = Color(0xFF2BB8AB);
  static const Color primaryDarkTeal = Color(0xFF1B7B70);

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

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryYellow, primaryGreen, primaryTeal],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryGreen, primaryTeal],
  );
}
