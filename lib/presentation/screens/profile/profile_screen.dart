import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/providers/auth_provider.dart';
import '../../../../data/providers/user_provider.dart';
import '../../../../data/providers/item_provider.dart';
import '../../widgets/bottom_navigation_widget.dart';
import '../../widgets/app_header_bar.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_info_tab.dart';
import 'widgets/profile_products_tab.dart';
import 'widgets/profile_achievements_tab.dart';
import 'widgets/create_product_modal.dart';

class ProfileScreen extends StatefulWidget {
  final bool isOwnProfile;
  final String? userId;

  const ProfileScreen({
    super.key,
    this.isOwnProfile = true,
    this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load user profile when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final userProvider = context.read<UserProvider>();

      print('[ProfileScreen] Access token: ${authProvider.accessToken}');
      print('[ProfileScreen] Is logged in: ${authProvider.isLoggedIn}');

      // Set auth token if available
      if (authProvider.accessToken != null) {
        print('[ProfileScreen] Setting token for UserProvider');
        userProvider.setAuthToken(authProvider.accessToken!);
      } else {
        print('[ProfileScreen] WARNING: No access token found!');
      }

      // Load current user if it's own profile
      if (widget.isOwnProfile) {
        userProvider.loadCurrentUser();
        // Load transaction stats for own profile
        userProvider.loadTransactionStats();
      }
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
      appBar: AppHeaderBar(
        onSearchTap: () => context.push('/search'),
        onSettingsTap: () => context.push('/settings'),
        showSettingsButton: widget.isOwnProfile,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading && userProvider.currentUser == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Lỗi: ${userProvider.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => userProvider.loadCurrentUser(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final user = userProvider.currentUser;
          if (user == null) {
            return const Center(
                child: Text('Không tìm thấy thông tin người dùng'));
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // Profile header
                SliverToBoxAdapter(
                  child: ProfileHeader(
                    name: user.fullName,
                    trustScore: user.trustScore,
                    avatar: user.avatar,
                  ),
                ),

                // Tab bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primaryGreen,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: AppTextStyles.label,
                      indicatorColor: AppColors.primaryGreen,
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
                  userData: {
                    'name': user.fullName,
                    'email': user.email,
                    'address': user.address ?? 'Địa chỉ',
                    'phone': user.phoneNumber?.isNotEmpty == true
                        ? user.phoneNumber
                        : 'Số điện thoại',
                    'avatar': user.avatar ?? '',
                    'points': user.trustScore ?? 0,
                    'productsShared':
                        userProvider.transactionStats?.completedShared ??
                            user.itemsShared,
                    'productsReceived':
                        userProvider.transactionStats?.completedReceived ??
                            user.itemsReceived,
                  },
                  isOwnProfile: widget.isOwnProfile,
                  userId: int.tryParse(user.id) ?? 0,
                ),

                // Tab 2: Sản phẩm
                ProfileProductsTab(
                  isOwnProfile: widget.isOwnProfile,
                  userId: int.tryParse(user.id) ?? 0,
                ),

                // Tab 3: Thành tựu
                ProfileAchievementsTab(),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: 3,
        onAddPressed: _showAddItemModal,
      ),
    );
  }

  void _showAddItemModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CreateProductModal(
        onProductCreated: (success) {
          if (success) {
            final itemProvider = context.read<ItemProvider>();
            itemProvider.loadItems();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tạo sản phẩm thành công!')),
            );
          }
        },
      ),
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
