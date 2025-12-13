import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/mock_data.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_info_tab.dart';
import 'widgets/profile_products_tab.dart';
import 'widgets/profile_achievements_tab.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String? userName;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _userData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  void _loadUserData() {
    try {
      int userId = int.parse(widget.userId);
      // Debug print
      print('DEBUG: UserProfileScreen - Looking for userId: $userId');
      print(
          'DEBUG: Available users: ${MockData.users.map((u) => u.userId).toList()}');

      final user = MockData.users.firstWhere(
        (u) => u.userId == userId,
        orElse: () {
          print('DEBUG: User $userId not found, using fallback user 2');
          return MockData.users[1];
        },
      );

      setState(() {
        _userData = {
          'id': user.userId.toString(),
          'name': user.name,
          'email': user.email,
          'address': user.address,
          'avatar': user.avatar,
          'points': user.trustScore * 100,
          'productsShared':
              MockData.items.where((i) => i.userId == user.userId).length,
          'productsReceived': 0,
        };
      });
    } catch (e) {
      print('DEBUG: Error in _loadUserData: $e');
      // Fallback to user id 2
      final user = MockData.users[1];
      setState(() {
        _userData = {
          'id': user.userId.toString(),
          'name': user.name,
          'email': user.email,
          'address': user.address,
          'avatar': user.avatar,
          'points': user.trustScore * 100,
          'productsShared':
              MockData.items.where((i) => i.userId == user.userId).length,
          'productsReceived': 0,
        };
      });
    }
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // App bar
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              expandedHeight: 0,
              leading: IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined,
                      color: AppColors.textPrimary),
                  onPressed: () {},
                ),
              ],
            ),
            // Header
            SliverToBoxAdapter(
              child: ProfileHeader(
                name: _userData['name'],
                points: _userData['points'],
                avatar: _userData['avatar'],
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Tab bar
            Container(
              color: AppColors.backgroundWhite,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTextStyles.bodyMedium,
                unselectedLabelStyle: AppTextStyles.bodyMedium,
                indicatorColor: AppColors.primaryTeal,
                indicatorWeight: 2,
                tabs: const [
                  Tab(text: 'Thông tin'),
                  Tab(text: 'Sản phẩm'),
                  Tab(text: 'Thành tích'),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ProfileInfoTab(
                    userData: _userData,
                    isOwnProfile: false,
                    userId: int.parse(widget.userId),
                  ),
                  ProfileProductsTab(
                      isOwnProfile: false, userId: int.parse(widget.userId)),
                  ProfileAchievementsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
