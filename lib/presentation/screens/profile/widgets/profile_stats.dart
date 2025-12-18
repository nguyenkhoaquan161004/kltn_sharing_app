import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class ProfileStats extends StatelessWidget {
  final int productsShared;
  final int productsReceived;

  const ProfileStats({
    super.key,
    required this.productsShared,
    required this.productsReceived,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            value: '$productsShared',
            label: 'Sản phẩm đã chia sẻ',
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: AppColors.borderLight,
        ),
        Expanded(
          child: _buildStatItem(
            value: '$productsReceived',
            label: 'Sản phẩm đã nhận',
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
