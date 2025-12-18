import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/mock_data.dart';
import 'widgets/item_request_modal.dart';

class OrderDetailProcessingScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailProcessingScreen({
    super.key,
    this.orderId = '1',
  });

  @override
  Widget build(BuildContext context) {
    // Get item from mock data using orderId
    final item = MockData.items.firstWhere(
      (i) => i.itemId.toString() == orderId,
      orElse: () => MockData.items.first,
    );

    // Get seller from mock data
    final seller = MockData.users.firstWhere(
      (u) => u.userId == item.userId,
      orElse: () => MockData.users.first,
    );

    // Check if product is available
    final isAvailable = item.status == 'pending' || item.status == 'available';

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
          'Chi tiết đơn hàng',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unavailable notification
            if (!isAvailable)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sản phẩm không khả dụng',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (!isAvailable) const SizedBox(height: 16),

            // Seller info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: GestureDetector(
                onTap: () {
                  // Navigate to seller profile
                  context.push(
                      AppRoutes.getUserProfileRoute(item.userId.toString()));
                },
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGray,
                        borderRadius: BorderRadius.circular(25),
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
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '5 sản phẩm đã cho',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Products
            Text(
              'Sản phẩm',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
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

            // Order timeline
            Text(
              'Quá trình đơn hàng',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimeline(),
            const SizedBox(height: 24),

            // Payment info
            Text(
              'Thông tin thanh toán',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildPaymentRow('Số tiền', '24000 VND'),
                  const SizedBox(height: 8),
                  _buildPaymentRow('Shipping Fee', '0 VND'),
                  const Divider(height: 16),
                  _buildPaymentRow(
                    'Tổng tiền',
                    '24000 VND',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Shipping address
            Text(
              'Địa chỉ chỉ lấy hàng',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '22 Baker Street London MG91 9AF',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Copy',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
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
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryTeal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Tôi muốn nhận',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Đã nhận được hàng',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: [
        Row(
          children: [
            _buildTimelinePoint(true),
            Expanded(
              child: Container(
                height: 3,
                color: AppColors.success,
              ),
            ),
            _buildTimelinePoint(true),
            Expanded(
              child: Container(
                height: 3,
                color: AppColors.borderLight,
              ),
            ),
            _buildTimelinePoint(false),
            Expanded(
              child: Container(
                height: 3,
                color: AppColors.borderLight,
              ),
            ),
            _buildTimelinePoint(false),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Đã đặt hàng',
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
              ),
            ),
            Text(
              'Chờ duyệt',
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Đã duyệt',
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
              ),
            ),
            Text(
              'Hoàn thành',
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelinePoint(bool isCompleted) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.success : Colors.white,
        border: Border.all(
          color: isCompleted ? AppColors.success : AppColors.borderLight,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: isCompleted
          ? const Icon(Icons.check, size: 12, color: Colors.white)
          : null,
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
