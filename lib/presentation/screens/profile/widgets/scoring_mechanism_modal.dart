import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class ScoringMechanismModal extends StatelessWidget {
  const ScoringMechanismModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cơ chế tính điểm',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _buildPointsTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cách kiếm điểm',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Main actions
          _buildPointSection(
            title: 'Giao dịch chính',
            items: [
              _PointItem(
                icon: Icons.send,
                title: 'Chia sẻ sản phẩm',
                points: '+10',
                description: 'Khi tạo một sản phẩm mới',
                color: Colors.blue,
              ),
              _PointItem(
                icon: Icons.check_circle,
                title: 'Người bán hoàn thành giao dịch',
                points: '+50',
                description: 'Khi giao dịch được xác nhận',
                color: Colors.green,
              ),
              _PointItem(
                icon: Icons.shopping_bag,
                title: 'Người nhận hoàn thành giao dịch',
                points: '+20',
                description: 'Khi nhận được sản phẩm',
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Interaction actions
          _buildPointSection(
            title: 'Tương tác (Hàng ngày)',
            items: [
              _PointItem(
                icon: Icons.visibility,
                title: 'Xem sản phẩm',
                points: '+1',
                description: 'Mỗi lần xem (tối đa 10 lần/ngày = 10 điểm)',
                color: Colors.purple,
              ),
              _PointItem(
                icon: Icons.message,
                title: 'Gửi tin nhắn',
                points: '+5',
                description: 'Mỗi tin nhắn (tối đa 2 tin/ngày = 10 điểm)',
                color: Colors.pink,
              ),
              _PointItem(
                icon: Icons.shopping_cart,
                title: 'Thêm vào giỏ hàng',
                points: '+2',
                description: 'Mỗi lần thêm (tối đa 10 lần/ngày = 20 điểm)',
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryTeal, width: 0.5),
            ),
            child: Text(
              '💡 Lưu ý: Điểm tương tác hàng ngày có giới hạn để ngăn chặn spam',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointSection({
    required String title,
    required List<_PointItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryTeal,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          items.length,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index < items.length - 1 ? 12 : 0),
            child: _buildPointItemWidget(items[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildPointItemWidget(_PointItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.icon,
              color: item.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.points,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: item.color,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: AppTextStyles.caption.copyWith(
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
}

class _PointItem {
  final IconData icon;
  final String title;
  final String points;
  final String description;
  final Color color;

  _PointItem({
    required this.icon,
    required this.title,
    required this.points,
    required this.description,
    required this.color,
  });
}
