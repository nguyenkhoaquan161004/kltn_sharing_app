import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kltn_sharing_app/core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/user_response_model.dart';
import '../../../../data/services/user_api_service.dart';
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
  UserDto? _userData;
  bool _isLoading = true;
  String? _errorMessage;
  late UserApiService _userApiService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _userApiService = UserApiService();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Gọi API để lấy dữ liệu người dùng
      final user = await _userApiService.getUserById(widget.userId);

      setState(() {
        _userData = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      print('[UserProfileScreen] Error loading user: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Nếu đang loading
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    // Nếu có lỗi
    if (_errorMessage != null || _userData == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Không thể tải thông tin người dùng',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 8),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final user = _userData!;

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
                onPressed: () => {
                  if (context.canPop())
                    {context.pop()}
                  else
                    {context.go(AppRoutes.home)}
                },
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
                name: user.fullName,
                trustScore: user.trustScore,
                avatar: user.avatar,
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
                indicatorColor: AppColors.primaryGreen,
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
                    userData: {
                      'id': user.id,
                      'name': user.fullName,
                      'email': user.email,
                      'address': user.address,
                      'avatar': user.avatar,
                      'bio': user.bio,
                      'phoneNumber': user.phoneNumber,
                      'points': user.trustScore ?? 0,
                      'productsShared': user.itemsShared,
                      'productsReceived': user.itemsReceived,
                      'verified': user.verified,
                    },
                    isOwnProfile: false,
                    userId: int.tryParse(user.id) ?? 0,
                  ),
                  ProfileProductsTab(
                    isOwnProfile: false,
                    userId: int.tryParse(user.id) ?? 0,
                  ),
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
