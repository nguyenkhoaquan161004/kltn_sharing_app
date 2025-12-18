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
    final h = _remainingTime.inHours;
    final m = _remainingTime.inMinutes % 60;
    final s = _remainingTime.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ??
          () {
            context.push('/item/${widget.item.itemId}');
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
                // Image placeholder
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    color: Colors.grey[200],
                  ),
                  child: Center(
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
                      MockData.getCategoryById(widget.item.categoryId)?.name ??
                          'Khác',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Price
                    Text(
                      widget.item.price == 0
                          ? 'Miễn phí'
                          : '${widget.item.price.toStringAsFixed(0)} VNĐ',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTeal,
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
