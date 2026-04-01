import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import 'admin_chat_conversation_screen.dart';

/// Admin screen: list of all user conversations with unread indicators.
class AdminChatListScreen extends StatefulWidget {
  const AdminChatListScreen({super.key});

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;
  StreamSubscription<List<ChatMessage>>? _streamSub;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _setupRealtimeStream();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      final convs = await ChatService.getConversationList();
      if (mounted) {
        setState(() {
          _conversations = convs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('❌ [AdminChatList] Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeStream() {
    _streamSub = ChatService.streamAllMessages().listen((_) {
      // Refresh conversation list whenever any message changes
      _loadConversations();
    });
  }

  int get _totalUnread =>
      _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Text(
              'Chat Pengguna',
              style: GoogleFonts.mulish(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_totalUnread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _totalUnread > 99 ? '99+' : '$_totalUnread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadConversations();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : _buildConversationList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 72, color: Colors.grey[350]),
          const SizedBox(height: 16),
          Text(
            'Belum ada pesan',
            style: GoogleFonts.mulish(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pesan dari pengguna akan muncul di sini',
            style: GoogleFonts.mulish(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList() {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: AppColors.primaryDark,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: Colors.grey[200],
          indent: 76,
        ),
        itemBuilder: (context, index) {
          final conv = _conversations[index];
          return _ConversationTile(
            conversation: conv,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminChatConversationScreen(
                    userId: conv.userId,
                    userName: conv.userName,
                  ),
                ),
              );
              // Refresh after returning from conversation
              _loadConversations();
            },
          );
        },
      ),
    );
  }
}

/// Single conversation list tile with red dot for unread messages.
class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;
    final initials = conversation.userName.isNotEmpty
        ? conversation.userName[0].toUpperCase()
        : '?';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar with red dot badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryDark,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.userName,
                    style: GoogleFonts.mulish(
                      fontSize: 15,
                      fontWeight:
                          hasUnread ? FontWeight.w700 : FontWeight.w600,
                      color: AppColors.darkPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conversation.lastMessage ?? 'Belum ada pesan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.mulish(
                      fontSize: 13,
                      color: hasUnread
                          ? AppColors.darkPrimaryText
                          : AppColors.darkLabelText,
                      fontWeight: hasUnread
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Timestamp + unread count badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (conversation.lastMessageTime != null)
                  Text(
                    _formatTime(conversation.lastMessageTime!),
                    style: GoogleFonts.mulish(
                      fontSize: 11,
                      color: hasUnread ? Colors.red : AppColors.darkLabelText,
                      fontWeight: hasUnread
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                if (hasUnread) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      conversation.unreadCount > 99
                          ? '99+'
                          : '${conversation.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inDays == 0) return DateFormat('HH:mm').format(local);
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) {
      return DateFormat('EEEE', 'id_ID').format(local);
    }
    return DateFormat('dd/MM/yy').format(local);
  }
}
