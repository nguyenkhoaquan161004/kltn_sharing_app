import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/location_provider.dart';

class LocationPermissionDialog extends StatefulWidget {
  final VoidCallback? onLocationEnabled;
  final VoidCallback? onLocationSkipped;

  const LocationPermissionDialog({
    super.key,
    this.onLocationEnabled,
    this.onLocationSkipped,
  });

  @override
  State<LocationPermissionDialog> createState() =>
      _LocationPermissionDialogState();
}

class _LocationPermissionDialogState extends State<LocationPermissionDialog> {
  bool _isRequesting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Location icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.location_on,
                size: 40,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            // Title
            const Text(
              'Cho phép truy cập vị trí',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Description
            const Text(
              'Chúng tôi cần truy cập vị trí của bạn để tìm kiếm sản phẩm gần nhất và cải thiện trải nghiệm.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Enable button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRequesting
                    ? null
                    : () async {
                        setState(() => _isRequesting = true);
                        try {
                          final locationProvider =
                              context.read<LocationProvider>();
                          await locationProvider
                              .requestLocationPermissionAndGetLocation();

                          if (mounted) {
                            Navigator.pop(context);
                            widget.onLocationEnabled?.call();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e')),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isRequesting = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isRequesting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Cho phép',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            // Skip button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isRequesting
                    ? null
                    : () {
                        Navigator.pop(context);
                        widget.onLocationSkipped?.call();
                      },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: Color(0xFFE0E0E0),
                    ),
                  ),
                ),
                child: const Text(
                  'Bỏ qua',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
