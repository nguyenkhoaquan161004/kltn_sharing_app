import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/mock_data.dart';
import '../../../widgets/item_card.dart';
import 'profile_stats.dart';
import 'scoring_mechanism_modal.dart';

class ProfileInfoTab extends StatelessWidget {
  final Map<String, dynamic> userData;
  final bool isOwnProfile;
  final int? userId;

  const ProfileInfoTab({
    super.key,
    required this.userData,
    required this.isOwnProfile,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Stats + Scoring mechanism button (horizontally aligned)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ProfileStats(
                  productsShared: userData['productsShared'],
                  productsReceived: userData['productsReceived'],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 50,
                child: OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const ScoringMechanismModal(),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryTeal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: AppColors.primaryTeal,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Content based on profile type
          if (isOwnProfile)
            // Own profile: Show user info
            _buildOwnProfileContent()
          else
            // Other user's profile: Show products
            _buildOtherUserProfileContent(),
        ],
      ),
    );
  }

  Widget _buildOwnProfileContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thông tin người dùng',
                style: AppTextStyles.h4,
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  // TODO: Navigate to edit profile
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Name
          _buildInfoRow(
            label: 'Tên người dùng',
            value: userData['name'] ?? '',
          ),
          const SizedBox(height: 16),

          // Email
          _buildInfoRow(
            label: 'Email',
            value: userData['email'] ?? '',
          ),
          const SizedBox(height: 16),

          // Address
          _buildInfoRow(
            label: 'Địa chỉ',
            value: userData['address'] ?? '',
          ),
        ],
      ),
    );
  }

  Widget _buildOtherUserProfileContent() {
    // Get products for this user
    final userProducts = userId != null
        ? MockData.items.where((item) => item.userId == userId).toList()
        : [];

    // Split products: free (0 đồng) and paid (suggested)
    final freeProducts = userProducts.where((item) => item.price == 0).toList();
    final suggestedProducts =
        userProducts.where((item) => item.price > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Free products section
        if (freeProducts.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sản phẩm 0 đồng',
                style: AppTextStyles.h4,
              ),
              if (freeProducts.length > 3)
                GestureDetector(
                  onTap: () {
                    // TODO: View all free products
                  },
                  child: Text(
                    'Xem thêm',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.6,
            ),
            itemCount: freeProducts.length > 3 ? 3 : freeProducts.length,
            itemBuilder: (context, index) {
              final product = freeProducts[index];
              return ItemCard(
                item: product,
                showTimeRemaining: true,
              );
            },
          ),
          const SizedBox(height: 32),
        ],

        // Suggested products section
        if (suggestedProducts.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đề xuất cho bạn',
                style: AppTextStyles.h4,
              ),
              if (suggestedProducts.length > 3)
                GestureDetector(
                  onTap: () {
                    // TODO: View all suggested products
                  },
                  child: Text(
                    'Xem thêm',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.6,
            ),
            itemCount:
                suggestedProducts.length > 3 ? 3 : suggestedProducts.length,
            itemBuilder: (context, index) {
              final product = suggestedProducts[index];
              return ItemCard(
                item: product,
                showTimeRemaining: true,
              );
            },
          ),
        ],

        // Empty state
        if (freeProducts.isEmpty && suggestedProducts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Người dùng chưa có sản phẩm',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTextStyles.bodyMedium,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
