import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:kltn_sharing_app/core/constants/app_text_styles.dart';
import 'package:kltn_sharing_app/core/theme/app_colors.dart';
import 'package:kltn_sharing_app/core/constants/app_routes.dart';
import 'package:kltn_sharing_app/presentation/widgets/gradient_button.dart';
import 'package:kltn_sharing_app/data/services/auth_api_service.dart';

class VerifyPasswordResetOtpScreen extends StatefulWidget {
  final String email;

  const VerifyPasswordResetOtpScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyPasswordResetOtpScreen> createState() =>
      _VerifyPasswordResetOtpScreenState();
}

class _VerifyPasswordResetOtpScreenState
    extends State<VerifyPasswordResetOtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int _secondsRemaining = 300; // 5 minutes
  late bool _canResend = false;

  final _authApiService = AuthApiService();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_secondsRemaining > 0 && mounted) {
        setState(() {
          _secondsRemaining--;
        });
        _startTimer();
      } else if (_secondsRemaining == 0 && mounted) {
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mã OTP';
      });
      return;
    }

    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Mã OTP phải có 6 chữ số';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resetToken = await _authApiService.verifyPasswordResetOtp(
        widget.email,
        otp,
      );

      if (mounted) {
        // Navigate to reset password screen
        context.push(
          AppRoutes.resetPassword,
          extra: {'resetToken': resetToken},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Đã xảy ra lỗi'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleResendOtp() async {
    // Implement resend OTP logic here
    setState(() {
      _secondsRemaining = 300;
      _canResend = false;
    });
    _startTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mã OTP đã được gửi lại'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Xác nhận OTP',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Nhập mã 6 chữ số đã được gửi đến ${widget.email}',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 32),

              // OTP input field
              PinCodeTextField(
                appContext: context,
                length: 6,
                enableActiveFill: true,
                obscureText: false,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 50,
                  activeFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                  activeColor: AppColors.primaryTeal,
                  selectedColor: AppColors.primaryTeal,
                  inactiveColor: AppColors.lightGray,
                ),
                keyboardType: TextInputType.number,
                controller: _otpController,
                onChanged: (String value) {
                  setState(() {
                    _errorMessage = null;
                  });
                },
                beforeTextPaste: (text) {
                  return true;
                },
              ),
              const SizedBox(height: 32),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 20),

              // Timer and resend
              Center(
                child: Column(
                  children: [
                    Text(
                      'Mã hết hạn trong: ${_formatTime(_secondsRemaining)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _secondsRemaining < 60
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _canResend ? _handleResendOtp : null,
                      child: Text(
                        'Gửi lại mã OTP',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _canResend
                              ? AppColors.primaryTeal
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              GradientButton(
                text: 'Xác nhận',
                onPressed: _isLoading ? null : _handleVerifyOtp,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
