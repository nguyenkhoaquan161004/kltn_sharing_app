import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/mock_data.dart';
import 'widgets/item_request_modal.dart';

class CartAllScreen extends StatefulWidget {
  const CartAllScreen({super.key});

  @override
  State<CartAllScreen> createState() => _CartAllScreenState();
}

class _CartAllScreenState extends State<CartAllScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            labelColor: AppColors.primaryTeal,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryTeal,
            labelStyle:
                AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            unselectedLabelStyle: AppTextStyles.bodyMedium,
            tabs: const [
              Tab(text: 'Giỏ hàng'),
              Tab(text: 'Chờ duyệt'),
              Tab(text: 'Đã duyệt'),
            ],
          ),
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCartTab(),
                _buildProcessingTab(),
                _buildDoneTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartTab() {
    final cartItems =
        MockData.items.where((item) => item.status == 'available').toList();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        _buildOrderSection('Giỏ hàng', cartItems.length, 'cart', cartItems),
      ],
    );
  }

  Widget _buildProcessingTab() {
    final processingItems =
        MockData.items.where((item) => item.status == 'pending').toList();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        _buildOrderSection(
            'Chờ duyệt', processingItems.length, 'processing', processingItems),
      ],
    );
  }

  Widget _buildDoneTab() {
    final doneItems =
        MockData.items.where((item) => item.status == 'shared').toList();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        _buildOrderSection('Đã duyệt', doneItems.length, 'done', doneItems),
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

  Widget _buildOrderCard(String type, dynamic item) {
    final itemId = item.itemId.toString();

    // Get seller info for cart items
    final seller = MockData.users.firstWhere(
      (u) => u.userId == item.userId,
      orElse: () => MockData.users.first,
    );

    return GestureDetector(
      onTap: () {
        if (type == 'cart') {
          context.pushNamed(
            AppRoutes.cartItemDetailName,
            pathParameters: {'id': itemId},
          );
        } else if (type == 'processing' || type == 'done') {
          context.pushNamed(
            AppRoutes.orderDetailName,
            pathParameters: {'id': itemId},
          );
        }
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
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://via.placeholder.com/60',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name ?? 'Product Name',
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.price ?? 0} VND',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'x${item.quantity ?? 1}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
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
            // Status or buttons
            if (type == 'cart')
              Row(
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
                      side: BorderSide(color: AppColors.primaryTeal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Chi tiết',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryTeal,
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
      ),
    );
  }
}
