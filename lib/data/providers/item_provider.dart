import 'package:flutter/material.dart';
import 'package:kltn_sharing_app/data/models/item_response_model.dart';
import 'package:kltn_sharing_app/data/services/item_api_service.dart';

class ItemProvider extends ChangeNotifier {
  final ItemApiService _itemApiService;

  ItemProvider({ItemApiService? itemApiService})
      : _itemApiService = itemApiService ?? ItemApiService();

  // State management
  List<ItemDto> _items = [];
  List<ItemDto> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _currentPage = 0;
  int _totalPages = 0;
  int get totalPages => _totalPages;

  // Filters
  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  /// Set authorization token from AuthProvider
  void setAuthToken(String accessToken) {
    _itemApiService.setAuthToken(accessToken);
  }

  /// Set token callback from AuthProvider
  void setGetValidTokenCallback(Future<String?> Function() callback) {
    _itemApiService.setGetValidTokenCallback(callback);
  }

  /// Load items with pagination
  Future<void> loadItems({
    int page = 0,
    String? search,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? status,
    double? latitude,
    double? longitude,
    int? radiusKm,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _itemApiService.searchItems(
        page: page,
        size: 20,
        keyword: search,
        category: category,
        minPrice: minPrice,
        maxPrice: maxPrice,
        status: status,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );

      _items = response.content;
      _currentPage = response.currentPage;
      _totalPages = response.totalPages;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('[ItemProvider] Error: $_errorMessage');
      notifyListeners();
    }
  }

  /// Load next page of items
  Future<void> loadNextPage() async {
    if (_currentPage < _totalPages - 1) {
      await loadItems(page: _currentPage + 1);
    }
  }

  /// Refresh items (reload first page)
  Future<void> refreshItems() async {
    await loadItems(page: 0);
  }

  /// Set selected category filter
  void setCategory(String? category) {
    _selectedCategory = category;
    loadItems(category: category);
  }

  /// Search items
  Future<void> searchItems(String query) async {
    await loadItems(search: query);
  }

  /// Get single item by ID
  Future<ItemDto?> getItemById(String itemId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final item = await _itemApiService.getItem(itemId);
      _isLoading = false;
      notifyListeners();
      return item;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('[ItemProvider] Error loading item: $_errorMessage');
      notifyListeners();
      return null;
    }
  }

  /// Clear all filters and reset to initial state
  void clearFilters() {
    _selectedCategory = null;
    _items = [];
    _errorMessage = null;
    _currentPage = 0;
    _totalPages = 0;
    notifyListeners();
  }
}
