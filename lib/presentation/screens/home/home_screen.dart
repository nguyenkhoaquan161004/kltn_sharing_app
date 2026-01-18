import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/providers/item_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/location_provider.dart';
import '../../../data/providers/recommendation_provider.dart';
import '../../../data/models/item_model.dart';
import '../../../data/models/recommendation_response_model.dart';
import '../../dialogs/location_permission_dialog.dart';
import '../../widgets/bottom_navigation_widget.dart';
import '../../widgets/item_card.dart';
import '../../widgets/app_header_bar.dart';
import '../profile/widgets/create_product_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Pagination for Recommendations tab
  int _recommendationPage = 0;
  int _recommendationPageSize = 20;
  late ScrollController _recommendationScrollController;
  bool _isLoadingMoreRecommendations = false;

  // Pagination for Latest Items tab
  int _itemsPage = 0;
  int _itemsPageSize = 20;
  late ScrollController _itemsScrollController;
  bool _isLoadingMoreItems = false;

  // Pagination for Trending tab
  int _trendingPage = 0;
  int _trendingPageSize = 20;
  bool _isLoadingMoreTrending = false;

  // Pagination for Nearby tab
  int _nearbyPage = 0;
  int _nearbyPageSize = 20;
  late ScrollController _nearbyScrollController;
  bool _isLoadingMoreNearby = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _recommendationScrollController = ScrollController();
    _itemsScrollController = ScrollController();
    _nearbyScrollController = ScrollController();
    _recommendationScrollController.addListener(_onRecommendationScroll);
    _itemsScrollController.addListener(_onItemsScroll);
    _nearbyScrollController.addListener(_onNearbyScroll);

    // Add listener to reload nearby items when "Gần đây" tab is tapped
    _tabController.addListener(_onTabChanged);

    print('[HomeScreen] Scroll listeners attached');

    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[HomeScreen] Loading initial data...');
      final authProvider = context.read<AuthProvider>();
      final itemProvider = context.read<ItemProvider>();
      final recommendationProvider = context.read<RecommendationProvider>();
      final locationProvider = context.read<LocationProvider>();

      // Set auth token if available
      if (authProvider.accessToken != null) {
        itemProvider.setAuthToken(authProvider.accessToken!);
        recommendationProvider.setAuthToken(authProvider.accessToken!);

        // Set callback for when token refresh fails (403 or 401 after refresh fails)
        itemProvider.setGetValidTokenCallback(() async {
          print(
              '[HomeScreen] Token expired callback triggered - navigating to login');
          if (mounted) {
            // Clear auth state
            authProvider.logout();
            // Navigate to login
            context.go(AppRoutes.login);
          }
        });
      }

      // Load all data
      itemProvider.loadItems();
      recommendationProvider.loadRecommendations();

      // Load nearby items if location is available
      if (locationProvider.hasLocation) {
        print(
            '[HomeScreen] Location available in initState, loading nearby items');
        _loadNearbyItems(itemProvider, locationProvider);
      } else {
        print(
            '[HomeScreen] Location not available in initState, will wait for location update');
      }

      // Request location permission if user just logged in
      _checkAndRequestLocation(locationProvider);
    });
  }

  /// Check if location permission was already requested, if not show dialog
  void _checkAndRequestLocation(LocationProvider locationProvider) async {
    final prefs = await SharedPreferences.getInstance();
    final hasRequestedLocation =
        prefs.getBool('location_permission_requested') ?? false;

    if (!hasRequestedLocation && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => LocationPermissionDialog(
          onLocationEnabled: () {
            _markLocationPermissionRequested();
          },
          onLocationSkipped: () {
            _markLocationPermissionRequested();
          },
        ),
      );
    }
  }

  /// Mark location permission as requested
  void _markLocationPermissionRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_permission_requested', true);
  }

  void _onRecommendationScroll() {
    if (_recommendationScrollController.position.pixels >=
        _recommendationScrollController.position.maxScrollExtent - 500) {
      final provider = context.read<RecommendationProvider>();
      print(
          '[HomeScreen] Scroll triggered - length: ${provider.recommendations.length}, total: ${provider.totalRecommendations}, loading: $_isLoadingMoreRecommendations');
      if (!_isLoadingMoreRecommendations &&
          provider.recommendations.length < provider.totalRecommendations) {
        print('[HomeScreen] Loading more recommendations...');
        setState(() => _isLoadingMoreRecommendations = true);
        _recommendationPage++;
        provider
            .loadMoreRecommendations(
          page: _recommendationPage,
          limit: _recommendationPageSize,
        )
            .then((_) {
          print('[HomeScreen] More recommendations loaded');
          if (mounted) {
            setState(() => _isLoadingMoreRecommendations = false);
          }
        }).catchError((e) {
          print('[HomeScreen] Error loading more: $e');
          if (mounted) {
            setState(() => _isLoadingMoreRecommendations = false);
          }
        });
      }
    }
  }

  void _onItemsScroll() {
    if (_itemsScrollController.position.pixels >=
        _itemsScrollController.position.maxScrollExtent - 500) {
      final provider = context.read<ItemProvider>();
      print(
          '[HomeScreen] Items scroll triggered - length: ${provider.items.length}, total: ${provider.totalItems}, loading: $_isLoadingMoreItems');
      if (!_isLoadingMoreItems && provider.items.length < provider.totalItems) {
        print('[HomeScreen] Loading more items...');
        setState(() => _isLoadingMoreItems = true);
        _itemsPage++;
        provider
            .loadMoreItems(
          page: _itemsPage,
          limit: _itemsPageSize,
        )
            .then((_) {
          print('[HomeScreen] More items loaded');
          if (mounted) {
            setState(() => _isLoadingMoreItems = false);
          }
        }).catchError((e) {
          print('[HomeScreen] Error loading more items: $e');
          if (mounted) {
            setState(() => _isLoadingMoreItems = false);
          }
        });
      }
    }
  }

  void _onNearbyScroll() {
    if (_nearbyScrollController.position.pixels >=
        _nearbyScrollController.position.maxScrollExtent - 500) {
      final itemProvider = context.read<ItemProvider>();
      final locationProvider = context.read<LocationProvider>();

      print(
          '[HomeScreen] Nearby scroll triggered - length: ${itemProvider.nearbyItems.length}, total: ${itemProvider.nearbyTotalItems}, loading: $_isLoadingMoreNearby');

      if (!_isLoadingMoreNearby &&
          itemProvider.nearbyItems.length < itemProvider.nearbyTotalItems &&
          locationProvider.hasLocation) {
        print('[HomeScreen] Loading more nearby items...');
        setState(() => _isLoadingMoreNearby = true);
        _nearbyPage++;

        itemProvider
            .loadMoreNearbyItems(
          latitude: locationProvider.latitude!,
          longitude: locationProvider.longitude!,
          maxDistanceKm: 20,
          page: _nearbyPage,
        )
            .then((_) {
          print('[HomeScreen] More nearby items loaded');
          if (mounted) {
            setState(() => _isLoadingMoreNearby = false);
          }
        }).catchError((e) {
          print('[HomeScreen] Error loading more nearby items: $e');
          if (mounted) {
            setState(() => _isLoadingMoreNearby = false);
          }
        });
      }
    }
  }

  /// Handle tab changes - reload nearby items when "Gần đây" tab is tapped
  void _onTabChanged() {
    // Tab index 1 is "Gần đây" (Nearby)
    if (_tabController.index == 1) {
      print('[HomeScreen] "Gần đây" tab tapped - reloading nearby items');
      final itemProvider = context.read<ItemProvider>();
      final locationProvider = context.read<LocationProvider>();

      // Chặn gọi khi đang loading
      if (_isLoadingMoreNearby) {
        print('[HomeScreen] Already loading, skip duplicate call');
        return;
      }

      if (locationProvider.hasLocation) {
        // Reset pagination for nearby items
        _nearbyPage = 0;
        _loadNearbyItems(itemProvider, locationProvider);
      } else {
        print('[HomeScreen] Location not available, cannot load nearby items');
      }
    }
  }

  /// Load nearby items based on user location
  Future<void> _loadNearbyItems(
      ItemProvider itemProvider, LocationProvider locationProvider) async {
    print('[HomeScreen] _loadNearbyItems called');
    print('[HomeScreen] hasLocation: ${locationProvider.hasLocation}');
    print('[HomeScreen] latitude: ${locationProvider.latitude}');
    print('[HomeScreen] longitude: ${locationProvider.longitude}');

    // Chặn ngay đầu nếu đang loading
    if (_isLoadingMoreNearby) {
      print('[HomeScreen] Already loading nearby items, skip');
      return;
    }

    if (locationProvider.hasLocation) {
      print(
          '[HomeScreen] Loading nearby items at lat: ${locationProvider.latitude}, lon: ${locationProvider.longitude}');

      _isLoadingMoreNearby = true;

      try {
        // Thêm delay 3 giây trước khi load
        print('[HomeScreen] Waiting 3 seconds before loading...');
        await Future.delayed(const Duration(seconds: 3));
        print('[HomeScreen] Delay finished, starting load now');

        await itemProvider.loadNearbyItems(
          latitude: locationProvider.latitude!,
          longitude: locationProvider.longitude!,
          maxDistanceKm: 20,
        );

        if (itemProvider.nearbyErrorMessage == null) {
          print('[HomeScreen] Nearby items loaded successfully');
        } else {
          print(
              '[HomeScreen] Loading complete but has error: ${itemProvider.nearbyErrorMessage}');
        }
      } catch (e) {
        print('[HomeScreen] Error loading nearby items: $e');
      } finally {
        _isLoadingMoreNearby = false;
      }
    } else {
      print('[HomeScreen] Location not available, requesting location...');
      // Show location request dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Bật vị trí'),
            content: const Text('Cần bật vị trí để xem các sản phẩm gần đây'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Huỷ'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  locationProvider.requestLocationPermissionAndGetLocation();
                },
                child: const Text('Bật vị trí'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recommendationScrollController.dispose();
    _itemsScrollController.dispose();
    _nearbyScrollController.dispose();
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
                Tab(text: 'Đề xuất'),
                Tab(text: 'Gần đây'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecommendationsGrid(),
                _buildNearbyGrid(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: 0,
        onAddPressed: _showAddItemModal,
      ),
      floatingActionButton: _buildChatButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _buildChatButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 72, right: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.pushNamed('chatbot');
          },
          borderRadius: BorderRadius.circular(50),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
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
            // Reload items after successful creation
            final itemProvider = context.read<ItemProvider>();
            itemProvider.loadItems();
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Thêm sản phẩm thành công!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildChatFAB() {
    return GestureDetector(
      onTap: () {
        context.pushNamed('chatbot');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 70, right: 16),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.pushNamed('chatbot');
            },
            borderRadius: BorderRadius.circular(50),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
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
                    // Retry loading recommendations
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
            onRefresh: () {
              _recommendationPage = 0;
              return recommendationProvider.loadRecommendations();
            },
            child: GridView.builder(
              controller: _recommendationScrollController,
              shrinkWrap: false,
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemCount: recommendationProvider.recommendations.length +
                  (_isLoadingMoreRecommendations ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == recommendationProvider.recommendations.length) {
                  return const Center(child: CircularProgressIndicator());
                }

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

  Widget _buildNearbyGrid() {
    print('[HomeScreen] _buildNearbyGrid called');
    return Consumer2<ItemProvider, LocationProvider>(
      builder: (context, itemProvider, locationProvider, child) {
        print(
            '[HomeScreen] Building nearby grid - hasLocation: ${locationProvider.hasLocation}');
        print(
            '[HomeScreen] Location: lat=${locationProvider.latitude}, lon=${locationProvider.longitude}');
        print(
            '[HomeScreen] nearbyItems count: ${itemProvider.nearbyItems.length}');
        print('[HomeScreen] isLoadingNearby: ${itemProvider.isLoadingNearby}');
        print(
            '[HomeScreen] nearbyErrorMessage: ${itemProvider.nearbyErrorMessage}');

        // Check if location is available
        if (!locationProvider.hasLocation) {
          print(
              '[HomeScreen] Location not available, showing enable location prompt');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Bật vị trí để xem sản phẩm gần đây'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    print('[HomeScreen] User clicked enable location button');
                    locationProvider.requestLocationPermissionAndGetLocation();
                  },
                  child: const Text('Bật vị trí'),
                ),
              ],
            ),
          );
        }

        if (itemProvider.isLoadingNearby && itemProvider.nearbyItems.isEmpty) {
          print('[HomeScreen] Loading nearby items...');
          return const Center(child: CircularProgressIndicator());
        }

        if (itemProvider.nearbyErrorMessage != null) {
          print('[HomeScreen] Error: ${itemProvider.nearbyErrorMessage}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Lỗi: ${itemProvider.nearbyErrorMessage}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    print('[HomeScreen] User clicked retry for nearby items');
                    _loadNearbyItems(itemProvider, locationProvider);
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (itemProvider.nearbyItems.isEmpty) {
          print('[HomeScreen] No nearby items found');
          return const Center(child: Text('Không có sản phẩm gần đây'));
        }

        print(
            '[HomeScreen] Rendering ${itemProvider.nearbyItems.length} nearby items');
        return Padding(
          padding: const EdgeInsets.all(16),
          child: RefreshIndicator(
            onRefresh: () {
              print('[HomeScreen] Refresh nearby items triggered');
              _nearbyPage = 0;
              return itemProvider.refreshNearbyItems(
                latitude: locationProvider.latitude!,
                longitude: locationProvider.longitude!,
              );
            },
            child: GridView.builder(
              controller: _nearbyScrollController,
              shrinkWrap: false,
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemCount: itemProvider.nearbyItems.length +
                  (_isLoadingMoreNearby ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == itemProvider.nearbyItems.length) {
                  return const Center(child: CircularProgressIndicator());
                }

                final itemDto = itemProvider.nearbyItems[index];
                final itemModel = ItemModel(
                  itemId: itemDto.id.hashCode,
                  itemId_str: itemDto.id,
                  userId: 0,
                  name: itemDto.name,
                  description: itemDto.description,
                  quantity: itemDto.quantity ?? 0,
                  status: itemDto.status ?? 'AVAILABLE',
                  categoryName: itemDto.categoryName,
                  expiryDate: itemDto.expiryDate,
                  createdAt: itemDto.createdAt,
                  image: itemDto.imageUrl,
                  latitude: itemDto.latitude,
                  longitude: itemDto.longitude,
                  distance: itemDto.distanceKm,
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
            onRefresh: () {
              _itemsPage = 0;
              return itemProvider.refreshItems();
            },
            child: GridView.builder(
              controller: _itemsScrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemCount:
                  itemProvider.items.length + (_isLoadingMoreItems ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == itemProvider.items.length) {
                  return const Center(child: CircularProgressIndicator());
                }

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
