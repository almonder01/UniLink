import 'package:flutter/material.dart';

import '../../models/chat_message.dart';
import '../../models/user.dart';
import '../../services/database_service.dart';
import '../../services/direct_chat_service.dart';
import '../../services/event_service.dart';
import '../../widgets/chat_message_tile.dart';
import '../student/event_detail_screen.dart';
import '../student/post_detail_screen.dart';

class DirectChatScreen extends StatefulWidget {
  final String chatId;
  final String title;
  final UserModel user;

  const DirectChatScreen({
    super.key,
    required this.chatId,
    required this.title,
    required this.user,
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _service = DirectChatService();

  @override
  void initState() {
    super.initState();
    _service.markRead(chatId: widget.chatId, userId: widget.user.id);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text;
    _textCtrl.clear();
    await _service.sendMessage(
      chatId: widget.chatId,
      sender: widget.user,
      text: text,
    );
  }

  Future<void> _openAttachment(ChatMessage message) async {
    final attachmentId = message.attachmentId;
    if (attachmentId == null) return;

    if (message.attachmentType == 'event') {
      final event = await EventService().getEventById(
        attachmentId,
        userId: widget.user.id,
      );
      if (!mounted || event == null) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
      );
      return;
    }

    final post = await DatabaseService().getPostById(attachmentId);
    if (!mounted || post == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
    );
  }

  void _scrollToEnd() {
    if (!_scrollCtrl.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _service.messagesStream(widget.chatId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const <ChatMessage>[];
                _scrollToEnd();
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hello',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.42),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ChatMessageTile(
                      message: message,
                      isMine: message.senderId == widget.user.id,
                      onAttachmentTap: _openAttachment,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Write a message',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor:
                            cs.surfaceContainerHighest.withValues(alpha: 0.55),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
