import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/mock_data_service.dart';
import '../../../data/models/item_model.dart';
import '../../widgets/item_card.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool _showFilters = false;
  final MockDataService _mockDataService = MockDataService();

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
          'Kết quả tìm kiếm',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.textPrimary),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
              context.go('/filter');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Chip(
                    label: const Text('Giá: Thấp → Cao'),
                    backgroundColor: AppColors.primaryTeal,
                    labelStyle: const TextStyle(color: AppColors.white),
                  ),
                  Chip(
                    label: const Text('Rating: Cao'),
                    backgroundColor: AppColors.lightGray,
                  ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<ItemModel>>(
              future: _mockDataService.getAvailableItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy sản phẩm nào'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ItemCard(
                      item: item,
                      showTimeRemaining: true,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
