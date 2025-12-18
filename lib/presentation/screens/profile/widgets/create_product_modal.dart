import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/item_model.dart';

class CreateProductModal extends StatefulWidget {
  final Function(ItemModel) onProductCreated;

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

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;

  String _selectedCategory = '1';
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;
  List<File> _selectedImages = [];
  final int _maxImages = 5;

  final List<Map<String, dynamic>> categories = [
    {'id': '1', 'name': 'Quần áo'},
    {'id': '2', 'name': 'Giày dép'},
    {'id': '3', 'name': 'Điện tử'},
    {'id': '4', 'name': 'Sách'},
    {'id': '5', 'name': 'Đồ chơi'},
    {'id': '6', 'name': 'Nội thất'},
    {'id': '7', 'name': 'Thể thao'},
    {'id': '8', 'name': 'Khác'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController(text: '0');
    _quantityController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Simulate upload delay
      Future.delayed(const Duration(seconds: 1), () {
        final newProduct = ItemModel(
          itemId: DateTime.now().millisecondsSinceEpoch,
          userId: 1, // Current user
          name: _nameController.text,
          description: _descriptionController.text,
          quantity: int.parse(_quantityController.text),
          status: 'available',
          categoryId: int.parse(_selectedCategory),
          locationId: 1, // Default location
          expirationDate: _expirationDate,
          createdAt: DateTime.now(),
          price: double.parse(_priceController.text),
        );

        widget.onProductCreated(newProduct);
        Navigator.pop(context);
      });
    }
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tối đa $_maxImages ảnh'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
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
                    value: category['id'].toString(),
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value ?? '1');
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
                            if (int.tryParse(value) == null) {
                              return 'Phải là số';
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
              Text('Ảnh sản phẩm (tối đa $_maxImages ảnh)',
                  style: AppTextStyles.label),
              const SizedBox(height: 8),

              // Image preview grid
              if (_selectedImages.isNotEmpty)
                Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImages[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: -8,
                              right: -8,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
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
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

              // Add image button
              if (_selectedImages.length < _maxImages)
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                        const Icon(
                          Icons.add_photo_alternate,
                          color: AppColors.primaryTeal,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thêm ảnh (${_selectedImages.length}/$_maxImages)',
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
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _expirationDate,
                    firstDate: DateTime.now(),
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
