import 'package:dio/dio.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';

/// Admin API Service - Handles all admin operations
class AdminApiService {
  final Dio _dio;

  AdminApiService(this._dio);

  // ==================== USER MANAGEMENT ====================
  
  /// Get all users
  /// GET /api/v2/users
  Future<List<Map<String, dynamic>>> getAllUsers({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v2/users',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data'] as List);
        }
      }
      throw Exception('Failed to fetch users');
    } catch (e) {
      print('[AdminApiService] Get users error: $e');
      rethrow;
    }
  }

  /// Delete user
  /// DELETE /api/v2/users/{userId}
  Future<void> deleteUser(String userId) async {
    try {
      final response = await _dio.delete('/api/v2/users/$userId');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      print('[AdminApiService] Delete user error: $e');
      rethrow;
    }
  }

  // ==================== CATEGORY MANAGEMENT ====================
  
  /// Get all categories
  /// GET /api/v2/categories
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      final response = await _dio.get('/api/v2/categories');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data'] as List);
        }
      }
      throw Exception('Failed to fetch categories');
    } catch (e) {
      print('[AdminApiService] Get categories error: $e');
      rethrow;
    }
  }

  /// Get category by ID
  /// GET /api/v2/categories/{categoryId}
  Future<Map<String, dynamic>> getCategoryById(String categoryId) async {
    try {
      final response = await _dio.get('/api/v2/categories/$categoryId');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      throw Exception('Failed to fetch category');
    } catch (e) {
      print('[AdminApiService] Get category error: $e');
      rethrow;
    }
  }

  /// Create category
  /// POST /api/v2/categories
  Future<Map<String, dynamic>> createCategory({
    required String name,
    required String description,
    String? icon,
    String? color,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v2/categories',
        data: {
          'name': name,
          'description': description,
          'icon': icon,
          'color': color,
        },
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      throw Exception('Failed to create category');
    } catch (e) {
      print('[AdminApiService] Create category error: $e');
      rethrow;
    }
  }

  /// Update category
  /// PUT /api/v2/categories/{categoryId}
  Future<Map<String, dynamic>> updateCategory(
    String categoryId, {
    required String name,
    required String description,
    String? icon,
    String? color,
  }) async {
    try {
      final response = await _dio.put(
        '/api/v2/categories/$categoryId',
        data: {
          'name': name,
          'description': description,
          'icon': icon,
          'color': color,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      throw Exception('Failed to update category');
    } catch (e) {
      print('[AdminApiService] Update category error: $e');
      rethrow;
    }
  }

  /// Delete category
  /// DELETE /api/v2/categories/{categoryId}
  Future<void> deleteCategory(String categoryId) async {
    try {
      final response = await _dio.delete('/api/v2/categories/$categoryId');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete category');
      }
    } catch (e) {
      print('[AdminApiService] Delete category error: $e');
      rethrow;
    }
  }

  // ==================== BADGE/ACHIEVEMENT MANAGEMENT ====================
  
  /// Get all badges
  /// GET /api/v2/admin/gamification/badges
  Future<List<Map<String, dynamic>>> getAllBadges() async {
    try {
      final response = await _dio.get('/api/v2/admin/gamification/badges');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data'] as List);
        }
      }
      throw Exception('Failed to fetch badges');
    } catch (e) {
      print('[AdminApiService] Get badges error: $e');
      rethrow;
    }
  }

  /// Get badge by ID
  /// GET /api/v2/admin/gamification/badges/{id}
  Future<Map<String, dynamic>> getBadgeById(String badgeId) async {
    try {
      final response = await _dio.get('/api/v2/admin/gamification/badges/$badgeId');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      throw Exception('Failed to fetch badge');
    } catch (e) {
      print('[AdminApiService] Get badge error: $e');
      rethrow;
    }
  }

  /// Create badge
  /// POST /api/v2/admin/gamification/badges
  Future<Map<String, dynamic>> createBadge({
    required String name,
    required String description,
    String? icon,
    int? pointsRequired,
    String? rarity, // COMMON, RARE, EPIC, LEGENDARY
  }) async {
    try {
      final response = await _dio.post(
        '/api/v2/admin/gamification/badges',
        data: {
          'name': name,
          'description': description,
          'icon': icon,
          'pointsRequired': pointsRequired,
          'rarity': rarity,
        },
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      throw Exception('Failed to create badge');
    } catch (e) {
      print('[AdminApiService] Create badge error: $e');
      rethrow;
    }
  }

  /// Update badge
  /// PUT /api/v2/admin/gamification/badges/{id}
  Future<Map<String, dynamic>> updateBadge(
    String badgeId, {
    required String name,
    required String description,
    String? icon,
    int? pointsRequired,
    String? rarity,
  }) async {
    try {
      final response = await _dio.put(
        '/api/v2/admin/gamification/badges/$badgeId',
        data: {
          'name': name,
          'description': description,
          'icon': icon,
          'pointsRequired': pointsRequired,
          'rarity': rarity,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      throw Exception('Failed to update badge');
    } catch (e) {
      print('[AdminApiService] Update badge error: $e');
      rethrow;
    }
  }

  /// Delete badge
  /// DELETE /api/v2/admin/gamification/badges/{id}
  Future<void> deleteBadge(String badgeId) async {
    try {
      final response = await _dio.delete('/api/v2/admin/gamification/badges/$badgeId');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete badge');
      }
    } catch (e) {
      print('[AdminApiService] Delete badge error: $e');
      rethrow;
    }
  }

  // ==================== GAMIFICATION ====================
  
  /// Add points to user
  /// POST /api/v2/gamification/points/add
  Future<Map<String, dynamic>> addPointsToUser({
    required String userId,
    required int points,
    required String reason,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v2/gamification/points/add',
        data: {
          'userId': userId,
          'points': points,
          'reason': reason,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      throw Exception('Failed to add points');
    } catch (e) {
      print('[AdminApiService] Add points error: $e');
      rethrow;
    }
  }

  // ==================== NOTIFICATIONS ====================
  
  /// Send notification to user
  /// POST /api/v2/notifications/send
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v2/notifications/send',
        data: {
          'userId': userId,
          'title': title,
          'message': message,
        },
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to send notification');
      }
    } catch (e) {
      print('[AdminApiService] Send notification error: $e');
      rethrow;
    }
  }
}
