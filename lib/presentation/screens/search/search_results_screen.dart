import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/item_model.dart';
import '../../../data/mock_data.dart';
import '../../widgets/item_card.dart';

class SearchResultsScreen extends StatefulWidget {
  final String keyword;

  const SearchResultsScreen({
    super.key,
    this.keyword = '',
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late List<ItemModel> _searchResults = [];
  TextEditingController _searchKeywordController = TextEditingController();
  String _sortBy = 'suggested'; // suggested (default), newest
  String _filterByPrice = 'all'; // all, free, paid
  String _filterByCategory = 'all'; // all, or categoryId

  // Price range filter
  double _minPrice = 0;
  double _maxPrice = 1000000;
  TextEditingController _minPriceController = TextEditingController(text: '0');
  TextEditingController _maxPriceController =
      TextEditingController(text: '1000000');

  @override
  void initState() {
    super.initState();
    _searchKeywordController.text = widget.keyword;
    // Load all available items
    _searchResults = MockData.items;
  }

  @override
  void dispose() {
    _searchKeywordController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.search);
            }
          },
        ),
        title: TextField(
          controller: _searchKeywordController,
          onTap: () {
            context.go(AppRoutes.search);
          },
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm sản phẩm...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppColors.lightGray,
            prefixIcon:
                const Icon(Icons.search, color: AppColors.textSecondary),
            suffixIcon: _searchKeywordController.text.isNotEmpty
                ? IconButton(
                    icon:
                        const Icon(Icons.clear, color: AppColors.textSecondary),
                    onPressed: () {
                      _searchKeywordController.clear();
                      setState(() {});
                    },
                  )
                : null,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Sort and Filter header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Sort button
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => _buildFilterModal(),
                    );
                  },
                  child: Row(
                    children: [
                      const Text(
                        'Sort By: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _getSortLabel(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ),
                // Filter button
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => _buildFilterModal(),
                    );
                  },
                  child: const Icon(
                    Icons.tune,
                    color: AppColors.textPrimary,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Results count
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16),
          //   child: Text(
          //     'Tìm thấy ${_getFilteredProducts().length} sản phẩm',
          //     style: const TextStyle(
          //       fontSize: 14,
          //       fontWeight: FontWeight.w500,
          //       color: AppColors.textSecondary,
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 16),
          Expanded(
            child: _buildProductGrid(),
          ),
        ],
      ),
    );
  }

  String _getSortLabel() {
    return _sortBy == 'newest' ? 'Gần đây' : 'Đề xuất';
  }

  List<ItemModel> _getFilteredProducts() {
    List<ItemModel> filtered = _searchResults;

    // Apply keyword filter first
    if (widget.keyword.isNotEmpty) {
      filtered = filtered
          .where((item) =>
              item.name.toLowerCase().contains(widget.keyword.toLowerCase()))
          .toList();
    }

    // Apply price type filter
    if (_filterByPrice == 'free') {
      filtered = filtered.where((item) => item.price == 0).toList();
    } else if (_filterByPrice == 'paid') {
      filtered = filtered.where((item) => item.price > 0).toList();
    }

    // Apply price range filter
    filtered = filtered.where((item) {
      final price = item.price.toDouble();
      return price >= _minPrice && price <= _maxPrice;
    }).toList();

    // Apply category filter
    if (_filterByCategory != 'all') {
      filtered = filtered
          .where((item) => item.categoryId.toString() == _filterByCategory)
          .toList();
    }

    // Apply sort
    if (_sortBy == 'newest') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    // 'suggested' (default) = no sort, keep original order

    return filtered;
  }

  Widget _buildProductGrid() {
    final filtered = _getFilteredProducts();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy sản phẩm nào'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return ItemCard(
          item: item,
          showTimeRemaining: true,
        );
      },
    );
  }

  Widget _buildFilterModal() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and reset button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setModalState(() {
                            _sortBy = 'suggested';
                            _filterByPrice = 'all';
                            _filterByCategory = 'all';
                            _minPrice = 0;
                            _maxPrice = 1000000;
                            _minPriceController.text = '0';
                            _maxPriceController.text = '1000000';
                          });
                          setState(() {});
                        },
                        child: const Text(
                          'Đặt lại',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, size: 28),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sort by section
                      const Text(
                        'Sort by',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  _sortBy = 'newest';
                                });
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _sortBy == 'newest'
                                      ? AppColors.primaryTeal
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _sortBy == 'newest'
                                        ? AppColors.primaryTeal
                                        : const Color(0xFFCCCCCC),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Gần đây',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _sortBy == 'newest'
                                        ? Colors.white
                                        : AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  _sortBy = 'suggested';
                                });
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _sortBy == 'suggested'
                                      ? AppColors.primaryTeal
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _sortBy == 'suggested'
                                        ? AppColors.primaryTeal
                                        : const Color(0xFFCCCCCC),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Đề xuất',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _sortBy == 'suggested'
                                        ? Colors.white
                                        : AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Price range filter section
                      const Text(
                        'Giá (VND)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Price input fields
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _minPriceController,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setModalState(() {
                                  _minPrice = double.tryParse(value) ?? 0;
                                });
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                hintText: '0',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '—',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _maxPriceController,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setModalState(() {
                                  _maxPrice = double.tryParse(value) ?? 1000000;
                                });
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                hintText: '1000000',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Category filter section (as pills)
                      const Text(
                        'Phân loại',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildCategoryPill('all', 'Tất cả', setModalState),
                          for (final category in MockData.categories)
                            _buildCategoryPill(category.categoryId.toString(),
                                category.name, setModalState),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryPill(
      String value, String label, StateSetter setModalState) {
    final isSelected = _filterByCategory == value;
    return GestureDetector(
      onTap: () {
        setModalState(() {
          _filterByCategory = value;
        });
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : const Color(0xFFCCCCCC),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.primaryTeal,
          ),
        ),
      ),
    );
  }
}
