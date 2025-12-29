import 'package:flutter/foundation.dart';
import 'package:kltn_sharing_app/data/models/recommendation_response_model.dart';
import 'package:kltn_sharing_app/data/services/recommendation_api_service.dart';

/// Provider for managing recommendations state
class RecommendationProvider extends ChangeNotifier {
  final RecommendationApiService _apiService;

  // Recommendations (Đề xuất)
  List<RecommendationDto> _recommendations = [];
  bool _isLoadingRecommendations = false;
  String? _recommendationsError;
  int _totalRecommendations = 0; // Add total count

  // Trending recommendations (Gầy đây)
  List<RecommendationDto> _trendingRecommendations = [];
  bool _isLoadingTrending = false;
  String? _trendingError;
  int _totalTrendingRecommendations = 0; // Add total count

  RecommendationProvider({required RecommendationApiService apiService})
      : _apiService = apiService;

  // Getters for recommendations
  List<RecommendationDto> get recommendations => _recommendations;
  bool get isLoadingRecommendations => _isLoadingRecommendations;
  String? get recommendationsError => _recommendationsError;
  int get totalRecommendations => _totalRecommendations;

  // Getters for trending
  List<RecommendationDto> get trendingRecommendations =>
      _trendingRecommendations;
  bool get isLoadingTrending => _isLoadingTrending;
  String? get trendingError => _trendingError;
  int get totalTrendingRecommendations => _totalTrendingRecommendations;

  /// Load recommendations (Đề xuất)
  Future<void> loadRecommendations({int page = 0, int size = 20}) async {
    try {
      _isLoadingRecommendations = true;
      _recommendationsError = null;
      notifyListeners();

      final response = await _apiService.getRecommendations(
        page: page,
        size: size,
      );

      _recommendations = response.data.data;
      _totalRecommendations = response.data.totalItems;
      print(
          '[RecommendationProvider] loadRecommendations: Received ${_recommendations.length} items, total: $_totalRecommendations');
      _isLoadingRecommendations = false;
      notifyListeners();
    } catch (e) {
      _isLoadingRecommendations = false;
      _recommendationsError = e.toString().replaceAll('Exception: ', '');
      print(
          '[RecommendationProvider] Error loading recommendations: $_recommendationsError');
      notifyListeners();
    }
  }

  /// Load trending recommendations (Gầy đây)
  Future<void> loadTrendingRecommendations(
      {int page = 0, int size = 20}) async {
    try {
      _isLoadingTrending = true;
      _trendingError = null;
      notifyListeners();

      final response = await _apiService.getTrendingRecommendations(
        page: page,
        size: size,
      );

      _trendingRecommendations = response.data.data;
      _totalTrendingRecommendations = response.data.totalItems;
      print(
          '[RecommendationProvider] loadTrendingRecommendations: Received ${_trendingRecommendations.length} items, total: $_totalTrendingRecommendations');
      _isLoadingTrending = false;
      notifyListeners();
    } catch (e) {
      _isLoadingTrending = false;
      _trendingError = e.toString().replaceAll('Exception: ', '');
      print('[RecommendationProvider] Error loading trending: $_trendingError');
      notifyListeners();
    }
  }

  /// Load more recommendations (appends to existing list for infinite scroll)
  Future<void> loadMoreRecommendations({int page = 0, int limit = 20}) async {
    try {
      final response = await _apiService.getRecommendations(
        page: page,
        size: limit,
      );

      _recommendations.addAll(response.data.data);
      print(
          '[RecommendationProvider] loadMoreRecommendations: Added ${response.data.data.length} items');
      notifyListeners();
    } catch (e) {
      _recommendationsError = e.toString().replaceAll('Exception: ', '');
      print(
          '[RecommendationProvider] Error loading more recommendations: $_recommendationsError');
      notifyListeners();
    }
  }

  /// Load more trending recommendations (appends to existing list for infinite scroll)
  Future<void> loadMoreTrendingRecommendations(
      {int page = 0, int size = 20}) async {
    try {
      final response = await _apiService.getTrendingRecommendations(
        page: page,
        size: size,
      );

      _trendingRecommendations.addAll(response.data.data);
      print(
          '[RecommendationProvider] loadMoreTrendingRecommendations: Added ${response.data.data.length} items');
      notifyListeners();
    } catch (e) {
      _trendingError = e.toString().replaceAll('Exception: ', '');
      print(
          '[RecommendationProvider] Error loading more trending: $_trendingError');
      notifyListeners();
    }
  }

  /// Set auth token
  void setAuthToken(String accessToken) {
    _apiService.setAuthToken(accessToken);
  }

  /// Remove auth token
  void removeAuthToken() {
    _apiService.removeAuthToken();
  }

  /// Clear all data
  void clearAll() {
    _recommendations.clear();
    _trendingRecommendations.clear();
    _recommendationsError = null;
    _trendingError = null;
    notifyListeners();
  }
}
