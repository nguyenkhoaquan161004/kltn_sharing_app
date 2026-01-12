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

  int _totalItems = 0;
  int get totalItems => _totalItems;

  // Filters
  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  // Nearby items state
  List<ItemDto> _nearbyItems = [];
  List<ItemDto> get nearbyItems => _nearbyItems;

  bool _isLoadingNearby = false;
  bool get isLoadingNearby => _isLoadingNearby;

  String? _nearbyErrorMessage;
  String? get nearbyErrorMessage => _nearbyErrorMessage;

  int _nearbyCurrentPage = 0;
  int _nearbyTotalPages = 0;
  int _nearbyTotalItems = 0;
  int get nearbyTotalItems => _nearbyTotalItems;

  /// Set authorization token from AuthProvider
  void setAuthToken(String accessToken) {
    _itemApiService.setAuthToken(accessToken);
  }

  /// Set token callback from AuthProvider
  void setGetValidTokenCallback(Future<String?> Function() callback) {
    print('[ItemProvider] setGetValidTokenCallback called');
    _itemApiService.setGetValidTokenCallback(callback);
  }

  /// Load items with pagination - simplified parameters
  /// Supports keyword search and category filtering
  Future<void> loadItems({
    int page = 0,
    String? search,
    String? category,
    String? status,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _itemApiService.searchItems(
        page: page,
        size: 20,
        keyword: search,
        categoryId: category,
        status: status,
      );

      _items = response.content;
      _currentPage = response.currentPage;
      _totalPages = response.totalPages;
      _totalItems = response.totalElements;

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

  /// Load more items (appends to existing list for infinite scroll)
  Future<void> loadMoreItems({int page = 0, int limit = 20}) async {
    try {
      final response = await _itemApiService.searchItems(
        page: page,
        size: limit,
        status: 'AVAILABLE',
      );

      _items.addAll(response.content);
      _currentPage = response.currentPage;
      _totalPages = response.totalPages;
      _totalItems = response.totalElements;

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('[ItemProvider] Error loading more items: $_errorMessage');
      notifyListeners();
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

  /// Load nearby items based on user location
  /// Backend filters results by distance using lat/lon coordinates
  Future<void> loadNearbyItems({
    required double latitude,
    required double longitude,
    double maxDistanceKm = 50,
    int page = 0,
  }) async {
    try {
      print(
          '[ItemProvider.loadNearbyItems] Starting - lat: $latitude, lon: $longitude, maxDistanceKm: $maxDistanceKm, page: $page');
      _isLoadingNearby = true;
      _nearbyErrorMessage = null;
      notifyListeners();
      print('[ItemProvider.loadNearbyItems] Calling API...');

      final response = await _itemApiService.searchNearbyItems(
        latitude: latitude,
        longitude: longitude,
        maxDistanceKm: maxDistanceKm,
        page: page,
        size: 20,
        status: 'AVAILABLE',
      );

      print('[ItemProvider.loadNearbyItems] API response received');
      print(
          '[ItemProvider.loadNearbyItems] Response content length: ${response.content.length}');
      print(
          '[ItemProvider.loadNearbyItems] Response totalElements: ${response.totalElements}');

      _nearbyItems = response.content;
      _nearbyCurrentPage = response.currentPage;
      _nearbyTotalPages = response.totalPages;
      _nearbyTotalItems = response.totalElements;
      _nearbyErrorMessage = null; // Clear error on success

      print(
          '[ItemProvider] Loaded ${_nearbyItems.length} nearby items, total: $_nearbyTotalItems');
      _isLoadingNearby = false;
      notifyListeners();
      print('[ItemProvider.loadNearbyItems] Done - notified listeners');
    } catch (e) {
      _isLoadingNearby = false;
      final errorMsg = e.toString().replaceAll('Exception: ', '');

      // Chỉ set error nếu không có data. Nếu đã có data → GIỮ NGUYÊN để UX không bị xáo trộn
      if (_nearbyItems.isEmpty) {
        _nearbyErrorMessage = errorMsg;
        print(
            '[ItemProvider] Error loading nearby items (no existing data): $_nearbyErrorMessage');
      } else {
        print(
            '[ItemProvider] Error loading nearby items (but keeping existing data): $errorMsg');
        _nearbyErrorMessage = null; // Giữ nguyên dữ liệu cũ, không show error
      }

      print('[ItemProvider] Full error: $e');
      notifyListeners();
    }
  }

  /// Load more nearby items (appends to existing list for infinite scroll)
  Future<void> loadMoreNearbyItems({
    required double latitude,
    required double longitude,
    double maxDistanceKm = 50,
    int page = 0,
  }) async {
    // Don't load if we already have all items
    if (_nearbyItems.length >= _nearbyTotalItems) {
      print(
          '[ItemProvider] Already loaded all items (${_nearbyItems.length}/$_nearbyTotalItems), skipping');
      return;
    }

    try {
      print(
          '[ItemProvider.loadMoreNearbyItems] Loading page $page - current: ${_nearbyItems.length}, total: $_nearbyTotalItems');

      final response = await _itemApiService.searchNearbyItems(
        latitude: latitude,
        longitude: longitude,
        maxDistanceKm: maxDistanceKm,
        page: page,
        size: 20,
        status: 'AVAILABLE',
      );

      _nearbyItems.addAll(response.content);
      _nearbyCurrentPage = response.currentPage;
      _nearbyTotalPages = response.totalPages;
      _nearbyTotalItems = response.totalElements;

      print(
          '[ItemProvider] Loaded more nearby items, total now: ${_nearbyItems.length}/$_nearbyTotalItems');
      notifyListeners();
    } catch (e) {
      _nearbyErrorMessage = e.toString().replaceAll('Exception: ', '');
      print(
          '[ItemProvider] Error loading more nearby items: $_nearbyErrorMessage');
      notifyListeners();
    }
  }

  /// Refresh nearby items (reload first page)
  Future<void> refreshNearbyItems({
    required double latitude,
    required double longitude,
    double maxDistanceKm = 50,
  }) async {
    await loadNearbyItems(
      latitude: latitude,
      longitude: longitude,
      maxDistanceKm: maxDistanceKm,
      page: 0,
    );
  }
}
