import 'package:flutter/material.dart';
import 'package:kltn_sharing_app/data/models/gamification_response_model.dart';
import 'package:kltn_sharing_app/data/services/gamification_api_service.dart';

class GamificationProvider extends ChangeNotifier {
  final GamificationApiService _gamificationApiService;

  List<GamificationDto> _leaderboard = [];
  List<GamificationDto> _topUsers = [];
  GamificationDto? _currentUserStats;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 0;
  int _totalPages = 0;

  GamificationProvider({required GamificationApiService gamificationApiService})
      : _gamificationApiService = gamificationApiService;

  // Getters
  List<GamificationDto> get leaderboard => _leaderboard;
  List<GamificationDto> get topUsers => _topUsers;
  GamificationDto? get currentUserStats => _currentUserStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  /// Set auth token
  void setAuthToken(String accessToken) {
    _gamificationApiService.setAuthToken(accessToken);
  }

  /// Load full leaderboard
  Future<void> loadLeaderboard({int page = 0, int size = 10}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _gamificationApiService.getLeaderboard(
        page: page,
        size: size,
        sortBy: 'points',
        sortDirection: 'DESC',
      );

      _leaderboard = response.content;
      _currentPage = response.currentPage;
      _totalPages = response.totalPages;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load top 3 users for podium
  Future<void> loadTopUsers({int limit = 3}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _topUsers = await _gamificationApiService.getTopUsers(limit: limit);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load current user's gamification stats
  Future<void> loadCurrentUserStats() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentUserStats = await _gamificationApiService.getCurrentUserStats();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load next page of leaderboard
  Future<void> loadNextPage({int size = 10}) async {
    if (_currentPage < _totalPages - 1) {
      await loadLeaderboard(page: _currentPage + 1, size: size);
    }
  }

  /// Load previous page of leaderboard
  Future<void> loadPreviousPage({int size = 10}) async {
    if (_currentPage > 0) {
      await loadLeaderboard(page: _currentPage - 1, size: size);
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _leaderboard = [];
    _topUsers = [];
    _currentUserStats = null;
    _isLoading = false;
    _errorMessage = null;
    _currentPage = 0;
    _totalPages = 0;
    notifyListeners();
  }
}
