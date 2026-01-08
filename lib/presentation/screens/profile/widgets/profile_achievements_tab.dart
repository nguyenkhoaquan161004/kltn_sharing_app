import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/services/gamification_api_service.dart';
import '../../../../data/models/gamification_response_model.dart';
import '../../../../data/providers/auth_provider.dart';
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

    // Set auth token and token refresh callback from AuthProvider BEFORE loading data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.accessToken != null) {
          _gamificationApiService.setAuthToken(authProvider.accessToken!);
          // Set token refresh callback to automatically get fresh token
          _gamificationApiService.setGetValidTokenCallback(
            () async => authProvider.accessToken,
          );
          print(
              '[ProfileAchievementsTab] Auth token and callback set for GamificationApiService');

          // Load data AFTER token is set
          _loadData();
        } else {
          setState(() {
            _errorMessage = 'Token không tìm thấy. Vui lòng đăng nhập lại.';
            _isLoading = false;
          });
        }
      } catch (e) {
        print('[ProfileAchievementsTab] Error setting auth token: $e');
        setState(() {
          _errorMessage = 'Lỗi: $e';
          _isLoading = false;
        });
      }
    });
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

      // Fetch all data in parallel
      print('DEBUG: Calling getCurrentUserStats...');
      final statsResponse = _gamificationApiService.getCurrentUserStats();

      print('DEBUG: Calling getAllBadges...');
      final allBadgesResponse = _gamificationApiService.getAllBadges();

      print('DEBUG: Calling getUserBadges...');
      final userBadgesResponse = _gamificationApiService.getUserBadges();

      print('DEBUG: Awaiting all results...');

      // Add individual timeouts for each request
      final statsWithTimeout = statsResponse.timeout(
        const Duration(seconds: 20),
        onTimeout: () =>
            throw TimeoutException('getCurrentUserStats timed out'),
      );

      final allBadgesWithTimeout = allBadgesResponse.timeout(
        const Duration(seconds: 25),
        onTimeout: () => throw TimeoutException('getAllBadges timed out'),
      );

      final userBadgesWithTimeout = userBadgesResponse.timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('getUserBadges timed out'),
      );

      final results = await Future.wait([
        statsWithTimeout,
        allBadgesWithTimeout,
        userBadgesWithTimeout,
      ]).timeout(const Duration(seconds: 60), onTimeout: () {
        throw TimeoutException('Loading badges data timed out');
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
    } on DioException catch (e) {
      if (!mounted) return;

      print('DEBUG: ❌ DioException - Status Code: ${e.response?.statusCode}');
      print('DEBUG: Error: $e');

      String errorMessage = 'Lỗi tải dữ liệu';

      if (e.response?.statusCode == 403) {
        errorMessage = 'Bạn không có quyền truy cập tính năng này';
      } else if (e.response?.statusCode == 401) {
        errorMessage = 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Kết nối bị hết thời gian, vui lòng thử lại';
      }

      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      if (!mounted) return;

      print('DEBUG: ❌ Error loading badges data');
      print('DEBUG: Error: $e');
      print('DEBUG: StackTrace: $stackTrace');

      setState(() {
        _errorMessage = 'Lỗi tải dữ liệu: ${e.toString().substring(0, 50)}';
        _isLoading = false;
      });
    }
  }

  /// Check if a badge is earned by the user
  bool _isBadgeEarned(dynamic badgeId) {
    if (badgeId == null) return false;

    final badgeIdStr = badgeId.toString().toLowerCase();

    return _userBadges.any((ub) {
      final id = ub['id'] ?? ub['badge_id'] ?? ub['badgeId'];
      final idStr = id?.toString().toLowerCase() ?? '';
      return idStr == badgeIdStr;
    });
  }

  /// Get earned date for a badge
  String? _getEarnedDate(dynamic badgeId) {
    if (badgeId == null) return null;

    final badgeIdStr = badgeId.toString().toLowerCase();

    final userBadge = _userBadges.firstWhere(
      (ub) {
        final id = ub['id'] ?? ub['badge_id'] ?? ub['badgeId'];
        final idStr = id?.toString().toLowerCase() ?? '';
        return idStr == badgeIdStr;
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
    // Separate earned and unearned badges
    final earnedBadges = _allBadges
        .where((b) => _isBadgeEarned(b['id'] ?? b['badge_id'] ?? b['badgeId']))
        .toList();
    final unearnedBadges = _allBadges
        .where((b) => !_isBadgeEarned(b['id'] ?? b['badge_id'] ?? b['badgeId']))
        .toList();

    print(
        '[ProfileAchievementsTab] DEBUG: All badges: ${_allBadges.length}, Earned: ${earnedBadges.length}, Unearned: ${unearnedBadges.length}');
    print(
        '[ProfileAchievementsTab] DEBUG: User badges count: ${_userBadges.length}');
    if (_userBadges.isNotEmpty) {
      print(
          '[ProfileAchievementsTab] DEBUG: First user badge: ${_userBadges[0]}');
    }
    if (_allBadges.isNotEmpty) {
      print(
          '[ProfileAchievementsTab] DEBUG: First all badge: ${_allBadges[0]}');
    }

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
                                '$_userPoints',
                                style: AppTextStyles.h2.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Điểm tương tác',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Earned badges section - Only show earned badges
                    if (earnedBadges.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Danh hiệu đã đạt được',
                            style: AppTextStyles.h4,
                          ),
                          GestureDetector(
                            onTap: () {
                              context.push('/badges/list');
                            },
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
                    ] else ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Icon(Icons.emoji_events_outlined,
                                  size: 48, color: AppColors.textSecondary),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa đạt được danh hiệu nào',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tiếp tục tham gia để kiếm danh hiệu',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
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
                      isEarned ? _getBadgeColor(badgeColor) : Colors.grey[300],
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
                          'Đạt được: ${_getEarnedDate(badge['id'] ?? badge['badge_id'] ?? badge['badgeId']) ?? 'N/A'}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
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
      case 'certified':
        return '✓';
      default:
        return '🏅';
    }
  }
}
