import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // if (_formKey.currentState!.validate()) {
    //   if (!_agreeToTerms) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(
    //           content: Text('Vui lòng đồng ý với điều khoản sử dụng')),
    //     );
    //     return;
    //   }
    setState(() => _isLoading = true);
    // TODO: Implement register logic
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    if (mounted) {
      context.go(AppRoutes.terms);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/svgs/logo/name.svg',
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Tạo tài khoản',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đăng ký nhanh bằng username và mật khẩu',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'Họ và tên',
                  hint: 'Nhập họ và tên',
                  controller: _fullNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Tên đăng nhập',
                  hint: 'Chọn username của bạn',
                  controller: _userNameController,
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập username';
                    }
                    if (value.length < 4) {
                      return 'Username phải có ít nhất 4 ký tự';
                    }
                    final usernameRegex = RegExp(r'^[a-zA-Z0-9_\\.]+$');
                    if (!usernameRegex.hasMatch(value)) {
                      return 'Chỉ dùng chữ, số, dấu chấm hoặc gạch dưới';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Mật khẩu',
                  hint: 'Nhập mật khẩu',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Xác nhận mật khẩu',
                  hint: 'Nhập lại mật khẩu',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword);
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
                ),
                const SizedBox(height: 20),
                // Row(
                //   children: [
                //     Checkbox(
                //       value: _agreeToTerms,
                //       onChanged: (value) {
                //         setState(() => _agreeToTerms = value ?? false);
                //       },
                //       activeColor: AppColors.primaryTeal,
                //     ),
                //     Expanded(
                //       child: GestureDetector(
                //         onTap: () => context.go(AppRoutes.terms),
                //         child: RichText(
                //           text: const TextSpan(
                //             style: TextStyle(
                //               fontSize: 14,
                //               color: AppColors.textSecondary,
                //             ),
                //             children: [
                //               TextSpan(text: 'Tôi đồng ý với '),
                //               TextSpan(
                //                 text: 'Điều khoản sử dụng',
                //                 style: TextStyle(
                //                   color: AppColors.primaryTeal,
                //                   fontWeight: FontWeight.w600,
                //                 ),
                //               ),
                //             ],
                //           ),
                //         ),
                //       ),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 24),
                GradientButton(
                  text: 'Đăng ký',
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Đã có tài khoản? ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
