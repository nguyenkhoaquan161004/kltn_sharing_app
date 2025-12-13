import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';

class StoreInformationScreen extends StatefulWidget {
  const StoreInformationScreen({super.key});

  @override
  State<StoreInformationScreen> createState() => _StoreInformationScreenState();
}

class _StoreInformationScreenState extends State<StoreInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _storeNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // TODO: Implement save store information logic
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _isLoading = false);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu thông tin cửa hàng')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Thông tin cửa hàng',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Store Image
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.borderGray,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.store,
                        size: 60,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppColors.buttonGradient,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                label: 'Tên cửa hàng',
                hint: 'Nhập tên cửa hàng',
                controller: _storeNameController,
                prefixIcon: const Icon(Icons.store_outlined,
                    color: AppColors.textSecondary),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên cửa hàng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Mô tả',
                hint: 'Nhập mô tả về cửa hàng',
                controller: _descriptionController,
                maxLines: 4,
                prefixIcon: const Icon(Icons.description_outlined,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Địa chỉ',
                hint: 'Nhập địa chỉ cửa hàng',
                controller: _addressController,
                prefixIcon: const Icon(Icons.location_on_outlined,
                    color: AppColors.textSecondary),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập địa chỉ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Số điện thoại',
                hint: 'Nhập số điện thoại',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined,
                    color: AppColors.textSecondary),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              GradientButton(
                text: 'Lưu thông tin',
                onPressed: _handleSave,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
