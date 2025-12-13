import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class ProfileAchievementsTab extends StatelessWidget {
  ProfileAchievementsTab({super.key});

  // Mock data
  final Map<String, dynamic> _stats = {
    'achievementsCount': 12,
    'badgesCount': 15,
  };

  final List<Map<String, dynamic>> _achievements = [
    {
      'id': '1',
      'name': 'Người chia sẻ của tháng',
      'date': '23.10.2025',
      'color': 'gold',
      'isUnlocked': true,
    },
    {
      'id': '2',
      'name': 'Kết nối cộng đồng',
      'date': '23.10.2025',
      'color': 'silver',
      'isUnlocked': true,
    },
    {
      'id': '3',
      'name': 'Tên thành tựu',
      'date': '23.10.2025',
      'color': 'bronze',
      'isUnlocked': true,
    },
  ];

  final List<Map<String, dynamic>> _badges = [
    {
      'id': '1',
      'name': 'Người chia sẻ của tháng',
      'date': '23.10.2025',
      'color': 'green',
      'isUnlocked': true
    },
    {
      'id': '2',
      'name': 'Người chia sẻ của tháng',
      'date': '23.10.2025',
      'color': 'yellow',
      'isUnlocked': true
    },
    {
      'id': '3',
      'name': 'Người chia sẻ của tháng',
      'date': '23.10.2025',
      'color': 'blue',
      'isUnlocked': true
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  value: '${_stats['achievementsCount']}',
                  label: 'Thành tựu đạt được',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.borderLight,
              ),
              Expanded(
                child: _buildStatItem(
                  value: '${_stats['badgesCount']}',
                  label: 'Danh hiệu đạt được',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Achievements section
          _buildSection(
            title: 'Thành tựu đạt được',
            onViewAll: () {
              // TODO: Navigate to achievements list
            },
            child: Column(
              children:
                  _achievements.map((a) => _buildAchievementItem(a)).toList(),
            ),
          ),
          const SizedBox(height: 32),

          // Badges section
          _buildSection(
            title: 'Bộ sưu tập danh hiệu',
            onViewAll: () {
              // TODO: Navigate to badges collection
            },
            child: SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _badges.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return _buildBadgeItem(_badges[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h2.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required VoidCallback onViewAll,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.h4),
              GestureDetector(
                onTap: onViewAll,
                child: Text(
                  'Xem tất cả',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildAchievementItem(Map<String, dynamic> achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getAchievementColor(achievement['color']),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['name'],
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ngày đạt được: ${achievement['date']}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(Map<String, dynamic> badge) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _getBadgeColor(badge['color']),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getBadgeColor(badge['color']).withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '1',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            badge['name'],
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getAchievementColor(String color) {
    switch (color) {
      case 'gold':
        return AppColors.achievementGold;
      case 'silver':
        return AppColors.achievementSilver;
      case 'bronze':
        return AppColors.achievementBronze;
      default:
        return AppColors.achievementLocked;
    }
  }

  Color _getBadgeColor(String color) {
    switch (color) {
      case 'green':
        return AppColors.primaryGreen;
      case 'yellow':
        return AppColors.achievementGold;
      case 'blue':
        return const Color(0xFF64B5F6);
      default:
        return AppColors.achievementLocked;
    }
  }
}
