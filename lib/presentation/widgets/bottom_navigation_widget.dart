import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_routes.dart';
import '../../data/providers/notification_provider.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int currentIndex;

  const BottomNavigationWidget({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go(AppRoutes.home);
            break;
          case 1:
            context.go(AppRoutes.leaderboard);
            break;
          case 2:
            context.go(AppRoutes.notifications);
            break;
          case 3:
            context.go(AppRoutes.profile);
            break;
        }
      },
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.leaderboard),
          label: 'Xếp hạng',
        ),
        BottomNavigationBarItem(
          icon: Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              final hasUnread = notifProvider.unreadNotifications.isNotEmpty;
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
                        decoration: BoxDecoration(
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
    );
  }
}
