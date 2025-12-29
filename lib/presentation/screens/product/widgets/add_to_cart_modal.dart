import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/item_response_model.dart';
import '../../../../data/models/cart_request_model.dart';
import '../../../../data/services/cart_api_service.dart';
import '../../../../data/providers/auth_provider.dart';
import '../../../../data/providers/order_provider.dart';

class AddToCartModal extends StatefulWidget {
  final ItemDto item;

  const AddToCartModal({
    super.key,
    required this.item,
  });

  @override
  State<AddToCartModal> createState() => _AddToCartModalState();
}

class _AddToCartModalState extends State<AddToCartModal> {
  int _selectedQuantity = 1;
  String? _selectedVariation;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Product image
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(widget.item.imageUrl ?? ''),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Price
              Center(
                child: Text(
                  '₫${widget.item.price?.toString() ?? '0'}',
                  style: AppTextStyles.h3.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quantity selector
              const Text('Số lượng', style: AppTextStyles.label),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderLight),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          onPressed: _selectedQuantity > 1
                              ? () {
                                  setState(() => _selectedQuantity--);
                                }
                              : null,
                          constraints: const BoxConstraints(minWidth: 36),
                          padding: EdgeInsets.zero,
                        ),
                        Container(
                          width: 50,
                          alignment: Alignment.center,
                          child: Text(
                            '$_selectedQuantity',
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          onPressed:
                              _selectedQuantity < (widget.item.quantity ?? 1)
                                  ? () {
                                      setState(() => _selectedQuantity++);
                                    }
                                  : null,
                          constraints: const BoxConstraints(minWidth: 36),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.red.shade700),
                  ),
                ),
              const SizedBox(height: 24),

              // Add to cart button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: GestureDetector(
                  onTap: _isLoading ? null : _addToCart,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isLoading ? AppColors.textDisabled : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Thêm vào Giỏ hàng',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final cartService = CartApiService();
      if (authProvider.accessToken != null) {
        cartService.setAuthToken(authProvider.accessToken!);
      }

      final request = CartRequest(
        itemId: widget.item.id,
        quantity: _selectedQuantity,
      );

      await cartService.addToCart(request);

      // Update order count in OrderProvider
      if (mounted) {
        context.read<OrderProvider>().incrementOrderCount();
      }

      setState(() => _isLoading = false);

      if (mounted) {
        context.pop();
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm $_selectedQuantity sản phẩm vào giỏ hàng'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }
}
