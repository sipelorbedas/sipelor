/// Chat message model for admin-user communication
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final bool isAdmin;
  final String? receiverId;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.isAdmin,
    this.receiverId,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String,
      isAdmin: json['is_admin'] as bool? ?? false,
      receiverId: json['receiver_id'] as String?,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'is_admin': isAdmin,
      'receiver_id': receiverId,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of this message with some fields changed
  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    bool? isAdmin,
    String? receiverId,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      isAdmin: isAdmin ?? this.isAdmin,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if this message is sent by the given user
  bool isSentBy(String userId) {
    return senderId == userId;
  }

  /// Check if this message is received by the given user
  bool isReceivedBy(String userId) {
    return receiverId == userId;
  }

  @override
  String toString() {
    final preview = message.length > 21
        ? '${message.substring(0, 21)}...'
        : message;
    return 'ChatMessage(id: $id, sender: $senderName, isAdmin: $isAdmin, message: $preview, isRead: $isRead)';
  }
}

/// Chat conversation summary for listing
class ChatConversation {
  final String userId;
  final String userName;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;

  ChatConversation({
    required this.userId,
    required this.userName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  factory ChatConversation.fromMessages({
    required String userId,
    required String userName,
    required List<ChatMessage> messages,
    required String currentUserId,
  }) {
    // Get last message
    final lastMsg = messages.isNotEmpty ? messages.first : null;
    
    // Count unread messages (messages sent to current user that are unread)
    final unread = messages.where((msg) => 
      msg.receiverId == currentUserId && !msg.isRead
    ).length;

    return ChatConversation(
      userId: userId,
      userName: userName,
      lastMessage: lastMsg?.message,
      lastMessageTime: lastMsg?.createdAt,
      unreadCount: unread,
      isOnline: false, // Can be implemented with presence system
    );
  }

  @override
  String toString() {
    return 'ChatConversation(user: $userName, unread: $unreadCount, lastMsg: ${lastMessage?.substring(0, lastMessage!.length > 20 ? 20 : lastMessage!.length)})';
  }
}
