import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  String _selectedSort = 'newest';
  RangeValues _priceRange = const RangeValues(90, 200);
  final List<String> _selectedCategories = ['Quần áo'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedSort = 'newest';
                          _priceRange = const RangeValues(90, 200);
                          _selectedCategories.clear();
                          _selectedCategories.add('Quần áo');
                        });
                      },
                      child: const Text(
                        'Đặt lại',
                        style: TextStyle(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.close, size: 28),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Sort By
            const Text(
              'Sort by',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                _buildSortButton('Gần đây', 'newest'),
                _buildSortButton('Đề xuất', 'recommended'),
              ],
            ),
            const SizedBox(height: 32),
            // Price Range
            const Text(
              'Price (USD)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: _priceRange.start.toInt().toString(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('—', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: _priceRange.end.toInt().toString(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Price Slider
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 300,
              divisions: 30,
              activeColor: AppColors.primaryTeal,
              inactiveColor: Colors.grey[300],
              onChanged: (RangeValues values) {
                setState(() => _priceRange = values);
              },
            ),
            const SizedBox(height: 20),
            // Price Display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _priceRange.start.toInt().toString(),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _priceRange.end.toInt().toString(),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Categories
            const Text(
              'Phân loại',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildCategoryButton('Sách'),
                _buildCategoryButton('Quần áo'),
                _buildCategoryButton('Thực phẩm'),
                _buildCategoryButton('Nội thất'),
                _buildCategoryButton('Thể thao'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton(String label, String value) {
    final isSelected = _selectedSort == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedSort = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : AppColors.primaryTeal,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.primaryTeal,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String label) {
    final isSelected = _selectedCategories.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedCategories.remove(label);
          } else {
            _selectedCategories.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : AppColors.white,
          border: Border.all(
            color: AppColors.primaryTeal,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.primaryTeal,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
