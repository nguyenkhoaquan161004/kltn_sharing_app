import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/auth_token_callback_helper.dart';
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
  final String? imageUrl;
  final List<ItemModel>? precomputedResults;

  const SearchResultsScreen({
    super.key,
    this.keyword = '',
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.precomputedResults,
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
        '[SearchResultsScreen] initState - keyword: ${widget.keyword}, categoryId: ${widget.categoryId}, categoryName: ${widget.categoryName}, imageUrl: ${widget.imageUrl}');
    print(
        '[SearchResultsScreen] initState - _filterByCategory: $_filterByCategory');
    if (widget.precomputedResults != null) {
      print(
          '[SearchResultsScreen] initState - Pre-computed results available: ${widget.precomputedResults!.length} items');
    }

    // Set up ItemApiService with token callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final itemService = context.read<ItemApiService>();
      if (authProvider.accessToken != null) {
        itemService.setAuthToken(authProvider.accessToken!);
        itemService.setGetValidTokenCallback(
          createTokenExpiredCallback(context),
        );
      }
    });

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

      // Handle image search if imageUrl is provided
      if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
        print(
            '[SearchResultsScreen] _loadItems - Performing image search with imageUrl: ${widget.imageUrl}');
        print(
            '[SearchResultsScreen] _loadItems - precomputedResults: ${widget.precomputedResults}');
        print(
            '[SearchResultsScreen] _loadItems - precomputedResults length: ${widget.precomputedResults?.length}');

        // Use pre-computed results if available, otherwise fetch from API
        List<ItemModel> itemModels;
        if (widget.precomputedResults != null &&
            widget.precomputedResults!.isNotEmpty) {
          print(
              '[SearchResultsScreen] _loadItems - ✅ Using pre-computed results: ${widget.precomputedResults!.length} items');
          itemModels = widget.precomputedResults!;
        } else {
          print(
              '[SearchResultsScreen] _loadItems - ⚠️ Fetching image search results from API (precomputedResults is ${widget.precomputedResults == null ? 'NULL' : 'EMPTY'})');
          itemModels = await itemService.searchByImage(widget.imageUrl!);
        }

        List<ItemDto> items = itemModels.map((model) {
          return ItemDto(
            id: model.itemId_str ?? model.itemId.toString(),
            name: model.name,
            description: model.description,
            quantity: model.quantity,
            imageUrl: model.image,
            expiryDate: model.expiryDate,
            categoryId: model.categoryId_str ?? model.categoryId.toString(),
            categoryName: model.categoryName,
            latitude: model.latitude,
            longitude: model.longitude,
            price: model.price,
            status: model.status,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt,
            userId: model.userId_str ?? model.userId.toString(),
            distanceKm: model.distance,
            isCharityItem: model.isCharityItem,
            donationAmountFormatted: model.donationAmount,
            interestedCount: 0,
          );
        }).toList();

        print(
            '[SearchResultsScreen] _loadItems - Converted ${items.length} items from image search results');

        setState(() {
          _searchResults = items;
          _isLoading = false;
          _totalItems = items.length;
        });
        return;
      }

      // Simplified API call with only necessary parameters
      print('[SearchResultsScreen] _loadItems - calling API with:');
      print(
          '[SearchResultsScreen]   keyword: ${widget.keyword.isNotEmpty ? widget.keyword : null}');
      print(
          '[SearchResultsScreen]   categoryId: ${_filterByCategory.isNotEmpty && _filterByCategory != 'all' ? _filterByCategory : null}');
      print(
          '[SearchResultsScreen]   _filterByCategory value: $_filterByCategory');

      // Smart sort: when searching by keyword, sort by name (relevance)
      // Otherwise use user's selected sort
      final String finalSortBy =
          widget.keyword.isNotEmpty && _sortBy == 'createdAt'
              ? 'name' // Sort by name when searching by keyword
              : _sortBy;

      print(
          '[SearchResultsScreen] Final sortBy: $finalSortBy (keyword: ${widget.keyword})');

      final response = await itemService.searchItems(
        page: _currentPage,
        size: _pageSize,
        keyword: widget.keyword.isNotEmpty ? widget.keyword : null,
        categoryId: _filterByCategory.isNotEmpty && _filterByCategory != 'all'
            ? _filterByCategory
            : null,
        status: _filterByStatus,
        sortBy: _sortBy, // Keep original sortBy for server
        sortDirection: 'DESC',
      );

      // Client-side sort by relevance when searching by keyword
      List<ItemDto> items = response.content;
      if (widget.keyword.isNotEmpty) {
        items.sort((a, b) {
          final keywordLower = widget.keyword.toLowerCase();
          final aNameLower = a.name.toLowerCase();
          final bNameLower = b.name.toLowerCase();

          // Exact match first
          if (aNameLower == keywordLower && bNameLower != keywordLower)
            return -1;
          if (bNameLower == keywordLower && aNameLower != keywordLower)
            return 1;

          // Starts with keyword
          if (aNameLower.startsWith(keywordLower) &&
              !bNameLower.startsWith(keywordLower)) return -1;
          if (bNameLower.startsWith(keywordLower) &&
              !aNameLower.startsWith(keywordLower)) return 1;

          // Contains keyword (closer to start = more relevant)
          int aIndex = aNameLower.indexOf(keywordLower);
          int bIndex = bNameLower.indexOf(keywordLower);
          if (aIndex != bIndex) return aIndex.compareTo(bIndex);

          // Same relevance -> sort by newer first
          return b.createdAt.compareTo(a.createdAt);
        });
        print(
            '[SearchResultsScreen] Sorted ${items.length} items by relevance to keyword: "${widget.keyword}"');
      }

      setState(() {
        if (isInitial) {
          _searchResults = items;
        } else {
          _searchResults.addAll(items);
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
