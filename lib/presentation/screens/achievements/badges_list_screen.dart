import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/services/gamification_api_service.dart';

class BadgesListScreen extends StatefulWidget {
  const BadgesListScreen({super.key});

  @override
  State<BadgesListScreen> createState() => _BadgesListScreenState();
}

class _BadgesListScreenState extends State<BadgesListScreen> {
  late GamificationApiService _gamificationApiService;
  List<Map<String, dynamic>> _allBadges = [];
  List<Map<String, dynamic>> _userBadges = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _gamificationApiService = context.read<GamificationApiService>();
    _loadBadges();
  }

  /// Load all badges and user's earned badges
  Future<void> _loadBadges() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch all badges and user badges in parallel
      final allBadgesResponse = _gamificationApiService.getAllBadges();
      final userBadgesResponse = _gamificationApiService.getUserBadges();

      final results = await Future.wait([
        allBadgesResponse,
        userBadgesResponse,
      ]);

      if (!mounted) return;

      setState(() {
        _allBadges = results[0] as List<Map<String, dynamic>>;
        _userBadges = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;
      });

      print(
          'DEBUG: Loaded ${_allBadges.length} all badges and ${_userBadges.length} user badges');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('DEBUG: Error loading badges: $e');
    }
  }

  /// Check if a badge is earned by the user
  bool _isBadgeEarned(dynamic badgeId) {
    if (badgeId == null) return false;

    final badgeIdStr = badgeId.toString().toLowerCase();

    final isEarned = _userBadges.any((ub) {
      // Check multiple possible ID field names
      final id = ub['id'] ?? ub['badge_id'] ?? ub['badgeId'];
      final idStr = id?.toString().toLowerCase() ?? '';
      return idStr == badgeIdStr;
    });

    // Debug log
    if (isEarned) {
      print('[BadgesListScreen] Badge $badgeId is earned by user');
    }

    return isEarned;
  }

  /// Get earned date for a badge
  String? _getEarnedDate(dynamic badgeId) {
    if (badgeId == null) return null;

    final badgeIdStr = badgeId.toString().toLowerCase();

    final userBadge = _userBadges.firstWhere(
      (ub) {
        // Check multiple possible ID field names
        final id = ub['id'] ?? ub['badge_id'] ?? ub['badgeId'];
        final idStr = id?.toString().toLowerCase() ?? '';
        return idStr == badgeIdStr;
      },
      orElse: () => {},
    );
    if (userBadge.isEmpty) return null;

    final earnedAt = userBadge['earned_at'] ?? userBadge['earnedAt'];
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
    // Separate earned and unearned badges
    final earnedBadges = _allBadges
        .where((b) => _isBadgeEarned(b['id'] ?? b['badge_id'] ?? b['badgeId']))
        .toList();
    final unearnedBadges = _allBadges
        .where((b) => !_isBadgeEarned(b['id'] ?? b['badge_id'] ?? b['badgeId']))
        .toList();

    print(
        '[BadgesListScreen] DEBUG: All badges: ${_allBadges.length}, Earned: ${earnedBadges.length}, Unearned: ${unearnedBadges.length}');
    print('[BadgesListScreen] DEBUG: User badges count: ${_userBadges.length}');
    if (_userBadges.isNotEmpty) {
      print('[BadgesListScreen] DEBUG: First user badge: ${_userBadges[0]}');
    }
    if (_allBadges.isNotEmpty) {
      print('[BadgesListScreen] DEBUG: First all badge: ${_allBadges[0]}');
    }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lỗi tải danh hiệu',
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
                        onPressed: _loadBadges,
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
                                  '${earnedBadges.length}',
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
                                  '${unearnedBadges.length}',
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
                                  _allBadges.isEmpty
                                      ? '0%'
                                      : '${(earnedBadges.length / _allBadges.length * 100).toStringAsFixed(0)}%',
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

                      // Earned badges section
                      if (earnedBadges.isNotEmpty) ...[
                        Text(
                          'Danh hiệu đã đạt được',
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GridView.count(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: earnedBadges
                                .map((b) => _buildBadgeItem(b, true))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Unearned badges section
                      if (unearnedBadges.isNotEmpty) ...[
                        Text(
                          'Danh hiệu chưa đạt được',
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GridView.count(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: unearnedBadges
                                .map((b) => _buildBadgeItem(b, false))
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildBadgeItem(Map<String, dynamic> badge, bool isEarned) {
    final badgeName = badge['name'] ?? badge['badge_name'] ?? 'Unknown Badge';
    final badgeDescription = badge['description'] ?? '';
    final iconValue = badge['icon'] ?? '';
    // Use icon directly from API if it looks like an emoji/unicode, otherwise convert
    final badgeIcon =
        _isEmoji(iconValue) ? iconValue : _getEmojiForBadge(iconValue);
    final badgeColor = badge['color'] ?? badge['badge_color'] ?? 'gray';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isEarned
              ? AppColors.primaryGreen.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEarned
                ? AppColors.primaryGreen.withOpacity(0.5)
                : AppColors.borderLight,
            width: isEarned ? 2 : 1,
          ),
          boxShadow: isEarned
              ? [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
          gradient: isEarned
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryGreen.withOpacity(0.05),
                    AppColors.primaryGreen.withOpacity(0.02),
                  ],
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular badge
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color:
                      isEarned ? _getBadgeColor(badgeColor) : Colors.grey[200],
                  shape: BoxShape.circle,
                  boxShadow: isEarned
                      ? [
                          BoxShadow(
                            color: _getBadgeColor(badgeColor).withOpacity(0.35),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                ),
                child: Center(
                  child: Text(
                    badgeIcon,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Badge info
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      badgeName,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isEarned
                            ? AppColors.primaryGreen
                            : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: Text(
                        badgeDescription,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isEarned)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Đạt được: ${_getEarnedDate(badge['badge_id'] ?? badge['badgeId'] ?? badge['id']) ?? 'N/A'}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Chưa đạt được',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[600],
                            fontSize: 9,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBadgeColor(String color) {
    switch (color.toLowerCase()) {
      case 'green':
        return const Color(0xFF4CAF50);
      case 'gold':
        return AppColors.achievementGold;
      case 'blue':
        return const Color(0xFF64B5F6);
      case 'teal':
        return AppColors.primaryTeal;
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

  /// Check if the string is likely an emoji or unicode character
  bool _isEmoji(String? value) {
    if (value == null || value.isEmpty) return false;
    // Check if it's a single character (likely emoji/unicode)
    // or if it contains common emoji patterns
    final codeUnits = value.codeUnits;
    if (codeUnits.isEmpty) return false;
    // Emoji are typically represented as high unicode values or multiple code units
    // This is a simple heuristic check
    return value.length <= 2 && codeUnits.any((cu) => cu > 127);
  }

  /// Map icon name from API to emoji
  String _getEmojiForBadge(String? iconName) {
    if (iconName == null || iconName.isEmpty) return '🏅';

    final name = iconName.toLowerCase().replaceAll('-', '').replaceAll('_', '');

    switch (name) {
      case 'badgenewcomer':
      case 'newcomer':
        return '👋';
      case 'badgefirstshare':
      case 'firstshare':
        return '📦';
      case 'badgefirstreceive':
      case 'firstreceive':
        return '🎁';
      case 'badgebronze':
      case 'bronze':
        return '🥉';
      case 'badgesilver':
      case 'silver':
        return '🥈';
      case 'badgegold':
      case 'gold':
        return '🥇';
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
