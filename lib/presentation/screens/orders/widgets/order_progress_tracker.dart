import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OrderProgressTracker extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const OrderProgressTracker({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Progress Line
          Row(
            children: List.generate(steps.length, (index) {
              final isActive = index < currentStep;
              // final isCurrent = index == currentStep - 1; // Not used yet

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primaryTeal
                              : AppColors.borderGray,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primaryTeal
                              : AppColors.borderGray,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Step Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final isActive = index < currentStep;
              final isCurrent = index == currentStep - 1;

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primaryTeal
                            : AppColors.borderGray,
                        shape: BoxShape.circle,
                      ),
                      child: isActive
                          ? const Icon(
                              Icons.check,
                              color: AppColors.white,
                              size: 20,
                            )
                          : isCurrent
                              ? const Icon(
                                  Icons.radio_button_checked,
                                  color: AppColors.white,
                                  size: 20,
                                )
                              : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.normal,
                        color: isActive
                            ? AppColors.primaryTeal
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
