import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/item_model.dart';
import '../../../../data/mock_data.dart';
import '../../../../data/services/item_api_service.dart';
import '../../../../data/models/item_response_model.dart';
import '../../../widgets/gradient_button.dart';
import '../../../widgets/profile_item_card.dart';
import '../../../widgets/item_card.dart';
import 'create_product_modal.dart';

class ProfileProductsTab extends StatefulWidget {
  final bool isOwnProfile;
  final int userId;

  const ProfileProductsTab({
    super.key,
    required this.isOwnProfile,
    required this.userId,
  });

  @override
  State<ProfileProductsTab> createState() => _ProfileProductsTabState();
}

class _ProfileProductsTabState extends State<ProfileProductsTab>
    with AutomaticKeepAliveClientMixin {
  late List<ItemDto> _availableProducts;
  late List<ItemDto> _expiredProducts;
  late ItemApiService _itemApiService;
  Map<String, int> _itemInterestCount =
      {}; // itemId -> count of interested users

  bool _isLoadingProducts = false;
  String? _errorMessage;

  String _sortBy = 'suggested'; // suggested (default), newest
  String _filterByPrice = 'all'; // all, free, paid
  String _filterByCategory = 'all'; // all, or categoryId

  // Price range filter
  double _minPrice = 0;
  double _maxPrice = 1000000;
  TextEditingController _minPriceController = TextEditingController(text: '0');
  TextEditingController _maxPriceController =
      TextEditingController(text: '1000000');

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Get ItemApiService from Provider (already configured with token callback)
    _itemApiService = context.read<ItemApiService>();

    _availableProducts = [];
    _expiredProducts = [];

    // Load products for own profile only
    if (widget.isOwnProfile) {
      _loadUserProducts();
      _loadInterestedCount();
    } else {
      // For other users, use mock data
      _loadMockData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-load data when dependencies change (e.g., route change)
    if (widget.isOwnProfile &&
        _availableProducts.isEmpty &&
        _expiredProducts.isEmpty &&
        !_isLoadingProducts) {
      _loadUserProducts();
    }
  }

  /// Load user's products from API
  Future<void> _loadUserProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoadingProducts = true;
      _errorMessage = null;
    });

    try {
      final response = await _itemApiService.getUserItems(
        page: 1, // Backend uses 1-indexed pages
        size: 50,
        sortBy: 'createdAt',
        sortOrder: 'DESC',
      );

      print('DEBUG: response.content length = ${response.content.length}');
      print('DEBUG: response = $response');

      if (!mounted) return;

      final now = DateTime.now();

      // Separate into available and expired based on expiryDate
      final available = <ItemDto>[];
      final expired = <ItemDto>[];

      for (final item in response.content) {
        print(
            'DEBUG: Processing item: ${item.name}, expiryDate: ${item.expiryDate}');
        if (item.expiryDate != null && item.expiryDate!.isBefore(now)) {
          expired.add(item);
        } else {
          available.add(item);
        }
      }

      setState(() {
        _availableProducts = available;
        _expiredProducts = expired;
        _isLoadingProducts = false;
      });

      print(
          'DEBUG: Loaded ${available.length} available, ${expired.length} expired products');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoadingProducts = false;
      });

      print('ERROR loading user products: $_errorMessage');
    }
  }

  /// Load mock data for other users' profiles
  void _loadMockData() {
    final allProducts = MockData.getItemsByUserId(widget.userId);
    print(
        'DEBUG ProfileProductsTab: userId=${widget.userId}, allProducts=${allProducts.length}');

    // For mock: simulate distribution
    final available = <ItemDto>[];
    final expired = <ItemDto>[];

    if (allProducts.isNotEmpty) {
      // In mock, we don't have real expiry dates, so all go to available
      for (var product in allProducts) {
        available.add(ItemDto(
          id: product.itemId.toString(),
          name: product.name,
          description: product.description,
          quantity: product.quantity,
          imageUrl: null,
          status: product.status,
          userId: product.userId.toString(),
          categoryId: product.categoryId.toString(),
          categoryName: null,
          price: product.price,
          createdAt: DateTime.now(),
          expiryDate: null,
        ));
      }
    }

    setState(() {
      _availableProducts = available;
      _expiredProducts = expired;
    });
  }

  /// Load interested count for user's items
  Future<void> _loadInterestedCount() async {
    try {
      final interestCount = await _itemApiService.getSharerTransactions();
      if (!mounted) return;

      setState(() {
        _itemInterestCount = interestCount;
      });

      print(
          'DEBUG: Loaded interested count for ${interestCount.length} items: $interestCount');
    } catch (e) {
      print('DEBUG: Error loading interested count: $e');
      // Don't show error to user, just log it
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // For other users' profile (store view)
    if (!widget.isOwnProfile) {
      return _buildStoreView();
    }

    // For own profile (detailed view)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add product button (own profile only)
          GradientButton(
            text: 'Tôi muốn chia sẻ sản phẩm',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                builder: (context) => CreateProductModal(
                  onProductCreated: (success) {
                    if (success) {
                      // Reload products after creating
                      _loadUserProducts();
                    }
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Loading state
          if (_isLoadingProducts)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryTeal,
                ),
              ),
            )
          else if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Lỗi tải dữ liệu',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ?? 'Đã xảy ra lỗi',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loadUserProducts,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sản phẩm khả dụng section
                _buildProductSection(
                  title: 'Sản phẩm khả dụng',
                  products: _availableProducts,
                  statusType: 'available',
                ),
                const SizedBox(height: 32),

                // Sản phẩm không khả dụng section
                _buildUnavailableSection(),
              ],
            ),
        ],
      ),
    );
  }

  /// Build store view for other users' products (like Home screen)
  Widget _buildStoreView() {
    final allProducts = _availableProducts + _expiredProducts;

    // Convert ItemDto to ItemModel for filtering
    List<ItemModel> allItemModels = allProducts.map((product) {
      return ItemModel(
        itemId: int.tryParse(product.id) ?? 0,
        itemId_str: product.id,
        userId: int.tryParse(product.userId) ?? 0,
        userId_str: product.userId,
        name: product.name,
        description: product.description ?? '',
        quantity: product.quantity ?? 1,
        status: product.status.toLowerCase(),
        categoryId: int.tryParse(product.categoryId) ?? 0,
        categoryId_str: product.categoryId,
        categoryName: product.categoryName,
        locationId: 1,
        expiryDate: product.expiryDate,
        createdAt: product.createdAt,
        price: product.price ?? 0,
        image: product.imageUrl,
        latitude: product.latitude,
        longitude: product.longitude,
      );
    }).toList();

    // Apply filter by price range
    List<ItemModel> filteredProducts = allItemModels
        .where((p) => p.price >= _minPrice && p.price <= _maxPrice)
        .toList();

    // Apply filter by price
    if (_filterByPrice == 'free') {
      filteredProducts = filteredProducts.where((p) => p.price == 0).toList();
    } else if (_filterByPrice == 'paid') {
      filteredProducts = filteredProducts.where((p) => p.price > 0).toList();
    }

    // Apply filter by category
    if (_filterByCategory != 'all') {
      filteredProducts = filteredProducts
          .where((p) => p.categoryId.toString() == _filterByCategory)
          .toList();
    }

    // Apply sort
    if (_sortBy == 'newest') {
      filteredProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    // 'suggested' is default (no sort, keep original order)

    // Map sort option to Vietnamese text
    String getSortLabel() {
      return _sortBy == 'newest' ? 'Gần đây' : 'Đề xuất';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Sort and Filter header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sort button
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => _buildSortModal(),
                  );
                },
                child: Row(
                  children: [
                    const Text(
                      'Sort By: ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      getSortLabel(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
              // Filter button
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => _buildFilterModal(),
                  );
                },
                child: const Icon(
                  Icons.tune,
                  color: AppColors.textPrimary,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Products grid
          if (filteredProducts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'Chưa có sản phẩm',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return ItemCard(
                  item: product,
                  showTimeRemaining: true,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildUnavailableSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sản phẩm không khả dụng', style: AppTextStyles.h4),
        const SizedBox(height: 16),

        // Sản phẩm hết hạn subsection
        if (_expiredProducts.isNotEmpty) ...[
          Text(
            'Hết hạn (${_expiredProducts.length})',
            style: AppTextStyles.label.copyWith(
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _expiredProducts.length,
            itemBuilder: (context, index) {
              final product = _expiredProducts[index];
              // Convert ItemDto to ItemModel
              final itemModel = ItemModel(
                itemId: int.tryParse(product.id) ?? index,
                itemId_str: product.id,
                userId: int.tryParse(product.userId) ?? 0,
                userId_str: product.userId,
                name: product.name,
                description: product.description ?? '',
                quantity: product.quantity ?? 1,
                status: 'expired',
                categoryId: int.tryParse(product.categoryId) ?? 0,
                categoryId_str: product.categoryId,
                categoryName: product.categoryName,
                locationId: 1,
                expiryDate: product.expiryDate,
                createdAt: product.createdAt,
                price: product.price ?? 0,
                image: product.imageUrl,
                latitude: product.latitude,
                longitude: product.longitude,
              );
              return ProfileItemCard(
                item: itemModel,
                onTap: () => _showUnavailableProductDetails(itemModel, false),
                showTimeRemaining: false,
              );
            },
          ),
        ],

        // Empty state
        if (_expiredProducts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Chưa có sản phẩm không khả dụng',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showUnavailableProductDetails(ItemModel item, bool isShared) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildUnavailableDetailSheet(item, isShared),
    );
  }

  Widget _buildUnavailableDetailSheet(ItemModel item, bool isShared) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTextStyles.h3,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isShared
                              ? AppColors.success.withOpacity(0.2)
                              : AppColors.warning.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isShared ? 'Đã chia sẻ' : 'Hết hạn',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isShared
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Description
            Text(
              'Mô tả',
              style: AppTextStyles.label,
            ),
            const SizedBox(height: 8),
            Text(
              item.description ?? '',
              style: AppTextStyles.bodySmall,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            // Details
            _buildDetailRow('Danh mục', 'Danh mục ${item.categoryId}'),
            _buildDetailRow('Số lượng', '${item.quantity}'),
            _buildDetailRow(
              'Giá',
              item.price == 0 ? 'Miễn phí' : '${item.price}đ',
            ),
            _buildDetailRow(
              'Ngày tạo',
              '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
            ),

            if (isShared) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),

              // Recipient info (only for shared products)
              Text(
                'Thông tin người nhận',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Tên', 'Người nhận ${item.itemId}'),
                    _buildDetailRow(
                        'Email', 'recipient${item.itemId}@gmail.com'),
                    _buildDetailRow('Địa chỉ', 'Quận 1, TP.HCM'),
                    _buildDetailRow('Ngày nhận', '15/12/2025'),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection({
    required String title,
    required List<ItemDto> products,
    required String statusType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h4),
        const SizedBox(height: 16),
        if (products.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Chưa có sản phẩm',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              // Convert ItemDto to ItemModel for ProfileItemCard
              final itemModel = ItemModel(
                itemId: int.tryParse(product.id) ?? index,
                itemId_str: product.id,
                userId: int.tryParse(product.userId) ?? 0,
                userId_str: product.userId,
                name: product.name,
                description: product.description ?? '',
                quantity: product.quantity ?? 1,
                status: product.status.toLowerCase(),
                categoryId: int.tryParse(product.categoryId) ?? 0,
                categoryId_str: product.categoryId,
                categoryName: product.categoryName,
                locationId: 1,
                expiryDate: product.expiryDate,
                createdAt: product.createdAt,
                price: product.price ?? 0,
                image: product.imageUrl,
                latitude: product.latitude,
                longitude: product.longitude,
              );
              return ProfileItemCard(
                item: itemModel,
                onTap: () => _showProductDetails(itemModel),
                showTimeRemaining: false,
              );
            },
          ),
      ],
    );
  }

  void _showProductDetails(ItemModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildProductDetailSheet(product),
    );
  }

  Widget _buildProductDetailSheet(ItemModel product) {
    // Mock data for people who want to receive
    final requesters = [
      {
        'id': 1,
        'name': 'Phạm Duy',
        'avatar': 'https://i.pravatar.cc/150?img=2',
        'reason': 'Tôi cần sản phẩm này để sử dụng trong công việc hàng ngày',
        'sentTime': '2 giờ trước',
      },
      {
        'id': 2,
        'name': 'Lê Thảo',
        'avatar': 'https://i.pravatar.cc/150?img=3',
        'reason':
            'Sản phẩm rất cần thiết cho công việc của tôi, giúp tôi tiết kiệm chi phí',
        'sentTime': '5 giờ trước',
      },
      {
        'id': 3,
        'name': 'Trương Minh',
        'avatar': 'https://i.pravatar.cc/150?img=4',
        'reason':
            'Mình rất thích sản phẩm này và muốn thử sử dụng trước khi mua',
        'sentTime': '1 ngày trước',
      },
      {
        'id': 4,
        'name': 'Ngô Hương',
        'avatar': 'https://i.pravatar.cc/150?img=5',
        'reason':
            'Tôi đang tìm kiếm sản phẩm này đã lâu, rất mong muốn được nhận',
        'sentTime': '2 ngày trước',
      },
      {
        'id': 5,
        'name': 'Đỗ Hiệp',
        'avatar': 'https://i.pravatar.cc/150?img=6',
        'reason':
            'Bạn bè tôi gợi ý sản phẩm này, tôi muốn thử xem có phù hợp không',
        'sentTime': '3 ngày trước',
      },
    ];

    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product info header
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: AppTextStyles.h4,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${product.price} VND',
                            style: AppTextStyles.price.copyWith(
                              color: AppColors.primaryCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Requesters list
                Text('Người muốn nhận', style: AppTextStyles.h4),
                const SizedBox(height: 16),
                ...requesters.map((requester) {
                  return _buildRequesterCard(requester);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequesterCard(Map<String, dynamic> requester) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.backgroundGray,
                ),
                child: const Icon(Icons.person, size: 20),
              ),
              const SizedBox(width: 12),

              // Name and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requester['name'] as String,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      requester['sentTime'] as String,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Reason
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              requester['reason'] as String,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.warning),
                  ),
                  child: Text(
                    'Từ chối',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryCyan,
                  ),
                  child: Text(
                    'Nhắn tin',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Sort modal
  Widget _buildSortModal() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sắp xếp theo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildSortOption('suggested', 'Đề xuất'),
          _buildSortOption('newest', 'Gần đây'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSortOption(String value, String label) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primaryTeal
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                color: AppColors.primaryTeal,
              ),
          ],
        ),
      ),
    );
  }

  // Filter modal
  Widget _buildFilterModal() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and reset button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setModalState(() {
                            _sortBy = 'suggested';
                            _filterByPrice = 'all';
                            _filterByCategory = 'all';
                            _minPrice = 0;
                            _maxPrice = 1000000;
                            _minPriceController.text = '0';
                            _maxPriceController.text = '1000000';
                          });
                          setState(() {});
                        },
                        child: const Text(
                          'Đặt lại',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, size: 28),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sort by section
                      const Text(
                        'Sort by',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  _sortBy = 'newest';
                                });
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _sortBy == 'newest'
                                      ? AppColors.primaryTeal
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _sortBy == 'newest'
                                        ? AppColors.primaryTeal
                                        : const Color(0xFFCCCCCC),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Gần đây',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _sortBy == 'newest'
                                        ? Colors.white
                                        : AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  _sortBy = 'suggested';
                                });
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _sortBy == 'suggested'
                                      ? AppColors.primaryTeal
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _sortBy == 'suggested'
                                        ? AppColors.primaryTeal
                                        : const Color(0xFFCCCCCC),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Đề xuất',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _sortBy == 'suggested'
                                        ? Colors.white
                                        : AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Price range filter section
                      const Text(
                        'Giá (VND)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Price input fields
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _minPriceController,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setModalState(() {
                                  _minPrice = double.tryParse(value) ?? 0;
                                });
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                hintText: '0',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '—',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _maxPriceController,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setModalState(() {
                                  _maxPrice = double.tryParse(value) ?? 1000000;
                                });
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                hintText: '1000000',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Category filter section (as pills)
                      const Text(
                        'Phân loại',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildCategoryPill('all', 'Tất cả', setModalState),
                          for (final category in MockData.categories)
                            _buildCategoryPill(category.categoryId.toString(),
                                category.name, setModalState),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryPill(
      String value, String label, StateSetter setModalState) {
    final isSelected = _filterByCategory == value;
    return GestureDetector(
      onTap: () {
        setModalState(() {
          _filterByCategory = value;
        });
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : const Color(0xFFCCCCCC),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.primaryTeal,
          ),
        ),
      ),
    );
  }
}
