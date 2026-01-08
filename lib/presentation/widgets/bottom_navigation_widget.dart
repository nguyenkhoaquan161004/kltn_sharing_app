import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/providers/notification_provider.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int currentIndex;
  final VoidCallback? onAddPressed;

  const BottomNavigationWidget({
    super.key,
    required this.currentIndex,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Bottom Navigation Bar
        BottomNavigationBar(
          currentIndex: currentIndex < 2
              ? currentIndex
              : currentIndex + 1, // Adjust for empty middle button
          onTap: (index) {
            _handleNavigation(context, index);
          },
          type: BottomNavigationBarType.fixed,
          iconSize: 22,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard),
              label: 'Xếp hạng',
            ),
            // Empty space for the floating add button
            const BottomNavigationBarItem(
              icon: SizedBox.shrink(),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Consumer<NotificationProvider>(
                builder: (context, notifProvider, _) {
                  final hasUnread =
                      notifProvider.unreadNotifications.isNotEmpty;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications),
                      if (hasUnread)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              label: 'Thông báo',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Tôi',
            ),
          ],
        ),
        // Floating Add Button in the middle
        Positioned(
          bottom: 28,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: onAddPressed,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Handle navigation
  void _handleNavigation(BuildContext context, int index) {
    // Skip the empty item at index 2
    if (index == 2) {
      return; // Do nothing for the empty middle button
    }

    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.leaderboard);
        break;
      case 3:
        context.go(AppRoutes.notifications);
        break;
      case 4:
        context.go(AppRoutes.profile);
        break;
    }
  }
}
