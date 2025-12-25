import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class AchievementsListScreen extends StatefulWidget {
  const AchievementsListScreen({super.key});

  @override
  State<AchievementsListScreen> createState() => _AchievementsListScreenState();
}

class _AchievementsListScreenState extends State<AchievementsListScreen> {
  // Mock achievements data - both unlocked and locked
  late List<Map<String, dynamic>> _achievements;

  @override
  void initState() {
    super.initState();
    _achievements = [
      // Unlocked achievements
      {
        'id': '1',
        'name': 'Người chia sẻ của tháng',
        'description': 'Chia sẻ nhiều sản phẩm nhất trong tháng',
        'icon': '🏆',
        'color': 'gold',
        'isUnlocked': true,
        'unlockedDate': '23.10.2025',
      },
      {
        'id': '2',
        'name': 'Kết nối cộng đồng',
        'description': 'Nhận được 50 lượt quan tâm',
        'icon': '🤝',
        'color': 'silver',
        'isUnlocked': true,
        'unlockedDate': '15.10.2025',
      },
      {
        'id': '3',
        'name': 'Người đào tạo',
        'description': 'Giúp 10 người mới tham gia',
        'icon': '👨‍🏫',
        'color': 'bronze',
        'isUnlocked': true,
        'unlockedDate': '01.10.2025',
      },
      // Locked achievements
      {
        'id': '4',
        'name': 'Điểm số cao',
        'description': 'Đạt 1000 điểm gamification',
        'icon': '⭐',
        'color': 'locked',
        'isUnlocked': false,
        'progress': '650/1000',
      },
      {
        'id': '5',
        'name': 'Nhà sưu tập',
        'description': 'Chia sẻ 100 sản phẩm',
        'icon': '📦',
        'color': 'locked',
        'isUnlocked': false,
        'progress': '45/100',
      },
      {
        'id': '6',
        'name': 'Người quản lý cộng đồng',
        'description': 'Tham gia nhóm cộng đồng',
        'icon': '👥',
        'color': 'locked',
        'isUnlocked': false,
        'progress': 'Chưa bắt đầu',
      },
      {
        'id': '7',
        'name': 'Công dân tốt',
        'description': 'Nhận được 5 sao từ 20 người',
        'icon': '⭐⭐⭐⭐⭐',
        'color': 'locked',
        'isUnlocked': false,
        'progress': '12/20',
      },
      {
        'id': '8',
        'name': 'Người chia sẻ hàng ngày',
        'description': 'Chia sẻ sản phẩm 30 ngày liên tiếp',
        'icon': '📅',
        'color': 'locked',
        'isUnlocked': false,
        'progress': '15/30',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Separate unlocked and locked achievements
    final unlockedAchievements =
        _achievements.where((a) => a['isUnlocked']).toList();
    final lockedAchievements =
        _achievements.where((a) => !a['isUnlocked']).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Thành tựu',
          style: AppTextStyles.h3,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${unlockedAchievements.length}',
                        style: AppTextStyles.h2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đã đạt được',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${lockedAchievements.length}',
                        style: AppTextStyles.h2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chưa đạt được',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${(unlockedAchievements.length / _achievements.length * 100).toStringAsFixed(0)}%',
                        style: AppTextStyles.h2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hoàn thành',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Unlocked achievements section
            if (unlockedAchievements.isNotEmpty) ...[
              Text(
                'Thành tựu đã đạt được',
                style: AppTextStyles.h4,
              ),
              const SizedBox(height: 12),
              ...unlockedAchievements
                  .map((a) => _buildAchievementItem(a))
                  .toList(),
              const SizedBox(height: 24),
            ],

            // Locked achievements section
            if (lockedAchievements.isNotEmpty) ...[
              Text(
                'Thành tựu chưa đạt được',
                style: AppTextStyles.h4,
              ),
              const SizedBox(height: 12),
              ...lockedAchievements
                  .map((a) => _buildAchievementItem(a))
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem(Map<String, dynamic> achievement) {
    final isUnlocked = achievement['isUnlocked'];
    final backgroundColor = isUnlocked ? Colors.white : Colors.grey[200];
    final borderColor = isUnlocked ? AppColors.borderLight : Colors.grey[300];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? Colors.transparent,
          width: 1,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          // Icon/Badge
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? _getAchievementColor(achievement['color'])
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                achievement['icon'],
                style: const TextStyle(fontSize: 32),
              ),
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
                    color:
                        isUnlocked ? AppColors.textPrimary : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement['description'],
                  style: AppTextStyles.caption.copyWith(
                    color:
                        isUnlocked ? AppColors.textSecondary : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
                if (isUnlocked)
                  Text(
                    'Đạt được: ${achievement['unlockedDate']}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryTeal,
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _parseProgress(achievement['progress']),
                            minHeight: 4,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primaryTeal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        achievement['progress'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _parseProgress(String progress) {
    if (progress == 'Chưa bắt đầu') return 0;
    try {
      final parts = progress.split('/');
      if (parts.length == 2) {
        final current = int.parse(parts[0].trim());
        final total = int.parse(parts[1].trim());
        return current / total;
      }
    } catch (e) {
      return 0;
    }
    return 0;
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
}
