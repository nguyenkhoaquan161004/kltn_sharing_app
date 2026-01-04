class MessageModel {
  final String id; // UUID from backend
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String content;
  final String messageType; // TEXT, IMAGE, etc.
  final String? itemId;
  final bool readStatus;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.content,
    required this.messageType,
    this.itemId,
    required this.readStatus,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String? ?? json['message_id']?.toString() ?? '',
      senderId:
          json['senderId'] as String? ?? json['sender_id']?.toString() ?? '',
      senderName: json['senderName'] as String? ?? '',
      receiverId: json['receiverId'] as String? ??
          json['receiver_id']?.toString() ??
          '',
      receiverName: json['receiverName'] as String? ?? '',
      content: json['content'] as String? ?? '',
      messageType: json['messageType'] as String? ?? 'TEXT',
      itemId: json['itemId'] as String? ?? json['item_id']?.toString(),
      readStatus: json['readStatus'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'content': content,
      'messageType': messageType,
      'itemId': itemId,
      'readStatus': readStatus,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? receiverName,
    String? content,
    String? messageType,
    String? itemId,
    bool? readStatus,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      itemId: itemId ?? this.itemId,
      readStatus: readStatus ?? this.readStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Model for Conversation
class ConversationModel {
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final String? lastMessageSenderId;

  ConversationModel({
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    this.lastMessageSenderId,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      otherUserId: json['otherUserId'] as String? ?? '',
      otherUserName: json['otherUserName'] as String? ?? '',
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : DateTime.now(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'unreadCount': unreadCount,
      if (lastMessageSenderId != null)
        'lastMessageSenderId': lastMessageSenderId,
    };
  }
}
