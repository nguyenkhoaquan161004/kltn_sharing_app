import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../widgets/bottom_navigation_widget.dart';
import '../../widgets/app_header_bar.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_info_tab.dart';
import 'widgets/profile_products_tab.dart';
import 'widgets/profile_achievements_tab.dart';

class ProfileScreen extends StatefulWidget {
  final bool isOwnProfile;

  const ProfileScreen({
    super.key,
    this.isOwnProfile = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock user data
  final Map<String, dynamic> _userData = {
    'name': 'Quan Nguyen',
    'email': 'quan123@gmail.com',
    'address': '8A/12A Thái Văn Lung, Q.1, TP.HCM',
    'avatar': '',
    'points': 23123,
    'productsShared': 63,
    'productsReceived': 12,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      appBar: AppHeaderBar(
        orderCount: 8,
        onSearchTap: () => context.push('/search'),
        onSettingsTap: () {},
        showSettingsButton: widget.isOwnProfile,
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Profile header
            SliverToBoxAdapter(
              child: ProfileHeader(
                name: _userData['name'],
                points: _userData['points'],
                avatar: _userData['avatar'],
              ),
            ),

            // Tab bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryTeal,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTextStyles.label,
                  indicatorColor: AppColors.primaryTeal,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Thông tin'),
                    Tab(text: 'Sản phẩm'),
                    Tab(text: 'Thành tựu'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Thông tin
            ProfileInfoTab(
              userData: _userData,
              isOwnProfile: widget.isOwnProfile,
              userId: 1, // Current user ID (for own profile)
            ),

            // Tab 2: Sản phẩm
            ProfileProductsTab(
              isOwnProfile: widget.isOwnProfile,
              userId: 1, // Current user ID (for own profile)
            ),

            // Tab 3: Thành tựu
            ProfileAchievementsTab(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 3),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.backgroundWhite,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
