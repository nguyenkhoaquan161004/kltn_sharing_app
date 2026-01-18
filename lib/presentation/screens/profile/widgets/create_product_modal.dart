import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../widgets/address_autocomplete_field.dart';
import '../../../../data/services/item_api_service.dart';
import '../../../../data/services/cloudinary_service.dart';
import '../../../../data/providers/user_provider.dart';

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
  late TextEditingController _addressController;

  String _selectedCategory = '';
  String? _selectedCategoryId;
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;
  bool _categoriesLoading = true;
  bool _simulateDuplicate = false; // Toggle để fake duplicate error
  String? _selectedImagePath;
  String? _uploadedImageUrl;
  String? _errorMessage;
  String? _categoryError;

  // Location
  double? _latitude;
  double? _longitude;
  String? _selectedAddress;
  String _locationMode = 'current'; // 'current' or 'other'
  String? _userCurrentAddress;

  // Categories from API
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    // Get ItemApiService from Provider (already configured with token callback)
    _itemApiService = context.read<ItemApiService>();

    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController(text: '0');
    _quantityController = TextEditingController(text: '1');
    _addressController = TextEditingController();

    // Use default Ho Chi Minh City coordinates initially
    _latitude = 10.7769;
    _longitude = 106.7009;
    _selectedAddress = 'Mặc định (TP. Hồ Chí Minh)';

    // Load categories and user address after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
      _loadUserAddressAndGeocode();
    });
  }

  Future<void> _loadCategories() async {
    try {
      final loadedCategories = await _itemApiService.getCategories();

      if (mounted) {
        setState(() {
          categories = loadedCategories;
          _categoriesLoading = false;

          if (categories.isNotEmpty) {
            _selectedCategoryId = categories[0]['id'];
            _selectedCategory = categories[0]['name'] ?? '';
          }

          print('[CreateProductModal] Loaded ${categories.length} categories');
          for (var cat in categories) {
            print(
                '[CreateProductModal] Category: ${cat['name']} (${cat['id']})');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoryError = 'Không thể tải danh mục: ${e.toString()}';
          _categoriesLoading = false;
          print('[CreateProductModal] Error loading categories: $e');
        });
      }
    }
  }

  Future<void> _loadUserAddressAndGeocode() async {
    try {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.currentUser;

      if (user == null || (user.address == null || user.address!.isEmpty)) {
        print(
            '[CreateProductModal] No user address found, using default coordinates');
        if (mounted) {
          setState(() {
            _userCurrentAddress = null; // No address from user
            _latitude = 10.7769;
            _longitude = 106.7009;
            _selectedAddress = 'Mặc định (TP. Hồ Chí Minh)';
          });
        }
        return;
      }

      final address = user.address!;
      print('[CreateProductModal] Geocoding user address: $address');

      // Geocode the address
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        final location = locations.first;
        if (mounted) {
          setState(() {
            _userCurrentAddress = address; // User's actual address
            _latitude = location.latitude;
            _longitude = location.longitude;
            _selectedAddress = address;
            print(
                '[CreateProductModal] Geocoded address - Lat: $_latitude, Long: $_longitude');
          });
        }
      } else {
        print(
            '[CreateProductModal] Geocoding failed, using default coordinates');
        if (mounted) {
          setState(() {
            _userCurrentAddress = null; // Geocoding failed
            _latitude = 10.7769;
            _longitude = 106.7009;
            _selectedAddress = 'Mặc định (TP. Hồ Chí Minh)';
          });
        }
      }
    } catch (e) {
      print('[CreateProductModal] Error geocoding address: $e');
      if (mounted) {
        setState(() {
          _userCurrentAddress = null; // Error occurred
          _latitude = 10.7769;
          _longitude = 106.7009;
          _selectedAddress = 'Mặc định (TP. Hồ Chí Minh)';
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _addressController.dispose();
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
    print('[CreateProductModal] DEBUG - _submitForm called');
    print(
        '[CreateProductModal] DEBUG - _simulateDuplicate = $_simulateDuplicate');
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

      if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn danh mục'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Check for duplicate products with same name and AVAILABLE status
      print(
          '[CreateProductModal] DEBUG - Checking for duplicate products with name: ${_nameController.text.trim()}');
      final isDuplicate =
          await _checkDuplicateProduct(_nameController.text.trim());
      if (isDuplicate) {
        print(
            '[CreateProductModal] DEBUG - Duplicate product found, showing error');
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

      print(
          '[CreateProductModal] DEBUG - No duplicate found, proceeding with submit');
      setState(() => _isLoading = true);

      try {
        // Call API to create item
        final success = await _itemApiService.createItem(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          quantity: int.parse(_quantityController.text),
          imageUrl: _uploadedImageUrl!,
          expiryDate: _expirationDate,
          categoryId: _selectedCategoryId!,
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
              _buildCategoryDropdown(),
              const SizedBox(height: 16),

              // Chọn vị trí lấy hàng
              Text('Vị trí lấy hàng *', style: AppTextStyles.label),
              const SizedBox(height: 12),
              _buildLocationSelector(),
              const SizedBox(height: 16),

              // Số lượng và Giá (side by side)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 8),
              Text(
                'Số tiền sẽ được góp vào quỹ Mặt trận Tổ quốc Việt Nam',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
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
              Text('Ngày hết hạn', style: AppTextStyles.label),
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

  Widget _buildCategoryDropdown() {
    if (_categoriesLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
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
          border: Border.all(color: AppColors.error),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.error.withOpacity(0.1),
        ),
        child: Text(
          _categoryError!,
          style: const TextStyle(color: AppColors.error),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
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
          value: category['id'] as String,
          child: Text(category['name'] as String? ?? 'Unknown'),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCategoryId = value;
            _selectedCategory = categories
                    .firstWhere((c) => c['id'] == value)['name'] as String? ??
                '';
          });
        }
      },
    );
  }

  Widget _buildLocationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Option 1: Địa chỉ hiện tại
        GestureDetector(
          onTap: () {
            setState(() {
              _locationMode = 'current';
              _addressController.clear();
              // Set to user's current address with geocoded coordinates
              if (_userCurrentAddress != null &&
                  _userCurrentAddress!.isNotEmpty) {
                _selectedAddress = _userCurrentAddress;
              } else {
                _selectedAddress = 'Mặc định (TP. Hồ Chí Minh)';
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: _locationMode == 'current'
                    ? AppColors.primaryTeal
                    : AppColors.borderLight,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: _locationMode == 'current'
                  ? AppColors.primaryTeal.withOpacity(0.05)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Radio<String>(
                  value: 'current',
                  groupValue: _locationMode,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _locationMode = value;
                        _addressController.clear();
                        if (_userCurrentAddress != null &&
                            _userCurrentAddress!.isNotEmpty) {
                          _selectedAddress = _userCurrentAddress;
                        } else {
                          _selectedAddress = 'Mặc định (TP. Hồ Chí Minh)';
                        }
                      });
                    }
                  },
                  activeColor: AppColors.primaryTeal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dùng địa chỉ hiện tại',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Show current address below
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show user's address if available, otherwise show default
              Text(
                _userCurrentAddress ?? 'Mặc định (TP. Hồ Chí Minh)',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${_latitude?.toStringAsFixed(4)}, ${_longitude?.toStringAsFixed(4)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Option 2: Địa chỉ khác
        GestureDetector(
          onTap: () {
            setState(() {
              _locationMode = 'other';
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: _locationMode == 'other'
                    ? AppColors.primaryTeal
                    : AppColors.borderLight,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: _locationMode == 'other'
                  ? AppColors.primaryTeal.withOpacity(0.05)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Radio<String>(
                  value: 'other',
                  groupValue: _locationMode,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _locationMode = value;
                      });
                    }
                  },
                  activeColor: AppColors.primaryTeal,
                ),
                const SizedBox(width: 8),
                Text(
                  'Chọn địa chỉ khác',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Input địa chỉ khác
        if (_locationMode == 'other') ...[
          const SizedBox(height: 12),
          AddressAutocompleteField(
            controller: _addressController,
            label: '',
            hintText: 'Nhập địa chỉ lấy hàng',
            onAddressSelected: (latitude, longitude, address) {
              setState(() {
                _latitude = latitude;
                _longitude = longitude;
                _selectedAddress = address;
              });
              print(
                  '[CreateProductModal] Selected custom location: $address ($_latitude, $_longitude)');
            },
            initialAddress: null,
          ),
        ],
      ],
    );
  }

  /// Check if product with same name and AVAILABLE status already exists
  Future<bool> _checkDuplicateProduct(String productName) async {
    try {
      // Get all available products
      final response = await _itemApiService.searchItems(
        keyword: productName,
        page: 0,
        size: 100,
      );

      if (response.content != null) {
        for (var item in response.content!) {
          // Check if product name matches and status is AVAILABLE
          if (item.name?.toLowerCase() == productName.toLowerCase() &&
              item.status == 'AVAILABLE') {
            print('[CreateProductModal] Found duplicate: ${item.name}');
            return true;
          }
        }
      }

      print('[CreateProductModal] No duplicate found');
      return false;
    } catch (e) {
      print('[CreateProductModal] Error checking duplicate: $e');
      // If API call fails, allow product creation
      return false;
    }
  }
}
