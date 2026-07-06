import 'package:flutter/material.dart';

import '../../models/chat_message.dart';
import '../../models/club.dart';
import '../../models/club_room.dart';
import '../../models/user.dart';
import '../../services/database_service.dart';
import '../../services/club_room_service.dart';
import '../../services/event_service.dart';
import '../../widgets/base64_image.dart';
import '../../widgets/chat_message_tile.dart';
import '../student/event_detail_screen.dart';
import '../student/post_detail_screen.dart';
import 'club_room_settings_screen.dart';

class ClubRoomChatScreen extends StatelessWidget {
  final ClubRoom? room;
  final String? roomId;
  final ClubModel? club;
  final UserModel user;

  const ClubRoomChatScreen({
    super.key,
    this.room,
    this.roomId,
    this.club,
    required this.user,
  }) : assert(room != null || roomId != null);

  @override
  Widget build(BuildContext context) {
    if (room != null) {
      return _RoomScreenBody(room: room!, club: club, user: user);
    }

    return FutureBuilder<ClubRoom?>(
      future: ClubRoomService().getRoom(roomId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final loadedRoom = snapshot.data;
        if (loadedRoom == null) {
          return const Scaffold(
            body: Center(child: Text('Room not found')),
          );
        }
        return _RoomScreenBody(room: loadedRoom, club: club, user: user);
      },
    );
  }
}

class _RoomScreenBody extends StatelessWidget {
  final ClubRoom room;
  final ClubModel? club;
  final UserModel user;

  const _RoomScreenBody({
    required this.room,
    required this.club,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _RoomHeaderAvatar(room: room, size: 30),
            const SizedBox(width: 8),
            Expanded(child: Text(room.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          if (club != null)
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClubRoomSettingsScreen(
                    club: club!,
                    user: user,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ClubRoomChatPanel(
        room: room,
        user: user,
        showHeader: false,
      ),
    );
  }
}

class _RoomHeaderAvatar extends StatelessWidget {
  final ClubRoom room;
  final double size;

  const _RoomHeaderAvatar({required this.room, required this.size});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final image = room.imageBase64;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Container(
        width: size,
        height: size,
        color: cs.primary.withValues(alpha: 0.12),
        child: image == null || image.isEmpty
            ? Icon(Icons.forum_rounded, color: cs.primary, size: size * 0.52)
            : Base64Image(data: image),
      ),
    );
  }
}

class ClubRoomChatPanel extends StatefulWidget {
  final ClubRoom room;
  final ClubModel? club;
  final UserModel user;
  final bool showHeader;
  final VoidCallback? onOpenFull;

  const ClubRoomChatPanel({
    super.key,
    required this.room,
    required this.user,
    this.club,
    this.showHeader = true,
    this.onOpenFull,
  });

  @override
  State<ClubRoomChatPanel> createState() => _ClubRoomChatPanelState();
}

class _ClubRoomChatPanelState extends State<ClubRoomChatPanel> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _service = ClubRoomService();

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
      roomId: widget.room.id,
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

    return Column(
      children: [
        if (widget.showHeader)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                bottom: BorderSide(
                  color: cs.onSurface.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Row(
              children: [
                _RoomHeaderAvatar(room: widget.room, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.room.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Club room',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.52),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.club != null)
                  IconButton(
                    tooltip: 'Room settings',
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClubRoomSettingsScreen(
                          club: widget.club!,
                          user: widget.user,
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: 'Open full chat',
                  icon: const Icon(Icons.open_in_full_rounded),
                  onPressed: widget.onOpenFull,
                ),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: _service.messagesStream(widget.room.id),
            builder: (context, snapshot) {
              final messages = snapshot.data ?? const <ChatMessage>[];
              _scrollToEnd();
              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    'Start the room conversation',
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
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Write a message',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
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
    );
  }
}
