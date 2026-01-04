import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kltn_sharing_app/core/constants/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kltn_sharing_app/data/providers/auth_provider.dart';
import 'package:kltn_sharing_app/data/providers/user_provider.dart';
import 'package:kltn_sharing_app/data/services/fcm_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userProvider = context.read<UserProvider>();

      // Sign in with Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return;
      }

      // Get authentication details
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      // Call Google login API
      final success = await authProvider.googleLogin(
        idToken: idToken,
      );

      if (mounted) {
        if (success) {
          // Load user data
          try {
            await userProvider.loadCurrentUser();
            print('[LoginScreen] ✅ User data loaded successfully');
          } catch (e) {
            print('[LoginScreen] ⚠️  Failed to load user data: $e');
          }

          // Update FCM token
          try {
            final fcmToken = await FCMService().getFCMTokenFromFirebase();
            final currentUser = userProvider.currentUser;

            if (fcmToken != null &&
                fcmToken.isNotEmpty &&
                currentUser != null) {
              print('[LoginScreen] 📤 Updating FCM token on backend');
              await userProvider.updateFCMToken(
                userId: currentUser.id,
                fcmToken: fcmToken,
              );
              print('[LoginScreen] ✅ FCM token updated successfully');
            }
          } catch (e) {
            print('[LoginScreen] ⚠️  Failed to update FCM token: $e');
          }

          context.go(AppRoutes.home);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Google login failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google login error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Google sign-in error: $e');
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final userProvider = context.read<UserProvider>();

      final success = await authProvider.login(
        usernameOrEmail: _userNameController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (success) {
          // Load user data from API after successful login
          try {
            await userProvider.loadCurrentUser();
            print('[LoginScreen] ✅ User data loaded successfully');
          } catch (e) {
            print('[LoginScreen] ⚠️  Failed to load user data: $e');
            // Don't prevent navigation even if user data load fails
          }

          context.go(AppRoutes.home);
          // Update FCM token on backend
          // TODO: Enable FCM token update later
          try {
            final fcmToken = await FCMService().getFCMTokenFromFirebase();
            final currentUser = userProvider.currentUser;

            if (fcmToken != null &&
                fcmToken.isNotEmpty &&
                currentUser != null) {
              print('[LoginScreen] 📤 Updating FCM token on backend');
              await userProvider.updateFCMToken(
                userId: currentUser.id,
                fcmToken: fcmToken,
              );
              print('[LoginScreen] ✅ FCM token updated successfully');
            } else {
              print('[LoginScreen] ⚠️  FCM token or user ID is null');
              print(
                  '[LoginScreen] - FCM Token: ${fcmToken?.substring(0, 20) ?? 'null'}');
              print('[LoginScreen] - User ID: ${currentUser?.id ?? 'null'}');
            }
          } catch (e) {
            print('[LoginScreen] ⚠️  Failed to update FCM token: $e');
            // Don't prevent navigation even if FCM token update fails
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Đăng nhập thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
          child: Form(
            key: _formKey,
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // Logo or App Name
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
                    Text(
                      'Thông tin đăng nhập',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chào mừng bạn trở lại!',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomTextField(
                      label: 'Tên đăng nhập hoặc Email',
                      hint: 'Nhập username hoặc email của bạn',
                      controller: _userNameController,
                      keyboardType: TextInputType.text,
                      enabled: !authProvider.isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập username hoặc email';
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
                      enabled: !authProvider.isLoading,
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
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () {
                                context.push(AppRoutes.forgotPassword);
                              },
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            color: AppColors.primaryTeal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    if (authProvider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
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
                    const SizedBox(height: 16),
                    GradientButton(
                      text: 'Đăng nhập',
                      onPressed: authProvider.isLoading ? null : _handleLogin,
                      isLoading: authProvider.isLoading,
                    ),
                    const SizedBox(height: 12),
                    // Google Sign-In Button
                    GestureDetector(
                      onTap:
                          authProvider.isLoading ? null : _handleGoogleSignIn,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.borderGray,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/svgs/logo/icon.svg',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Đăng nhập bằng Google',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Chưa có tài khoản? ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : () => context.go(AppRoutes.register),
                          child: const Text(
                            'Đăng ký',
                            style: TextStyle(
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
      ),
    );
  }
}
