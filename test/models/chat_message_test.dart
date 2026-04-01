import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/models/chat_message.dart';

void main() {
  group('ChatMessage Model', () {
    final testDateTime = DateTime(2024, 1, 1, 12, 0);
    
    final testMessage = ChatMessage(
      id: 'msg123',
      senderId: 'user456',
      senderName: 'John Doe',
      isAdmin: false,
      receiverId: 'admin789',
      message: 'Hello, I have a question',
      isRead: false,
      createdAt: testDateTime,
      updatedAt: testDateTime,
    );

    test('should create ChatMessage with all fields', () {
      expect(testMessage.id, 'msg123');
      expect(testMessage.senderId, 'user456');
      expect(testMessage.senderName, 'John Doe');
      expect(testMessage.isAdmin, false);
      expect(testMessage.receiverId, 'admin789');
      expect(testMessage.message, 'Hello, I have a question');
      expect(testMessage.isRead, false);
      expect(testMessage.createdAt, testDateTime);
    });

    test('should create ChatMessage with null receiverId', () {
      final broadcastMessage = ChatMessage(
        id: 'msg456',
        senderId: 'admin123',
        senderName: 'Admin',
        isAdmin: true,
        message: 'Broadcast message',
        isRead: false,
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      expect(broadcastMessage.receiverId, isNull);
      expect(broadcastMessage.isAdmin, true);
    });

    test('fromJson should parse JSON correctly', () {
      final json = {
        'id': 'msg123',
        'sender_id': 'user456',
        'sender_name': 'John Doe',
        'is_admin': false,
        'receiver_id': 'admin789',
        'message': 'Hello, I have a question',
        'is_read': false,
        'created_at': '2024-01-01T12:00:00.000',
        'updated_at': '2024-01-01T12:00:00.000',
      };

      final message = ChatMessage.fromJson(json);

      expect(message.id, 'msg123');
      expect(message.senderId, 'user456');
      expect(message.senderName, 'John Doe');
      expect(message.isAdmin, false);
      expect(message.receiverId, 'admin789');
      expect(message.message, 'Hello, I have a question');
      expect(message.isRead, false);
    });

    test('fromJson should handle default values', () {
      final json = {
        'id': 'msg456',
        'sender_id': 'user789',
        'sender_name': 'Jane Doe',
        'message': 'Test message',
        'created_at': '2024-01-01T12:00:00.000',
        'updated_at': '2024-01-01T12:00:00.000',
      };

      final message = ChatMessage.fromJson(json);

      expect(message.isAdmin, false); // Default
      expect(message.isRead, false); // Default
      expect(message.receiverId, isNull);
    });

    test('toJson should convert ChatMessage to JSON correctly', () {
      final json = testMessage.toJson();

      expect(json['id'], 'msg123');
      expect(json['sender_id'], 'user456');
      expect(json['sender_name'], 'John Doe');
      expect(json['is_admin'], false);
      expect(json['receiver_id'], 'admin789');
      expect(json['message'], 'Hello, I have a question');
      expect(json['is_read'], false);
      expect(json['created_at'], testDateTime.toIso8601String());
      expect(json['updated_at'], testDateTime.toIso8601String());
    });

    test('copyWith should update specified fields only', () {
      final updated = testMessage.copyWith(
        isRead: true,
        message: 'Updated message',
      );

      expect(updated.isRead, true);
      expect(updated.message, 'Updated message');
      expect(updated.id, testMessage.id);
      expect(updated.senderId, testMessage.senderId);
    });

    test('isSentBy should return true for sender', () {
      expect(testMessage.isSentBy('user456'), true);
      expect(testMessage.isSentBy('other-user'), false);
    });

    test('isReceivedBy should return true for receiver', () {
      expect(testMessage.isReceivedBy('admin789'), true);
      expect(testMessage.isReceivedBy('other-user'), false);
    });

    test('toString should include key info', () {
      final str = testMessage.toString();
      
      expect(str, contains('msg123'));
      expect(str, contains('John Doe'));
      expect(str, contains('isAdmin: false'));
      expect(str, contains('isRead: false'));
      expect(str, contains('Hello, I have a quest'));
    });

    test('toString should truncate long messages', () {
      final longMessage = ChatMessage(
        id: 'msg789',
        senderId: 'user123',
        senderName: 'Test User',
        isAdmin: false,
        message: 'This is a very long message that should be truncated in the toString output',
        isRead: false,
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      final str = longMessage.toString();
      expect(str, contains('This is a very long m...'));
    });

    test('round trip JSON conversion should preserve data', () {
      final json = testMessage.toJson();
      final reconstructed = ChatMessage.fromJson(json);

      expect(reconstructed.id, testMessage.id);
      expect(reconstructed.senderId, testMessage.senderId);
      expect(reconstructed.message, testMessage.message);
      expect(reconstructed.isRead, testMessage.isRead);
    });
  });

  group('ChatConversation Model', () {
    final testDateTime = DateTime(2024, 1, 1, 12, 0);

    test('should create ChatConversation with all fields', () {
      final conversation = ChatConversation(
        userId: 'user123',
        userName: 'John Doe',
        lastMessage: 'Hello!',
        lastMessageTime: testDateTime,
        unreadCount: 5,
        isOnline: true,
      );

      expect(conversation.userId, 'user123');
      expect(conversation.userName, 'John Doe');
      expect(conversation.lastMessage, 'Hello!');
      expect(conversation.lastMessageTime, testDateTime);
      expect(conversation.unreadCount, 5);
      expect(conversation.isOnline, true);
    });

    test('should create ChatConversation with defaults', () {
      final conversation = ChatConversation(
        userId: 'user456',
        userName: 'Jane Doe',
      );

      expect(conversation.unreadCount, 0);
      expect(conversation.isOnline, false);
      expect(conversation.lastMessage, isNull);
      expect(conversation.lastMessageTime, isNull);
    });

    test('fromMessages should create conversation from message list', () {
      final messages = [
        ChatMessage(
          id: 'msg3',
          senderId: 'user123',
          senderName: 'User',
          isAdmin: false,
          receiverId: 'admin',
          message: 'Latest message',
          isRead: false,
          createdAt: testDateTime.add(Duration(hours: 2)),
          updatedAt: testDateTime.add(Duration(hours: 2)),
        ),
        ChatMessage(
          id: 'msg2',
          senderId: 'admin',
          senderName: 'Admin',
          isAdmin: true,
          receiverId: 'user123',
          message: 'Second message',
          isRead: false,
          createdAt: testDateTime.add(Duration(hours: 1)),
          updatedAt: testDateTime.add(Duration(hours: 1)),
        ),
        ChatMessage(
          id: 'msg1',
          senderId: 'user123',
          senderName: 'User',
          isAdmin: false,
          receiverId: 'admin',
          message: 'First message',
          isRead: true,
          createdAt: testDateTime,
          updatedAt: testDateTime,
        ),
      ];

      final conversation = ChatConversation.fromMessages(
        userId: 'user123',
        userName: 'John Doe',
        messages: messages,
        currentUserId: 'user123',
      );

      expect(conversation.userId, 'user123');
      expect(conversation.userName, 'John Doe');
      expect(conversation.lastMessage, 'Latest message');
      expect(conversation.unreadCount, 1); // Only msg2 is unread and sent to user123
    });

    test('fromMessages should handle empty message list', () {
      final conversation = ChatConversation.fromMessages(
        userId: 'user789',
        userName: 'Test User',
        messages: [],
        currentUserId: 'admin',
      );

      expect(conversation.lastMessage, isNull);
      expect(conversation.lastMessageTime, isNull);
      expect(conversation.unreadCount, 0);
    });

    test('toString should include key info', () {
      final conversation = ChatConversation(
        userId: 'user123',
        userName: 'John Doe',
        lastMessage: 'Hello there! How are you doing?',
        unreadCount: 3,
      );

      final str = conversation.toString();
      
      expect(str, contains('John Doe'));
      expect(str, contains('unread: 3'));
      expect(str, contains('Hello there! How are'));
    });
  });
}
