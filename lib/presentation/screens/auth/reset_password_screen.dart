import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kltn_sharing_app/core/constants/app_text_styles.dart';
import 'package:kltn_sharing_app/core/theme/app_colors.dart';
import 'package:kltn_sharing_app/core/constants/app_routes.dart';
import 'package:kltn_sharing_app/presentation/widgets/custom_text_field.dart';
import 'package:kltn_sharing_app/presentation/widgets/gradient_button.dart';
import 'package:kltn_sharing_app/data/services/auth_api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String resetToken;

  const ResetPasswordScreen({
    super.key,
    required this.resetToken,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _authApiService = AuthApiService();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }
    if (value.length > 100) {
      return 'Mật khẩu không được vượt quá 100 ký tự';
    }
    // Check for at least one uppercase, one lowercase, one number
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Mật khẩu phải chứa ít nhất một chữ hoa';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Mật khẩu phải chứa ít nhất một chữ thường';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Mật khẩu phải chứa ít nhất một số';
    }
    return null;
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (password != confirmPassword) {
        setState(() {
          _errorMessage = 'Mật khẩu không khớp';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await _authApiService.resetPassword(widget.resetToken, password);

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mật khẩu đã được thay đổi thành công'),
              backgroundColor: AppColors.success,
            ),
          );

          // Navigate back to login screen
          context.go(AppRoutes.login);
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
                  'Đặt lại mật khẩu',
                  style: AppTextStyles.h1,
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Nhập mật khẩu mới để hoàn tất quá trình đặt lại',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Password field
                Text(
                  'Mật khẩu mới',
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _passwordController,
                  hint: 'Nhập mật khẩu mới',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.darkGray,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: _validatePassword,
                  onChanged: (value) {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Password requirements
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yêu cầu mật khẩu:',
                        style: AppTextStyles.label,
                      ),
                      const SizedBox(height: 8),
                      _buildRequirement('Ít nhất 8 ký tự',
                          _passwordController.text.length >= 8),
                      _buildRequirement('Chứa chữ hoa (A-Z)',
                          RegExp(r'[A-Z]').hasMatch(_passwordController.text)),
                      _buildRequirement('Chứa chữ thường (a-z)',
                          RegExp(r'[a-z]').hasMatch(_passwordController.text)),
                      _buildRequirement('Chứa số (0-9)',
                          RegExp(r'[0-9]').hasMatch(_passwordController.text)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Confirm password field
                Text(
                  'Xác nhận mật khẩu',
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _confirmPasswordController,
                  hint: 'Nhập lại mật khẩu',
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.darkGray,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu';
                    }
                    if (value != _passwordController.text) {
                      return 'Mật khẩu không khớp';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _errorMessage = null;
                    });
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
                  text: 'Đặt lại mật khẩu',
                  onPressed: _isLoading ? null : _handleResetPassword,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: isMet ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
