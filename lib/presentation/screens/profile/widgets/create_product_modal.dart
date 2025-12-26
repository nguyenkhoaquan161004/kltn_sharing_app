import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/services/item_api_service.dart';
import '../../../../data/services/cloudinary_service.dart';

class CreateProductModal extends StatefulWidget {
  final Function(bool) onProductCreated; // true = success, false = error

  const CreateProductModal({
    super.key,
    required this.onProductCreated,
  });

  @override
  State<CreateProductModal> createState() => _CreateProductModalState();
}

class _CreateProductModalState extends State<CreateProductModal> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  late ItemApiService _itemApiService;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;

  String _selectedCategory = '';
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;
  String? _selectedImagePath;
  String? _uploadedImageUrl;
  String? _errorMessage;

  // Location
  double? _latitude;
  double? _longitude;

  // Mock categories - should be fetched from API
  final List<Map<String, String>> categories = [
    {'id': '3fa85f64-5717-4562-b3fc-2c963f66afa1', 'name': 'Quần áo'},
    {'id': '3fa85f64-5717-4562-b3fc-2c963f66afa2', 'name': 'Giày dép'},
    {'id': '3fa85f64-5717-4562-b3fc-2c963f66afa3', 'name': 'Điện tử'},
    {'id': '3fa85f64-5717-4562-b3fc-2c963f66afa4', 'name': 'Sách'},
    {'id': '3fa85f64-5717-4562-b3fc-2c963f66afa5', 'name': 'Đồ chơi'},
    {'id': '3fa85f64-5717-4562-b3fc-2c963f66afa6', 'name': 'Nội thất'},
  ];

  @override
  void initState() {
    super.initState();
    // Get ItemApiService from Provider (already configured with token callback)
    _itemApiService = context.read<ItemApiService>();

    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController(text: '0');
    _quantityController = TextEditingController(text: '1');

    if (categories.isNotEmpty) {
      _selectedCategory = categories[0]['id']!;
    }

    // Use default Ho Chi Minh City coordinates
    // In a real app, you would integrate with location services
    _latitude = 10.7769;
    _longitude = 106.7009;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
          _isLoading = true;
          _errorMessage = null;
        });

        // Upload to Cloudinary
        final imageFile = File(pickedFile.path);
        final imageUrl = await _cloudinaryService.uploadProductImage(imageFile);

        setState(() {
          _uploadedImageUrl = imageUrl;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tải ảnh lên thành công!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải ảnh: $_errorMessage'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_uploadedImageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng tải lên ảnh sản phẩm'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      if (_latitude == null || _longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể lấy vị trí. Vui lòng thử lại.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Call API to create item
        final success = await _itemApiService.createItem(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          quantity: int.parse(_quantityController.text),
          imageUrl: _uploadedImageUrl!,
          expiryDate: _expirationDate,
          categoryId: _selectedCategory,
          latitude: _latitude!,
          longitude: _longitude!,
          price: double.parse(_priceController.text),
        );

        if (success) {
          widget.onProductCreated(true);
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chia sẻ sản phẩm thành công!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });

        widget.onProductCreated(false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $_errorMessage'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chia sẻ sản phẩm',
                    style: AppTextStyles.h3,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tên sản phẩm
              Text('Tên sản phẩm *', style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Nhập tên sản phẩm',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên sản phẩm';
                  }
                  if (value.length < 3) {
                    return 'Tên sản phẩm phải có ít nhất 3 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mô tả
              Text('Mô tả *', style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Mô tả chi tiết về sản phẩm',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mô tả sản phẩm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Danh mục
              Text('Danh mục *', style: AppTextStyles.label),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['id']!,
                    child: Text(category['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value ?? '');
                },
              ),
              const SizedBox(height: 16),

              // Số lượng và Giá (side by side)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Số lượng *', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '1',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập số lượng';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Phải là số';
                            }
                            if (int.parse(value) < 1) {
                              return 'Số lượng phải ≥ 1';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Giá (đ) *', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '0',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập giá';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Phải là số';
                            }
                            if (double.parse(value) < 0) {
                              return 'Giá không được âm';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Ảnh sản phẩm
              Text('Ảnh sản phẩm *', style: AppTextStyles.label),
              const SizedBox(height: 8),

              // Image preview
              if (_uploadedImageUrl != null)
                Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.borderLight,
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _uploadedImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.backgroundGray,
                                  child: const Icon(Icons.broken_image),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _uploadedImageUrl = null;
                                _selectedImagePath = null;
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                )
              else
                GestureDetector(
                  onTap: _isLoading ? null : _pickAndUploadImage,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryTeal,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.primaryTeal.withOpacity(0.05),
                    ),
                    child: Column(
                      children: [
                        if (_isLoading)
                          const SizedBox(
                            height: 32,
                            width: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryTeal,
                              ),
                            ),
                          )
                        else
                          const Icon(
                            Icons.add_photo_alternate,
                            color: AppColors.primaryTeal,
                            size: 32,
                          ),
                        const SizedBox(height: 12),
                        Text(
                          _isLoading ? 'Đang tải lên...' : 'Thêm ảnh sản phẩm',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Ngày hết hạn
              Text('Ngày hết hạn *', style: AppTextStyles.label),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final firstDate = DateTime.now().add(const Duration(days: 1));
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _expirationDate.isBefore(firstDate)
                        ? firstDate
                        : _expirationDate,
                    firstDate: firstDate,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    setState(() => _expirationDate = pickedDate);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_expirationDate.day}/${_expirationDate.month}/${_expirationDate.year}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const Icon(
                        Icons.calendar_today,
                        color: AppColors.primaryTeal,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    disabledBackgroundColor: AppColors.textDisabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Chia sẻ sản phẩm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
