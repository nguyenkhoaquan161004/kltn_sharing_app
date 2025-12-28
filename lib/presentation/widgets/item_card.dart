import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/item_model.dart';
import '../../data/mock_data.dart';

class ItemCard extends StatefulWidget {
  final ItemModel item;
  final VoidCallback? onTap;
  final bool showTimeRemaining;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.showTimeRemaining = true,
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  late Duration _remainingTime;
  late Timer? _timer;

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

    final days = _remainingTime.inDays;
    if (days > 0) {
      return '$days ngày';
    }

    final h = _remainingTime.inHours;
    final m = _remainingTime.inMinutes % 60;
    final s = _remainingTime.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatPrice(double price) {
    if (price == 0) return 'Miễn phí';

    final formatted = price.toStringAsFixed(0);
    // Add thousand separators with dots
    final buffer = StringBuffer();
    final reversed = formatted.split('').reversed.toList();

    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(reversed[i]);
    }

    return buffer.toString().split('').reversed.join() + ' VNĐ';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ??
          () {
            // Use UUID string (itemId_str) if available, otherwise fallback to itemId
            final itemId =
                widget.item.itemId_str ?? widget.item.itemId.toString();
            context.push('/item/$itemId');
          },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
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
                // Image placeholder or actual image
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    color: Colors.grey[200],
                  ),
                  child: widget.item.image != null &&
                          widget.item.image!.isNotEmpty
                      ? Image.network(
                          widget.item.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                ),

                // Free tag at top left (if price is 0) and Time remaining at top right
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        // Free tag (if price is 0)
                        if (widget.item.price == 0)
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
                        // Time remaining tag (if applicable)
                        if (widget.showTimeRemaining &&
                            widget.item.expirationDate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
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
                                fontSize: 10,
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
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item name
                    Text(
                      widget.item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 3),

                    // Category
                    Text(
                      widget.item.categoryName ??
                          MockData.getCategoryById(
                                  widget.item.categoryId.hashCode)
                              ?.name ??
                          'Khác',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Price
                    Text(
                      _formatPrice(widget.item.price),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),

                    const Spacer(),

                    // Quantity remaining
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Còn ${widget.item.quantity}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
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
    );
  }
}
