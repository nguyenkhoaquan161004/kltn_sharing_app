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
