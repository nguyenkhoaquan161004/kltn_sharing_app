import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_routes.dart';
import '../leaderboard_screen.dart';

class LeaderboardItem extends StatelessWidget {
  final LeaderboardUser user;
  final bool isCurrentUser;

  const LeaderboardItem({
    super.key,
    required this.user,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCurrentUser
          ? null
          : () => context.push(AppRoutes.getUserProfileRoute(user.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? AppColors.primaryTeal.withOpacity(0.1)
              : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          border: isCurrentUser
              ? Border.all(color: AppColors.primaryTeal, width: 1)
              : null,
          boxShadow: isCurrentUser
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Rank number
            SizedBox(
              width: 30,
              child: Text(
                '${user.rank}',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser
                      ? AppColors.primaryTeal
                      : AppColors.textPrimary,
                ),
              ),
            ),

            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.borderLight,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: user.avatar.isNotEmpty
                    ? Image.network(user.avatar, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.backgroundGray,
                        child: const Icon(
                          Icons.person,
                          size: 24,
                          color: AppColors.textSecondary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Name and points
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${user.points} độ uy tín',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            // Change indicator
            _buildChangeIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeIndicator() {
    if (user.change == 0) {
      return const SizedBox(width: 40);
    }

    final isPositive = user.change > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        '${isPositive ? '+' : ''}${user.change}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isPositive ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}
