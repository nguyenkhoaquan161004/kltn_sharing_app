import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

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
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đơn hàng',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 20),
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
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: AppColors.primaryTeal, width: 3),
            ),
            tabs: const [
              Tab(text: 'Tất cả'),
              Tab(text: 'Giỏ hàng'),
              Tab(text: 'Chờ duyệt'),
              Tab(text: 'Dự...'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllOrdersTab(),
                _buildCartTab(),
                _buildProcessingTab(),
                _buildOtherTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllOrdersTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOrderSection('Giỏ hàng', 1),
        const SizedBox(height: 16),
        _buildOrderSection('Dang chờ duyệt', 3),
        const SizedBox(height: 16),
        _buildOrderSection('Đã được duyệt', 2),
      ],
    );
  }

  Widget _buildCartTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOrderSection('Giỏ hàng', 1),
      ],
    );
  }

  Widget _buildProcessingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOrderSection('Dang chờ duyệt', 3),
      ],
    );
  }

  Widget _buildOtherTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOrderSection('Đã được duyệt', 2),
      ],
    );
  }

  Widget _buildOrderSection(String title, int itemCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Xem tất cả (3)',
                style: TextStyle(color: AppColors.primaryTeal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(
          itemCount,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Product Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '12000 VND',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Đen\nx1',
                          style: TextStyle(
                            fontSize: 12,
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
        ),
      ],
    );
  }
}
