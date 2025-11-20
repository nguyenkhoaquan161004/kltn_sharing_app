import 'package:flutter/material.dart';

class AppColors {
  // Primary gradient colors
  static const Color primaryGreen = Color(0xFF1ABC9C);
  static const Color primaryYellow = Color(0xFFF9CA24);
  static const Color primaryTeal = Color.fromARGB(255, 111, 210, 200);
  static const Color primaryDarkTeal = Color(0xFF1B7B70);
  static const Color primaryDark = Color(0xFF34495E);

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
}
