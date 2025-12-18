import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class ExpandableDescription extends StatefulWidget {
  final String text;
  final int maxLines;

  const ExpandableDescription({
    super.key,
    required this.text,
    this.maxLines = 3,
  });

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    if (_isExpanded) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mô tả sản phẩm', style: AppTextStyles.h4),
        const SizedBox(height: 12),

        // Animated container for description
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Stack(
            children: [
              // Text content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.text,
                    maxLines: _isExpanded ? null : widget.maxLines,
                    overflow: _isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 12),
                ],
              ),

              // Gradient overlay (when collapsed)
              if (!_isExpanded)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.backgroundWhite.withOpacity(0),
                          AppColors.backgroundWhite.withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Show "View more" button only if text is long enough
        if (widget.text.split('\n').length > widget.maxLines ||
            widget.text.length > 100)
          GestureDetector(
            onTap: _toggleExpanded,
            child: Container(
              width: double.infinity, // 👈 FULL WIDTH
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryTeal.withOpacity(0.1),
                    AppColors.primaryTeal.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryTeal.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center, // 👈 căn giữa nội dung
                children: [
                  Text(
                    _isExpanded ? 'Thu gọn' : 'Xem thêm',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.expand_more,
                      color: AppColors.primaryTeal,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          )
      ],
    );
  }
}
