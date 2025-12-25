import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/providers/category_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Sample suggested keywords
  final List<String> allSuggestedKeywords = [
    'Áo thun nam',
    'Giày thể thao',
    'Mũ lưỡi trai',
    'Quần jean',
    'Áo khoác',
    'Túi xách',
    'Dép',
    'Tất lưỡi',
    'Áo sơ mi',
    'Quần short',
  ];

  final List<Map<String, dynamic>> recentSearches = [
    {'term': 'Áo thun nam', 'time': '2 giờ trước'},
    {'term': 'Giày thể thao', 'time': 'Hôm qua'},
    {'term': 'Mũ lưỡi trai', 'time': '3 ngày trước'},
  ];

  // Predefined icon and color mapping for categories by icon name
  final Map<String, Map<String, dynamic>> categoryIconColorMap = {
    'food': {
      'icon': Icons.fastfood,
      'color': const Color(0xFF6BCB77),
    },
    'clothing': {
      'icon': Icons.checkroom,
      'color': const Color(0xFFFFC93C),
    },
    'furniture': {
      'icon': Icons.chair,
      'color': const Color(0xFFFF6B5B),
    },
    'books': {
      'icon': Icons.library_books,
      'color': const Color(0xFF3498DB),
    },
    'electronics': {
      'icon': Icons.devices,
      'color': const Color(0xFF9B59B6),
    },
    'baby': {
      'icon': Icons.child_friendly,
      'color': const Color(0xFFE91E63),
    },
    'others': {
      'icon': Icons.category,
      'color': const Color(0xFF95A5A6),
    },
    'Sách': {
      'icon': Icons.menu_book,
      'color': const Color(0xFFFF6B9D),
    },
    'Quần áo': {
      'icon': Icons.checkroom,
      'color': const Color(0xFFFFC93C),
    },
    'Thực phẩm': {
      'icon': Icons.fastfood,
      'color': const Color(0xFF6BCB77),
    },
    'Nội thất': {
      'icon': Icons.chair,
      'color': const Color(0xFFFF6B5B),
    },
    'Thể thao': {
      'icon': Icons.sports_baseball,
      'color': const Color(0xFF4D96FF),
    },
    'Điện tử': {
      'icon': Icons.devices,
      'color': const Color(0xFF9B59B6),
    },
    'Sách vở': {
      'icon': Icons.library_books,
      'color': const Color(0xFF3498DB),
    },
    'Mỹ phẩm': {
      'icon': Icons.spa,
      'color': const Color(0xFFE91E63),
    },
    'Đồ chơi': {
      'icon': Icons.toys,
      'color': const Color(0xFF00BCD4),
    },
    'Khác': {
      'icon': Icons.category,
      'color': const Color(0xFF95A5A6),
    },
  };

  @override
  void initState() {
    super.initState();
    // Load categories on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getSuggestedKeywords() {
    if (_searchController.text.isEmpty) {
      return [];
    }

    final query = _searchController.text.toLowerCase();
    return allSuggestedKeywords
        .where((keyword) => keyword.toLowerCase().contains(query))
        .toList();
  }

  void _navigateToResults(String keyword) {
    if (keyword.isNotEmpty) {
      context.pushNamed(AppRoutes.searchResultsName,
          queryParameters: {'keyword': keyword});
    }
  }

  void _navigateToCategory(String category) {
    context.pushNamed(AppRoutes.searchResultsName,
        queryParameters: {'category': category});
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
            onPressed: () => {
                  if (context.canPop())
                    {context.pop()}
                  else
                    {context.go(AppRoutes.home)}
                }),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppColors.lightGray,
            prefixIcon:
                const Icon(Icons.search, color: AppColors.textSecondary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon:
                        const Icon(Icons.clear, color: AppColors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) => setState(() {}),
          onSubmitted: (value) {
            _navigateToResults(value);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_searchController.text.isEmpty) ...[
              const Text(
                'Tìm kiếm gần đây',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentSearches.length,
                itemBuilder: (context, index) {
                  final search = recentSearches[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => _navigateToResults(search['term']),
                      child: Row(
                        children: [
                          const Icon(Icons.history,
                              color: AppColors.textSecondary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  search['term'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  search['time'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: AppColors.textSecondary, size: 18),
                            onPressed: () {
                              setState(() => recentSearches.removeAt(index));
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // const SizedBox(height: 24),
              // const Text(
              //   'Gợi ý tìm kiếm',
              //   style: TextStyle(
              //     fontSize: 16,
              //     fontWeight: FontWeight.bold,
              //     color: AppColors.textPrimary,
              //   ),
              // ),
              // const SizedBox(height: 12),
              // ListView.builder(
              //   shrinkWrap: true,
              //   physics: const NeverScrollableScrollPhysics(),
              //   itemCount: allSuggestedKeywords.take(5).length,
              //   itemBuilder: (context, index) {
              //     final keyword = allSuggestedKeywords[index];
              //     return Padding(
              //       padding: const EdgeInsets.only(bottom: 12),
              //       child: GestureDetector(
              //         onTap: () => _navigateToResults(keyword),
              //         child: Row(
              //           children: [
              //             const Icon(Icons.search,
              //                 color: AppColors.textSecondary, size: 20),
              //             const SizedBox(width: 12),
              //             Expanded(
              //               child: Text(
              //                 keyword,
              //                 style: const TextStyle(
              //                   fontSize: 14,
              //                   color: AppColors.textPrimary,
              //                 ),
              //               ),
              //             ),
              //             const Icon(Icons.arrow_outward,
              //                 color: AppColors.textSecondary, size: 18),
              //           ],
              //         ),
              //       ),
              //     );
              //   },
              // ),
              const SizedBox(height: 24),
              const Text(
                'Danh mục sản phẩm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Consumer<CategoryProvider>(
                builder: (context, categoryProvider, _) {
                  if (categoryProvider.isLoading) {
                    return SizedBox(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (categoryProvider.categories.isEmpty) {
                    return SizedBox(
                      height: 100,
                      child: Center(
                        child: Text('Không có danh mục'),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categoryProvider.categories.length,
                      itemBuilder: (context, index) {
                        final category = categoryProvider.categories[index];

                        // Try to get icon color from API icon field first, then from category name
                        Map<String, dynamic> iconColorData = {};

                        if (category.icon != null &&
                            category.icon!.isNotEmpty) {
                          iconColorData = categoryIconColorMap[category.icon] ??
                              categoryIconColorMap[category.name] ??
                              {
                                'icon': Icons.category,
                                'color': const Color(0xFF95A5A6),
                              };
                        } else {
                          iconColorData = categoryIconColorMap[category.name] ??
                              {
                                'icon': Icons.category,
                                'color': const Color(0xFF95A5A6),
                              };
                        }

                        return Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? 0 : 12,
                            right:
                                index == categoryProvider.categories.length - 1
                                    ? 0
                                    : 0,
                          ),
                          child: GestureDetector(
                            onTap: () => _navigateToCategory(category.name),
                            child: Container(
                              width: 90,
                              decoration: BoxDecoration(
                                color: iconColorData['color'] as Color,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    iconColorData['icon'] as IconData,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    category.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ] else ...[
              const Text(
                'Gợi ý tìm kiếm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (_getSuggestedKeywords().isEmpty)
                const Center(
                  child: Text('Không tìm thấy gợi ý nào'),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _getSuggestedKeywords().length,
                  itemBuilder: (context, index) {
                    final keyword = _getSuggestedKeywords()[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _navigateToResults(keyword),
                        child: Row(
                          children: [
                            const Icon(Icons.search,
                                color: AppColors.textSecondary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                keyword,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_outward,
                                color: AppColors.textSecondary, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}
