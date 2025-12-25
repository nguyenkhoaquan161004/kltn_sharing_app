import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppTextStyles {
  // Headings

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  // Price
  static const TextStyle price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryCyan,
  );

  static const TextStyle priceLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryCyan,
  );

  // Button
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle captionBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  // Label
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // Countdown timer
  static const TextStyle countdown = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
  );

  // DISPLAY
  static const TextStyle displayL34 = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w700,
    fontSize: 34,
    height: 1.3,
    letterSpacing: -0.015,
    color: Colors.black,
  );

  static const TextStyle displayS32 = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 1.3,
    letterSpacing: -0.015,
    color: Colors.black,
  );

  // HEADLINES
  static const TextStyle h1 = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w700,
    fontSize: 28,
    height: 1.3,
    letterSpacing: -0.015,
    color: Colors.black,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w800,
    fontSize: 24,
    height: 1.3,
    letterSpacing: 0.02,
    color: Colors.black,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    fontSize: 20,
    height: 1.35,
    letterSpacing: -0.01,
    color: Colors.black,
  );

  // SUBTITLE
  static const TextStyle subtitle18 = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    fontSize: 18,
    height: 1.35,
    letterSpacing: -0.008,
    color: Colors.black,
  );

  // BODY 16
  static const TextStyle body16B = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w700,
    fontSize: 16,
    height: 1.4,
    color: Colors.black,
  );

  static const TextStyle body16SB = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.4,
    color: Colors.black,
  );

  static const TextStyle body16M = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    fontSize: 16,
    height: 1.4,
    color: Colors.black,
  );

  static const TextStyle body16R = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.4,
    color: Colors.black,
  );

  static const TextStyle body16L = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w300,
    fontSize: 16,
    height: 1.4,
    color: Colors.black,
  );

  // SECONDARY BODY 14
  static const TextStyle secondary14B = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w700,
    fontSize: 14,
    height: 1.45,
    letterSpacing: 0.005,
    color: Colors.black,
  );

  static const TextStyle secondary14SB = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 1.45,
    letterSpacing: 0.005,
    color: Colors.black,
  );

  static const TextStyle secondary14M = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1.45,
    letterSpacing: 0.005,
    color: Colors.black,
  );

  static const TextStyle secondary14R = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.45,
    letterSpacing: 0.005,
    color: Colors.black,
  );

  static const TextStyle secondary14L = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w300,
    fontSize: 14,
    height: 1.45,
    letterSpacing: 0.005,
    color: Colors.black,
  );

  // NOTE 12
  static const TextStyle note12B = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w700,
    fontSize: 12,
    height: 1.5,
    letterSpacing: 0.01,
    color: Colors.black,
  );

  static const TextStyle note12SB = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 1.5,
    letterSpacing: 0.01,
    color: Colors.black,
  );

  static const TextStyle note12M = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 1.5,
    letterSpacing: 0.01,
    color: Colors.black,
  );

  static const TextStyle note12R = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.5,
    letterSpacing: 0.01,
    color: Colors.black,
  );

  static const TextStyle note12L = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w300,
    fontSize: 12,
    height: 1.5,
    letterSpacing: 0.01,
    color: Colors.black,
  );
}
