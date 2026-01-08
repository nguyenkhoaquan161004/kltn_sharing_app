import 'package:flutter/material.dart';
import 'package:kltn_sharing_app/data/models/gamification_response_model.dart';
import 'package:kltn_sharing_app/data/services/gamification_api_service.dart';

class GamificationProvider extends ChangeNotifier {
  final GamificationApiService _gamificationApiService;

  List<GamificationDto> _leaderboard = [];
  List<GamificationDto> _topUsers = [];
  GamificationDto? _currentUserStats;
  dynamic
      _currentUserEntryFromLeaderboard; // LeaderboardEntryDto from leaderboard API
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
  dynamic get currentUserEntryFromLeaderboard =>
      _currentUserEntryFromLeaderboard;
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
      // If 403, silently fail (leaderboard is public and should work)
      // If other error, log it
      String errorMsg = e.toString();
      if (!errorMsg.contains('403')) {
        _errorMessage = errorMsg.replaceFirst('Exception: ', '');
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load top N users for podium
  Future<void> loadTopUsers({
    int limit = 3,
    String timeFrame = 'ALL_TIME',
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _topUsers = await _gamificationApiService.getTopUsers(
        limit: limit,
        timeFrame: timeFrame,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // If 403, silently fail (leaderboard is public and should work)
      String errorMsg = e.toString();
      if (!errorMsg.contains('403')) {
        _errorMessage = errorMsg.replaceFirst('Exception: ', '');
      }
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

      // Use authenticated version to get user's actual stats
      _currentUserStats = await _gamificationApiService.getCurrentUserStats();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // If 403, user not authenticated - that's okay
      // Leaderboard still works without user stats
      String errorMsg = e.toString();
      if (!errorMsg.contains('403')) {
        _errorMessage = errorMsg.replaceFirst('Exception: ', '');
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load leaderboard with scope (GLOBAL or NEARBY)
  /// For NEARBY, requires currentUserLat and currentUserLon
  Future<void> loadLeaderboardWithScope({
    required String scope, // 'GLOBAL' or 'NEARBY'
    String timeFrame = 'ALL_TIME',
    double? currentUserLat,
    double? currentUserLon,
    double radiusKm = 50.0,
    int page = 0,
    int size = 20,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _gamificationApiService.getLeaderboardWithScope(
        scope: scope,
        timeFrame: timeFrame,
        currentUserLat: currentUserLat,
        currentUserLon: currentUserLon,
        radiusKm: radiusKm,
        page: page,
        size: size,
      );

      // Convert LeaderboardEntryDto to GamificationDto format
      _leaderboard = response.entries
          .map((entry) => GamificationDto(
                id: entry.userId,
                userId: entry.userId,
                username: entry.username,
                avatarUrl: entry.avatarUrl,
                points: entry.totalPoints,
                rank: entry.rank,
                itemsShared: 0,
                itemsReceived: 0,
                badge: null,
              ))
          .toList();

      // Extract current user entry from leaderboard response
      if (response.currentUserEntry != null) {
        _currentUserEntryFromLeaderboard = response.currentUserEntry;
        print(
            '[GamificationProvider] Current user entry extracted from leaderboard');
      }

      _currentPage = response.page;
      _totalPages = response.totalPages;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // If 403, silently fail (leaderboard is public)
      String errorMsg = e.toString();
      if (!errorMsg.contains('403')) {
        _errorMessage = errorMsg.replaceFirst('Exception: ', '');
      }
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
