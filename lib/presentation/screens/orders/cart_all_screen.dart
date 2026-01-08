import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_status.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/transaction_api_service.dart';
import '../../../data/services/cart_api_service.dart';
import '../../../data/services/message_api_service.dart';
import '../../../data/services/item_api_service.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/order_provider.dart';

import '../../../presentation/screens/product/widgets/order_request_modal.dart';

class CartAllScreen extends StatefulWidget {
  const CartAllScreen({super.key});

  @override
  State<CartAllScreen> createState() => _CartAllScreenState();
}

class _CartAllScreenState extends State<CartAllScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late TransactionApiService _transactionApiService;
  late CartApiService _cartApiService;
  late MessageApiService _messageApiService;
  late ItemApiService _itemApiService;

  List<dynamic> _cartItems = [];
  Map<String, double> _itemPriceCache = {}; // Cache để lưu giá của item

  List<TransactionModel> _receiverPendingTransactions = [];
  List<TransactionModel> _sharerAcceptedTransactions = [];
  List<TransactionModel> _receiverAcceptedTransactions = [];
  List<TransactionModel> _sharerCompletedTransactions = [];
  List<TransactionModel> _receiverCompletedTransactions = [];

  bool _isLoadingCart = false;
  bool _isLoadingTransactions = false;
  String? _errorMessage;

  // Refresh control
  bool _isRefreshing = false;

  // Multi-select state
  bool _isSelectionMode = false;
  Set<String> _selectedItemIds = {}; // Set of selected item IDs
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    // Add lifecycle observer to detect when app resumes
    WidgetsBinding.instance.addObserver(this);

    _tabController = TabController(length: 4, vsync: this);
    _transactionApiService = TransactionApiService();
    _cartApiService = CartApiService();
    _messageApiService = MessageApiService();
    _itemApiService = ItemApiService();

    // Setup auth token from AuthProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.accessToken != null) {
        _transactionApiService.setAuthToken(authProvider.accessToken!);
        _cartApiService.setAuthToken(authProvider.accessToken!);
        _messageApiService.setAuthToken(authProvider.accessToken!);
        _itemApiService.setAuthToken(authProvider.accessToken!);

        // Set token refresh callback
        _transactionApiService.setGetValidTokenCallback(
          () async => authProvider.accessToken,
        );
        _cartApiService.setGetValidTokenCallback(
          () async => authProvider.accessToken,
        );
        _messageApiService.setGetValidTokenCallback(
          () async => authProvider.accessToken,
        );
        _itemApiService.setGetValidTokenCallback(
          () async => authProvider.accessToken,
        );
      }

      // Load initial data
      _loadCartAndTransactions();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload data when app is resumed (coming back from order detail screen)
      _loadCartAndTransactions();
    }
  }

  Future<void> _loadCartAndTransactions() async {
    setState(() {
      _isLoadingCart = true;
      _isLoadingTransactions = true;
      _errorMessage = null;
      _isRefreshing = true;
    });

    try {
      // Clear price cache to get fresh prices
      _itemPriceCache.clear();

      // Load cart items from API
      final cartItems = await _cartApiService.getCart();

      // Load sharer transactions (user is the sharer)
      final sharerTransactions =
          await _transactionApiService.getTransactionsAsSharer();

      // Load receiver transactions (user is the receiver)
      final receiverTransactions =
          await _transactionApiService.getTransactionsAsReceiver();

      // Filter sharer transactions by status
      _sharerAcceptedTransactions = sharerTransactions
          .where((t) =>
              t.status == TransactionStatus.accepted ||
              t.status == TransactionStatus.inProgress)
          .toList();

      _sharerCompletedTransactions = sharerTransactions
          .where((t) =>
              t.status == TransactionStatus.rejected ||
              t.status == TransactionStatus.completed ||
              t.status == TransactionStatus.cancelled)
          .toList();

      // Filter receiver transactions by status
      _receiverPendingTransactions = receiverTransactions
          .where((t) => t.status == TransactionStatus.pending)
          .toList();

      _receiverAcceptedTransactions = receiverTransactions
          .where((t) =>
              t.status == TransactionStatus.accepted ||
              t.status == TransactionStatus.inProgress)
          .toList();

      _receiverCompletedTransactions = receiverTransactions
          .where((t) =>
              t.status == TransactionStatus.rejected ||
              t.status == TransactionStatus.completed ||
              t.status == TransactionStatus.cancelled)
          .toList();

      setState(() {
        _cartItems = cartItems;
        _isLoadingCart = false;
        _isLoadingTransactions = false;
        _isRefreshing = false;
      });

      // Update cart count in OrderProvider
      if (mounted) {
        context.read<OrderProvider>().setCartCount(cartItems.length);
      }
    } catch (e) {
      print('[CartAllScreen] Error loading data: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoadingCart = false;
        _isLoadingTransactions = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _deleteSelectedItems() async {
    if (_selectedItemIds.isEmpty) return;

    try {
      setState(() => _isDeleting = true);

      // Call delete API for each selected item
      for (String itemId in _selectedItemIds) {
        try {
          await _cartApiService.deleteCartItem(itemId);
          print('[CartAllScreen] Deleted item: $itemId');
        } catch (e) {
          print('[CartAllScreen] Error deleting item $itemId: $e');
        }
      }

      // Reload cart after deletion
      setState(() {
        _isDeleting = false;
        _isSelectionMode = false;
        _selectedItemIds.clear();
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã xóa ${_selectedItemIds.length} mục khỏi giỏ hàng',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Refresh cart
      await _loadCartAndTransactions();
    } catch (e) {
      print('[CartAllScreen] Error deleting items: $e');
      setState(() => _isDeleting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatPrice(double price) {
    final priceStr = price.toStringAsFixed(0);
    final reversedPrice = priceStr.split('').reversed.toList();
    final formatted = <String>[];
    for (int i = 0; i < reversedPrice.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formatted.add('.');
      }
      formatted.add(reversedPrice[i]);
    }
    return formatted.reversed.join('');
  }

  Future<void> _handleSendMessage(dynamic item) async {
    try {
      print('[CartAllScreen] _handleSendMessage called with item: $item');

      // Try to get seller ID from cart item - field name is 'ownerUserId' from API
      var sellerId =
          item['ownerUserId']?.toString() ?? item['userId']?.toString() ?? '';
      final itemId = item['itemId'] ?? item['id'] ?? '';

      // If sellerId not found in cart item, fetch full item details from API
      if (sellerId.isEmpty && itemId.isNotEmpty) {
        print('[CartAllScreen] Fetching item details to get seller ID...');
        try {
          final itemDetails = await _itemApiService.getItem(itemId.toString());
          sellerId = itemDetails.userId.toString();
          print('[CartAllScreen] Got sellerId from item API: $sellerId');
        } catch (e) {
          print('[CartAllScreen] Error fetching item details: $e');
        }
      }

      print('[CartAllScreen] Final sellerId: $sellerId, itemId: $itemId');

      if (sellerId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy thông tin người bán'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Send message to the seller
      await _messageApiService.sendMessage(
        receiverId: sellerId,
        content: 'Xin chào, tôi quan tâm đến sản phẩm này.',
        messageType: 'TEXT',
        itemId: itemId.toString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi tin nhắn'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate directly to chat screen
        context.push('/chat/$sellerId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('[CartAllScreen] Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: Icon(Icons.close, color: AppColors.textPrimary),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedItemIds.clear();
                  });
                },
              )
            : IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
        title: _isSelectionMode
            ? Text(
                '${_selectedItemIds.length} mục đã chọn',
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              )
            : Text(
                'Đơn hàng',
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              ),
        actions: [
          // Delete button (shown when in selection mode and items are selected)
          if (_isSelectionMode && _selectedItemIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: _isDeleting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : ElevatedButton(
                        onPressed: _deleteSelectedItems,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(
                          'Xóa tất cả',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ),
          // Refresh button
          if (!_isRefreshing && !_isSelectionMode)
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.textPrimary),
              onPressed: _loadCartAndTransactions,
              tooltip: 'Làm mới',
            ),
          if (_isRefreshing && !_isSelectionMode)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          TabBar(
            controller: _tabController,
            onTap: (index) => setState(() {}),
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryGreen,
            labelStyle:
                AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            unselectedLabelStyle: AppTextStyles.bodyMedium,
            tabs: const [
              Tab(text: 'Giỏ hàng'),
              Tab(text: 'Chờ duyệt'),
              Tab(text: 'Đã duyệt'),
              Tab(text: 'Hoàn thành'),
            ],
          ),
          // Tab views with RefreshIndicator
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadCartAndTransactions,
              color: AppColors.primaryGreen,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCartTab(),
                  _buildPendingTab(),
                  _buildAcceptedTab(),
                  _buildCompletedTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartTab() {
    if (_isLoadingCart) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          'Lỗi: $_errorMessage',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
        ),
      );
    }

    if (_cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Chưa có sản phẩm trong giỏ hàng',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        _buildOrderSection('Giỏ hàng', _cartItems.length, 'cart', _cartItems),
      ],
    );
  }

  Widget _buildPendingTab() {
    if (_isLoadingTransactions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_receiverPendingTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Không có đơn hàng chờ duyệt',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        ..._receiverPendingTransactions
            .map((t) => _buildTransactionItem(t, false)),
      ],
    );
  }

  Widget _buildAcceptedTab() {
    if (_isLoadingTransactions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_receiverAcceptedTransactions.isEmpty &&
        _sharerAcceptedTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Không có đơn hàng đã duyệt',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        if (_receiverAcceptedTransactions.isNotEmpty) ...[
          _buildSectionHeader('Đã được duyệt'),
          ..._receiverAcceptedTransactions
              .map((t) => _buildTransactionItem(t, false)),
          const SizedBox(height: 24),
        ],
        if (_sharerAcceptedTransactions.isNotEmpty) ...[
          _buildSectionHeader('Chuẩn bị giao hàng'),
          ..._sharerAcceptedTransactions
              .map((t) => _buildTransactionItem(t, true)),
        ],
      ],
    );
  }

  Widget _buildCompletedTab() {
    if (_isLoadingTransactions) {
      return const Center(child: CircularProgressIndicator());
    }

    // Separate by status for completed tab
    final receiverDelivered = _receiverCompletedTransactions
        .where((t) => t.status == TransactionStatus.completed)
        .toList();
    final sharerDelivered = _sharerCompletedTransactions
        .where((t) => t.status == TransactionStatus.completed)
        .toList();
    final others = [
      ..._receiverCompletedTransactions
          .where((t) => t.status != TransactionStatus.completed),
      ..._sharerCompletedTransactions
          .where((t) => t.status != TransactionStatus.completed),
    ];

    if (receiverDelivered.isEmpty &&
        sharerDelivered.isEmpty &&
        others.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Không có đơn hàng hoàn thành',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        if (receiverDelivered.isNotEmpty) ...[
          _buildSectionHeader('Đã nhận'),
          ...receiverDelivered.map((t) => _buildTransactionItem(t, false)),
          const SizedBox(height: 24),
        ],
        if (sharerDelivered.isNotEmpty) ...[
          _buildSectionHeader('Đã giao'),
          ...sharerDelivered.map((t) => _buildTransactionItem(t, true)),
          const SizedBox(height: 24),
        ],
        if (others.isNotEmpty) ...[
          _buildSectionHeader('Khác'),
          ...others.map((t) => _buildTransactionItem(
              t, _sharerCompletedTransactions.contains(t))),
        ],
      ],
    );
  }

  String _getStatusDisplay(TransactionStatus status) {
    return status.getDisplayName();
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.accepted:
        return Colors.blue;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.rejected:
      case TransactionStatus.cancelled:
        return Colors.red;
      case TransactionStatus.inProgress:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Old methods removed - using new _buildTransactionItem instead

  // Helper methods for transaction UI
  Widget _buildOrderSection(
      String title, int count, String type, List<dynamic> items) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Chưa có sản phẩm',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title),
        ...items.map((item) {
          final itemId = item['itemId'] ?? item['id'] ?? '0';
          final itemIdStr = itemId.toString();
          final itemName = item['name'] ?? item['itemName'] ?? 'Sản phẩm';
          final itemImage = item['itemImageUrl'] ?? item['imageUrl'];
          final sellerName =
              item['sellerName'] ?? item['userName'] ?? 'Người bán';
          final isSelected = _selectedItemIds.contains(itemIdStr);

          return GestureDetector(
            onLongPress: () {
              setState(() {
                _isSelectionMode = true;
                if (_selectedItemIds.contains(itemIdStr)) {
                  _selectedItemIds.remove(itemIdStr);
                } else {
                  _selectedItemIds.add(itemIdStr);
                }
              });
            },
            onTap: _isSelectionMode
                ? () {
                    setState(() {
                      if (_selectedItemIds.contains(itemIdStr)) {
                        _selectedItemIds.remove(itemIdStr);
                        if (_selectedItemIds.isEmpty) {
                          _isSelectionMode = false;
                        }
                      } else {
                        _selectedItemIds.add(itemIdStr);
                      }
                    });
                  }
                : () {
                    context.push(
                        AppRoutes.getProductDetailRoute(itemId.toString()));
                  },
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryTeal.withOpacity(0.1)
                    : Colors.white,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryTeal
                      : AppColors.borderLight,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Checkbox (shown when in selection mode)
                      if (_isSelectionMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedItemIds.add(itemIdStr);
                                } else {
                                  _selectedItemIds.remove(itemIdStr);
                                  if (_selectedItemIds.isEmpty) {
                                    _isSelectionMode = false;
                                  }
                                }
                              });
                            },
                            activeColor: AppColors.primaryTeal,
                          ),
                        ),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Từ: $sellerName',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '${item['quantity'] ?? 1}x',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Hiển thị giá của sản phẩm từ API
                                FutureBuilder<double?>(
                                  future: _getItemPrice(
                                      item['itemId'] ?? item['id'] ?? ''),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text(
                                        '...',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primaryTeal,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    }

                                    final itemPrice = snapshot.data ?? 0.0;
                                    final quantity = item['quantity'] ?? 1;
                                    final totalPrice = itemPrice * quantity;

                                    if (totalPrice == 0) {
                                      return Text(
                                        'Miễn phí',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    }

                                    return Text(
                                      '${_formatPrice(totalPrice)} VND',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primaryTeal,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _isSelectionMode
                            ? Icons.check_circle
                            : Icons.arrow_forward_ios,
                        size: 16,
                        color: isSelected
                            ? AppColors.primaryTeal
                            : AppColors.textSecondary,
                      ),
                    ],
                  ),
                  // Action buttons (hidden in selection mode)
                  if (!_isSelectionMode) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleSendMessage(item),
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
                              final itemId = item['itemId'] ?? item['id'] ?? '';
                              // Lấy giá từ cache, nếu chưa có thì dùng 0
                              final itemPrice =
                                  _itemPriceCache[itemId.toString()] ?? 0.0;

                              final productModel = ProductModel(
                                id: itemId.toString(),
                                name: item['name'] ??
                                    item['itemName'] ??
                                    'Sản phẩm',
                                description: item['description'] ?? '',
                                quantity: item['quantity'] ?? 1,
                                price: itemPrice,
                                category: item['categoryName'] ?? 'Danh mục',
                                images: item['itemImageUrl'] != null
                                    ? [item['itemImageUrl']]
                                    : (item['imageUrl'] != null
                                        ? [item['imageUrl']]
                                        : []),
                                interestedCount: 0,
                                expiryDate: DateTime.now()
                                    .add(const Duration(days: 30)),
                                createdAt: DateTime.now(),
                                owner: UserInfo(
                                  id: item['userId']?.toString() ?? '0',
                                  name: item['sellerName'] ??
                                      item['userName'] ??
                                      'Người bán',
                                  avatar: '',
                                  productsShared: 0,
                                ),
                                status: item['status'] ?? 'available',
                                isFree: itemPrice == 0,
                                cartItemId: itemId.toString(),
                              );

                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => OrderRequestModal(
                                  product: productModel,
                                ),
                              ).then((result) {
                                if (result == true) {
                                  _loadCartAndTransactions();
                                }
                              });
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
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction, bool isSharer) {
    return GestureDetector(
      onTap: () async {
        final transactionId = transaction.transactionIdUuid ??
            transaction.transactionId.toString();
        // Navigate to order detail and refresh data when returning
        await context.pushNamed(
          AppRoutes.orderDetailName,
          pathParameters: {'id': transactionId},
        );
        // Refresh data when coming back from detail screen
        _loadCartAndTransactions();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.borderLight),
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
                image: transaction.itemImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(transaction.itemImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: transaction.itemImageUrl == null
                  ? Icon(Icons.image_not_supported, color: Colors.grey[400])
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.itemName ?? 'Sản phẩm',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSharer
                        ? 'Nhận: ${transaction.receiverName ?? 'N/A'}'
                        : 'Từ: ${transaction.sharerName ?? 'N/A'}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          transaction.status.getDisplayName(),
                          style: AppTextStyles.caption.copyWith(
                            color: _getStatusColor(transaction.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Hiển thị giá của sản phẩm
                      FutureBuilder<double?>(
                        future: _getItemPrice(transaction.itemIdUuid ??
                            transaction.itemId.toString()),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text(
                              '...',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primaryTeal,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }

                          final itemPrice = snapshot.data ?? 0.0;
                          final quantity = transaction.quantity ?? 1;
                          final totalPrice = itemPrice * quantity;

                          if (totalPrice == 0) {
                            return Text(
                              'Miễn phí',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }

                          return Text(
                            '${_formatPrice(totalPrice)} VND',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<double?> _getItemPrice(String itemId) async {
    try {
      // Kiểm tra cache trước
      if (_itemPriceCache.containsKey(itemId)) {
        return _itemPriceCache[itemId];
      }

      // Lấy item details từ API
      final itemDto = await _itemApiService.getItem(itemId);
      final price = itemDto.price?.toDouble() ?? 0.0;

      // Lưu vào cache
      _itemPriceCache[itemId] = price;

      return price;
    } catch (e) {
      print('[CartAllScreen] Error getting item price: $e');
      return null;
    }
  }
}
