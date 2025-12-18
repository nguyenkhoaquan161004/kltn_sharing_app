import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';

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

  @override
  void initState() {
    super.initState();
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
