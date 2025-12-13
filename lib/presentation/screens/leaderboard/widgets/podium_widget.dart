import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_routes.dart';
import '../leaderboard_screen.dart';

class PodiumWidget extends StatelessWidget {
  final List<LeaderboardUser> topUsers;

  const PodiumWidget({
    super.key,
    required this.topUsers,
  });

  @override
  Widget build(BuildContext context) {
    if (topUsers.length < 3) {
      return const SizedBox();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 280,
        width: MediaQuery.of(context).size.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 2nd place (left)
            _buildPodiumItem(
              context: context,
              user: topUsers[1],
              rank: 2,
              podiumHeight: 70,
              podiumColor: AppColors.textSecondary.withOpacity(0.3),
              crownColor: null,
            ),
            const SizedBox(width: 8),

            // 1st place (center)
            _buildPodiumItem(
              context: context,
              user: topUsers[0],
              rank: 1,
              podiumHeight: 100,
              podiumColor: AppColors.primaryYellow.withOpacity(0.5),
              crownColor: AppColors.achievementGold,
            ),
            const SizedBox(width: 8),

            // 3rd place (right)
            _buildPodiumItem(
              context: context,
              user: topUsers[2],
              rank: 3,
              podiumHeight: 50,
              podiumColor: AppColors.achievementBronze.withOpacity(0.3),
              crownColor: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumItem({
    required BuildContext context,
    required LeaderboardUser user,
    required int rank,
    required double podiumHeight,
    required Color podiumColor,
    Color? crownColor,
  }) {
    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.getUserProfileRoute(user.id));
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Crown for 1st place
          if (crownColor != null)
            Icon(
              Icons.workspace_premium,
              color: crownColor,
              size: 24,
            ),
          const SizedBox(height: 2),

          // Avatar
          Container(
            width: rank == 1 ? 70 : 56,
            height: rank == 1 ? 70 : 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getRankColor(rank),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getRankColor(rank).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
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
          const SizedBox(height: 6),

          // Name
          SizedBox(
            width: 70,
            child: Text(
              user.name,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Points
          Text(
            '${user.points}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),

          // Podium
          Container(
            width: rank == 1 ? 90 : 70,
            height: podiumHeight,
            decoration: BoxDecoration(
              color: podiumColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getRankColor(rank).withOpacity(0.2),
                  border: Border.all(
                    color: _getRankColor(rank),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getRankColor(rank),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return AppColors.achievementGold;
      case 2:
        return AppColors.achievementSilver;
      case 3:
        return AppColors.achievementBronze;
      default:
        return AppColors.textSecondary;
    }
  }
}
