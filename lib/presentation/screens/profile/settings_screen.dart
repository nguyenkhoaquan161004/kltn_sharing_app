import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/user_provider.dart';
import 'widgets/edit_profile_modal.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoggingOut = false;

  void _handleLogout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoggingOut = true);

    try {
      final authProvider = context.read<AuthProvider>();
      print('[SettingsScreen] Calling logout...');

      await authProvider.logout();

      print('[SettingsScreen] Logout successful');

      if (mounted) {
        // Navigate to login screen
        context.go('/login');
      }
    } catch (e) {
      print('[SettingsScreen] Logout error: $e');
      if (mounted) {
        setState(() => _isLoggingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng xuất: $e')),
        );
      }
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Điều khoản người dùng'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Điều khoản sử dụng dịch vụ Shareo',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Quyền và trách nhiệm của người dùng\n\n'
                'Người dùng đồng ý tuân thủ các điều khoản và điều kiện của dịch vụ. '
                'Mỗi người dùng chịu trách nhiệm về mọi hoạt động trong tài khoản của mình.\n\n'
                '2. Nội dung do người dùng cung cấp\n\n'
                'Người dùng cam kết rằng nội dung được chia sẻ hợp pháp, không vi phạm quyền của bên thứ ba, '
                'và phù hợp với tiêu chuẩn cộng đồng.\n\n'
                '3. Hạn chế sử dụng\n\n'
                'Không được sử dụng dịch vụ cho bất kỳ mục đích bất hợp pháp hoặc gây hại nào. '
                'Không được cố gắng hack hoặc làm hư hỏng hệ thống.\n\n'
                '4. Chính sách ủng hộ từ thiện\n\n'
                'Toàn bộ lợi nhuận từ các giao dịch trên Shareo sẽ được góp vào quỹ Mặt trận Tổ quốc Việt Nam.\n\n'
                '🇻🇳 Ngân hàng TMCP Công Thương Việt Nam (VietinBank)\n'
                'Tên TK: Ban Vận động cứu trợ Trung ương\n'
                'STK: 55102025 - Chi nhánh: Đông Hà Nội\n\n'
                '5. Chấm dứt dịch vụ\n\n'
                'Chúng tôi có quyền chấm dứt tài khoản của bạn nếu vi phạm điều khoản này.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chính sách bảo mật'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chính sách bảo mật dữ liệu Shareo',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Thu thập thông tin\n\n'
                'Chúng tôi thu thập thông tin cá nhân để cung cấp và cải thiện dịch vụ của mình. '
                'Thông tin bao gồm tên, email, số điện thoại, và địa chỉ.\n\n'
                '2. Sử dụng thông tin\n\n'
                'Thông tin của bạn được sử dụng để:\n'
                '- Cung cấp dịch vụ\n'
                '- Gửi thông báo\n'
                '- Cải thiện trải nghiệm người dùng\n'
                '- Bảo vệ chống gian lận\n\n'
                '3. Bảo vệ thông tin\n\n'
                'Chúng tôi sử dụng các biện pháp bảo mật công nghệ cao để bảo vệ dữ liệu của bạn.\n\n'
                '4. Chia sẻ dữ liệu\n\n'
                'Chúng tôi không chia sẻ thông tin cá nhân với bên thứ ba ngoài trường hợp được yêu cầu bởi pháp luật.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cài đặt',
          style: AppTextStyles.h3,
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Thông tin tài khoản
          _buildSettingItem(
            icon: Icons.person,
            title: 'Thông tin tài khoản',
            subtitle: 'Cập nhật thông tin cá nhân',
            onTap: () {
              final userProvider = context.read<UserProvider>();
              final currentUser = userProvider.currentUser;

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => EditProfileModal(
                  currentName: currentUser?.fullName,
                  currentEmail: currentUser?.email,
                  currentAddress: currentUser?.address,
                  currentPhone: currentUser?.phoneNumber,
                  currentAvatar: currentUser?.avatar,
                  onProfileUpdated: () {
                    // Reload user data after profile update
                    userProvider.loadCurrentUser();
                  },
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 56),

          // Thông báo
          _buildSettingItem(
            icon: Icons.notifications,
            title: 'Thông báo',
            subtitle: 'Cài đặt thông báo',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng sắp có')),
              );
            },
          ),
          const Divider(height: 1, indent: 56),

          // Điều khoản người dùng
          _buildSettingItem(
            icon: Icons.description,
            title: 'Điều khoản người dùng',
            subtitle: 'Xem điều khoản dịch vụ',
            onTap: () {
              _showTermsDialog();
            },
          ),
          const Divider(height: 1, indent: 56),

          // Chính sách
          _buildSettingItem(
            icon: Icons.policy,
            title: 'Chính sách',
            subtitle: 'Xem chính sách bảo mật',
            onTap: () {
              _showPolicyDialog();
            },
          ),
          const Divider(height: 1, indent: 56),

          // Đăng xuất
          _buildSettingItem(
            icon: Icons.logout,
            title: 'Đăng xuất',
            subtitle: 'Thoát khỏi tài khoản',
            titleColor: Colors.red,
            isLoading: _isLoggingOut,
            onTap: _isLoggingOut ? null : _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color titleColor = AppColors.textPrimary,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
        ),
        child: Row(
          children: [
            Icon(icon, color: titleColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
