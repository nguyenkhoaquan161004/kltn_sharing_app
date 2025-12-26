import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/services/gamification_api_service.dart';

class AchievementsListScreen extends StatefulWidget {
  const AchievementsListScreen({super.key});

  @override
  State<AchievementsListScreen> createState() => _AchievementsListScreenState();
}

class _AchievementsListScreenState extends State<AchievementsListScreen> {
  late GamificationApiService _gamificationApiService;
  List<Map<String, dynamic>> _allAchievements = [];
  List<Map<String, dynamic>> _userAchievements = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _gamificationApiService = context.read<GamificationApiService>();
    _loadAchievements();
  }

  /// Load all achievements and user's earned achievements
  Future<void> _loadAchievements() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch all achievements and user achievements in parallel
      final allAchievementsResponse =
          _gamificationApiService.getAllAchievements();
      final userAchievementsResponse =
          _gamificationApiService.getUserAchievements();

      final results = await Future.wait([
        allAchievementsResponse,
        userAchievementsResponse,
      ]);

      if (!mounted) return;

      setState(() {
        _allAchievements = results[0] as List<Map<String, dynamic>>;
        _userAchievements = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;
      });

      print(
          'DEBUG: Loaded ${_allAchievements.length} all achievements and ${_userAchievements.length} user achievements');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('DEBUG: Error loading achievements: $e');
    }
  }

  /// Check if an achievement is earned by the user
  bool _isAchievementEarned(dynamic achievementId) {
    if (achievementId == null) return false;
    return _userAchievements.any((ua) {
      final id = ua['achievement_id'] ?? ua['achievementId'];
      return id.toString() == achievementId.toString();
    });
  }

  /// Get earned date for an achievement
  String? _getEarnedDate(dynamic achievementId) {
    if (achievementId == null) return null;
    final userAchievement = _userAchievements.firstWhere(
      (ua) {
        final id = ua['achievement_id'] ?? ua['achievementId'];
        return id.toString() == achievementId.toString();
      },
      orElse: () => {},
    );
    if (userAchievement.isEmpty) return null;

    final earnedAt =
        userAchievement['earned_at'] ?? userAchievement['earnedAt'];
    if (earnedAt == null) return null;

    try {
      final date = DateTime.parse(earnedAt.toString());
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Separate earned and unearned achievements
    final earnedAchievements = _allAchievements
        .where((a) =>
            _isAchievementEarned(a['achievement_id'] ?? a['achievementId']))
        .toList();
    final unearnedAchievements = _allAchievements
        .where((a) =>
            !_isAchievementEarned(a['achievement_id'] ?? a['achievementId']))
        .toList();

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lỗi tải thành tựu',
                        style: AppTextStyles.h4,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage ?? 'Đã xảy ra lỗi',
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAchievements,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
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
                                  '${earnedAchievements.length}',
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
                                  '${unearnedAchievements.length}',
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
                                  _allAchievements.isEmpty
                                      ? '0%'
                                      : '${(earnedAchievements.length / _allAchievements.length * 100).toStringAsFixed(0)}%',
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

                      // Earned achievements section
                      if (earnedAchievements.isNotEmpty) ...[
                        Text(
                          'Thành tựu đã đạt được',
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: 12),
                        ...earnedAchievements
                            .map((a) => _buildAchievementItem(a, true))
                            .toList(),
                        const SizedBox(height: 24),
                      ],

                      // Unearned achievements section
                      if (unearnedAchievements.isNotEmpty) ...[
                        Text(
                          'Thành tựu chưa đạt được',
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: 12),
                        ...unearnedAchievements
                            .map((a) => _buildAchievementItem(a, false))
                            .toList(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildAchievementItem(
      Map<String, dynamic> achievement, bool isEarned) {
    final achievementName = achievement['name'] ??
        achievement['achievement_name'] ??
        'Unknown Achievement';
    final achievementDescription = achievement['description'] ?? '';
    final achievementIcon = achievement['icon'] ?? '🏆';
    final achievementColor =
        achievement['color'] ?? achievement['achievement_color'] ?? 'gold';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEarned ? Colors.white : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEarned
              ? AppColors.borderLight
              : (Colors.grey[300] ?? Colors.transparent),
          width: 1,
        ),
        boxShadow: isEarned
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
              color: isEarned
                  ? _getAchievementColor(achievementColor)
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                achievementIcon,
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
                  achievementName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isEarned ? AppColors.textPrimary : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievementDescription,
                  style: AppTextStyles.caption.copyWith(
                    color:
                        isEarned ? AppColors.textSecondary : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
                if (isEarned)
                  Text(
                    'Đạt được: ${_getEarnedDate(achievement['achievement_id'] ?? achievement['achievementId']) ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryTeal,
                    ),
                  )
                else
                  Text(
                    'Tiếp tục cố gắng',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAchievementColor(String color) {
    switch (color.toLowerCase()) {
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
