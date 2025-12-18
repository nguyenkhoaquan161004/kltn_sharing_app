import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class BadgesListScreen extends StatefulWidget {
  const BadgesListScreen({super.key});

  @override
  State<BadgesListScreen> createState() => _BadgesListScreenState();
}

class _BadgesListScreenState extends State<BadgesListScreen> {
  // Mock badges data
  late List<Map<String, dynamic>> _badges;

  @override
  void initState() {
    super.initState();
    _badges = [
      // Unlocked badges
      {
        'id': '1',
        'name': 'Bạn tốt bụng',
        'description': 'Chia sẻ mà không cần tiền',
        'icon': '💚',
        'color': 'green',
        'isUnlocked': true,
        'unlockedDate': '20.10.2025',
      },
      {
        'id': '2',
        'name': 'Người lãnh đạo',
        'description': 'Giành được 500 điểm',
        'icon': '👑',
        'color': 'gold',
        'isUnlocked': true,
        'unlockedDate': '18.10.2025',
      },
      {
        'id': '3',
        'name': 'Sao sáng',
        'description': 'Nhận 5 sao từ 10 người',
        'icon': '⭐',
        'color': 'blue',
        'isUnlocked': true,
        'unlockedDate': '10.10.2025',
      },
      {
        'id': '4',
        'name': 'Quân đội xanh',
        'description': 'Hoàn thành 5 giao dịch',
        'icon': '💪',
        'color': 'teal',
        'isUnlocked': true,
        'unlockedDate': '05.10.2025',
      },
      // Locked badges
      {
        'id': '5',
        'name': 'Huyền thoại',
        'description': 'Đạt 2000 điểm',
        'icon': '🏅',
        'color': 'locked',
        'isUnlocked': false,
        'progress': '500/2000',
      },
      {
        'id': '6',
        'name': 'Người gây ảnh hưởng',
        'description': 'Có 100 người theo dõi',
        'icon': '📢',
        'color': 'locked',
        'isUnlocked': false,
        'progress': '45/100',
      },
      {
        'id': '7',
        'name': 'Chuyên gia',
        'description': 'Chia sẻ trong 5 danh mục khác nhau',
        'icon': '🎓',
        'color': 'locked',
        'isUnlocked': false,
        'progress': '2/5',
      },
      {
        'id': '8',
        'name': 'Vị thần',
        'description': 'Được 100 người yêu thích',
        'icon': '✨',
        'color': 'locked',
        'isUnlocked': false,
        'progress': 'Chưa bắt đầu',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Separate unlocked and locked badges
    final unlockedBadges = _badges.where((b) => b['isUnlocked']).toList();
    final lockedBadges = _badges.where((b) => !b['isUnlocked']).toList();

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
          'Danh hiệu',
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
                        '${unlockedBadges.length}',
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
                        '${lockedBadges.length}',
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
                        '${(unlockedBadges.length / _badges.length * 100).toStringAsFixed(0)}%',
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

            // Unlocked badges section
            if (unlockedBadges.isNotEmpty) ...[
              Text(
                'Danh hiệu đã đạt được',
                style: AppTextStyles.h4,
              ),
              const SizedBox(height: 12),
              ...unlockedBadges.map((b) => _buildBadgeItem(b)).toList(),
              const SizedBox(height: 24),
            ],

            // Locked badges section
            if (lockedBadges.isNotEmpty) ...[
              Text(
                'Danh hiệu chưa đạt được',
                style: AppTextStyles.h4,
              ),
              const SizedBox(height: 12),
              ...lockedBadges.map((b) => _buildBadgeItem(b)).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeItem(Map<String, dynamic> badge) {
    final isUnlocked = badge['isUnlocked'];
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
          // Badge circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isUnlocked
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getBadgeColor(badge['color']),
                        _getBadgeColor(badge['color']).withOpacity(0.7),
                      ],
                    )
                  : null,
              color: isUnlocked ? null : Colors.grey[300],
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: _getBadgeColor(badge['color']).withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                badge['icon'],
                style: const TextStyle(
                  fontSize: 36,
                ),
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
                  badge['name'],
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        isUnlocked ? AppColors.textPrimary : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badge['description'],
                  style: AppTextStyles.caption.copyWith(
                    color:
                        isUnlocked ? AppColors.textSecondary : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
                if (isUnlocked)
                  Text(
                    'Đạt được: ${badge['unlockedDate']}',
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
                            value: _parseProgress(badge['progress']),
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
                        badge['progress'],
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

  Color _getBadgeColor(String color) {
    switch (color) {
      case 'green':
        return const Color(0xFF4CAF50);
      case 'gold':
        return AppColors.achievementGold;
      case 'blue':
        return const Color(0xFF64B5F6);
      case 'teal':
        return AppColors.primaryTeal;
      default:
        return AppColors.achievementLocked;
    }
  }
}
