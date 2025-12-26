import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/transaction_request_model.dart';
import '../../../../data/services/transaction_api_service.dart';
import '../../../../data/providers/auth_provider.dart';
import '../../../../data/providers/user_provider.dart';

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
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // Receiver info toggle
  bool _useCurrentUserInfo = true;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
  }

  void _loadCurrentUserInfo() {
    final userProvider = context.read<UserProvider>();
    if (userProvider.currentUser != null) {
      final user = userProvider.currentUser!;
      _fullNameController.text = user.fullName ?? '';
      _phoneController.text = user.phoneNumber ?? '';
      _addressController.text = user.address ?? '';
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
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
    // Validate inputs
    if (_reasonController.text.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập lý do');
      return;
    }
    if (_fullNameController.text.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập họ tên');
      return;
    }
    if (_phoneController.text.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập số điện thoại');
      return;
    }
    if (_addressController.text.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập địa chỉ');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userProvider = context.read<UserProvider>();
      final transactionService = TransactionApiService();

      // Set auth token if available
      if (authProvider.accessToken != null) {
        transactionService.setAuthToken(authProvider.accessToken!);
      }

      // Get receiver ID (current user's ID)
      final receiverId = userProvider.currentUser?.id ?? '';

      // Create transaction request with correct format
      final request = TransactionRequest(
        itemId: widget.product.id,
        message: _reasonController.text,
        receiverFullName: _fullNameController.text,
        receiverPhone: _phoneController.text,
        shippingAddress: _addressController.text,
        shippingNote: _noteController.text,
        paymentMethod: 'CASH',
        transactionFee: 0.0,
        receiverId: receiverId,
      );

      print(
          '[OrderRequestModal] Creating transaction with request: ${request.toJson()}');

      // Call API
      await transactionService.createTransaction(request);

      setState(() => _isLoading = false);

      if (mounted) {
        context.pop();
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      print('[OrderRequestModal] Error creating transaction: $e');
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
                'Yêu cầu thành công',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 12),
              Text(
                'Người cho đã được thông báo về yêu cầu của bạn. Chúng tôi sẽ liên hệ với bạn sớm nhất.',
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
            const SizedBox(height: 24),

            // Receiver info section
            const Text('Thông tin người nhận', style: AppTextStyles.h4),
            const SizedBox(height: 16),

            // Toggle: Use current user info or enter new
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _useCurrentUserInfo = true);
                            _loadCurrentUserInfo();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _useCurrentUserInfo
                                  ? AppColors.primaryGreen
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Thông tin hiện tại',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: _useCurrentUserInfo
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _useCurrentUserInfo = false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !_useCurrentUserInfo
                                  ? AppColors.primaryGreen
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Thông tin khác',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: !_useCurrentUserInfo
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Full name field
            const Text('Họ tên', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _fullNameController,
              enabled: !_useCurrentUserInfo,
              decoration: InputDecoration(
                hintText: 'Nhập họ tên của bạn',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDisabled,
                ),
                filled: true,
                fillColor: _useCurrentUserInfo
                    ? AppColors.backgroundGray.withOpacity(0.5)
                    : AppColors.backgroundGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Phone field
            const Text('Số điện thoại', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              enabled: !_useCurrentUserInfo,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Nhập số điện thoại',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDisabled,
                ),
                filled: true,
                fillColor: _useCurrentUserInfo
                    ? AppColors.backgroundGray.withOpacity(0.5)
                    : AppColors.backgroundGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Address field
            const Text('Địa chỉ giao hàng', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              enabled: !_useCurrentUserInfo,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Nhập địa chỉ giao hàng',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDisabled,
                ),
                filled: true,
                fillColor: _useCurrentUserInfo
                    ? AppColors.backgroundGray.withOpacity(0.5)
                    : AppColors.backgroundGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Note field
            const Text('Ghi chú (tùy chọn)', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ghi chú thêm (ví dụ: giao hàng vào buổi tối)',
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

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],

            // Action buttons
            const SizedBox(height: 16),
            Row(
              children: [
                // Request now button
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
            color: enabled ? AppColors.primaryGreen : AppColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.primaryGreen : AppColors.textDisabled,
        ),
      ),
    );
  }
}
