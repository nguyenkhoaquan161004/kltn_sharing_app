import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/services/cloudinary_service.dart';
import '../../../../data/services/user_api_service.dart';
import '../../../../data/models/update_profile_request.dart';
import '../../../../data/providers/auth_provider.dart';

class EditProfileModal extends StatefulWidget {
  final String? currentName;
  final String? currentEmail;
  final String? currentAddress;
  final String? currentPhone;
  final String? currentAvatar;
  final DateTime? currentBirthDate;
  final VoidCallback? onProfileUpdated;

  const EditProfileModal({
    super.key,
    this.currentName,
    this.currentEmail,
    this.currentAddress,
    this.currentPhone,
    this.currentAvatar,
    this.currentBirthDate,
    this.onProfileUpdated,
  });

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  late TextEditingController _nameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  DateTime? _selectedBirthDate;
  String? _avatarUrl;
  File? _selectedImageFile;
  bool _isLoading = false;
  String? _errorMessage;
  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName ?? '');
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _addressController =
        TextEditingController(text: widget.currentAddress ?? '');
    _phoneController = TextEditingController(text: widget.currentPhone ?? '');
    _selectedBirthDate = widget.currentBirthDate;
    _avatarUrl = widget.currentAvatar;

    // Parse current name to first and last name if available
    if (widget.currentName != null && widget.currentName!.isNotEmpty) {
      final names = widget.currentName!.split(' ');
      if (names.isNotEmpty) {
        _lastNameController.text = names.first;
        if (names.length > 1) {
          _firstNameController.text = names.sublist(1).join(' ');
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  Future<void> _selectAvatar() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _isUploadingImage = true;
        });

        try {
          // Upload to Cloudinary
          final uploadedImageUrl =
              await _cloudinaryService.uploadUserAvatar(_selectedImageFile!);

          setState(() {
            _avatarUrl = uploadedImageUrl;
            _isUploadingImage = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ảnh đã được tải lên thành công!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          setState(() {
            _isUploadingImage = false;
            _errorMessage =
                'Lỗi tải ảnh: ${e.toString().replaceAll('Exception: ', '')}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveProfile() async {
    // Fill empty fields with current data
    String firstName = _firstNameController.text.isNotEmpty
        ? _firstNameController.text
        : (widget.currentName?.split(' ').length == 2
            ? widget.currentName!.split(' ')[1]
            : '');
    String lastName = _lastNameController.text.isNotEmpty
        ? _lastNameController.text
        : (widget.currentName?.split(' ').isNotEmpty == true
            ? widget.currentName!.split(' ')[0]
            : '');
    String address = _addressController.text.isNotEmpty
        ? _addressController.text
        : (widget.currentAddress ?? '');
    String phone = _phoneController.text.isNotEmpty
        ? _phoneController.text
        : (widget.currentPhone ?? '');
    DateTime? birthDate = _selectedBirthDate ?? widget.currentBirthDate;
    String? avatarUrl = _avatarUrl ?? widget.currentAvatar;

    // Check if all fields are empty
    if (firstName.isEmpty &&
        lastName.isEmpty &&
        address.isEmpty &&
        phone.isEmpty &&
        birthDate == null) {
      setState(() =>
          _errorMessage = 'Vui lòng nhập ít nhất một thông tin để cập nhật');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get auth provider for token
      final authProvider = context.read<AuthProvider>();

      // Create update request with filled data
      final updateRequest = UpdateProfileRequest(
        firstName: firstName.isNotEmpty ? firstName : null,
        lastName: lastName.isNotEmpty ? lastName : null,
        avatarUrl: avatarUrl,
        birthDate: birthDate,
        address: address.isNotEmpty ? address : null,
        phone: phone.isNotEmpty ? phone : null,
      );

      // Create API service
      final userApiService = UserApiService();

      // Set auth token if available
      if (authProvider.accessToken != null) {
        userApiService.setAuthToken(authProvider.accessToken!);
      }

      // Call API
      await userApiService.updateProfile(updateRequest);

      setState(() => _isLoading = false);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Call callback to refresh profile data
        widget.onProfileUpdated?.call();

        // Close the modal after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      print('Error updating profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chỉnh sửa thông tin',
                  style: AppTextStyles.h3,
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Avatar section
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryTeal,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? Image.network(
                              _avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.backgroundGray,
                                  child: const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: AppColors.textSecondary,
                                  ),
                                );
                              },
                            )
                          : _selectedImageFile != null && !_isUploadingImage
                              ? Image.file(
                                  _selectedImageFile!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: AppColors.backgroundGray,
                                  child: const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                    ),
                  ),
                  // Loading indicator during upload
                  if (_isUploadingImage)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.3),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: GestureDetector(
                      onTap: _selectAvatar,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryTeal,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: Colors.red.shade700),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Form fields
            // Last name
            const Text('Họ', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                hintText: 'Nhập họ',
                filled: true,
                fillColor: AppColors.backgroundGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // First name
            const Text('Tên và tên đệm', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                hintText: 'Nhập tên',
                filled: true,
                fillColor: AppColors.backgroundGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Birth date
            const Text('Ngày sinh', style: AppTextStyles.label),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectBirthDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedBirthDate != null
                          ? DateFormat('dd/MM/yyyy').format(_selectedBirthDate!)
                          : 'Chọn ngày sinh',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _selectedBirthDate != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Address
            const Text('Địa chỉ', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Nhập địa chỉ',
                filled: true,
                fillColor: AppColors.backgroundGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Phone
            const Text('Số điện thoại', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Nhập số điện thoại',
                filled: true,
                fillColor: AppColors.backgroundGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 28),

            // Buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.borderLight,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Save button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      disabledBackgroundColor:
                          AppColors.primaryTeal.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Lưu',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
