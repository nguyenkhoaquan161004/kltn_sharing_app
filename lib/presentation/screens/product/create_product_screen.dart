import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../..//widgets/custom_text_field.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _expiryDate;
  String? _selectedCategory;
  bool _useDefaultAddress = true;
  bool _isLoading = false;
  List<String> _selectedImages = [];

  final List<String> _categories = [
    'Sách',
    'Quần áo',
    'Thực phẩm',
    'Nội thất',
    'Thể thao',
    'Điện tử',
    'Khác',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _expiryDate = date);
    }
  }

  void _addImage() {
    // Simulate adding image
    setState(() {
      _selectedImages.add('image_${_selectedImages.length + 1}');
    });
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất 1 hình ảnh'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn phân loại'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng sản phẩm thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Chia sẻ sản phẩm', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product name
              _buildLabel('Tên sản phẩm'),
              CustomTextField(
                controller: _nameController,
                hint: 'Nhập tên sản phẩm',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên sản phẩm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Price
              _buildLabel('Giá sản phẩm'),
              CustomTextField(
                controller: _priceController,
                hint: '0',
                keyboardType: TextInputType.number,
                suffixIcon: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('VND', style: AppTextStyles.bodyMedium),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập giá';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Quantity
              _buildLabel('Số lượng sản phẩm'),
              CustomTextField(
                controller: _quantityController,
                hint: '1',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số lượng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Expiry date
              _buildLabel('Ngày hết hạn'),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _expiryDate != null
                            ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                            : 'Chọn ngày',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _expiryDate != null
                              ? AppColors.textPrimary
                              : AppColors.textDisabled,
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Images
              _buildLabel('Hình ảnh minh họa'),
              Text(
                'Phải có ít nhất một hình ảnh minh họa về sản phẩm bạn muốn chia sẻ',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 12),
              _buildImagePicker(),
              const SizedBox(height: 20),

              // Category
              _buildLabel('Phân loại'),
              _buildCategoryDropdown(),
              const SizedBox(height: 20),

              // Use default address
              Row(
                children: [
                  Checkbox(
                    value: _useDefaultAddress,
                    onChanged: (value) {
                      setState(() => _useDefaultAddress = value ?? true);
                    },
                    activeColor: AppColors.primaryTeal,
                  ),
                  const Text(
                    'Sử dụng địa chỉ mặc định',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),

              // Address (if not using default)
              if (!_useDefaultAddress) ...[
                const SizedBox(height: 12),
                _buildLabel('Địa chỉ'),
                CustomTextField(
                  controller: _addressController,
                  hint: 'Nhập địa chỉ lấy hàng',
                ),
              ],
              const SizedBox(height: 20),

              // Description
              _buildLabel('Mô tả sản phẩm'),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Mô tả chi tiết về sản phẩm...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDisabled,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  // Back button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.borderMedium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Trở về',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Submit button
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFA726), Color(0xFFFFD54F)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : _submit,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.center,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Chia sẻ',
                                    style: AppTextStyles.button),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.label),
    );
  }

  Widget _buildImagePicker() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Selected images
          ..._selectedImages.asMap().entries.map((entry) {
            return Container(
              width: 120,
              height: 120,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.image,
                        size: 48, color: AppColors.textSecondary),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Add button
          GestureDetector(
            onTap: _addImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderLight, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.add,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          hint: const Text('Chọn phân loại'),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: _categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedCategory = value);
          },
        ),
      ),
    );
  }
}
