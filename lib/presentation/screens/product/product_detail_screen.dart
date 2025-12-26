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
import '../../../data/models/cart_request_model.dart';
import '../../../data/services/cart_api_service.dart';
import '../../../data/providers/auth_provider.dart';
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

  // Product data
  ProductModel? _product;
  ItemDto? _itemDto;
  bool _isLoading = true;
  String? _errorMessage;

  // Mock related products
  late List<ItemModel> _relatedProducts;

  @override
  void initState() {
    super.initState();
    _loadProduct();
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

  void _loadRelatedProducts() {
    try {
      _relatedProducts = MockData.items
          .where((item) => item.itemId.toString() != widget.productId)
          .take(6)
          .toList();
    } catch (e) {
      _relatedProducts = [];
    }
  }

  ProductModel _convertDtoToProduct(ItemDto itemDto) {
    // Try to find user info in MockData
    final user = MockData.users.firstWhere(
      (u) => u.userId.toString() == itemDto.userId,
      orElse: () => MockData.users[0],
    );

    // Get category name from MockData or use the one from API
    final categoryName = itemDto.categoryName ??
        MockData.getCategoryById(itemDto.categoryId.hashCode)?.name ??
        'Khác';

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
      createdAt: itemDto.createdAt ?? DateTime.now(),
      owner: UserInfo(
        id: user.userId.toString(),
        name: user.name,
        avatar: user.avatar ?? '',
        productsShared: MockData.getItemsByUserId(user.userId).length,
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
    super.dispose();
  }

  String get _formattedTime {
    if (_remainingTime.isNegative) return 'Hết hạn';
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
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.backgroundGray,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Icon(Icons.person, color: AppColors.textSecondary),
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
          itemCount: _relatedProducts.length,
          itemBuilder: (context, index) {
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
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 12),

            // A/s button
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () {},
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
