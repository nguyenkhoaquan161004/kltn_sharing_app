import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/providers/auth_provider.dart';
import '../../../../data/providers/gamification_provider.dart';
import '../../widgets/bottom_navigation_widget.dart';
import '../../widgets/app_header_bar.dart';
import 'widgets/podium_widget.dart';
import 'widgets/leaderboard_item.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedMonth = 'Tháng 10.2025';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load leaderboard data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final gamificationProvider = context.read<GamificationProvider>();

      // Set auth token if available
      if (authProvider.accessToken != null) {
        gamificationProvider.setAuthToken(authProvider.accessToken!);
      }

      // Load leaderboard data
      gamificationProvider.loadTopUsers(limit: 3);
      gamificationProvider.loadLeaderboard(page: 0, size: 100);
      gamificationProvider.loadCurrentUserStats();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: const AppHeaderBar(orderCount: 8),
      body: Column(
        children: [
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTextStyles.h4,
              unselectedLabelStyle: AppTextStyles.h4,
              indicatorColor: AppColors.primaryTeal,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Thế giới'),
                Tab(text: 'Gần đây'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWorldRanking(),
                _buildNearbyRanking(),
              ],
            ),
          ),

          // Current user ranking
          _buildCurrentUserRanking(),
        ],
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 1),
    );
  }

  Widget _buildWorldRanking() {
    return Consumer<GamificationProvider>(
      builder: (context, gamificationProvider, _) {
        if (gamificationProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Title
              const Text(
                'BẢNG XẾP HẠNG',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cạnh tranh với những người giỏi nhất và leo lên đỉnh cao!',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Month selector
              _buildMonthSelector(),
              const SizedBox(height: 32),

              // Podium - show top 3 or placeholders
              if (gamificationProvider.topUsers.isEmpty)
                const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text('Chưa có dữ liệu'),
                  ),
                )
              else
                _buildPodium(gamificationProvider.topUsers),
              const SizedBox(height: 32),

              // Leaderboard list
              if (gamificationProvider.leaderboard.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('Chưa có dữ liệu bảng xếp hạng'),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Top 10', style: AppTextStyles.h3),
                      const SizedBox(height: 16),
                      // Show leaderboard items
                      ...gamificationProvider.leaderboard
                          .take(10)
                          .map((gamer) => LeaderboardItem(
                                user: LeaderboardUser(
                                  id: gamer.userId,
                                  name: gamer.username ?? 'Tên người dùng',
                                  avatar: gamer.avatarUrl ??
                                      'https://i.pravatar.cc/150?u=${gamer.userId}',
                                  points: gamer.points,
                                  rank: gamer.rank,
                                  change: 0,
                                ),
                              )),
                    ],
                  ),
                ),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  /// Build podium with top 3 users
  Widget _buildPodium(List<dynamic> topUsers) {
    // Create LeaderboardUser objects from gamification data
    final List<LeaderboardUser> podiumUsers = topUsers
        .map((gamer) => LeaderboardUser(
              id: gamer.userId,
              name: gamer.username ?? 'Tên người dùng',
              avatar: gamer.avatarUrl ??
                  'https://i.pravatar.cc/150?u=${gamer.userId}',
              points: gamer.points,
              rank: gamer.rank,
              change: 0,
            ))
        .toList();

    return PodiumWidget(topUsers: podiumUsers);
  }

  Widget _buildNearbyRanking() {
    return Consumer<GamificationProvider>(
      builder: (context, gamificationProvider, _) {
        if (gamificationProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Text(
                'XẾP HẠNG GẦN ĐÂY',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Những người chia sẻ gần bạn nhất!',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (gamificationProvider.leaderboard.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('Chưa có dữ liệu'),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Top người gần đây', style: AppTextStyles.h3),
                      const SizedBox(height: 16),
                      ...gamificationProvider.leaderboard
                          .take(5)
                          .map((gamer) => LeaderboardItem(
                                user: LeaderboardUser(
                                  id: gamer.userId,
                                  name: gamer.username ?? 'Tên người dùng',
                                  avatar: gamer.avatarUrl ??
                                      'https://i.pravatar.cc/150?u=${gamer.userId}',
                                  points: gamer.points,
                                  rank: gamer.rank,
                                  change: 0,
                                ),
                              )),
                    ],
                  ),
                ),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() => _selectedMonth = 'Tháng 09.2025');
          },
        ),
        Text(_selectedMonth, style: AppTextStyles.bodyMedium),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            setState(() => _selectedMonth = 'Tháng 10.2025');
          },
        ),
      ],
    );
  }

  Widget _buildCurrentUserRanking() {
    return Consumer<GamificationProvider>(
      builder: (context, gamificationProvider, _) {
        final userStats = gamificationProvider.currentUserStats;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Xếp hạng của bạn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.trending_up,
                            color: AppColors.success, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          userStats != null
                              ? '${userStats.points} điểm'
                              : 'Chưa có dữ liệu',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.success),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (userStats != null)
                  LeaderboardItem(
                    user: LeaderboardUser(
                      id: userStats.userId,
                      name: userStats.username ?? 'Tên người dùng',
                      avatar: userStats.avatarUrl ??
                          'https://i.pravatar.cc/150?u=${userStats.userId}',
                      points: userStats.points,
                      rank: userStats.rank,
                      change: 0,
                    ),
                    isCurrentUser: true,
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Chưa có thông tin xếp hạng'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class LeaderboardUser {
  final String id;
  final String name;
  final String avatar;
  final int points;

  final int rank;
  final int change;

  LeaderboardUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.points,
    required this.rank,
    required this.change,
  });
}
