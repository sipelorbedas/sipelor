import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../models/push_notification.dart';

/// Service for handling chat operations between users and admin
class ChatService {
  static SupabaseClient get _client => Supabase.instance.client;

  // Cache for admin users to avoid repeated queries
  static List<String>? _adminUserIds;
  static DateTime? _adminCacheTime;

  // ========================================
  // MESSAGE OPERATIONS
  // ========================================

  /// Get first available admin user ID
  static Future<String?> getAdminUserId() async {
    try {
      // Check cache first (valid for 5 minutes)
      if (_adminUserIds != null && 
          _adminCacheTime != null && 
          DateTime.now().difference(_adminCacheTime!) < const Duration(minutes: 5)) {
        return _adminUserIds!.isNotEmpty ? _adminUserIds!.first : null;
      }

      if (kDebugMode) {
        if (kDebugMode) print('🔍 [ChatService] Fetching admin users');
      }

      // Fetch all admin and superadmin users
      final response = await _client
          .from('profiles')
          .select('id')
          .inFilter('role', ['admin', 'superadmin']);

      final adminIds = (response as List)
          .map((profile) => profile['id'] as String)
          .toList();

      // Update cache
      _adminUserIds = adminIds;
      _adminCacheTime = DateTime.now();

      if (kDebugMode) {
        if (kDebugMode) print('✅ [ChatService] Found ${adminIds.length} admin users');
      }

      return adminIds.isNotEmpty ? adminIds.first : null;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ChatService] Error fetching admin user: $e');
      }
      return null;
    }
  }

  /// Get unread chat message count for admin
  /// Returns the count of unread messages sent by users to admin
  static Future<int> getUnreadChatCountForAdmin() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return 0;
      }

      if (kDebugMode) {
        if (kDebugMode) print('📊 [ChatService] Fetching unread chat count for admin');
      }

      // Get all unread messages where receiver is current admin user
      final response = await _client
          .from('chat_messages')
          .select('id')
          .eq('receiver_id', currentUser.id)
          .eq('is_read', false);

      final count = (response as List).length;

      if (kDebugMode) {
        if (kDebugMode) print('📊 [ChatService] Unread chat count: $count');
      }

      return count;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ChatService] Error fetching unread count: $e');
      }
      return 0;
    }
  }

  /// Get unread chat message count for a specific user
  /// Returns the count of unread messages sent by admin to this user
  static Future<int> getUnreadChatCountForUser(String userId) async {
    try {
      if (kDebugMode) {
        if (kDebugMode) print('📊 [ChatService] Fetching unread chat count for user: $userId');
      }

      // Get all unread messages where receiver is this user
      final response = await _client
          .from('chat_messages')
          .select('id')
          .eq('receiver_id', userId)
          .eq('is_read', false);

      final count = (response as List).length;

      if (kDebugMode) {
        if (kDebugMode) print('📊 [ChatService] Unread chat count: $count');
      }

      return count;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ChatService] Error fetching unread count: $e');
      }
      return 0;
    }
  }

  /// Send a notification for new chat message
  static Future<void> _sendChatNotification({
    required String receiverId,
    required String senderName,
    required String message,
  }) async {
    try {
      if (kDebugMode) {
        if (kDebugMode) print('📬 [ChatService] Sending chat notification to $receiverId');
        if (kDebugMode) print('📬 [ChatService] Sender: $senderName');
        if (kDebugMode) print('📬 [ChatService] Message: ${message.substring(0, message.length > 50 ? 50 : message.length)}...');
      }

      // Truncate message if too long
      final truncatedMessage = message.length > 50 
          ? '${message.substring(0, 50)}...' 
          : message;

      final insertData = {
        'user_id': receiverId,
        'type': NotificationType.chatMessage,
        'title': 'Pesan baru dari $senderName',
        'body': truncatedMessage,
        'data': {
          'sender_name': senderName,
        },
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (kDebugMode) {
        if (kDebugMode) print('📬 [ChatService] Notification data: $insertData');
      }

      await _client.from('notifications').insert(insertData);

      if (kDebugMode) {
        if (kDebugMode) print('✅ [ChatService] Chat notification sent successfully to database');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ChatService] Error sending chat notification: $e');
        if (kDebugMode) print('❌ [ChatService] Stack trace: ${StackTrace.current}');
      }
      // Don't throw - notification failure shouldn't block message sending
    }
  }

  /// Send a message from current user.
  /// Admin replies use the `send_admin_chat_message` RPC (SECURITY DEFINER)
  /// to avoid RLS recursion on the profiles table.
  static Future<ChatMessage?> sendMessage({
    required String message,
    required String senderName,
    required bool isAdmin,
    String? receiverId,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        if (kDebugMode) print('📤 [ChatService] Sending message from ${currentUser.id} (isAdmin=$isAdmin)');
      }

      // If user is sending to admin and receiverId is null, get an admin ID
      String? finalReceiverId = receiverId;
      if (!isAdmin && receiverId == null) {
        finalReceiverId = await getAdminUserId();
        if (kDebugMode) {
          if (kDebugMode) print('📤 [ChatService] User message to admin: $finalReceiverId');
        }
      }

      Map<String, dynamic> response;

      if (isAdmin) {
        // ── Admin reply ──────────────────────────────────────────────────────
        // Use SECURITY DEFINER RPC to bypass the RLS recursion bug that occurs
        // when the INSERT policy tries to sub-query the profiles table.
        if (kDebugMode) {
          if (kDebugMode) print('📤 [ChatService] Admin send via RPC → receiver: $finalReceiverId');
        }

        if (finalReceiverId == null || finalReceiverId.isEmpty) {
          throw Exception('receiverId is required for admin messages');
        }

        final rpcResult = await _client.rpc(
          'send_admin_chat_message',
          params: {
            'p_receiver_id': finalReceiverId,
            'p_message': message,
            'p_sender_name': senderName,
          },
        );

        if (rpcResult == null) {
          throw Exception('RPC returned null — check Supabase function');
        }

        response = Map<String, dynamic>.from(rpcResult as Map);
      } else {
        // ── Regular user send ────────────────────────────────────────────────
        final data = {
          'sender_id': currentUser.id,
          'sender_name': senderName,
          'is_admin': false,
          'receiver_id': finalReceiverId,
          'message': message,
          'is_read': false,
        };

        // Insert without select() to avoid PGRST204 (RLS blocks read-back).
        // Build the response locally from the data we already know.
        await _client.from('chat_messages').insert(data);

        final now = DateTime.now().toIso8601String();
        response = {
          'id': 'local_$now',
          'sender_id': currentUser.id,
          'sender_name': senderName,
          'is_admin': false,
          'receiver_id': finalReceiverId,
          'message': message,
          'is_read': false,
          'created_at': now,
          'updated_at': now,
        };
      }

      if (kDebugMode) {
        if (kDebugMode) print('✅ [ChatService] Message sent successfully');
      }

      // Send notification to receiver
      if (finalReceiverId != null && finalReceiverId.isNotEmpty) {
        await _sendChatNotification(
          receiverId: finalReceiverId,
          senderName: senderName,
          message: message,
        );
      }

      return ChatMessage.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ChatService] Error sending message: $e');
      }
      rethrow;
    }
  }

  /// Get messages for a specific conversation
  /// If userId is null, get all messages (for admin view)
  static Future<List<ChatMessage>> getMessages({
    String? userId,
    int limit = 100,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        if (kDebugMode) print('📥 [ChatService] Fetching messages for user: ${userId ?? "all"}');
      }

      final response = userId != null
          ? await _client
              .from('chat_messages')
              .select()
              .or('sender_id.eq.$userId,receiver_id.eq.$userId')
              .order('created_at', ascending: false)
              .limit(limit)
          : await _client
              .from('chat_messages')
              .select()
              .order('created_at', ascending: false)
              .limit(limit);

      final messages = (response as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();

      if (kDebugMode) {
        if (kDebugMode) print('✅ [ChatService] Fetched ${messages.length} messages');
      }

      return messages;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ChatService] Error fetching messages: $e');
      }
      rethrow;
    }
  }

  /// Get conversation between current user and admin
  static Future<List<ChatMessage>> getUserAdminConversation() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        if (kDebugMode) print('💬 [ChatService] Fetching user-admin conversation');
      }

      final response = await _client
          .from('chat_messages')
          .select()
          .or('sender_id.eq.${currentUser.id},receiver_id.eq.${currentUser.id}')
          .order('created_at', ascending: false)
          .limit(100);

      final messages = (response as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();

      if (kDebugMode) {
        if (kDebugMode) print('✅ [ChatService] Fetched ${messages.length} messages in conversation');
      }

      return messages;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ChatService] Error fetching conversation: $e');
      }
      rethrow;
    }
  }

  /// Mark messages as read
  static Future<void> markMessagesAsRead(List<String> messageIds) async {
    try {
      if (messageIds.isEmpty) return;

      if (kDebugMode) {
        if (kDebugMode) print('✓ [ChatService] Marking ${messageIds.length} messages as read');
      }

      await _client
          .from('chat_messages')
          .update({'is_read': true})
          .inFilter('id', messageIds);

      if (kDebugMode) {
        if (kDebugMode) print('✅ [ChatService] Messages marked as read');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ChatService] Error marking messages as read: $e');
      }
      rethrow;
    }
  }

  /// Mark all messages from a user as read (for admin)
  static Future<void> markUserMessagesAsRead(String userId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        if (kDebugMode) print('✓ [ChatService] Marking all messages from $userId as read');
      }

      await _client
          .from('chat_messages')
          .update({'is_read': true})
          .eq('sender_id', userId)
          .eq('receiver_id', currentUser.id)
          .eq('is_read', false);

      if (kDebugMode) {
        if (kDebugMode) print('✅ [ChatService] User messages marked as read');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ChatService] Error marking user messages as read: $e');
      }
      rethrow;
    }
  }

  /// Get unread message count for current user
  static Future<int> getUnreadCount() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return 0;
      }

      final response = await _client
          .from('chat_messages')
          .select('id')
          .eq('receiver_id', currentUser.id)
          .eq('is_read', false)
          .count(CountOption.exact);

      final count = response.count;

      if (kDebugMode) {
        if (kDebugMode) print('📊 [ChatService] Unread messages: $count');
      }

      return count;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ChatService] Error getting unread count: $e');
      }
      return 0;
    }
  }

  // ========================================
  // REAL-TIME STREAMS
  // ========================================

  /// Stream messages in real-time for a specific conversation
  static Stream<List<ChatMessage>> streamUserAdminConversation() {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ChatService] Cannot stream - user not authenticated');
      }
      return Stream.value([]);
    }

    if (kDebugMode) {
      if (kDebugMode) print('🔄 [ChatService] Setting up real-time stream for user: ${currentUser.id}');
    }

    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          // Filter messages for current user's conversation
          final filtered = data.where((json) {
            final senderId = json['sender_id'] as String?;
            final receiverId = json['receiver_id'] as String?;
            return senderId == currentUser.id || receiverId == currentUser.id;
          }).toList();

          return filtered
              .map((json) => ChatMessage.fromJson(json))
              .toList();
        });
  }

  /// Stream all conversations for admin (grouped by user)
  static Stream<List<ChatMessage>> streamAllMessages() {
    if (kDebugMode) {
      if (kDebugMode) print('🔄 [ChatService] Setting up real-time stream for all messages');
    }

    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          return (data as List)
              .map((json) => ChatMessage.fromJson(json))
              .toList();
        });
  }

  // ========================================
  // CONVERSATION LIST (FOR ADMIN)
  // ========================================

  /// Get all users (for admin to initiate chat)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        if (kDebugMode) print('👥 [ChatService] Fetching all users');
      }

      // Get all non-admin users from profiles
      final response = await _client
          .from('profiles')
          .select('id, full_name, role')
          .neq('role', 'superadmin')
          .neq('role', 'admin')
          .order('full_name', ascending: true);

      final users = (response as List).cast<Map<String, dynamic>>();

      if (kDebugMode) {
        if (kDebugMode) print('✅ [ChatService] Found ${users.length} users');
      }

      return users;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ChatService] Error fetching users: $e');
      }
      rethrow;
    }
  }

  /// Get list of all conversations (for admin dashboard)
  static Future<List<ChatConversation>> getConversationList() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        if (kDebugMode) print('📋 [ChatService] Fetching conversation list');
      }

      // Get all messages
      final response = await _client
          .from('chat_messages')
          .select()
          .order('created_at', ascending: false);

      final allMessages = (response as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();

      // Group by user (non-admin users only)
      final Map<String, List<ChatMessage>> messagesByUser = {};
      final Map<String, String> userNames = {};

      for (var message in allMessages) {
        String? otherUserId;
        String? otherUserName;

        if (!message.isAdmin) {
          // Message sent by user (to admin)
          // For user messages, sender is the user
          otherUserId = message.senderId;
          otherUserName = message.senderName;
        } else if (message.isAdmin && message.senderId == currentUser.id) {
          // Message sent by current admin to user
          // For admin messages, receiver is the user
          if (message.receiverId != null && message.receiverId!.isNotEmpty) {
            otherUserId = message.receiverId;
            // We'll try to get the name from other messages or fetch from profiles
          }
        } else {
          // Message from another admin, skip
          continue;
        }

        // Skip if we can't identify the other user
        if (otherUserId == null || otherUserId.isEmpty) continue;

        // Group messages by user
        messagesByUser.putIfAbsent(otherUserId, () => []);
        messagesByUser[otherUserId]!.add(message);
        
        // Store user name (prefer non-empty name from user messages)
        if (otherUserName != null && otherUserName.isNotEmpty) {
          userNames[otherUserId] = otherUserName;
        }
      }

      // Fetch missing user names from profiles table
      final userIdsWithoutNames = messagesByUser.keys
          .where((userId) => !userNames.containsKey(userId) || userNames[userId]!.isEmpty)
          .toList();

      if (userIdsWithoutNames.isNotEmpty) {
        if (kDebugMode) {
          if (kDebugMode) print('🔍 [ChatService] Fetching names for ${userIdsWithoutNames.length} users from profiles');
        }

        try {
          final profilesResponse = await _client
              .from('profiles')
              .select('id, full_name')
              .inFilter('id', userIdsWithoutNames);

          for (var profile in profilesResponse as List) {
            final userId = profile['id'] as String;
            final fullName = profile['full_name'] as String?;
            if (fullName != null && fullName.isNotEmpty) {
              userNames[userId] = fullName;
              if (kDebugMode) {
                if (kDebugMode) print('✅ [ChatService] Fetched name for $userId: $fullName');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            if (kDebugMode) print('⚠️ [ChatService] Error fetching user profiles: $e');
          }
        }
      }

      // Create conversation objects
      final conversations = messagesByUser.entries.map((entry) {
        return ChatConversation.fromMessages(
          userId: entry.key,
          userName: userNames[entry.key] ?? 'Unknown User',
          messages: entry.value,
          currentUserId: currentUser.id,
        );
      }).toList();

      // Sort by last message time
      conversations.sort((a, b) {
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      if (kDebugMode) {
        if (kDebugMode) print('✅ [ChatService] Found ${conversations.length} conversations');
      }

      return conversations;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ChatService] Error fetching conversation list: $e');
      }
      rethrow;
    }
  }

  /// Get conversation with a specific user (for admin)
  static Future<List<ChatMessage>> getConversationWithUser(String userId) async {
    try {
      if (kDebugMode) {
        if (kDebugMode) print('💬 [ChatService] Fetching conversation with user: $userId');
      }

      final response = await _client
          .from('chat_messages')
          .select()
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .order('created_at', ascending: false)
          .limit(100);

      final messages = (response as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();

      if (kDebugMode) {
        if (kDebugMode) print('✅ [ChatService] Fetched ${messages.length} messages');
      }

      return messages;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ChatService] Error fetching conversation: $e');
      }
      rethrow;
    }
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  /// Delete a message (only sender can delete within time limit)
  static Future<void> deleteMessage(String messageId) async {
    try {
      if (kDebugMode) {
        if (kDebugMode) print('🗑️ [ChatService] Deleting message: $messageId');
      }

      await _client
          .from('chat_messages')
          .delete()
          .eq('id', messageId);

      if (kDebugMode) {
        if (kDebugMode) print('✅ [ChatService] Message deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ChatService] Error deleting message: $e');
      }
      rethrow;
    }
  }

  /// Delete messages older than 24 hours
  /// This should be called periodically to clean up old chat messages
  static Future<int> deleteOldMessages({int hoursOld = 24}) async {
    try {
      if (kDebugMode) {
        if (kDebugMode) print('🗑️ [ChatService] Deleting messages older than $hoursOld hours...');
      }

      // Calculate the cutoff time (24 hours ago)
      final cutoffTime = DateTime.now().subtract(Duration(hours: hoursOld));
      final cutoffTimeStr = cutoffTime.toIso8601String();

      if (kDebugMode) {
        if (kDebugMode) print('🗑️ [ChatService] Cutoff time: $cutoffTimeStr');
      }

      // Delete messages older than cutoff time
      await _client
          .from('chat_messages')
          .delete()
          .lt('created_at', cutoffTimeStr);

      if (kDebugMode) {
        if (kDebugMode) print('✅ [ChatService] Old messages deleted successfully');
      }

      // Return success (we don't know the exact count from Supabase delete)
      return 0;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ChatService] Error deleting old messages: $e');
      }
      rethrow;
    }
  }

  /// Initialize periodic cleanup of old messages
  /// Call this once when the app starts to set up automatic message deletion
  static void initializeAutoCleanup({int hoursOld = 24, int checkIntervalHours = 6}) {
    if (kDebugMode) {
      if (kDebugMode) print('🔄 [ChatService] Initializing auto-cleanup: delete messages older than $hoursOld hours, checking every $checkIntervalHours hours');
    }

    // Run cleanup immediately on initialization
    deleteOldMessages(hoursOld: hoursOld).catchError((error) {
      if (kDebugMode) {
        if (kDebugMode) print('⚠️ [ChatService] Initial cleanup failed: $error');
      }
    });

    // Set up periodic cleanup
    Timer.periodic(Duration(hours: checkIntervalHours), (timer) {
      if (kDebugMode) {
        if (kDebugMode) print('🔄 [ChatService] Running periodic cleanup...');
      }
      deleteOldMessages(hoursOld: hoursOld).catchError((error) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️ [ChatService] Periodic cleanup failed: $error');
        }
      });
    });
  }

  /// Check if current user is admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      final response = await _client
          .from('staff')
          .select('role')
          .eq('user_id', currentUser.id)
          .eq('is_active', true)
          .maybeSingle();

      return response != null;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ChatService] Error checking admin status: $e');
      }
      return false;
    }
  }
}
