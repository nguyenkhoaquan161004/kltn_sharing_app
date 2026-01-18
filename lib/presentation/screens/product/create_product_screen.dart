import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../..//widgets/custom_text_field.dart';
import '../../widgets/address_autocomplete_field.dart';
import '../../../../data/services/item_api_service.dart';
import '../../../../data/providers/auth_provider.dart';

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
  String? _selectedCategoryId; // Store category ID for API
  String? _selectedLocationMode; // 'saved' or 'custom'
  String? _selectedSavedLocationIndex; // Index of selected saved location
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedAddress;
  bool _isLoading = false;
  bool _categoriesLoading = true;
  bool _userLoading = true;
  List<String> _selectedImages = [];
  bool _simulateDuplicate = true; // Toggle này để fake duplicate error

  List<Map<String, dynamic>> _categories = [];
  String? _categoryError;
  List<Map<String, dynamic>> _savedLocations = [];
  String? _userError;

  @override
  void initState() {
    super.initState();
    // Load categories and user data after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
      _loadUserData();
    });
  }

  Future<void> _loadCategories() async {
    try {
      final itemService = context.read<ItemApiService>();
      final categories = await itemService.getCategories();

      if (mounted) {
        setState(() {
          _categories = categories;
          _categoriesLoading = false;
          print('[CreateProduct] Loaded ${categories.length} categories');
          for (var cat in categories) {
            print('[CreateProduct] Category: ${cat['name']} (${cat['id']})');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoryError = 'Không thể tải danh mục: ${e.toString()}';
          _categoriesLoading = false;
          print('[CreateProduct] Error: $e');
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final authProvider = context.read<AuthProvider>();

      // Get user data to extract saved locations (address)
      if (authProvider.userId != null) {
        print(
            '[CreateProduct] Loading user data for userId: ${authProvider.userId}');

        // Initialize with default location (HCMC) as first option
        final defaultLocation = {
          'address': 'Mặc định (TP. Hồ Chí Minh)',
          'latitude': 10.7769,
          'longitude': 106.7009,
          'isDefault': true,
        };

        // Get user's saved address if available
        final itemService = context.read<ItemApiService>();
        try {
          // In a real app, we'd fetch user's saved locations from API
          // For now, using default location
          final savedLocations = [defaultLocation];

          if (mounted) {
            setState(() {
              _savedLocations = savedLocations;
              _selectedLocationMode = 'saved';
              _selectedSavedLocationIndex = '0';
              _selectedLatitude = defaultLocation['latitude'] as double;
              _selectedLongitude = defaultLocation['longitude'] as double;
              _selectedAddress = defaultLocation['address'] as String;
              _userLoading = false;
              print(
                  '[CreateProduct] User data loaded: ${savedLocations.length} locations');
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _userLoading = false;
              _userError = 'Không thể tải vị trí đã lưu';
              print('[CreateProduct] Error loading saved locations: $e');
              // Set default location anyway
              _savedLocations = [
                {
                  'address': 'Mặc định (TP. Hồ Chí Minh)',
                  'latitude': 10.7769,
                  'longitude': 106.7009,
                  'isDefault': true,
                }
              ];
              _selectedLocationMode = 'saved';
              _selectedSavedLocationIndex = '0';
              _selectedLatitude = 10.7769;
              _selectedLongitude = 106.7009;
              _selectedAddress = 'Mặc định (TP. Hồ Chí Minh)';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userLoading = false;
          print('[CreateProduct] Error loading user data: $e');
        });
      }
    }
  }

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất 1 hình ảnh'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn phân loại'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedLatitude == null || _selectedLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn vị trí lấy hàng'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check for duplicate products with same name and AVAILABLE status
    print(
        '[CreateProduct] DEBUG - Checking for duplicate products with name: ${_nameController.text.trim()}');
    final isDuplicate =
        await _checkDuplicateProduct(_nameController.text.trim());
    if (isDuplicate) {
      print('[CreateProduct] DEBUG - Duplicate product found, showing error');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sản phẩm đã tồn tại'),
            content: Text(
              'Sản phẩm "${_nameController.text.trim()}" đã tồn tại trong hệ thống. Không được đăng sản phẩm trùng!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
      return;
    }

    print('[CreateProduct] DEBUG - No duplicate found, proceeding with submit');
    _submitProduct();
  }

  Future<void> _submitProduct() async {
    setState(() => _isLoading = true);

    try {
      final itemService = context.read<ItemApiService>();

      // Use the first image for now (in a real app, you'd upload all images)
      final imageUrl = _selectedImages.isNotEmpty
          ? 'https://via.placeholder.com/300x300?text=Product'
          : '';

      final success = await itemService.createItem(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        quantity: int.tryParse(_quantityController.text) ?? 1,
        imageUrl: imageUrl,
        expiryDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
        categoryId: _selectedCategoryId!,
        latitude: _selectedLatitude!,
        longitude: _selectedLongitude!,
        price: double.tryParse(_priceController.text) ?? 0.0,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          print(
              '[CreateProduct] ✅ Product created successfully with location: $_selectedAddress ($_selectedLatitude, $_selectedLongitude)');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chia sẻ sản phẩm thành công!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else {
          throw Exception('Failed to create product');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('[CreateProduct] ❌ Error creating product: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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

              // Location Selection
              _buildLabel('Chọn vị trí lấy hàng'),
              _buildLocationSelector(),
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
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA726),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
    if (_categoriesLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_categoryError != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _categoryError!,
          style: const TextStyle(color: AppColors.error),
        ),
      );
    }

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
            final categoryName = category['name'] as String? ?? 'Unknown';
            final categoryId = category['id'] as String? ?? '';
            return DropdownMenuItem(
              value: categoryId,
              child: Text(categoryName),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value;
              _selectedCategory =
                  _categories.firstWhere((c) => c['id'] == value)['name'];
            });
          },
        ),
      ),
    );
  }

  Widget _buildLocationSelector() {
    if (_userLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Saved locations
        Text(
          'Vị trí đã lưu',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.backgroundGray,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSavedLocationIndex,
              hint: const Text('Chọn vị trí đã lưu'),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: _savedLocations.asMap().entries.map((entry) {
                final index = entry.key.toString();
                final location = entry.value;
                final displayText = location['address'] as String? ?? 'Unknown';
                return DropdownMenuItem(
                  value: index,
                  child: Text(
                    displayText,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  final selectedLoc = _savedLocations[int.parse(value)];
                  setState(() {
                    _selectedLocationMode = 'saved';
                    _selectedSavedLocationIndex = value;
                    _selectedAddress = selectedLoc['address'] as String?;
                    _selectedLatitude = selectedLoc['latitude'] as double?;
                    _selectedLongitude = selectedLoc['longitude'] as double?;
                  });
                  print(
                      '[CreateProduct] Selected saved location: $_selectedAddress ($_selectedLatitude, $_selectedLongitude)');
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // OR divider
        Center(
          child: Text(
            'HOẶC',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Custom location input
        Text(
          'Nhập vị trí khác',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        AddressAutocompleteField(
          controller: _addressController,
          label: '',
          hintText: 'Nhập địa chỉ lấy hàng',
          onAddressSelected: (latitude, longitude, address) {
            setState(() {
              _selectedLocationMode = 'custom';
              _selectedAddress = address;
              _selectedLatitude = latitude;
              _selectedLongitude = longitude;
            });
            print(
                '[CreateProduct] Selected custom location: $address ($latitude, $longitude)');
          },
          initialAddress: null,
        ),

        if (_selectedAddress != null && _selectedLocationMode == 'custom') ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryGreen),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primaryGreen,
                  size: 16,
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedAddress!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryGreen,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedLatitude?.toStringAsFixed(4)}, ${_selectedLongitude?.toStringAsFixed(4)}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Check if product with same name and AVAILABLE status already exists
  Future<bool> _checkDuplicateProduct(String productName) async {
    try {
      final itemService = context.read<ItemApiService>();
      // Get all available products
      final response = await itemService.searchProducts(
        keyword: productName,
        page: 0,
        pageSize: 100,
      );

      if (response.content != null) {
        for (var item in response.content!) {
          // Check if product name matches and status is AVAILABLE
          if (item.name?.toLowerCase() == productName.toLowerCase() &&
              item.status == 'AVAILABLE') {
            print('[CreateProduct] Found duplicate: ${item.name}');
            return true;
          }
        }
      }

      print('[CreateProduct] No duplicate found');
      return false;
    } catch (e) {
      print('[CreateProduct] Error checking duplicate: $e');
      // If API call fails, allow product creation
      return false;
    }
  }
}
