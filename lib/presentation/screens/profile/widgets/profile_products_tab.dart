import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/item_model.dart';
import '../../../../data/mock_data.dart';
import '../../../widgets/gradient_button.dart';

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

class _ProfileProductsTabState extends State<ProfileProductsTab> {
  String _sortBy = '0 đồng';
  late List<ItemModel> _products;

  @override
  void initState() {
    super.initState();
    _products = MockData.getItemsByUserId(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add product button (own profile only)
          if (widget.isOwnProfile) ...[
            GradientButton(
              text: 'Tôi muốn chia sẻ sản phẩm',
              onPressed: () {
                // TODO: Navigate to create product
              },
            ),
            const SizedBox(height: 24),
          ],

          // Sort & Filter row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Sort By: ', style: AppTextStyles.bodyMedium),
                  GestureDetector(
                    onTap: _showSortOptions,
                    child: Text(
                      _sortBy,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _showFilterModal,
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Filter'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Products list
          if (_products.isEmpty)
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
            ..._products.map((product) {
              return _buildProductCard(product);
            }),
        ],
      ),
    );
  }

  Widget _buildProductCard(ItemModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.image,
              size: 32,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.price} VND',
                  style: AppTextStyles.price.copyWith(
                    color: AppColors.primaryCyan,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.expirationDate != null
                      ? 'Hết hạn: ${product.expirationDate!.day}/${product.expirationDate!.month}/${product.expirationDate!.year}'
                      : 'Không có hạn',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.quantity} sản phẩm',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryTeal,
                  ),
                ),
              ],
            ),
          ),

          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: product.status == 'available'
                  ? AppColors.primaryTeal.withOpacity(0.1)
                  : AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              product.status == 'available' ? 'Có sẵn' : 'Chờ duyệt',
              style: AppTextStyles.caption.copyWith(
                color: product.status == 'available'
                    ? AppColors.primaryTeal
                    : AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sort By', style: AppTextStyles.h3),
              const SizedBox(height: 16),
              _buildSortOption('0 đồng', bottomSheetContext),
              _buildSortOption('Gần đây', bottomSheetContext),
              _buildSortOption('Đề xuất', bottomSheetContext),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String option, BuildContext modalContext) {
    final isSelected = _sortBy == option;
    return ListTile(
      title: Text(
        option,
        style: AppTextStyles.bodyLarge.copyWith(
          color: isSelected ? AppColors.primaryTeal : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primaryTeal)
          : null,
      onTap: () {
        setState(() => _sortBy = option);
        modalContext.pop();
      },
    );
  }

  void _showFilterModal() {
    // TODO: Implement filter modal
  }
}
