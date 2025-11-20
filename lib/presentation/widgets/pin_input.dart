import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/theme/app_colors.dart';

class PinInput extends StatelessWidget {
  final TextEditingController controller;
  final int length;
  final void Function(String)? onCompleted;
  final bool enabled;

  const PinInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.onCompleted,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return PinCodeTextField(
      appContext: context,
      length: length,
      controller: controller,
      enabled: enabled,
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(12),
        fieldHeight: 56,
        fieldWidth: 48,
        activeFillColor: AppColors.white,
        // inactiveFillColor: AppColors.lightGray,
        selectedFillColor: AppColors.white,
        activeColor: AppColors.primaryGreen,
        inactiveColor: AppColors.borderGray,
        selectedColor: AppColors.primaryGreen,
      ),
      cursorColor: AppColors.primaryGreen,
      animationDuration: const Duration(milliseconds: 300),
      enableActiveFill: true,
      keyboardType: TextInputType.number,
      onCompleted: onCompleted,
      onChanged: (value) {},
    );
  }
}
