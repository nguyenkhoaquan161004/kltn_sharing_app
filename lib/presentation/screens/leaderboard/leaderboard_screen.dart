import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/providers/gamification_provider.dart';
import '../../../../data/providers/user_provider.dart';
import '../../../../data/services/address_service.dart';
import '../../../../data/services/user_api_service.dart';
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
  final Map<String, String> _userNameCache = {}; // Cache userId -> username
  late UserApiService _userApiService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _userApiService = UserApiService();

    // Load leaderboard data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gamificationProvider = context.read<GamificationProvider>();
      final userProvider = context.read<UserProvider>();

      // Don't set auth token - leaderboard should work without auth
      // The API will use userDetails if available, otherwise show public leaderboard

      // Load current user first
      if (userProvider.currentUser == null) {
        userProvider.loadCurrentUser();
      }

      // Load leaderboard data with correct size
      gamificationProvider.loadTopUsers(limit: 3);
      gamificationProvider.loadLeaderboard(page: 0, size: 20);
      gamificationProvider.loadCurrentUserStats();

      // Load nearby leaderboard if user has address
      _loadNearbyLeaderboard();
    });
  }

  /// Convert user address to lat/lon and load nearby leaderboard
  Future<void> _loadNearbyLeaderboard() async {
    try {
      final userProvider = context.read<UserProvider>();
      final gamificationProvider = context.read<GamificationProvider>();

      final user = userProvider.currentUser;
      if (user?.address == null || user!.address!.isEmpty) {
        print(
            '[Leaderboard] User address not set, skipping nearby leaderboard');
        return;
      }

      print('[Leaderboard] Converting address to coordinates: ${user.address}');

      // Search address to get coordinates
      final suggestions =
          await AddressService.searchAddressesByText(user.address!);

      if (suggestions.isNotEmpty) {
        final location = suggestions.first;
        print(
            '[Leaderboard] Found coordinates - lat: ${location.latitude}, lon: ${location.longitude}');

        // Load nearby leaderboard
        await gamificationProvider.loadLeaderboardWithScope(
          scope: 'NEARBY',
          timeFrame: 'ALL_TIME',
          currentUserLat: location.latitude,
          currentUserLon: location.longitude,
          radiusKm: 50.0,
          page: 0,
          size: 20,
        );
      } else {
        print(
            '[Leaderboard] Could not find coordinates for address: ${user.address}');
      }
    } catch (e) {
      print('[Leaderboard] Error loading nearby leaderboard: $e');
    }
  }

  void _onTabChanged() {
    // Tab changed callback can be used if needed for additional logic
  }

  /// Fetch user name from userId with caching
  Future<String> _getUserName(String userId) async {
    // Check if already cached
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }

    try {
      final user = await _userApiService.getUserById(userId);
      final userName = user.username ?? 'Tên người dùng';
      _userNameCache[userId] = userName; // Cache the result
      return userName;
    } catch (e) {
      print('[Leaderboard] Error fetching user name for $userId: $e');
      return 'Tên người dùng';
    }
  }

  /// Get user rank compared to top 20
  /// Returns rank if in top 20, otherwise returns "20+"
  String _getUserRank(int userPoints, List<dynamic> leaderboard) {
    if (leaderboard.isEmpty) {
      return '20+';
    }

    // Find user position in leaderboard
    for (int i = 0; i < leaderboard.length && i < 20; i++) {
      final gamer = leaderboard[i];
      if (gamer.points <= userPoints) {
        // User rank is between i and i+1
        return '${i + 1}';
      }
    }

    // User is below top 20
    return '20+';
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: const AppHeaderBar(),
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
                'Cạnh tranh với những người giỏi nhất và\nleo lên đỉnh cao!',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              // Month selector
              _buildMonthSelector(),
              // const SizedBox(height: 12),

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
    return Consumer2<GamificationProvider, UserProvider>(
      builder: (context, gamificationProvider, userProvider, _) {
        final userStats = gamificationProvider.currentUserStats;
        final currentUser = userProvider.currentUser;

        // Use user info if available, fallback to userStats
        final userId = currentUser?.id ?? userStats?.userId ?? '';
        final userAvatar = currentUser?.avatar ??
            userStats?.avatarUrl ??
            'https://i.pravatar.cc/150?u=$userId';
        final points = userStats?.points ?? 0;
        final rank = userStats?.rank ?? 0;

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
                if (currentUser != null || userStats != null)
                  // Use FutureBuilder to fetch user name from API
                  FutureBuilder<String>(
                    future: _getUserName(userId),
                    builder: (context, snapshot) {
                      final userName = snapshot.data ??
                          currentUser?.username ??
                          userStats?.username ??
                          'Tên người dùng';

                      // Calculate rank based on comparison with top 20
                      final leaderboard = gamificationProvider.leaderboard;
                      final calculatedRank = _getUserRank(points, leaderboard);

                      return LeaderboardItem(
                        user: LeaderboardUser(
                          id: userId,
                          name: userName,
                          avatar: userAvatar,
                          points: points,
                          rank: rank,
                          change: 0,
                        ),
                        isCurrentUser: true,
                        customRankDisplay: calculatedRank,
                      );
                    },
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
