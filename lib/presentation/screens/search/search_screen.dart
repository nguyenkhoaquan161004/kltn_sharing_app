import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/providers/category_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/cloudinary_service.dart';
import '../../../data/services/item_api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late ItemApiService _itemApiService;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();

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

  List<Map<String, dynamic>> recentSearches = [];
  bool _isLoadingSearchHistory = false;

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
    _itemApiService = ItemApiService();
    // Set token from AuthProvider to ensure search history API has authorization
    final authProvider = context.read<AuthProvider>();
    if (authProvider.accessToken != null) {
      _itemApiService.setAuthToken(authProvider.accessToken!);
      print(
          '[SearchScreen] Token set on ItemApiService: ${authProvider.accessToken!.substring(0, 20)}...');
    }
    // Load categories on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
      _loadSearchHistory();
    });
  }

  Future<void> _loadSearchHistory() async {
    try {
      setState(() {
        _isLoadingSearchHistory = true;
      });

      // Use the new /api/v2/search/history/recent endpoint
      final searchTerms = await _itemApiService.getRecentSearchHistory(
        limit: 5,
      );

      print('[SearchScreen] Search terms loaded: $searchTerms');
      print('[SearchScreen] Search terms count: ${searchTerms.length}');

      setState(() {
        // Convert search terms to display format - just keep the keyword
        recentSearches = searchTerms.map((term) {
          return {
            'term': term,
          };
        }).toList();
        _isLoadingSearchHistory = false;
      });

      print(
          '[SearchScreen] Loaded ${recentSearches.length} recent search history items');
    } catch (e) {
      print('[SearchScreen] Error loading search history: $e');
      setState(() {
        _isLoadingSearchHistory = false;
      });
    }
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

      // Reload search history after search
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadSearchHistory();
      });
    }
  }

  void _navigateToCategoryResults(String categoryId, String categoryName) {
    print('[SearchScreen] _navigateToCategoryResults called');
    print('[SearchScreen]   categoryId: $categoryId');
    print('[SearchScreen]   categoryName: $categoryName');
    print('[SearchScreen]   routeName: ${AppRoutes.searchResultsName}');
    context.pushNamed(AppRoutes.searchResultsName, queryParameters: {
      'categoryId': categoryId,
      'categoryName': categoryName
    }).then((_) => print('[SearchScreen] Navigation completed'));
  }

  Future<void> _deleteSearchHistory() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xóa lịch sử tìm kiếm'),
          content:
              const Text('Bạn có chắc chắn muốn xóa toàn bộ lịch sử tìm kiếm?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final success = await _itemApiService.deleteSearchHistory();

      if (success) {
        setState(() {
          recentSearches.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa lịch sử tìm kiếm')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi khi xóa lịch sử tìm kiếm')),
          );
        }
      }
    } catch (e) {
      print('[SearchScreen] Error deleting search history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _handleImageSearch() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();

      print('[SearchScreen] Camera permission status: $status');

      if (status.isDenied) {
        // Permission denied
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cần cấp quyền truy cập camera')),
          );
        }
        return;
      } else if (status.isPermanentlyDenied) {
        // Permission permanently denied, open app settings
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Quyền camera bị từ chối. Vui lòng cấp quyền trong cài đặt.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        openAppSettings();
        return;
      }

      // Show bottom sheet with camera/gallery options
      if (mounted) {
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Chụp ảnh'),
                  onTap: () {
                    Navigator.pop(context);
                    _captureAndSearchImage();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Chọn từ thư viện'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSearchImage();
                  },
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      print('[SearchScreen] Error in _handleImageSearch: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _captureAndSearchImage() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        await _searchByImage(photo);
      }
    } catch (e) {
      print('[SearchScreen] Error capturing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _pickAndSearchImage() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (photo != null) {
        await _searchByImage(photo);
      }
    } catch (e) {
      print('[SearchScreen] Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _searchByImage(XFile imageFile) async {
    try {
      if (!mounted) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Upload to Cloudinary
      print('[SearchScreen] Uploading image to Cloudinary...');
      final imageUrl = await _cloudinaryService.uploadSearchImage(
        File(imageFile.path),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      print('[SearchScreen] Image uploaded: $imageUrl');

      // Search by image using the API
      print('[SearchScreen] Searching by image with URL: $imageUrl');
      final results = await _itemApiService.searchByImage(imageUrl);

      if (!mounted) return;

      // Navigate to results
      print('[SearchScreen] Got ${results.length} results');
      context.pushNamed(
        AppRoutes.searchResultsName,
        queryParameters: {'imageUrl': imageUrl},
        extra: results,
      );
    } catch (e) {
      print('[SearchScreen] Error searching by image: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tìm kiếm: $e')),
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
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt,
                      color: AppColors.textSecondary),
                  onPressed: _handleImageSearch,
                  tooltip: 'Tìm kiếm bằng hình ảnh',
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon:
                        const Icon(Icons.clear, color: AppColors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
              ],
            ),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (recentSearches.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history,
                          size: 48,
                          color: AppColors.textSecondary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có lịch sử tìm kiếm',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentSearches.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final search = recentSearches[index];
                        return GestureDetector(
                          onTap: () => _navigateToResults(search['term']),
                          child: Row(
                            children: [
                              Icon(
                                Icons.history,
                                color: AppColors.textSecondary.withOpacity(0.6),
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  search['term'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _deleteSearchHistory,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Xóa lịch sử tìm kiếm'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: BorderSide(
                            color: AppColors.textSecondary.withOpacity(0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                            onTap: () => _navigateToCategoryResults(
                                category.id, category.name),
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
