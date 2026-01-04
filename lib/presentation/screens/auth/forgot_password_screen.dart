import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kltn_sharing_app/core/constants/app_text_styles.dart';
import 'package:kltn_sharing_app/core/theme/app_colors.dart';
import 'package:kltn_sharing_app/core/constants/app_routes.dart';
import 'package:kltn_sharing_app/presentation/widgets/custom_text_field.dart';
import 'package:kltn_sharing_app/presentation/widgets/gradient_button.dart';
import 'package:kltn_sharing_app/data/services/auth_api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  final _authApiService = AuthApiService();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final email = _emailController.text.trim();
        await _authApiService.forgotPassword(email);

        if (mounted) {
          // Navigate to OTP verification screen
          context.push(
            AppRoutes.verifyPasswordResetOtp,
            extra: {'email': email},
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Quên mật khẩu?',
                  style: AppTextStyles.h1,
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Nhập email của bạn để nhận mã xác nhận',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Email input field
                Text(
                  'Email',
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _emailController,
                  hint: 'Nhập email của bạn',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Email không hợp lệ';
                    }
                    return null;
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

                // Submit button
                GradientButton(
                  text: 'Gửi mã xác nhận',
                  onPressed: _isLoading ? null : _handleForgotPassword,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
