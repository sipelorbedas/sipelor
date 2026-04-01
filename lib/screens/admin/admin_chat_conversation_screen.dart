import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/time_helper.dart';

/// Admin view: conversation with a specific user, with ability to reply.
class AdminChatConversationScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminChatConversationScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminChatConversationScreen> createState() =>
      _AdminChatConversationScreenState();
}

class _AdminChatConversationScreenState
    extends State<AdminChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String _adminName = 'Admin';
  String? _adminId;

  StreamSubscription<List<ChatMessage>>? _streamSub;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _streamSub?.cancel();
    super.dispose();
  }

  Future<void> _initChat() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    _adminId = user.id;

    // Load admin name from profile
    try {
      final profile = await SupabaseService.getUserProfile(user.id);
      if (mounted && profile != null) {
        setState(() {
          _adminName = profile['full_name'] ??
              profile['username'] ??
              user.email?.split('@').first ??
              'Admin';
        });
      }
    } catch (_) {}

    await _loadMessages();
    _setupStream();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await ChatService.getConversationWithUser(widget.userId);
      if (mounted) {
        setState(() {
          // getConversationWithUser returns descending → reverse for oldest-first
          _messages = msgs.reversed.toList();
          _isLoading = false;
        });
        // Mark incoming user messages as read
        await ChatService.markUserMessagesAsRead(widget.userId);
        _scrollToBottom();
      }
    } catch (e) {
      if (kDebugMode) print('❌ [AdminChat] Error loading messages: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupStream() {
    _streamSub = ChatService.streamAllMessages().listen((all) {
      // Filter to this specific user's conversation
      final filtered = all
          .where((m) =>
              m.senderId == widget.userId || m.receiverId == widget.userId)
          .toList()
          .reversed
          .toList();

      if (mounted) {
        setState(() => _messages = filtered);
        // Mark as read whenever new messages arrive
        ChatService.markUserMessagesAsRead(widget.userId).catchError((_) {});
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await ChatService.sendMessage(
        message: text,
        senderName: _adminName,
        isAdmin: true,
        receiverId: widget.userId,
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim pesan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

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
            // User avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Text(
                widget.userName.isNotEmpty
                    ? widget.userName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: GoogleFonts.mulish(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Pengguna',
                    style: GoogleFonts.mulish(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(),
          ),
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
            style: GoogleFonts.mulish(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai percakapan dengan ${widget.userName}',
            style: GoogleFonts.mulish(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isAdminMsg = message.senderId == _adminId;

        bool showDate = false;
        if (index == 0) {
          showDate = true;
        } else {
          final prev = DateFormat('yyyy-MM-dd')
              .format(_messages[index - 1].createdAt);
          final curr =
              DateFormat('yyyy-MM-dd').format(message.createdAt);
          showDate = curr != prev;
        }

        return Column(
          children: [
            if (showDate) _buildDateSeparator(message.createdAt),
            _buildBubble(message, isAdminMsg),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime dt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              TimeHelper.formatChatDate(dt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage message, bool isAdminMsg) {
    return Align(
      alignment:
          isAdminMsg ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isAdminMsg
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Sender label for user messages
            if (!isAdminMsg)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 3),
                child: Text(
                  widget.userName,
                  style: GoogleFonts.mulish(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isAdminMsg
                    ? AppColors.primaryDark
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft:
                      Radius.circular(isAdminMsg ? 12 : 0),
                  bottomRight:
                      Radius.circular(isAdminMsg ? 0 : 12),
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
                  color: isAdminMsg
                      ? Colors.white
                      : AppColors.darkPrimaryText,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${TimeHelper.formatChatTime(message.createdAt)} WIB',
              style: TextStyle(
                  fontSize: 11, color: Colors.grey[600]),
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
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.lightInputBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Balas pesan...',
                    hintStyle:
                        TextStyle(color: AppColors.darkLabelText),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  enabled: !_isSending,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: _isSending ? null : _sendMessage,
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send,
                            color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
