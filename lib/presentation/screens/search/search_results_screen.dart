import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/item_model.dart';
import '../../../data/models/item_response_model.dart';
import '../../../data/services/item_api_service.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/category_provider.dart';
import '../../widgets/item_card.dart';

class SearchResultsScreen extends StatefulWidget {
  final String keyword;
  final String? categoryId;
  final String? categoryName;

  const SearchResultsScreen({
    super.key,
    this.keyword = '',
    this.categoryId,
    this.categoryName,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late List<ItemDto> _searchResults = [];
  TextEditingController _searchKeywordController = TextEditingController();
  String _sortBy = 'createdAt'; // createdAt (newest) or other sort options
  String _filterByCategory = '';
  String _filterByStatus = 'AVAILABLE'; // AVAILABLE, RESERVED, SHARED

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Pagination
  int _currentPage = 0;
  int _pageSize = 10;
  int _totalItems = 0;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _searchKeywordController.text = widget.keyword;
    if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
      _filterByCategory = widget.categoryId!;
    } else {
      _filterByCategory = ''; // No category filter by default
    }
    print(
        '[SearchResultsScreen] initState - keyword: ${widget.keyword}, categoryId: ${widget.categoryId}, categoryName: ${widget.categoryName}');
    print(
        '[SearchResultsScreen] initState - _filterByCategory: $_filterByCategory');
    _currentPage = 0;
    _loadItems(isInitial: true);
  }

  Future<void> _loadItems({bool isInitial = false}) async {
    if (isInitial) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 0;
        _searchResults = [];
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final itemService = context.read<ItemApiService>();

      if (authProvider.accessToken != null) {
        itemService.setAuthToken(authProvider.accessToken!);
      }

      // Simplified API call with only necessary parameters
      print('[SearchResultsScreen] _loadItems - calling API with:');
      print(
          '[SearchResultsScreen]   keyword: ${widget.keyword.isNotEmpty ? widget.keyword : null}');
      print(
          '[SearchResultsScreen]   categoryId: ${_filterByCategory.isNotEmpty && _filterByCategory != 'all' ? _filterByCategory : null}');
      print(
          '[SearchResultsScreen]   _filterByCategory value: $_filterByCategory');

      final response = await itemService.searchItems(
        page: _currentPage,
        size: _pageSize,
        keyword: widget.keyword.isNotEmpty ? widget.keyword : null,
        categoryId: _filterByCategory.isNotEmpty && _filterByCategory != 'all'
            ? _filterByCategory
            : null,
        status: _filterByStatus,
        sortBy: _sortBy,
        sortDirection: 'DESC',
      );

      setState(() {
        if (isInitial) {
          _searchResults = response.content;
        } else {
          _searchResults.addAll(response.content);
        }
        _totalItems = response.totalElements;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: ${e.toString()}';
        _isLoading = false;
        _isLoadingMore = false;
      });
      print('[SearchResults] Error: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      // User is near the bottom, load more if available
      if (!_isLoadingMore && _searchResults.length < _totalItems) {
        _currentPage++;
        _loadItems(isInitial: false);
      }
    }
  }

  @override
  void dispose() {
    _searchKeywordController.dispose();
    _scrollController.dispose();
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
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _searchResults.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at the bottom
        if (index == _searchResults.length) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final dto = _searchResults[index];
        print(
            '[SearchResultsScreen] Item ${index}: id=${dto.id}, categoryId=${dto.categoryId}, categoryName="${dto.categoryName}"');

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
          categoryName: dto.categoryName ?? 'Khác',
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
                            _filterByCategory = '';
                          });
                          setState(() {});
                          _loadItems(isInitial: true);
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
                                _loadItems(isInitial: true);
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
                                _loadItems(isInitial: true);
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
                      // Category filter section (as pills)
                      const Text(
                        'Phân loại',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Consumer<CategoryProvider>(
                        builder: (context, categoryProvider, _) {
                          if (categoryProvider.isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildCategoryPill(
                                  'all', 'Tất cả', setModalState),
                              ...categoryProvider.categories.map((category) {
                                return _buildCategoryPill(
                                  category.id,
                                  category.name,
                                  setModalState,
                                );
                              }).toList(),
                            ],
                          );
                        },
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
        _loadItems(isInitial: true);
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
