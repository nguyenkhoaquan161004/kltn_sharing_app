class MessageModel {
  final int messageId;
  final int senderId;
  final int receiverId;
  final int? itemId; // Có thể null
  final String content;
  final DateTime createdAt;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    this.itemId,
    required this.content,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['message_id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      receiverId: json['receiver_id'] ?? 0,
      itemId: json['item_id'],
      content: json['content'] ?? '',
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      if (itemId != null) 'item_id': itemId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    int? messageId,
    int? senderId,
    int? receiverId,
    int? itemId,
    String? content,
    DateTime? createdAt,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      itemId: itemId ?? this.itemId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
