import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../widgets/pin_input.dart';
import '../../widgets/gradient_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kltn_sharing_app/data/providers/auth_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _pinController = TextEditingController();
  late String _email;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _email = widget.email;
  }

  @override
  void dispose() {
    _pinController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_pinController.text.length == 6) {
      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.verifyRegistrationOtp(
        email: _email,
        otp: _pinController.text,
      );

      if (mounted) {
        if (success) {
          _countdownTimer?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công! Vui lòng đăng nhập'),
              backgroundColor: Colors.green,
            ),
          );
          if (mounted) {
            context.go(AppRoutes.login);
          }
        } else {
          // Clear PIN on failure for user to retry
          _pinController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Xác thực thất bại'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleResendOtp() async {
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.sendOtp(email: _email);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã OTP đã được gửi lại'),
            backgroundColor: Colors.green,
          ),
        );

        // Start countdown
        setState(() => _resendCountdown = 60);

        _countdownTimer?.cancel();
        _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              if (_resendCountdown > 0) {
                _resendCountdown--;
              } else {
                timer.cancel();
              }
            });
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Gửi lại thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textPrimary),
                    onPressed: authProvider.isLoading
                        ? null
                        : () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRoutes.register);
                            }
                          },
                    alignment: Alignment.centerLeft,
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryYellow.withOpacity(0.6),
                          AppColors.primaryGreen.withOpacity(0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                        child: SvgPicture.asset('assets/svgs/logo/icon.svg')),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Nhập mã xác thực',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chúng tôi đã gửi mã xác thực đến email:\n$_email',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  PinInput(
                    controller: _pinController,
                    length: 6,
                    onCompleted: (value) => _handleVerify(),
                  ),
                  if (authProvider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          authProvider.errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  GradientButton(
                    text: 'Xác thực',
                    onPressed: authProvider.isLoading ? null : _handleVerify,
                    isLoading: authProvider.isLoading,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Chưa nhận được mã? ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed:
                            authProvider.isLoading ? null : _handleResendOtp,
                        child: Text(
                          _resendCountdown > 0
                              ? 'Gửi lại ($_resendCountdown)'
                              : 'Gửi lại',
                          style: const TextStyle(
                            color: AppColors.primaryTeal,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
