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

  List<dynamic> _cartItems = [];
  List<TransactionModel> _pendingTransactions = [];
  List<TransactionModel> _acceptedTransactions = [];
  List<TransactionModel> _completedTransactions = [];

  bool _isLoadingCart = false;
  bool _isLoadingTransactions = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Add lifecycle observer to detect when app resumes
    WidgetsBinding.instance.addObserver(this);

    _tabController = TabController(length: 4, vsync: this);
    _transactionApiService = TransactionApiService();
    _cartApiService = CartApiService();
    _messageApiService = MessageApiService();

    // Setup auth token from AuthProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.accessToken != null) {
        _transactionApiService.setAuthToken(authProvider.accessToken!);
        _cartApiService.setAuthToken(authProvider.accessToken!);
        _messageApiService.setAuthToken(authProvider.accessToken!);

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
    });

    try {
      // Load cart items from API
      final cartItems = await _cartApiService.getCart();

      // Load transactions from API
      final transactions = await _transactionApiService.getMyTransactions();

      // Filter transactions by status
      _pendingTransactions = transactions
          .where((t) => t.status == TransactionStatus.pending)
          .toList();

      _acceptedTransactions = transactions
          .where((t) =>
              t.status == TransactionStatus.accepted ||
              t.status == TransactionStatus.inProgress)
          .toList();

      _completedTransactions = transactions
          .where((t) =>
              t.status == TransactionStatus.rejected ||
              t.status == TransactionStatus.completed ||
              t.status == TransactionStatus.cancelled)
          .toList();

      setState(() {
        _cartItems = cartItems;
        _isLoadingCart = false;
        _isLoadingTransactions = false;
      });
    } catch (e) {
      print('[CartAllScreen] Error loading data: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoadingCart = false;
        _isLoadingTransactions = false;
      });
    }
  }

  Future<void> _handleSendMessage(dynamic item) async {
    try {
      final sellerId = item['userId']?.toString() ?? '';
      final itemId = item['itemId'] ?? item['id'] ?? '';

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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Đơn hàng',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
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
          // Tab views
          Expanded(
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

    if (_pendingTransactions.isEmpty) {
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
        _buildTransactionSection(
            'Chờ duyệt', _pendingTransactions, TransactionStatus.pending),
      ],
    );
  }

  Widget _buildAcceptedTab() {
    if (_isLoadingTransactions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_acceptedTransactions.isEmpty) {
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
        _buildTransactionSection(
            'Đã duyệt', _acceptedTransactions, TransactionStatus.accepted),
      ],
    );
  }

  Widget _buildCompletedTab() {
    if (_isLoadingTransactions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_completedTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all_outlined,
                size: 48, color: AppColors.textSecondary),
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
        _buildTransactionSection(
            'Hoàn thành', _completedTransactions, TransactionStatus.completed),
      ],
    );
  }

  Widget _buildOrderSection(
      String title, int itemCount, String type, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          itemCount,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildOrderCard(type, items[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionSection(String title,
      List<TransactionModel> transactions, TransactionStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          transactions.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTransactionCard(transactions[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(String type, dynamic item) {
    final itemId = item['itemId'] ?? item['id'] ?? '0';
    final itemName = item['name'] ?? item['itemName'] ?? 'Sản phẩm';
    final itemImage = item['itemImageUrl'] ?? item['imageUrl'];
    final sellerName = item['sellerName'] ?? item['userName'] ?? 'Người bán';

    return GestureDetector(
      onTap: () {
        if (type == 'cart') {
          context.push(AppRoutes.getProductDetailRoute(itemId.toString()));
        } else if (type == 'processing' || type == 'done') {
          context.pushNamed(
            AppRoutes.orderDetailName,
            pathParameters: {'id': itemId.toString()},
          );
        }
      },
      child: type == 'cart'
          ? Dismissible(
              key: Key(itemId.toString()),
              direction: DismissDirection.endToStart,
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xóa khỏi giỏ hàng'),
                    content: const Text('Bạn chắc chắn muốn xóa sản phẩm này?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Xóa',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                return confirmed ?? false;
              },
              onDismissed: (direction) async {
                try {
                  final deleteItemId = item['itemId'] ?? item['id'] ?? '';
                  await _cartApiService.removeFromCart(deleteItemId.toString());

                  // Decrement order count in OrderProvider
                  if (mounted) {
                    context.read<OrderProvider>().decrementOrderCount();
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã xóa khỏi giỏ hàng'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadCartAndTransactions();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    _loadCartAndTransactions();
                  }
                }
              },
              child: _buildCartItemCard(
                  type, item, itemName, itemImage, sellerName),
            )
          : _buildCartItemCard(type, item, itemName, itemImage, sellerName),
    );
  }

  Widget _buildCartItemCard(String type, dynamic item, String itemName,
      itemImage, String sellerName) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product row
          Row(
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
                    ? Icon(Icons.image_not_supported, color: Colors.grey[400])
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
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Từ: $sellerName',
                      style: AppTextStyles.bodySmall.copyWith(
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
                        if (item['price'] != null && item['price'] != 0)
                          Text(
                            '${item['price']} VND',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Text(
                            'Miễn phí',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
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
          const SizedBox(height: 12),
          // Status or buttons
          if (type == 'cart')
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
                      // Convert cart item to ProductModel for modal
                      final itemId = item['itemId'] ?? item['id'] ?? '';
                      final productModel = ProductModel(
                        id: itemId.toString(),
                        name: item['name'] ?? item['itemName'] ?? 'Sản phẩm',
                        description: item['description'] ?? '',
                        quantity: item['quantity'] ?? 1,
                        price: (item['price'] ?? 0).toDouble(),
                        category: item['categoryName'] ?? 'Danh mục',
                        images: item['itemImageUrl'] != null
                            ? [item['itemImageUrl']]
                            : (item['imageUrl'] != null
                                ? [item['imageUrl']]
                                : []),
                        interestedCount: 0,
                        expiryDate:
                            DateTime.now().add(const Duration(days: 30)),
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
                        isFree: (item['price'] ?? 0) == 0,
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
                          // Reload cart and transactions after successful request
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
            )
          else if (type == 'processing')
            Row(
              children: [
                Text(
                  'Chờ duyệt',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.orderDetail),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Chi tiết',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else if (type == 'done')
            Row(
              children: [
                Text(
                  'Đã nhận được hàng',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => context.push(AppRoutes.orderDetail),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Đã nhận được hàng',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    return GestureDetector(
      onTap: () {
        // Use UUID if available, otherwise fall back to int ID
        final transactionId = transaction.transactionIdUuid ??
            transaction.transactionId.toString();
        context.pushNamed(
          AppRoutes.orderDetailName,
          pathParameters: {'id': transactionId},
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product row
            Row(
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
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Từ: ${transaction.sharerName ?? 'Không rõ'}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getStatusDisplay(transaction.status),
                        style: AppTextStyles.caption.copyWith(
                          color: _getStatusColor(transaction.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons based on status
            _buildTransactionActionButtons(transaction),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionActionButtons(TransactionModel transaction) {
    final status = transaction.status;

    if (status == TransactionStatus.pending) {
      return Row(
        children: [
          Text(
            'Chờ người chia sẻ duyệt',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () {
              // Use UUID if available, otherwise fall back to int ID
              final transactionId = transaction.transactionIdUuid ??
                  transaction.transactionId.toString();
              context.pushNamed(
                AppRoutes.orderDetailName,
                pathParameters: {'id': transactionId},
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primaryGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Chi tiết',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    } else if (status == TransactionStatus.accepted ||
        status == TransactionStatus.inProgress) {
      return Row(
        children: [
          Expanded(
            child: Text(
              status == TransactionStatus.accepted
                  ? 'Đã duyệt - Đang chờ giao hàng'
                  : 'Đang giao hàng',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () {
              // Use UUID if available, otherwise fall back to int ID
              final transactionId = transaction.transactionIdUuid ??
                  transaction.transactionId.toString();
              context.pushNamed(
                AppRoutes.orderDetailName,
                pathParameters: {'id': transactionId},
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primaryGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Chi tiết',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    } else {
      // Completed, Rejected, Cancelled
      return Row(
        children: [
          Expanded(
            child: Text(
              _getStatusDisplay(status),
              style: AppTextStyles.bodySmall.copyWith(
                color: _getStatusColor(status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () {
              // Use UUID if available, otherwise fall back to int ID
              final transactionId = transaction.transactionIdUuid ??
                  transaction.transactionId.toString();
              context.pushNamed(
                AppRoutes.orderDetailName,
                pathParameters: {'id': transactionId},
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Chi tiết',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }
  }

  String _getStatusDisplay(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'Chờ duyệt';
      case TransactionStatus.accepted:
        return 'Đã chấp nhận';
      case TransactionStatus.rejected:
        return 'Từ chối';
      case TransactionStatus.inProgress:
        return 'Đang giao';
      case TransactionStatus.completed:
        return 'Hoàn thành';
      case TransactionStatus.cancelled:
        return 'Đã hủy';
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return const Color(0xFFFFA726); // Orange
      case TransactionStatus.accepted:
        return AppColors.primaryGreen;
      case TransactionStatus.rejected:
        return Colors.red;
      case TransactionStatus.inProgress:
        return Colors.cyan;
      case TransactionStatus.completed:
        return AppColors.success;
      case TransactionStatus.cancelled:
        return Colors.grey;
    }
  }
}
