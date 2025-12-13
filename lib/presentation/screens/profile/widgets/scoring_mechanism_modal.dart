import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class ScoringMechanismModal extends StatelessWidget {
  const ScoringMechanismModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cơ chế tính điểm',
                    style: AppTextStyles.h3,
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Description
              Text(
                'Điểm uy tín được tính dựa trên các hoạt động của bạn:',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Scoring items
              _buildScoringItem(
                icon: Icons.share,
                title: 'Chia sẻ sản phẩm',
                points: '+10 điểm',
                description: 'Mỗi lần chia sẻ sản phẩm',
              ),
              const SizedBox(height: 16),

              _buildScoringItem(
                icon: Icons.star,
                title: 'Đánh giá tích cực',
                points: '+5 điểm',
                description: 'Mỗi lần nhận được đánh giá ⭐⭐⭐⭐⭐',
              ),
              const SizedBox(height: 16),

              _buildScoringItem(
                icon: Icons.done_all,
                title: 'Hoàn thành giao dịch',
                points: '+20 điểm',
                description: 'Mỗi giao dịch được xác nhận thành công',
              ),
              const SizedBox(height: 16),

              _buildScoringItem(
                icon: Icons.access_time,
                title: 'Phản hồi nhanh',
                points: '+3 điểm',
                description: 'Phản hồi trong 1 giờ',
              ),
              const SizedBox(height: 16),

              _buildScoringItem(
                icon: Icons.warning,
                title: 'Vi phạm quy tắc',
                points: '-10 điểm',
                description: 'Mỗi lần vi phạm hoặc báo cáo',
                isNegative: true,
              ),
              const SizedBox(height: 24),

              // Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lưu ý: Điểm uy tín cao hơn = Được người khác tin tưởng nhiều hơn',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Close button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Đã hiểu',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  Widget _buildScoringItem({
    required IconData icon,
    required String title,
    required String points,
    required String description,
    bool isNegative = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isNegative
                ? AppColors.warning.withOpacity(0.1)
                : AppColors.primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isNegative ? AppColors.warning : AppColors.primaryTeal,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    points,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isNegative
                          ? AppColors.warning
                          : AppColors.primaryTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
