import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_routes.dart';

class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final int orderCount;
  final VoidCallback? onSearchTap;
  final VoidCallback? onMessagesTap;
  final VoidCallback? onSettingsTap;
  final bool showSettingsButton;

  const AppHeaderBar({
    super.key,
    this.orderCount = 0,
    this.onSearchTap,
    this.onMessagesTap,
    this.onSettingsTap,
    this.showSettingsButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 56,
      leading: IconButton(
        icon: const Icon(Icons.search, color: AppColors.textPrimary),
        onPressed: onSearchTap ?? () => context.push(AppRoutes.search),
      ),
      title: null,
      actions: [
        // Orders section with badge
        GestureDetector(
          onTap: () => context.push(AppRoutes.orders),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Đơn hàng', style: AppTextStyles.bodyLarge),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.badgePink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      orderCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Messages button
        IconButton(
          icon: const Icon(Icons.mail_outline, color: AppColors.textPrimary),
          onPressed: onMessagesTap ?? () => context.push(AppRoutes.messages),
        ),
        // Settings button (optional)
        if (showSettingsButton)
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            onPressed: onSettingsTap ?? () {},
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
