import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/item_model.dart';
import '../../../data/providers/item_provider.dart';
import '../../../data/models/item_response_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/services/message_api_service.dart';
import '../../../data/services/user_api_service.dart';
import '../../../data/services/item_api_service.dart';
import '../../../data/mock_data.dart';
import 'widgets/product_image_carousel.dart';
import 'widgets/order_request_modal.dart';
import 'widgets/add_to_cart_modal.dart';
import 'widgets/expandable_description.dart';
import '../../widgets/item_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

// Navigation helper - sử dụng với go_router
// Ví dụ: context.goToProduct('123');
// Hoặc: context.push('/product/123');

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Timer? _timer;
  late Duration _remainingTime = Duration.zero;
  late MessageApiService _messageApiService;

  // Product data
  ProductModel? _product;
  ItemDto? _itemDto;
  bool _isLoading = true;
  bool _isSellerLoading = true; // Track seller info loading state
  String? _errorMessage;

  // Mock related products
  late List<ItemModel> _relatedProducts;

  // Pagination for related products
  int _relatedProductsPage = 0;
  int _relatedProductsPageSize = 6;
  int _totalRelatedProducts = 0;
  bool _isLoadingMoreRelatedProducts = false;

  // Scroll controller for detecting pagination
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    print('[ProductDetail] Scroll listener attached');

    // Initialize MessageApiService with auth
    _messageApiService = MessageApiService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.accessToken != null) {
        _messageApiService.setAuthToken(authProvider.accessToken!);
        _messageApiService.setGetValidTokenCallback(
          () async => authProvider.accessToken,
        );
      }
    });

    _loadProduct();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      // Load more products whenever scrolling to the bottom
      print(
          '[ProductDetail] Scroll triggered - length: ${_relatedProducts.length}, page: $_relatedProductsPage, loading: $_isLoadingMoreRelatedProducts');
      if (!_isLoadingMoreRelatedProducts) {
        print('[ProductDetail] Loading more related products...');
        _relatedProductsPage++;
        _loadMoreRelatedProducts();
      }
    }
  }

  void _loadMoreRelatedProducts() {
    try {
      setState(() => _isLoadingMoreRelatedProducts = true);

      // Load more products from API instead of MockData
      if (_itemDto != null) {
        _loadMoreRelatedProductsFromApi();
      } else {
        // Fallback to MockData if no itemDto
        final moreProducts = MockData.items
            .where((item) => item.itemId.toString() != widget.productId)
            .skip(_relatedProducts.length)
            .take(_relatedProductsPageSize)
            .toList();

        if (mounted) {
          setState(() {
            _relatedProducts.addAll(moreProducts);
            _isLoadingMoreRelatedProducts = false;
          });
        }
      }
    } catch (e) {
      print('[ProductDetail] Error loading more related products: $e');
      if (mounted) {
        setState(() => _isLoadingMoreRelatedProducts = false);
      }
    }
  }

  Future<void> _loadMoreRelatedProductsFromApi() async {
    try {
      if (_itemDto == null) return;

      // Get ItemApiService to fetch products from API
      final itemApiService = context.read<ItemApiService>();
      final authProvider = context.read<AuthProvider>();

      // Set auth token if available
      if (authProvider.accessToken != null) {
        itemApiService.setAuthToken(authProvider.accessToken!);
      }

      // Fetch next page of items from same category
      final categoryId = _itemDto!.categoryId.toString();
      final response = await itemApiService.searchItems(
        categoryId: categoryId,
        page: _relatedProductsPage,
        size: _relatedProductsPageSize,
      );

      if (response != null && response.content != null) {
        // Convert ItemDto to ItemModel for display
        final itemModels = response.content!
            .where(
                (dto) => dto.id != widget.productId) // Exclude current product
            .map((dto) {
          print(
              '[ProductDetail] More product - Name: ${dto.name}, Image: ${dto.imageUrl}');
          return ItemModel(
            itemId: int.tryParse(dto.id) ?? 0,
            itemId_str: dto.id,
            name: dto.name,
            description: dto.description ?? '',
            image: dto.imageUrl, // Use API image URL
            price: dto.price?.toDouble() ?? 0,
            categoryName: dto.categoryName ?? 'Khác',
            categoryId: int.tryParse(dto.categoryId.toString()) ?? 0,
            quantity: dto.quantity ?? 1,
            status: 'AVAILABLE',
            createdAt: dto.createdAt,
            expiryDate: dto.expiryDate,
            userId_str: dto.userId.toString(),
          );
        }).toList();

        if (mounted) {
          setState(() {
            _relatedProducts.addAll(itemModels);
            _totalRelatedProducts = response.totalElements ?? 0;
            _isLoadingMoreRelatedProducts = false;
          });
        }
        print(
            '[ProductDetail] Loaded ${itemModels.length} more products from API');
      } else {
        if (mounted) {
          setState(() => _isLoadingMoreRelatedProducts = false);
        }
      }
    } catch (e) {
      print('[ProductDetail] Error loading more products from API: $e');
      if (mounted) {
        setState(() => _isLoadingMoreRelatedProducts = false);
      }
    }
  }

  Future<void> _loadProduct() async {
    try {
      final itemProvider = context.read<ItemProvider>();
      final itemDto = await itemProvider.getItemById(widget.productId);

      if (itemDto != null) {
        setState(() {
          _itemDto = itemDto;
          _product = _convertDtoToProduct(itemDto);
          _isLoading = false;
          _remainingTime = _product!.remainingTime;
        });
        _startTimer();

        // Fetch real seller information from API
        _loadSellerInfo(itemDto.userId.toString());
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              itemProvider.errorMessage ?? 'Không thể tải dữ liệu sản phẩm';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      print('Error loading product: $e');
    }

    // Load related products (from same category or all)
    _loadRelatedProducts();
  }

  Future<void> _loadSellerInfo(String userId) async {
    try {
      final userApiService = context.read<UserApiService>();
      final sellerUser = await userApiService.getUserById(userId);

      if (sellerUser != null && _product != null && mounted) {
        setState(() {
          _product = _product!.copyWith(
            owner: UserInfo(
              id: sellerUser.id,
              name: sellerUser.fullName,
              avatar: sellerUser.avatar ?? '',
              productsShared: sellerUser.itemsShared,
            ),
          );
          _isSellerLoading = false;
        });
        print('[ProductDetail] Seller info loaded: ${sellerUser.fullName}');
      }
    } catch (e) {
      print('[ProductDetail] Error loading seller info: $e');
      // Still mark as done loading even if error
      if (mounted) {
        setState(() {
          _isSellerLoading = false;
        });
      }
    }
  }

  void _loadRelatedProducts() {
    try {
      // First try to load from API using the product's category
      if (_itemDto != null) {
        final itemProvider = context.read<ItemProvider>();
        _loadRelatedProductsFromApi(itemProvider);
      } else {
        // Fallback to mock data
        _relatedProducts = MockData.items
            .where((item) => item.itemId.toString() != widget.productId)
            .take(_relatedProductsPageSize)
            .toList();
        _totalRelatedProducts =
            MockData.items.length - 1; // Total minus current product
      }
    } catch (e) {
      print('[ProductDetail] Error loading related products: $e');
      _relatedProducts = [];
      _totalRelatedProducts = 0;
    }
  }

  Future<void> _loadRelatedProductsFromApi(ItemProvider itemProvider) async {
    try {
      if (_itemDto == null) return;

      // Get ItemApiService to fetch products from API
      final itemApiService = context.read<ItemApiService>();
      final authProvider = context.read<AuthProvider>();

      // Set auth token if available
      if (authProvider.accessToken != null) {
        itemApiService.setAuthToken(authProvider.accessToken!);
      }

      // Fetch items from same category using the API
      final categoryId = _itemDto!.categoryId.toString();
      final response = await itemApiService.searchItems(
        categoryId: categoryId,
        page: 0,
        size: _relatedProductsPageSize,
      );

      if (response != null && response.content != null) {
        // Convert ItemDto to ItemModel for display
        final itemModels = response.content!
            .where(
                (dto) => dto.id != widget.productId) // Exclude current product
            .map((dto) {
          print(
              '[ProductDetail] Related product - Name: ${dto.name}, Image: ${dto.imageUrl}');
          return ItemModel(
            itemId: int.tryParse(dto.id) ?? 0,
            itemId_str: dto.id,
            name: dto.name,
            description: dto.description ?? '',
            image: dto.imageUrl, // Use API image URL
            price: dto.price?.toDouble() ?? 0,
            categoryName: dto.categoryName ?? 'Khác',
            categoryId: int.tryParse(dto.categoryId.toString()) ?? 0,
            quantity: dto.quantity ?? 1,
            status: 'AVAILABLE',
            createdAt: dto.createdAt,
            expiryDate: dto.expiryDate,
            userId_str: dto.userId.toString(),
          );
        }).toList();

        if (mounted) {
          setState(() {
            _relatedProducts = itemModels;
            _totalRelatedProducts = response.totalElements ?? 0;
          });
        }
        print(
            '[ProductDetail] Loaded ${itemModels.length} related products from API');
      } else {
        // If no response, use fallback
        _useRelatedProductsFallback();
      }
    } catch (e) {
      print('[ProductDetail] Error loading related products from API: $e');
      // Fallback to mock data
      _useRelatedProductsFallback();
    }
  }

  void _useRelatedProductsFallback() {
    _relatedProducts = MockData.items
        .where((item) => item.itemId.toString() != widget.productId)
        .take(_relatedProductsPageSize)
        .toList();
    _totalRelatedProducts = MockData.items.length - 1;

    if (mounted) {
      setState(() {});
    }
  }

  ProductModel _convertDtoToProduct(ItemDto itemDto) {
    // Get category name from MockData or use the one from API
    final categoryName = itemDto.categoryName ??
        MockData.getCategoryById(itemDto.categoryId.hashCode)?.name ??
        'Khác';

    // Start with empty seller info to avoid jumping
    // Real seller info will be loaded by _loadSellerInfo()
    return ProductModel(
      id: itemDto.id,
      name: itemDto.name,
      description: itemDto.description ?? '',
      price: itemDto.price?.toDouble() ?? 0.0,
      images: [
        itemDto.imageUrl ?? 'https://via.placeholder.com/500x500?text=No+Image',
      ],
      category: categoryName,
      quantity: itemDto.quantity ?? 1,
      interestedCount: 0,
      expiryDate:
          itemDto.expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      createdAt: itemDto.createdAt,
      owner: UserInfo(
        id: itemDto.userId.toString(),
        name: '', // Will be filled by _loadSellerInfo
        avatar: '', // Will be filled by _loadSellerInfo
        productsShared: 0, // Will be filled by _loadSellerInfo
      ),
      isFree: (itemDto.price ?? 0) == 0,
    );
  }

  void _startTimer() {
    if (_product == null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingTime = _product!.expiryDate.difference(DateTime.now());
          if (_remainingTime.isNegative) timer.cancel();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    if (_remainingTime.isNegative) return 'Hết hạn';

    final totalHours = _remainingTime.inHours;

    // If more than 24 hours, show in days format
    if (totalHours >= 24) {
      final days = totalHours ~/ 24;
      return '$days ngày';
    }

    // If 24 hours or less, show as countdown timer
    final h = _remainingTime.inHours;
    final m = _remainingTime.inMinutes % 60;
    final s = _remainingTime.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showOrderModal() {
    if (_product == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderRequestModal(product: _product!),
    );
  }

  void _showAddToCartModal() {
    if (_product == null || _itemDto == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddToCartModal(
        item: _itemDto!,
      ),
    );
  }

  Future<void> _handleSendMessage() async {
    try {
      if (_itemDto == null) return;

      // Use the userId from API directly (from itemDto)
      final receiverId = _itemDto!.userId.toString();
      print('[ProductDetail] Sending message to user ID: $receiverId');

      // Send message to the owner
      await _messageApiService.sendMessage(
        receiverId: receiverId,
        content: 'Xin chào, tôi quan tâm đến sản phẩm này.',
        messageType: 'TEXT',
      );

      if (mounted) {
        // Navigate directly to chat screen
        context.push('/chat/$receiverId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('[ProductDetail] Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
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
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error state
    if (_errorMessage != null || _product == null) {
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
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Không thể tải sản phẩm',
                style: AppTextStyles.h4,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Vui lòng thử lại',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadProduct,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    // Show product details
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App bar with image
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            expandedHeight: 300,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: ProductImageCarousel(images: _product!.images),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(_product!.name, style: AppTextStyles.h2),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    _product!.formattedPrice,
                    style: AppTextStyles.priceLarge,
                  ),
                  const SizedBox(height: 16),

                  // Stats row
                  _buildStatsRow(),
                  const SizedBox(height: 24),

                  // Product info section
                  _buildInfoSection(),
                  const SizedBox(height: 24),

                  // Owner section
                  _buildOwnerSection(),
                  const SizedBox(height: 24),

                  // Description
                  _buildDescriptionSection(),
                  const SizedBox(height: 24),

                  // Related products
                  _buildRelatedProducts(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatItem('${_product?.quantity ?? 0}', 'Số lượng'),
        _buildStatItem(
            '${_product?.interestedCount ?? 0}', 'Số người muốn nhận'),
        _buildStatItem(_formattedTime, 'Thời gian còn lại'),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow('Phân loại', _product?.category ?? 'Khác'),
          const Divider(height: 24),
          _buildInfoRow('Hạn sử dụng', 'Không giới hạn'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildOwnerSection() {
    if (_product == null) {
      return const SizedBox.shrink();
    }

    // Show loading state while seller info is being fetched
    if (_isSellerLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            // Avatar skeleton
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.backgroundGray,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const SizedBox.expand(),
            ),
            const SizedBox(width: 12),

            // Info skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Người cho', style: AppTextStyles.caption),
                  Container(
                    width: 120,
                    height: 20,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGray,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGray,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Navigate to owner profile
        context.push(AppRoutes.getUserProfileRoute(_product!.owner.id));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            // Avatar with image or fallback
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.backgroundGray,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: _product!.owner.avatar.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        _product!.owner.avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person,
                              color: AppColors.textSecondary);
                        },
                      ),
                    )
                  : const Icon(Icons.person, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Người cho', style: AppTextStyles.caption),
                  Text(
                    _product!.owner.name,
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${_product!.owner.productsShared} sản phẩm đã cho',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return ExpandableDescription(
      text: _product?.description ?? '',
      maxLines: 3,
    );
  }

  Widget _buildRelatedProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sản phẩm liên quan', style: AppTextStyles.h4),
        const SizedBox(height: 16),
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
          itemCount:
              _relatedProducts.length + (_isLoadingMoreRelatedProducts ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _relatedProducts.length) {
              return const Center(child: CircularProgressIndicator());
            }
            return ItemCard(
              item: _relatedProducts[index],
              showTimeRemaining: true,
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
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
        child: Row(
          children: [
            // Message button
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.mail_outline),
                onPressed: _handleSendMessage,
              ),
            ),
            const SizedBox(width: 12),

            // Add to cart button
            Expanded(
              child: GestureDetector(
                onTap: _showAddToCartModal,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Thêm vào giỏ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Order button
            Expanded(
              child: GestureDetector(
                onTap: _showOrderModal,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Tôi muốn nhận',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
