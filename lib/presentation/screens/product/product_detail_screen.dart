import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/item_model.dart';
import '../../../data/mock_data.dart';
import 'widgets/product_image_carousel.dart';
import 'widgets/order_request_modal.dart';

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
  late Duration _remainingTime;

  // Mock product data
  late ProductModel _product;

  // Mock related products
  late List<ProductModel> _relatedProducts;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  void _loadProduct() {
    try {
      int productId = int.parse(widget.productId);
      // Try to find product in MockData
      ItemModel? mockItem = MockData.getItemById(productId);

      if (mockItem != null) {
        // Found in MockData - use real data
        final user = MockData.users.firstWhere(
          (u) => u.userId == mockItem.userId,
          orElse: () => MockData.users[0],
        );

        _product = ProductModel(
          id: mockItem.itemId.toString(),
          name: mockItem.name,
          description: mockItem.description,
          price: mockItem.price,
          images: [],
          category:
              MockData.getCategoryById(mockItem.categoryId)?.name ?? 'Khác',
          quantity: mockItem.quantity,
          interestedCount: 0,
          expiryDate: mockItem.expirationDate ??
              DateTime.now().add(const Duration(hours: 12)),
          createdAt: mockItem.createdAt,
          owner: UserInfo(
            id: user.userId.toString(),
            name: user.name,
            avatar: user.avatar ?? '',
            productsShared: MockData.getItemsByUserId(user.userId).length,
          ),
          isFree: mockItem.price == 0,
        );
      } else {
        // Use fallback mock data
        final defaultUser = MockData.users[0];
        _product = ProductModel(
          id: widget.productId,
          name: 'Giày Nike',
          description:
              '''Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos...''',
          price: 0,
          images: [],
          category: 'Thể thao',
          quantity: 63,
          interestedCount: 12,
          expiryDate: DateTime.now()
              .add(const Duration(hours: 12, minutes: 32, seconds: 34)),
          createdAt: DateTime.now(),
          owner: UserInfo(
            id: defaultUser.userId.toString(),
            name: defaultUser.name,
            avatar: defaultUser.avatar ?? '',
            productsShared:
                MockData.getItemsByUserId(defaultUser.userId).length,
          ),
          isFree: true,
        );
      }
    } catch (e) {
      print('DEBUG: Error loading product: $e');
      // Fallback
      final defaultUser = MockData.users[0];
      _product = ProductModel(
        id: widget.productId,
        name: 'Giày Nike',
        description: 'Mô tả sản phẩm',
        price: 0,
        images: [],
        category: 'Thể thao',
        quantity: 63,
        interestedCount: 12,
        expiryDate: DateTime.now()
            .add(const Duration(hours: 12, minutes: 32, seconds: 34)),
        createdAt: DateTime.now(),
        owner: UserInfo(
          id: defaultUser.userId.toString(),
          name: defaultUser.name,
          avatar: defaultUser.avatar ?? '',
          productsShared: MockData.getItemsByUserId(defaultUser.userId).length,
        ),
        isFree: true,
      );
    }

    _remainingTime = _product.remainingTime;
    _startTimer();

    _relatedProducts = List.generate(
      6,
      (index) => ProductModel(
        id: 'related_$index',
        name: 'Giày Nike aaaaaaaaaaaaaaaaaaaaaa',
        description: '',
        price: 12000,
        images: [],
        category: 'Thể thao',
        quantity: 3,
        interestedCount: 32,
        expiryDate: DateTime.now().add(const Duration(hours: 12)),
        createdAt: DateTime.now(),
        owner: _product.owner,
        isFree: index % 2 == 0,
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingTime = _product.expiryDate.difference(DateTime.now());
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderRequestModal(product: _product),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              background: ProductImageCarousel(images: _product.images),
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
                  Text(_product.name, style: AppTextStyles.h2),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    _product.formattedPrice,
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
      children: [
        _buildStatItem('${_product.quantity}', 'Số lượng'),
        const SizedBox(width: 24),
        _buildStatItem('${_product.interestedCount}', 'Số người muốn nhận'),
        const SizedBox(width: 24),
        _buildStatItem(_formattedTime, 'Thời gian còn lại'),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
        ),
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
          _buildInfoRow('Phân loại', _product.category),
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
    return GestureDetector(
      onTap: () {
        // Navigate to owner profile
        context.push(AppRoutes.getUserProfileRoute(_product.owner.id));
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
                    _product.owner.name,
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${_product.owner.productsShared} sản phẩm đã cho',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mô tả sản phẩm', style: AppTextStyles.h4),
        const SizedBox(height: 12),
        Text(
          _product.description,
          style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
        ),
      ],
    );
  }

  Widget _buildRelatedProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sản phẩm liên quan', style: AppTextStyles.h4),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _relatedProducts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 160,
                child: _buildMiniProductCard(_relatedProducts[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMiniProductCard(ProductModel product) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Center(
                child: Icon(Icons.image, color: AppColors.textSecondary)),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTextStyles.bodySmall
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(product.formattedPrice,
                    style: AppTextStyles.price.copyWith(fontSize: 14)),
                Text('Còn ${product.quantity} sản phẩm',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
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
                      style: AppTextStyles.button,
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
