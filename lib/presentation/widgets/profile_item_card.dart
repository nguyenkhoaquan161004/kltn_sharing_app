import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/item_model.dart';
import '../../data/mock_data.dart';

class ProfileItemCard extends StatefulWidget {
  final ItemModel item;
  final VoidCallback? onTap;
  final bool showTimeRemaining;
  final bool isOwnProfile;
  final int interestedCount;
  final String? unavailableType; // 'shared' or 'expired' for unavailable items

  const ProfileItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.showTimeRemaining = true,
    this.isOwnProfile = false,
    this.interestedCount = 0,
    this.unavailableType,
  });

  @override
  State<ProfileItemCard> createState() => _ProfileItemCardState();
}

class _ProfileItemCardState extends State<ProfileItemCard> {
  late Duration _remainingTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    if (widget.showTimeRemaining) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateRemainingTime();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemainingTime() {
    if (widget.item.expirationDate != null) {
      _remainingTime = widget.item.expirationDate!.difference(DateTime.now());
      if (mounted && _remainingTime.isNegative) {
        _timer?.cancel();
      }
      if (mounted) setState(() {});
    }
  }

  String get _formattedTime {
    if (_remainingTime.isNegative) return 'Hết hạn';
    final h = _remainingTime.inHours;
    final m = _remainingTime.inMinutes % 60;
    final s = _remainingTime.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = widget.item.expirationDate != null &&
        widget.item.expirationDate!.isBefore(DateTime.now());
    final isShared = widget.item.status == '2'; // 2 = shared status
    final isExpiredShared = isExpired && isShared && !widget.isOwnProfile;
    final opacity = isExpiredShared ? 0.6 : 1.0;

    // Colors for unavailable items
    Color? unavailableBorderColor;
    Color? unavailableBackgroundColor;
    if (widget.unavailableType == 'shared') {
      unavailableBorderColor = AppColors.success.withOpacity(0.3);
      unavailableBackgroundColor = AppColors.success.withOpacity(0.05);
    } else if (widget.unavailableType == 'expired') {
      unavailableBorderColor = AppColors.warning.withOpacity(0.3);
      unavailableBackgroundColor = AppColors.warning.withOpacity(0.05);
    }

    return GestureDetector(
      onTap: widget.onTap ??
          () {
            context.push('/item/${widget.item.itemId}');
          },
      child: Opacity(
        opacity: opacity,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.unavailableType != null
                ? unavailableBackgroundColor
                : (isExpiredShared ? Colors.grey[100] : Colors.white),
            border: Border.all(
              color: widget.unavailableType != null
                  ? unavailableBorderColor!
                  : (isExpiredShared
                      ? Colors.grey[300]!
                      : const Color(0xFFE0E0E0)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with tags overlay
              Stack(
                children: [
                  // Image placeholder
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      color:
                          isExpiredShared ? Colors.grey[300] : Colors.grey[200],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.image,
                        size: 48,
                        color: isExpiredShared
                            ? Colors.grey[400]
                            : Colors.grey[400],
                      ),
                    ),
                  ),

                  // Free tag at top left (for user profile) and interested/time at top right
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          // Free tag (if price is 0 and not own profile - user view)
                          if (!widget.isOwnProfile && widget.item.price == 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.badgePink,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '0đ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const Spacer(),
                          // Column for interested badge and time for own profile
                          if (widget.isOwnProfile)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Interested badge for own profile - expanded
                                if (widget.interestedCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryTeal,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${widget.interestedCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const Text(
                                          ' quan tâm',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                // Time remaining for own profile
                                if (widget.showTimeRemaining &&
                                    widget.item.expirationDate != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _remainingTime.isNegative
                                          ? Colors.red
                                          : Colors.orange,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _formattedTime,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          // Time remaining for user profile (not own profile)
                          if (!widget.isOwnProfile &&
                              widget.showTimeRemaining &&
                              widget.item.expirationDate != null)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _remainingTime.isNegative
                                    ? Colors.red
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _formattedTime,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item name
                      Text(
                        widget.item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isExpiredShared
                              ? Colors.grey[600]
                              : AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Category
                      Text(
                        MockData.getCategoryById(widget.item.categoryId)
                                ?.name ??
                            'Khác',
                        style: TextStyle(
                          fontSize: 11,
                          color: isExpiredShared
                              ? Colors.grey[500]
                              : Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Price
                      Text(
                        widget.item.price == 0
                            ? 'Miễn phí'
                            : '${widget.item.price.toStringAsFixed(0)} VNĐ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isExpiredShared
                              ? Colors.grey[400]
                              : AppColors.primaryTeal,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Expiration date
                      if (widget.item.expirationDate != null)
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 12,
                              color: isExpiredShared
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Hết hạn: ${widget.item.expirationDate!.day}/${widget.item.expirationDate!.month}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isExpiredShared
                                    ? Colors.grey[500]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),

                      const Spacer(),

                      // Quantity remaining
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 14,
                            color: isExpiredShared
                                ? Colors.grey[500]
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Còn ${widget.item.quantity}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isExpiredShared
                                  ? Colors.grey[500]
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
