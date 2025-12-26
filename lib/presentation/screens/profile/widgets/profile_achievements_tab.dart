import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/services/gamification_api_service.dart';
import '../../../../data/models/gamification_response_model.dart';
import 'dart:async';

class ProfileAchievementsTab extends StatefulWidget {
  const ProfileAchievementsTab({super.key});

  @override
  State<ProfileAchievementsTab> createState() => _ProfileAchievementsTabState();
}

class _ProfileAchievementsTabState extends State<ProfileAchievementsTab> {
  late GamificationApiService _gamificationApiService;

  // User stats
  int _userPoints = 0;

  // Badges
  List<Map<String, dynamic>> _allBadges = [];
  List<Map<String, dynamic>> _userBadges = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _gamificationApiService = context.read<GamificationApiService>();
    _loadData();
  }

  /// Load user stats and badges data
  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('DEBUG: Starting to load badges data...');

      // Fetch all data in parallel with timeout
      print('DEBUG: Calling getCurrentUserStats...');
      final statsResponse = _gamificationApiService
          .getCurrentUserStats()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('getCurrentUserStats timed out');
      });

      print('DEBUG: Calling getAllBadges...');
      final allBadgesResponse = _gamificationApiService
          .getAllBadges()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('getAllBadges timed out');
      });

      print('DEBUG: Calling getUserBadges...');
      final userBadgesResponse = _gamificationApiService
          .getUserBadges()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('getUserBadges timed out');
      });

      print('DEBUG: Awaiting all results...');
      final results = await Future.wait([
        statsResponse,
        allBadgesResponse,
        userBadgesResponse,
      ]).timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Future.wait timed out after 15 seconds');
      });

      if (!mounted) return;

      print('DEBUG: ✅ Results received:');
      print('  - Stats type: ${results[0].runtimeType}');
      print('  - All Badges: ${results[1]}');
      print('  - User Badges: ${results[2]}');

      final userStats = results[0] as GamificationDto;
      final allBadges = results[1] as List<Map<String, dynamic>>;
      final userBadges = results[2] as List<Map<String, dynamic>>;

      setState(() {
        _userPoints = userStats.points;
        _allBadges = allBadges;
        _userBadges = userBadges;
        _isLoading = false;
      });

      print(
          'DEBUG: ✅ State updated - Points: $_userPoints, All Badges: ${_allBadges.length}, User Badges: ${_userBadges.length}');
    } on TimeoutException catch (e) {
      if (!mounted) return;

      print('DEBUG: ❌ Timeout error: $e');
      setState(() {
        _errorMessage = 'Kết nối bị hết thời gian: ${e.message}';
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      if (!mounted) return;

      print('DEBUG: ❌ Error loading badges data');
      print('DEBUG: Error: $e');
      print('DEBUG: StackTrace: $stackTrace');

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Check if a badge is earned by the user
  bool _isBadgeEarned(dynamic badgeId) {
    if (badgeId == null) return false;
    return _userBadges.any((ub) {
      final id = ub['id'] ?? ub['badge_id'] ?? ub['badgeId'];
      return id.toString() == badgeId.toString();
    });
  }

  /// Get earned date for a badge
  String? _getEarnedDate(dynamic badgeId) {
    if (badgeId == null) return null;
    final userBadge = _userBadges.firstWhere(
      (ub) {
        final id = ub['id'] ?? ub['badge_id'] ?? ub['badgeId'];
        return id.toString() == badgeId.toString();
      },
      orElse: () => {},
    );
    if (userBadge.isEmpty) return null;

    final earnedAt = userBadge['earnedAt'] ?? userBadge['earned_at'];
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
    // Get earned badges
    final earnedBadges =
        _allBadges.where((b) => _isBadgeEarned(b['id'])).take(5).toList();

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lỗi tải dữ liệu',
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
                      onPressed: _loadData,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats row - Gamification points + Total badges
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            value: '$_userPoints',
                            label: 'Điểm gamification',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.borderLight,
                        ),
                        Expanded(
                          child: _buildStatItem(
                            value: '${_userBadges.length}',
                            label: 'Danh hiệu đạt được',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Badges section
                    _buildSection(
                      title: 'Bộ sưu tập danh hiệu',
                      onViewAll: () {
                        context.push('/badges/list');
                      },
                      child: earnedBadges.isEmpty
                          ? Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  'Chưa đạt được danh hiệu nào',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          : SizedBox(
                              height: 160,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: earnedBadges.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  return _buildBadgeItem(earnedBadges[index]);
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

  Widget _buildBadgeItem(Map<String, dynamic> badge) {
    final badgeName = badge['name'] ?? badge['badge_name'] ?? 'Unknown Badge';
    final badgeColor = badge['color'] ?? badge['badge_color'] ?? 'green';
    final iconName = badge['icon'] ?? '';
    final badgeIcon = _getEmojiForBadge(iconName);

    return Column(
      children: [
        // Circular badge with shadow
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: _getBadgeColor(badgeColor),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getBadgeColor(badgeColor).withOpacity(0.35),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              badgeIcon,
              style: const TextStyle(fontSize: 42),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Badge name below circle
        SizedBox(
          width: 110,
          child: Text(
            badgeName,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getBadgeColor(String color) {
    switch (color.toLowerCase()) {
      case 'green':
        return AppColors.primaryGreen;
      case 'yellow':
      case 'gold':
        return AppColors.achievementGold;
      case 'blue':
        return const Color(0xFF64B5F6);
      case 'purple':
        return const Color(0xFF9C27B0);
      case 'red':
        return const Color(0xFFE53935);
      case 'orange':
        return const Color(0xFFFF9800);
      default:
        return AppColors.achievementLocked;
    }
  }

  /// Map icon name from API to emoji
  String _getEmojiForBadge(String? iconName) {
    if (iconName == null || iconName.isEmpty) return '🏅';

    final name = iconName.toLowerCase().replaceAll('-', '').replaceAll('_', '');

    switch (name) {
      case 'badgenewcomer':
      case 'newcomer':
        return '👋';
      case 'badgestar':
      case 'star':
        return '⭐';
      case 'badgetop':
      case 'top':
        return '🏆';
      case 'badgehero':
      case 'hero':
        return '💪';
      case 'badgesharer':
      case 'sharer':
        return '🤝';
      case 'badgecommunity':
      case 'community':
        return '👥';
      case 'badgegold':
      case 'gold':
        return '✨';
      case 'badgefire':
      case 'fire':
        return '🔥';
      case 'badgecertified':
      case 'certified':
        return '✓';
      default:
        return '🏅';
    }
  }
}
