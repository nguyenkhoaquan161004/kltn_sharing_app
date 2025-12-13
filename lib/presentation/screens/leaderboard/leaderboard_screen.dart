import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/mock_data.dart';
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

  // Mock data
  late List<LeaderboardUser> _topUsers;
  late List<LeaderboardUser> _otherUsers;
  late LeaderboardUser _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeLeaderboardData();
  }

  void _initializeLeaderboardData() {
    // Top 3 users from MockData
    _topUsers = [
      LeaderboardUser(
        id: MockData.users[0].userId.toString(),
        name: MockData.users[0].name,
        avatar: MockData.users[0].avatar ?? 'https://i.pravatar.cc/150?img=1',
        points: MockData.users[0].trustScore * 100,
        rank: 1,
        change: 0,
      ),
      LeaderboardUser(
        id: MockData.users[1].userId.toString(),
        name: MockData.users[1].name,
        avatar: MockData.users[1].avatar ?? 'https://i.pravatar.cc/150?img=2',
        points: MockData.users[1].trustScore * 100,
        rank: 2,
        change: 2,
      ),
      LeaderboardUser(
        id: MockData.users[4].userId.toString(),
        name: MockData.users[4].name,
        avatar: MockData.users[4].avatar ?? 'https://i.pravatar.cc/150?img=5',
        points: MockData.users[4].trustScore * 100,
        rank: 3,
        change: -1,
      ),
    ];

    // Other users from MockData
    _otherUsers = [
      LeaderboardUser(
        id: MockData.users[2].userId.toString(),
        name: MockData.users[2].name,
        avatar: MockData.users[2].avatar ?? 'https://i.pravatar.cc/150?img=3',
        points: MockData.users[2].trustScore * 100,
        rank: 4,
        change: 2,
      ),
      LeaderboardUser(
        id: MockData.users[3].userId.toString(),
        name: MockData.users[3].name,
        avatar: MockData.users[3].avatar ?? 'https://i.pravatar.cc/150?img=4',
        points: MockData.users[3].trustScore * 100,
        rank: 5,
        change: 1,
      ),
      LeaderboardUser(
        id: MockData.users[5].userId.toString(),
        name: MockData.users[5].name,
        avatar: MockData.users[5].avatar ?? 'https://i.pravatar.cc/150?img=6',
        points: MockData.users[5].trustScore * 100,
        rank: 6,
        change: -2,
      ),
    ];

    // Current user
    _currentUser = LeaderboardUser(
      id: '0', // Mock current user
      name: 'Bạn',
      avatar: 'https://i.pravatar.cc/150?img=0',
      points: 15240,
      rank: 47,
      change: 2,
    );
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

          // Podium
          PodiumWidget(topUsers: _topUsers),
          const SizedBox(height: 32),

          // Top 10 list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top 10', style: AppTextStyles.h3),
                const SizedBox(height: 16),
                ..._otherUsers.map((user) => LeaderboardItem(user: user)),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildNearbyRanking() {
    // Mock data for nearby users
    final List<LeaderboardUser> nearbyUsers = [
      LeaderboardUser(
        id: '1',
        name: 'Nguyễn Khoa Quân',
        avatar: 'https://i.pravatar.cc/150?img=1',
        points: 35216,
        rank: 1,
        change: 0,
      ),
      LeaderboardUser(
        id: '2',
        name: 'Trần Thị Mai',
        avatar: 'https://i.pravatar.cc/150?img=2',
        points: 33420,
        rank: 2,
        change: 2,
      ),
      LeaderboardUser(
        id: '3',
        name: 'Lê Minh Phú',
        avatar: 'https://i.pravatar.cc/150?img=3',
        points: 31850,
        rank: 3,
        change: -1,
      ),
      LeaderboardUser(
        id: '4',
        name: 'Phạm Quỳnh Anh',
        avatar: 'https://i.pravatar.cc/150?img=4',
        points: 29640,
        rank: 4,
        change: 2,
      ),
      LeaderboardUser(
        id: '5',
        name: 'Vũ Đức Huy',
        avatar: 'https://i.pravatar.cc/150?img=5',
        points: 28530,
        rank: 5,
        change: 1,
      ),
    ];

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top người gần đây', style: AppTextStyles.h3),
                const SizedBox(height: 16),
                ...nearbyUsers.map((user) => LeaderboardItem(user: user)),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      '30 điểm hôm nay',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LeaderboardItem(user: _currentUser, isCurrentUser: true),
          ],
        ),
      ),
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
