import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/time_helper.dart';

/// Screen for users to chat with admin
class UserChatScreen extends StatefulWidget {
  const UserChatScreen({super.key});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  StreamSubscription<List<ChatMessage>>? _messageSubscription;

  String _userName = 'User';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    // Get current user info
    final user = SupabaseService.currentUser;
    if (user == null) {
      _showError('Anda harus login terlebih dahulu');
      Navigator.of(context).pop();
      return;
    }

    _currentUserId = user.id;

    try {
      // Get user profile for name
      final profile = await SupabaseService.getUserProfile(user.id);
      if (mounted && profile != null) {
        setState(() {
          _userName = profile['full_name'] ?? 'User';
        });
      } else if (mounted) {
        setState(() {
          _userName = user.email?.split('@').first ?? 'User';
        });
      }
    } catch (e) {
      // Use email as fallback
      if (mounted) {
        setState(() {
          _userName = user.email?.split('@').first ?? 'User';
        });
      }
    }

    // Setup real-time stream
    _setupMessageStream();

    // Load initial messages
    await _loadMessages();
  }

  void _setupMessageStream() {
    _messageSubscription = ChatService.streamUserAdminConversation().listen(
      (messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
          });

          // Mark messages as read
          _markUnreadMessagesAsRead();

          // Scroll to bottom when new message arrives
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      },
      onError: (error) {
        if (kDebugMode) print('❌ [UserChat] Stream error: $error');
      },
    );
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await ChatService.getUserAdminConversation();
      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      // Mark messages as read
      _markUnreadMessagesAsRead();

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Gagal memuat pesan: $e');
    }
  }

  void _markUnreadMessagesAsRead() {
    if (_currentUserId == null) return;

    final unreadIds = _messages
        .where((msg) => msg.receiverId == _currentUserId && !msg.isRead)
        .map((msg) => msg.id)
        .toList();

    if (unreadIds.isNotEmpty) {
      ChatService.markMessagesAsRead(unreadIds).catchError((error) {
        if (kDebugMode) print('❌ [UserChat] Error marking messages as read: $error');
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      await ChatService.sendMessage(
        message: message,
        senderName: _userName,
        isAdmin: false,
        receiverId: null, // Null means sending to admin
      );

      _messageController.clear();

      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      _showError('Gagal mengirim pesan: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Support',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Online',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? _buildEmptyState()
                : _buildMessageList(),
          ),

          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada pesan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai percakapan dengan admin',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    // Reverse messages so newest is at bottom
    final reversedMessages = _messages.reversed.toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: reversedMessages.length,
      itemBuilder: (context, index) {
        final message = reversedMessages[index];
        final isMine = message.senderId == _currentUserId;

        // Show date separator if needed
        bool showDateSeparator = false;
        if (index == 0) {
          showDateSeparator = true;
        } else {
          final previousMessage = reversedMessages[index - 1];
          final currentDate = DateFormat(
            'yyyy-MM-dd',
          ).format(message.createdAt);
          final previousDate = DateFormat(
            'yyyy-MM-dd',
          ).format(previousMessage.createdAt);
          showDateSeparator = currentDate != previousDate;
        }

        return Column(
          children: [
            if (showDateSeparator) _buildDateSeparator(message.createdAt),
            _buildMessageBubble(message, isMine),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    // Convert UTC to Indonesian time (WIB)
    final dateText = TimeHelper.formatChatDate(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMine) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Message bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? const Color(0xFF211A2C) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isMine ? 12 : 0),
                  bottomRight: Radius.circular(isMine ? 0 : 12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  color: isMine ? Colors.white : AppColors.darkPrimaryText,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Timestamp in Indonesian time (WIB)
            Text(
              '${TimeHelper.formatChatTime(message.createdAt)} WIB',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: SafeArea(
        child: Row(
          children: [
            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.lightInputBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Ketik pesan...',
                    hintStyle: TextStyle(color: AppColors.darkLabelText),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  enabled: !_isSending,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            Material(
              color: const Color(0xFF211A2C),
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: _isSending ? null : _sendMessage,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _isSending
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
