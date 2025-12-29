import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/services/transaction_api_service.dart';
import '../../../../data/providers/auth_provider.dart';
import '../../../../data/providers/user_provider.dart';
import '../../../../data/providers/order_provider.dart';
import '../../../../data/models/transaction_request_model.dart';

class CartItemRequestModal extends StatefulWidget {
  final Map<String, dynamic> cartItem;

  const CartItemRequestModal({
    super.key,
    required this.cartItem,
  });

  @override
  State<CartItemRequestModal> createState() => _CartItemRequestModalState();
}

class _CartItemRequestModalState extends State<CartItemRequestModal> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

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
    _messageController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    // Validate inputs
    if (_messageController.text.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập lý do muốn nhận');
      return;
    }

    if (_fullNameController.text.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập họ và tên');
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
      final transactionApiService = TransactionApiService();
      final authProvider = context.read<AuthProvider>();

      // Set auth token
      if (authProvider.accessToken != null) {
        transactionApiService.setAuthToken(authProvider.accessToken!);
        transactionApiService.setGetValidTokenCallback(
          () async => authProvider.accessToken,
        );
      }

      // Get item ID from cart item
      final itemId = widget.cartItem['itemId'] ?? widget.cartItem['id'] ?? '';

      // Create transaction request
      final request = TransactionRequest(
        itemId: itemId.toString(),
        message: _messageController.text,
        receiverFullName: _fullNameController.text,
        receiverPhone: _phoneController.text,
        shippingAddress: _addressController.text,
        shippingNote: _noteController.text,
        paymentMethod: 'CASH',
        transactionFee: 0.0,
        receiverId: authProvider.userId ?? '', // Current user ID
      );

      // Call API to create transaction
      await transactionApiService.createTransaction(request);

      // Decrement order count in OrderProvider
      if (mounted) {
        context.read<OrderProvider>().decrementOrderCount();
      }

      if (!mounted) return;

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi yêu cầu nhận sản phẩm'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );

      // Close modal
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemName =
        widget.cartItem['name'] ?? widget.cartItem['itemName'] ?? 'Sản phẩm';
    final sellerName = widget.cartItem['sellerName'] ??
        widget.cartItem['userName'] ??
        'Người bán';
    final itemImage =
        widget.cartItem['itemImageUrl'] ?? widget.cartItem['imageUrl'];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Yêu cầu nhận sản phẩm',
                    style: AppTextStyles.h3,
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Product info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: itemImage != null
                            ? DecorationImage(
                                image: NetworkImage(itemImage),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: itemImage == null
                          ? Icon(Icons.image_not_supported,
                              color: Colors.grey[400])
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemName,
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Từ: $sellerName',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 16),

              // Message field
              Text(
                'Lý do muốn nhận',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhập lý do muốn nhận sản phẩm này...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),

              // Use current user info toggle
              Row(
                children: [
                  Checkbox(
                    value: _useCurrentUserInfo,
                    onChanged: (value) {
                      setState(() => _useCurrentUserInfo = value ?? true);
                    },
                  ),
                  Text(
                    'Sử dụng thông tin hiện tại',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Full name field
              Text(
                'Họ và tên',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _fullNameController,
                enabled: true,
                decoration: InputDecoration(
                  hintText: 'Nhập họ và tên',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Phone field
              Text(
                'Số điện thoại',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Nhập số điện thoại',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Address field
              Text(
                'Địa chỉ nhận hàng',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Nhập địa chỉ nhận hàng',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),

              // Note field
              Text(
                'Ghi chú (tùy chọn)',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Thêm ghi chú...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
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
                      onTap: _isLoading ? null : _submitRequest,
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
                                'Gửi yêu cầu',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
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
}
