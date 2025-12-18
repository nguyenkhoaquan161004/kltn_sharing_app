import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/item_model.dart';
import '../../../data/mock_data.dart';
import 'widgets/product_image_carousel.dart';
import 'widgets/order_request_modal.dart';
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
  late Duration _remainingTime;

  // Mock product data
  late ProductModel _product;

  // Mock related products
  late List<ItemModel> _relatedProducts;

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
          images: [
            'https://via.placeholder.com/500x500?text=Product+Image+1',
            'https://via.placeholder.com/500x500?text=Product+Image+2',
            'https://via.placeholder.com/500x500?text=Product+Image+3',
          ],
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
          name: 'Giày Nike Air Max',
          description:
              '''Giày Nike Air Max 90 chính hãng 100%, tình trạng như mới, mới mua được 2 tháng, chỉ mang 2 lần. Chất liệu cao cấp, đế bền, thoáng khí tốt. Phù hợp cho những ai yêu thích thể thao hoặc đi casual hàng ngày.

Thông tin chi tiết sản phẩm:
• Hãng: Nike chính hãng từ shop official
• Model: Air Max 90
• Kích cỡ: 42 (US 8.5)
• Màu sắc: Trắng xám, bóng bẩy
• Tình trạng: Như mới, 99% không có lỗi
• Số lần mang: Chỉ 2 lần
• Đế: Bền chắc, không trầy xước
• Chất liệu: Canvas + Leather cao cấp
• Thoáng khí: Cực tốt, thích hợp đi quanh năm
• Đi kèm: Hộp nguyên bản, túi bụi, giấy tờ đầy đủ

Lý do chia sẻ:
Giày được tặng nhân dịp sinh nhật nhưng mình không có nhu cầu sử dụng nhiều vì công việc thường xuyên phải mang giày tây chính thức. Do vậy mình muốn chia sẻ để bạn nào thích sneaker có cơ hội sử dụng.

Tình trạng chi tiết:
- Mặt giày không bị bẩn hay dơ
- Sợi chỉ không bị lỏng hay nát
- Đế ngoài vẫn cứng chắc, không mềm
- Lót giày sạch sẽ, mùi hương tự nhiên
- Dây giày không bị sờn

Hướng dẫn bảo quản:
Để giữ giày lâu bền, nên rửa bằng nước lạnh với xà phòng nhẹ, không nên giặt máy hoặc ngâm nước lâu. Sau khi rửa, phơi khô tự nhiên ở nơi thoáng mát.

Liên hệ:
Bạn nào quan tâm có thể liên hệ để xem thực tế hoặc chat hỏi thêm thông tin. Mình ở quận 1, TP.HCM, có thể gặp trực tiếp hoặc giao hàng gần đây. Giờ làm việc từ 8h-17h hàng ngày.''',
          price: 0,
          images: [
            'https://via.placeholder.com/500x500?text=Giay+Nike+1',
            'https://via.placeholder.com/500x500?text=Giay+Nike+2',
            'https://via.placeholder.com/500x500?text=Giay+Nike+3',
            'https://via.placeholder.com/500x500?text=Giay+Nike+4',
          ],
          category: 'Thể thao',
          quantity: 1,
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
        name: 'Giày Nike Air Max',
        description:
            '''Giày Nike Air Max 90 chính hãng 100%, tình trạng như mới, mới mua được 2 tháng, chỉ mang 2 lần. Chất liệu cao cấp, đế bền, thoáng khí tốt. Phù hợp cho những ai yêu thích thể thao hoặc đi casual hàng ngày.

Thông tin chi tiết sản phẩm:
• Hãng: Nike chính hãng từ shop official
• Model: Air Max 90
• Kích cỡ: 42 (US 8.5)
• Màu sắc: Trắng xám, bóng bẩy
• Tình trạng: Như mới, 99% không có lỗi
• Số lần mang: Chỉ 2 lần
• Đế: Bền chắc, không trầy xước
• Chất liệu: Canvas + Leather cao cấp
• Thoáng khí: Cực tốt, thích hợp đi quanh năm
• Đi kèm: Hộp nguyên bản, túi bụi, giấy tờ đầy đủ

Lý do chia sẻ:
Giày được tặng nhân dịp sinh nhật nhưng mình không có nhu cầu sử dụng nhiều vì công việc thường xuyên phải mang giày tây chính thức. Do vậy mình muốn chia sẻ để bạn nào thích sneaker có cơ hội sử dụng.

Tình trạng chi tiết:
- Mặt giày không bị bẩn hay dơ
- Sợi chỉ không bị lỏng hay nát
- Đế ngoài vẫn cứng chắc, không mềm
- Lót giày sạch sẽ, mùi hương tự nhiên
- Dây giày không bị sờn

Hướng dẫn bảo quản:
Để giữ giày lâu bền, nên rửa bằng nước lạnh với xà phòng nhẹ, không nên giặt máy hoặc ngâm nước lâu. Sau khi rửa, phơi khô tự nhiên ở nơi thoáng mát.

Liên hệ:
Bạn nào quan tâm có thể liên hệ để xem thực tế hoặc chat hỏi thêm thông tin. Mình ở quận 1, TP.HCM, có thể gặp trực tiếp hoặc giao hàng gần đây. Giờ làm việc từ 8h-17h hàng ngày.''',
        price: 0,
        images: [
          'https://via.placeholder.com/500x500?text=Giay+Nike+1',
          'https://via.placeholder.com/500x500?text=Giay+Nike+2',
          'https://via.placeholder.com/500x500?text=Giay+Nike+3',
          'https://via.placeholder.com/500x500?text=Giay+Nike+4',
        ],
        category: 'Thể thao',
        quantity: 1,
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

    // Get 6 related products from MockData (items from same category or just first 6)
    _relatedProducts = MockData.items
        .where((item) => item.itemId.toString() != widget.productId)
        .take(6)
        .toList();
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatItem('${_product.quantity}', 'Số lượng'),
        _buildStatItem('${_product.interestedCount}', 'Số người muốn nhận'),
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
    return ExpandableDescription(
      text: _product.description,
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
