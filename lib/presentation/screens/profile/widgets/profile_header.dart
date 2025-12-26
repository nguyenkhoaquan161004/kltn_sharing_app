import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final int? trustScore; // Nullable - có thể null từ API
  final String? avatar;

  const ProfileHeader({
    super.key,
    required this.name,
    this.trustScore,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: (avatar != null && avatar!.isNotEmpty)
                  ? Image.network(avatar!, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.backgroundGray,
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            name,
            style: AppTextStyles.h2.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),

          // Points
          Text(
            '${trustScore ?? 0} điểm uy tín',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
