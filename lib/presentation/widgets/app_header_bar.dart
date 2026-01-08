import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_routes.dart';
import '../../data/providers/order_provider.dart';
import '../../data/providers/notification_provider.dart';

class AppHeaderBar extends StatefulWidget implements PreferredSizeWidget {
  final int? orderCount; // Optional - if null, will auto-calculate
  final VoidCallback? onSearchTap;
  final VoidCallback? onMessagesTap;
  final VoidCallback? onSettingsTap;
  final bool showSettingsButton;

  const AppHeaderBar({
    super.key,
    this.orderCount,
    this.onSearchTap,
    this.onMessagesTap,
    this.onSettingsTap,
    this.showSettingsButton = false,
  });

  @override
  State<AppHeaderBar> createState() => _AppHeaderBarState();

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class _AppHeaderBarState extends State<AppHeaderBar> {
  @override
  Widget build(BuildContext context) {
    // Use provided orderCount if available, otherwise get cart count from OrderProvider
    final displayCount =
        widget.orderCount ?? context.watch<OrderProvider>().cartCount;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 56,
      leading: IconButton(
        icon: const Icon(Icons.search, color: AppColors.textPrimary),
        onPressed: widget.onSearchTap ?? () => context.push(AppRoutes.search),
      ),
      title: null,
      actions: [
        // Cart section with badge
        GestureDetector(
          onTap: () => context.push(AppRoutes.orders),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Giỏ hàng', style: AppTextStyles.bodyLarge),
                  const SizedBox(width: 8),
                  // Container(
                  //   padding:
                  //       const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  //   decoration: BoxDecoration(
                  //     color: AppColors.badgePink,
                  //     borderRadius: BorderRadius.circular(12),
                  //   ),
                  //   child: Text(
                  //     displayCount.toString(),
                  //     style: const TextStyle(
                  //       color: Colors.white,
                  //       fontSize: 12,
                  //       fontWeight: FontWeight.bold,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
        // Messages button with badge
        GestureDetector(
          onTap: widget.onMessagesTap ?? () => context.push(AppRoutes.messages),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.mail_outline,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
                // Badge for unread messages
                Consumer<NotificationProvider>(
                  builder: (context, notifProvider, _) {
                    final hasUnread =
                        notifProvider.unreadNotifications.isNotEmpty;
                    if (!hasUnread) {
                      return const SizedBox.shrink();
                    }
                    return Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // Settings button (optional)
        if (widget.showSettingsButton)
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            onPressed: widget.onSettingsTap ?? () {},
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
