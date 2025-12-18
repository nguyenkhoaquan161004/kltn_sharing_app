import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/mock_data.dart';
import 'widgets/item_request_modal.dart';

class CartItemDetailScreen extends StatelessWidget {
  final String itemId;

  const CartItemDetailScreen({
    super.key,
    this.itemId = '1',
  });

  @override
  Widget build(BuildContext context) {
    // Get item from mock data
    final item = MockData.items.firstWhere(
      (i) => i.itemId.toString() == itemId,
      orElse: () => MockData.items.first,
    );

    // Get seller from mock data
    final seller = MockData.users.firstWhere(
      (u) => u.userId == item.userId,
      orElse: () => MockData.users.first,
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Chi tiết sản phẩm',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seller info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  // Navigate to user profile (seller)
                  context.push(
                      AppRoutes.getUserProfileRoute(item.userId.toString()));
                },
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(Icons.person),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            seller.name,
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '5 sản phẩm đã cho',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline,
                          color: AppColors.primaryTeal),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Product info
            Text(
              'Thông tin sản phẩm',
              style:
                  AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: GestureDetector(
                onTap: () {
                  // Navigate to product detail
                  context.push(
                      AppRoutes.getProductDetailRoute(item.itemId.toString()));
                },
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.price} VND',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Số lượng: ${item.quantity}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.textSecondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Nhắn ngay',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (context) => ItemRequestModal(
                            item: item,
                            seller: seller,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Tôi muốn nhận',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
