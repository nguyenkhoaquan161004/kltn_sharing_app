// Gamification/Leaderboard models

class GamificationDto {
  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final int points;
  final int rank;
  final int itemsShared;
  final int itemsReceived;
  final String? badge;

  GamificationDto({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.points,
    required this.rank,
    required this.itemsShared,
    required this.itemsReceived,
    this.badge,
  });

  factory GamificationDto.fromJson(Map<String, dynamic> json) {
    return GamificationDto(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
      points: json['points'] ?? 0,
      rank: json['rank'] ?? 0,
      itemsShared: json['itemsShared'] ?? json['items_shared'] ?? 0,
      itemsReceived: json['itemsReceived'] ?? json['items_received'] ?? 0,
      badge: json['badge'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'avatarUrl': avatarUrl,
      'points': points,
      'rank': rank,
      'itemsShared': itemsShared,
      'itemsReceived': itemsReceived,
      'badge': badge,
    };
  }
}

/// Paginated response for leaderboard
class LeaderboardResponse {
  final List<GamificationDto> content;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  LeaderboardResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    List<GamificationDto> items = [];

    if (json['content'] is List) {
      items = (json['content'] as List)
          .map((item) => GamificationDto.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return LeaderboardResponse(
      content: items,
      totalElements: json['totalElements'] ?? json['total_elements'] ?? 0,
      totalPages: json['totalPages'] ?? json['total_pages'] ?? 0,
      currentPage: json['number'] ?? json['currentPage'] ?? 0,
      pageSize: json['size'] ?? json['pageSize'] ?? 10,
    );
  }
}

/// New Leaderboard Entry DTO from backend /api/v2/gamification/leaderboard
class LeaderboardEntryDto {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int totalPoints;
  final int rank;
  final int level;
  final double? distanceKm; // Only for NEARBY scope

  LeaderboardEntryDto({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.totalPoints,
    required this.rank,
    required this.level,
    this.distanceKm,
  });

  factory LeaderboardEntryDto.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryDto(
      userId: json['userId'] ?? json['user_id'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
      totalPoints: json['totalPoints'] ?? json['total_points'] ?? 0,
      rank: json['rank'] ?? 0,
      level: json['level'] ?? 0,
      distanceKm: json['distanceKm'] != null
          ? double.tryParse(json['distanceKm'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'avatarUrl': avatarUrl,
      'totalPoints': totalPoints,
      'rank': rank,
      'level': level,
      if (distanceKm != null) 'distanceKm': distanceKm,
    };
  }
}

/// New Leaderboard Response from backend /api/v2/gamification/leaderboard
class NewLeaderboardResponse {
  final List<LeaderboardEntryDto> entries;
  final LeaderboardEntryDto? currentUserEntry;
  final int totalUsers;
  final int page;
  final int size;
  final int totalPages;
  final String timeFrame;
  final String scope;
  final double? radiusKm;

  NewLeaderboardResponse({
    required this.entries,
    this.currentUserEntry,
    required this.totalUsers,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.timeFrame,
    required this.scope,
    this.radiusKm,
  });

  factory NewLeaderboardResponse.fromJson(Map<String, dynamic> json) {
    List<LeaderboardEntryDto> entries = [];

    if (json['entries'] is List) {
      entries = (json['entries'] as List)
          .map((item) =>
              LeaderboardEntryDto.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return NewLeaderboardResponse(
      entries: entries,
      currentUserEntry: json['currentUserEntry'] != null
          ? LeaderboardEntryDto.fromJson(
              json['currentUserEntry'] as Map<String, dynamic>)
          : null,
      totalUsers: json['totalUsers'] ?? json['total_users'] ?? 0,
      page: json['page'] ?? 0,
      size: json['size'] ?? 20,
      totalPages: json['totalPages'] ?? json['total_pages'] ?? 1,
      timeFrame: json['timeFrame'] ?? 'ALL_TIME',
      scope: json['scope'] ?? 'GLOBAL',
      radiusKm: json['radiusKm'] != null
          ? double.tryParse(json['radiusKm'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entries': entries.map((e) => e.toJson()).toList(),
      'currentUserEntry': currentUserEntry?.toJson(),
      'totalUsers': totalUsers,
      'page': page,
      'size': size,
      'totalPages': totalPages,
      'timeFrame': timeFrame,
      'scope': scope,
      if (radiusKm != null) 'radiusKm': radiusKm,
    };
  }
}
