import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/product_model.dart';

class OrderRequestModal extends StatefulWidget {
  final ProductModel product;

  const OrderRequestModal({
    super.key,
    required this.product,
  });

  @override
  State<OrderRequestModal> createState() => _OrderRequestModalState();
}

class _OrderRequestModalState extends State<OrderRequestModal> {
  int _quantity = 1;
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _increaseQuantity() {
    if (_quantity < widget.product.quantity) {
      setState(() => _quantity++);
    }
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  void _addToCart() async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thêm vào giỏ hàng'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _requestNow() async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    if (mounted) {
      context.pop();
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Purchase Successful',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 12),
              Text(
                'The seller has been notified to ship your item and we will only release the payment after you have received it.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  context.pop();
                },
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Product info row
            Row(
              children: [
                // Product image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: widget.product.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.product.images.first,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.image, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.product.formattedPrice,
                        style: AppTextStyles.price,
                      ),
                    ],
                  ),
                ),

                // Close button
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
            const Divider(height: 32),

            // Quantity selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Số lượng', style: AppTextStyles.label),
                    const SizedBox(height: 4),
                    Text(
                      'Còn ${widget.product.quantity} sản phẩm',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildQuantityButton(
                      icon: Icons.remove,
                      onTap: _decreaseQuantity,
                      enabled: _quantity > 1,
                    ),
                    Container(
                      width: 48,
                      alignment: Alignment.center,
                      child: Text(
                        '$_quantity',
                        style: AppTextStyles.h4,
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Icons.add,
                      onTap: _increaseQuantity,
                      enabled: _quantity < widget.product.quantity,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Reason text field
            const Text('Lý do', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Đưa ra lý do bạn muốn nhận sản phẩm',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDisabled,
                ),
                filled: true,
                fillColor: AppColors.backgroundGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                // Add to cart
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _addToCart,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primaryTeal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Thêm vào giỏ hàng',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Request now
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFA726), Color(0xFFFFD54F)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _requestNow,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Tôi muốn nhận',
                                  style: AppTextStyles.button,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled ? AppColors.primaryTeal : AppColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.primaryTeal : AppColors.textDisabled,
        ),
      ),
    );
  }
}
