import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_status.dart';
import '../../../data/services/transaction_api_service.dart';
import '../../../data/services/message_api_service.dart';
import '../../../data/services/report_api_service.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/user_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final String transactionId;

  const OrderDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late TransactionApiService _transactionApiService;
  late MessageApiService _messageApiService;
  late ReportApiService _reportApiService;
  TransactionModel? _transaction;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _transactionApiService = TransactionApiService();
    _messageApiService = MessageApiService();
    _reportApiService = ReportApiService();

    // Setup auth token and load transaction detail
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.accessToken != null) {
        _transactionApiService.setAuthToken(authProvider.accessToken!);
        _transactionApiService.setGetValidTokenCallback(
          () async => authProvider.accessToken,
        );

        _messageApiService.setAuthToken(authProvider.accessToken!);
        _messageApiService.setGetValidTokenCallback(
          () async => authProvider.accessToken,
        );

        _reportApiService.setAuthToken(authProvider.accessToken!);
        _reportApiService.setGetValidTokenCallback(
          () async => authProvider.accessToken,
        );
      }

      _loadTransactionDetail();
    });
  }

  Future<void> _loadTransactionDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // The transactionId can be either a UUID string or integer
      // The API expects the UUID string format
      final transaction = await _transactionApiService.getTransactionDetail(
        widget.transactionId,
      );

      setState(() {
        _transaction = transaction;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      print('[OrderDetailScreen] Error loading transaction: $e');
    }
  }

  Future<void> _handleCompleteTransaction() async {
    if (_transaction == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận nhận hàng'),
        content: const Text('Bạn chắc chắn đã nhận được hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Có, đã nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Call complete API
    try {
      await _transactionApiService.completeTransaction(
          _transaction!.transactionIdUuid ??
              _transaction!.transactionId.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đơn hàng đã được đánh dấu hoàn thành'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload transaction to update status
        _loadTransactionDetail();
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
    }
  }

  Future<void> _handleSendMessage() async {
    if (_transaction == null) return;

    try {
      final txn = _transaction!;
      final userProvider = context.read<UserProvider>();
      final currentUserId = userProvider.currentUser?.id;

      // Determine message receiver based on current user role (using UUID)
      String receiverId;
      String messageContent;

      if (currentUserId != null &&
          txn.sharerIdUuid != null &&
          currentUserId == txn.sharerIdUuid) {
        // Current user is the sharer
        receiverId = txn.receiverIdUuid ?? txn.receiverId.toString();
        messageContent = 'Chào bạn, tôi muốn thảo luận về đơn hàng';
      } else {
        // Current user is the receiver
        receiverId = txn.sharerIdUuid ?? txn.sharerId.toString();
        messageContent = 'Xin chào, tôi đang quan tâm đến đơn hàng này.';
      }

      final itemId = txn.itemIdUuid ?? txn.itemId.toString();

      // Check if conversation already exists
      try {
        final existingMessages = await _messageApiService.getConversation(
          otherUserId: receiverId,
          limit: 1,
        );

        // If conversation exists, just navigate to chat without sending message
        if (existingMessages.isNotEmpty) {
          if (mounted) {
            context.push('/chat/$receiverId');
          }
          return;
        }
      } catch (e) {
        // If checking conversation fails, continue to send message
        print('[OrderDetailScreen] Could not check conversation: $e');
      }

      // No existing conversation, send new message
      await _messageApiService.sendMessage(
        receiverId: receiverId,
        content: messageContent,
        messageType: 'TEXT',
        itemId: itemId,
      );

      if (mounted) {
        // Navigate directly to chat screen
        context.push('/chat/$receiverId');
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
      print('[OrderDetailScreen] Error sending message: $e');
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage ?? 'Có lỗi xảy ra',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadTransactionDetail,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_transaction == null) {
      return Center(
        child: Text(
          'Không tìm thấy đơn hàng',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller info (hide for accepted/inProgress status - chuẩn bị giao hàng)
          if (_transaction!.status != TransactionStatus.accepted &&
              _transaction!.status != TransactionStatus.inProgress) ...[
            _buildSellerSection(),
            const SizedBox(height: 24),
          ],

          // Products
          _buildProductSection(),
          const SizedBox(height: 24),

          // Receiver info (for inProgress or accepted status)
          if (_transaction!.status == TransactionStatus.inProgress ||
              _transaction!.status == TransactionStatus.accepted) ...[
            _buildReceiverSection(),
            const SizedBox(height: 24),
          ],

          // Order timeline
          _buildTimelineSection(),
          const SizedBox(height: 24),

          // Payment info
          _buildPaymentSection(),
          const SizedBox(height: 24),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSellerSection() {
    final txn = _transaction!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: GestureDetector(
        onTap: () {
          // Navigate to seller profile using UUID if available
          final sharerId = txn.sharerIdUuid ?? txn.sharerId.toString();
          context.push(
            AppRoutes.getUserProfileRoute(sharerId),
          );
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
              child: txn.sharerAvatar != null
                  ? Image.network(txn.sharerAvatar!, fit: BoxFit.cover)
                  : const Icon(Icons.person),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.sharerName ?? 'Không rõ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Người chia sẻ',
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
    );
  }

  Widget _buildReceiverSection() {
    final txn = _transaction!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              borderRadius: BorderRadius.circular(25),
            ),
            child: txn.receiverAvatar != null
                ? Image.network(txn.receiverAvatar!, fit: BoxFit.cover)
                : const Icon(Icons.person),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.receiverName ?? 'Không rõ',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Người nhận',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection() {
    final txn = _transaction!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              // Navigate to product detail using UUID string if available
              final productId = txn.itemIdUuid ?? txn.itemId.toString();
              context.push(
                AppRoutes.getProductDetailRoute(productId),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    image: txn.itemImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(txn.itemImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: txn.itemImageUrl == null
                      ? Icon(Icons.image, color: Colors.grey[400])
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        txn.itemName ?? 'Sản phẩm',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'x${txn.quantity ?? 1}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(txn.status),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusDisplay(txn.status),
                          style: AppTextStyles.caption.copyWith(
                            color: _getStatusColor(txn.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineSection() {
    final txn = _transaction!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quá trình đơn hàng',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildTimeline(txn.status),
      ],
    );
  }

  Widget _buildTimeline(TransactionStatus status) {
    // Determine which steps are completed based on status
    bool step1Completed = true; // Đã đặt hàng - always completed
    bool step2Completed = status == TransactionStatus.accepted ||
        status == TransactionStatus.inProgress ||
        status == TransactionStatus.completed;
    bool step3Completed = status == TransactionStatus.accepted ||
        status == TransactionStatus.inProgress ||
        status == TransactionStatus.completed;
    bool step4Completed = status == TransactionStatus.completed;

    return Column(
      children: [
        Row(
          children: [
            _buildTimelinePoint(step1Completed),
            Expanded(
              child: Container(
                height: 3,
                color:
                    step2Completed ? AppColors.success : AppColors.borderLight,
              ),
            ),
            _buildTimelinePoint(step2Completed),
            Expanded(
              child: Container(
                height: 3,
                color:
                    step3Completed ? AppColors.success : AppColors.borderLight,
              ),
            ),
            _buildTimelinePoint(step3Completed),
            Expanded(
              child: Container(
                height: 3,
                color:
                    step4Completed ? AppColors.success : AppColors.borderLight,
              ),
            ),
            _buildTimelinePoint(step4Completed),
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
                fontWeight:
                    step2Completed ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            Text(
              'Đã duyệt',
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                fontWeight:
                    step3Completed ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            Text(
              'Hoàn thành',
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                fontWeight:
                    step4Completed ? FontWeight.w600 : FontWeight.normal,
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

  Widget _buildPaymentSection() {
    final txn = _transaction!;
    final quantity = txn.quantity ?? 1;
    final amount = txn.transactionFee ?? 0.0;
    final itemTotal = amount * quantity;
    final shippingFee = 0.0;
    final totalPrice = itemTotal + shippingFee;

    String formatPrice(double price) {
      return '${price.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          )} VND';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              _buildPaymentRow('Số tiền', formatPrice(itemTotal)),
              const SizedBox(height: 8),
              _buildPaymentRow('Phí vận chuyển', formatPrice(shippingFee)),
              const Divider(height: 16),
              _buildPaymentRow(
                'Tổng tiền',
                formatPrice(totalPrice),
                isTotal: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleReportTransaction() {
    if (_transaction == null) return;

    final txn = _transaction!;

    // Show report dialog with category selection
    showDialog(
      context: context,
      builder: (context) => _ReportDialog(
        transactionId: txn.transactionIdUuid ?? txn.transactionId.toString(),
        transactionName: txn.itemName ?? 'Giao dịch',
        onSubmit: _submitReport,
      ),
    );
  }

  Future<void> _submitReport({
    required String category,
    required String description,
  }) async {
    if (_transaction == null) return;

    try {
      final txn = _transaction!;

      // Create report
      await _reportApiService.createReport(
        type: 'TRANSACTION', // This is a transaction report
        category: category,
        description: description,
        targetId: txn.transactionIdUuid ?? txn.transactionId.toString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Báo cáo đã được gửi. Cảm ơn bạn!'),
            backgroundColor: Colors.green,
          ),
        );
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
      print('[OrderDetailScreen] Error reporting transaction: $e');
    }
  }

  Widget _buildActionButtons() {
    final txn = _transaction!;
    final status = txn.status;
    final userProvider = context.read<UserProvider>();
    final currentUserId = userProvider.currentUser?.id;

    print('[OrderDetailScreen] DEBUG - currentUserId: $currentUserId');
    print('[OrderDetailScreen] DEBUG - sharerIdUuid: ${txn.sharerIdUuid}');
    print('[OrderDetailScreen] DEBUG - receiverIdUuid: ${txn.receiverIdUuid}');

    // Check if current user is the sharer or receiver (compare with UUID)
    final isSharer = currentUserId != null &&
        txn.sharerIdUuid != null &&
        currentUserId == txn.sharerIdUuid;
    final isReceiver = currentUserId != null &&
        txn.receiverIdUuid != null &&
        currentUserId == txn.receiverIdUuid;

    print(
        '[OrderDetailScreen] DEBUG - isSharer: $isSharer, isReceiver: $isReceiver');

    // PENDING: "Hủy đơn hàng" + "Nhắn tin"
    if (status == TransactionStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _showCancelConfirmDialog,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color.fromARGB(255, 188, 26, 26)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Hủy đơn hàng',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color.fromARGB(255, 188, 26, 26),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _handleSendMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Nhắn tin',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }
    // ACCEPTED: Different buttons based on user role
    else if (status == TransactionStatus.accepted) {
      // If current user is the receiver -> "Nhắn tin" + "Báo cáo"
      if (isReceiver) {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _handleSendMessage,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Nhắn tin',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleReportTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Báo cáo',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      }
      // If current user is the sharer -> "Nhắn tin" + "Hoàn tất đơn hàng"
      else if (isSharer) {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _handleSendMessage,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Nhắn tin',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleCompleteTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Hoàn tất đơn hàng',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      }
      // Fallback for unknown role
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _handleSendMessage,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Nhắn tin',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _handleCompleteTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Hoàn tất đơn hàng',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }
    // IN_PROGRESS: "Nhắn tin" + "Hoàn tất đơn hàng"
    else if (status == TransactionStatus.inProgress) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _handleSendMessage,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Nhắn tin',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _handleCompleteTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Hoàn tất đơn hàng',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // No actions for completed, rejected, or cancelled transactions
    return const SizedBox.shrink();
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

  String _getStatusDisplay(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'Chờ duyệt';
      case TransactionStatus.accepted:
        return 'Đã duyệt';
      case TransactionStatus.inProgress:
        return 'Đang giao dịch';
      case TransactionStatus.completed:
        return 'Hoàn thành';
      case TransactionStatus.rejected:
        return 'Từ chối';
      case TransactionStatus.cancelled:
        return 'Hủy';
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.accepted:
      case TransactionStatus.inProgress:
        return Colors.blue;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.rejected:
      case TransactionStatus.cancelled:
        return Colors.red;
    }
  }

  Color _getStatusBgColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Colors.orange.withOpacity(0.1);
      case TransactionStatus.accepted:
      case TransactionStatus.inProgress:
        return Colors.blue.withOpacity(0.1);
      case TransactionStatus.completed:
        return Colors.green.withOpacity(0.1);
      case TransactionStatus.rejected:
      case TransactionStatus.cancelled:
        return Colors.red.withOpacity(0.1);
    }
  }

  void _showCancelConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Hủy đơn hàng',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
          ),
          content: Text(
            'Bạn có chắc muốn hủy đơn hàng này chứ?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Không',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelTransaction();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: Text(
                'Hủy đơn',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelTransaction() async {
    if (_transaction == null) return;

    try {
      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Call API to cancel transaction
      final txnId = _transaction!.transactionIdUuid ??
          _transaction!.transactionId.toString();
      await _transactionApiService.cancelTransaction(txnId);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đơn hàng đã được hủy thành công'),
          backgroundColor: Colors.green,
        ),
      );

      // Pop back to cart_all_screen with delay to allow snackbar to show
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

/// Report Dialog Widget for submitting transaction reports
class _ReportDialog extends StatefulWidget {
  final String transactionId;
  final String transactionName;
  final Function({required String category, required String description})
      onSubmit;

  const _ReportDialog({
    required this.transactionId,
    required this.transactionName,
    required this.onSubmit,
  });

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String? _selectedCategory;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  String? _descriptionError;

  // Transaction-related report categories
  final Map<String, String> _categories = {
    'ITEM_NOT_RECEIVED': 'Chưa nhận được hàng',
    'ITEM_NOT_AS_DESCRIBED': 'Hàng không như mô tả',
    'DAMAGED_ITEM': 'Hàng bị hư hỏng',
    'WRONG_ITEM': 'Gửi nhầm hàng',
    'NO_SHOW': 'Người gửi không xuất hiện',
    'PAYMENT_ISSUE': 'Vấn đề về thanh toán',
  };

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_validateDescription);
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_validateDescription);
    _descriptionController.dispose();
    super.dispose();
  }

  void _validateDescription() {
    final text = _descriptionController.text;
    setState(() {
      if (text.isEmpty) {
        _descriptionError = 'Mô tả không được để trống';
      } else if (text.length < 10) {
        _descriptionError =
            'Mô tả phải có ít nhất 10 ký tự (hiện tại: ${text.length})';
      } else if (text.length > 2000) {
        _descriptionError = 'Mô tả không được vượt quá 2000 ký tự';
      } else {
        _descriptionError = null;
      }
    });
  }

  bool _isFormValid() {
    return _selectedCategory != null &&
        _descriptionController.text.length >= 10 &&
        _descriptionController.text.length <= 2000;
  }

  void _handleSubmit() async {
    if (!_isFormValid()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn lý do báo cáo'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(
        category: _selectedCategory!,
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Báo cáo giao dịch',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Giao dịch: ${widget.transactionName}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),

                // Category Dropdown
                Text(
                  'Lý do báo cáo',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Chọn lý do',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    value: _selectedCategory,
                    underline: const SizedBox.shrink(),
                    items: _categories.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(entry.value),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategory = value);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Description TextField
                Text(
                  'Mô tả chi tiết (tối thiểu 10 ký tự)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  minLines: 4,
                  maxLength: 2000,
                  onChanged: (_) => _validateDescription(),
                  decoration: InputDecoration(
                    hintText: 'Mô tả chi tiết về vấn đề...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _descriptionError != null
                            ? Colors.red
                            : AppColors.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _descriptionError != null
                            ? Colors.red
                            : AppColors.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _descriptionError != null
                            ? Colors.red
                            : AppColors.primaryGreen,
                        width: 2,
                      ),
                    ),
                    counterText: '',
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
                if (_descriptionError != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _descriptionError!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mô tả hợp lệ',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isSubmitting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.borderLight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Hủy',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting || !_isFormValid()
                            ? null
                            : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isFormValid() ? Colors.red : Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Báo cáo',
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
        ),
      ),
    );
  }
}
