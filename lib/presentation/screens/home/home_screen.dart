import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/providers/item_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/recommendation_provider.dart';
import '../../../data/models/item_model.dart';
import '../../../data/models/recommendation_response_model.dart';
import '../../widgets/bottom_navigation_widget.dart';
import '../../widgets/item_card.dart';
import '../../widgets/app_header_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final itemProvider = context.read<ItemProvider>();
      final recommendationProvider = context.read<RecommendationProvider>();

      // Set auth token if available
      if (authProvider.accessToken != null) {
        itemProvider.setAuthToken(authProvider.accessToken!);
        recommendationProvider.setAuthToken(authProvider.accessToken!);
      }

      // Load all data
      itemProvider.loadItems();
      recommendationProvider.loadRecommendations();
      recommendationProvider.loadTrendingRecommendations();
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
                Tab(text: 'Đề xuất'),
                Tab(text: 'Gầy đây'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecommendationsGrid(),
                _buildTrendingGrid(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 0),
    );
  }

  Widget _buildRecommendationsGrid() {
    return Consumer<RecommendationProvider>(
      builder: (context, recommendationProvider, child) {
        if (recommendationProvider.isLoadingRecommendations &&
            recommendationProvider.recommendations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (recommendationProvider.recommendationsError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Lỗi: ${recommendationProvider.recommendationsError}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    // Refresh token first, then retry
                    final authProvider = context.read<AuthProvider>();
                    await authProvider.refreshAccessToken();
                    if (mounted) {
                      recommendationProvider.loadRecommendations();
                    }
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (recommendationProvider.recommendations.isEmpty) {
          return const Center(child: Text('Không có gợi ý nào'));
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: RefreshIndicator(
            onRefresh: () => recommendationProvider.loadRecommendations(),
            child: GridView.builder(
              shrinkWrap: false,
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemCount: recommendationProvider.recommendations.length,
              itemBuilder: (context, index) {
                final rec = recommendationProvider.recommendations[index];
                final itemModel = rec.toItemModel();
                return ItemCard(
                  item: itemModel,
                  showTimeRemaining: true,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendingGrid() {
    return Consumer<RecommendationProvider>(
      builder: (context, recommendationProvider, child) {
        if (recommendationProvider.isLoadingTrending &&
            recommendationProvider.trendingRecommendations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (recommendationProvider.trendingError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Lỗi: ${recommendationProvider.trendingError}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    // Refresh token first, then retry
                    final authProvider = context.read<AuthProvider>();
                    await authProvider.refreshAccessToken();
                    if (mounted) {
                      recommendationProvider.loadTrendingRecommendations();
                    }
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (recommendationProvider.trendingRecommendations.isEmpty) {
          return const Center(child: Text('Không có sản phẩm nào'));
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: RefreshIndicator(
            onRefresh: () =>
                recommendationProvider.loadTrendingRecommendations(),
            child: GridView.builder(
              shrinkWrap: false,
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemCount: recommendationProvider.trendingRecommendations.length,
              itemBuilder: (context, index) {
                final rec =
                    recommendationProvider.trendingRecommendations[index];
                final itemModel = rec.toItemModel();
                return ItemCard(
                  item: itemModel,
                  showTimeRemaining: true,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductGrid() {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        if (itemProvider.isLoading && itemProvider.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (itemProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Lỗi: ${itemProvider.errorMessage}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => itemProvider.loadItems(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (itemProvider.items.isEmpty) {
          return const Center(child: Text('Không có sản phẩm nào'));
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: RefreshIndicator(
            onRefresh: () => itemProvider.refreshItems(),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemCount: itemProvider.items.length,
              itemBuilder: (context, index) {
                final itemDto = itemProvider.items[index];
                // Convert ItemDto to ItemModel for ItemCard compatibility
                final itemModel = ItemModel(
                  itemId: int.tryParse(itemDto.id) ?? 0,
                  itemId_str: itemDto.id, // Pass UUID for API navigation
                  userId: 0,
                  name: itemDto.name,
                  description: itemDto.description,
                  quantity: 1,
                  status: itemDto.status,
                  categoryId: 0,
                  locationId: 0,
                  createdAt: itemDto.createdAt,
                  price: itemDto.price ?? 0.0,
                );

                return ItemCard(
                  item: itemModel,
                  showTimeRemaining: true,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
