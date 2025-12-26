import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/item_model.dart';
import '../../../data/models/item_response_model.dart';
import '../../../data/services/item_api_service.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/item_card.dart';

class SearchResultsScreen extends StatefulWidget {
  final String keyword;
  final String? category;

  const SearchResultsScreen({
    super.key,
    this.keyword = '',
    this.category,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late List<ItemDto> _searchResults = [];
  TextEditingController _searchKeywordController = TextEditingController();
  String _sortBy = 'createdAt'; // createdAt (newest), or other sort options
  String _filterByPrice = 'all'; // all, free, paid
  String _filterByCategory = 'all'; // all, or categoryId

  // Price range filter
  double _minPrice = 0;
  double _maxPrice = 1000000;
  TextEditingController _minPriceController = TextEditingController(text: '0');
  TextEditingController _maxPriceController =
      TextEditingController(text: '1000000');

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchKeywordController.text = widget.keyword;
    if (widget.category != null && widget.category!.isNotEmpty) {
      _filterByCategory = widget.category!;
    }
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final itemService = context.read<ItemApiService>();

      if (authProvider.accessToken != null) {
        itemService.setAuthToken(authProvider.accessToken!);
      }

      final response = await itemService.searchItems(
        search: widget.keyword.isNotEmpty ? widget.keyword : null,
        category: _filterByCategory != 'all' ? _filterByCategory : null,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sortBy: _sortBy,
        sortDirection: 'DESC',
      );

      setState(() {
        _searchResults = response.content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: ${e.toString()}';
        _isLoading = false;
      });
      print('[SearchResults] Error: $e');
    }
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadItems,
                        child: const Text('Tải lại'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 8),
                    // Sort and Filter header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Sort button
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20)),
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
                                    color: AppColors.primaryGreen,
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
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20)),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Tìm thấy ${_searchResults.length} sản phẩm',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildProductGrid(),
                    ),
                  ],
                ),
    );
  }

  String _getSortLabel() {
    return _sortBy == 'createdAt' ? 'Mới nhất' : 'Đề xuất';
  }

  Widget _buildProductGrid() {
    if (_searchResults.isEmpty) {
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
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final dto = _searchResults[index];
        // Convert ItemDto to ItemModel for display
        final item = ItemModel(
          itemId: 0, // Will use itemId_str instead
          itemId_str: dto.id, // UUID from API
          userId: int.tryParse(dto.userId) ?? 0,
          userId_str: dto.userId,
          name: dto.name,
          description: dto.description,
          quantity: dto.quantity ?? 1,
          status: dto.status,
          categoryId: 0,
          categoryId_str: dto.categoryId,
          locationId: 0,
          expiryDate: dto.expiryDate,
          createdAt: dto.createdAt,
          price: dto.price ?? 0,
          image: dto.imageUrl,
          latitude: dto.latitude,
          longitude: dto.longitude,
          distance: dto.distanceKm,
        );

        return GestureDetector(
          onTap: () {
            context.pushNamed(
              'product-detail',
              pathParameters: {'id': dto.id},
            );
          },
          child: ItemCard(
            item: item,
            showTimeRemaining: false,
          ),
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
                            _sortBy = 'createdAt';
                            _filterByPrice = 'all';
                            _filterByCategory = 'all';
                            _minPrice = 0;
                            _maxPrice = 1000000;
                            _minPriceController.text = '0';
                            _maxPriceController.text = '1000000';
                          });
                          setState(() {});
                          _loadItems();
                        },
                        child: const Text(
                          'Đặt lại',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
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
                                  _sortBy = 'createdAt';
                                });
                                setState(() {});
                                _loadItems();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _sortBy == 'createdAt'
                                      ? AppColors.primaryGreen
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _sortBy == 'createdAt'
                                        ? AppColors.primaryGreen
                                        : const Color(0xFFCCCCCC),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Mới nhất',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _sortBy == 'createdAt'
                                        ? Colors.white
                                        : AppColors.primaryGreen,
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
                                  _sortBy = 'default';
                                });
                                setState(() {});
                                _loadItems();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _sortBy == 'default'
                                      ? AppColors.primaryGreen
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _sortBy == 'default'
                                        ? AppColors.primaryGreen
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
                                        : AppColors.primaryGreen,
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
                          _buildCategoryPill('Sách', 'Sách', setModalState),
                          _buildCategoryPill(
                              'Quần áo', 'Quần áo', setModalState),
                          _buildCategoryPill(
                              'Thực phẩm', 'Thực phẩm', setModalState),
                          _buildCategoryPill(
                              'Nội thất', 'Nội thất', setModalState),
                          _buildCategoryPill(
                              'Thể thao', 'Thể thao', setModalState),
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
        _loadItems();
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
