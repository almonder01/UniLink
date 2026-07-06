import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_provider.dart';
import '../../providers/notification_provider.dart';
import '../../screens/chat/direct_chat_screen.dart';
import '../../screens/chat/club_room_chat_screen.dart';
import '../../services/club_payment_service.dart';
import '../../services/club_room_service.dart';
import '../../services/database_service.dart';
import '../../services/event_service.dart';
import 'event_detail_screen.dart';
import 'club_detail_screen.dart';
import 'post_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(String type) {
    switch (type) {
      case 'event':
        return Icons.event_rounded;
      case 'club':
        return Icons.groups_rounded;
      case 'room_invite':
        return Icons.forum_rounded;
      case 'club_payment_request':
        return Icons.payments_rounded;
      case 'direct_message':
        return Icons.mark_chat_unread_rounded;
      case 'event_invite':
      case 'event_registration':
        return Icons.event_available_rounded;
      default:
        return Icons.chat_bubble_rounded;
    }
  }

  Future<void> _joinRoom(
    BuildContext context,
    NotificationProvider provider,
    NotificationModel notif,
  ) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || notif.refId == null) return;
    await ClubRoomService().acceptInvite(roomId: notif.refId!, userId: user.id);
    await provider.markRead(notif.id);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClubRoomChatScreen(
          roomId: notif.refId,
          user: user,
        ),
      ),
    );
  }

  Future<void> _uploadPaymentReceipt(
    BuildContext context,
    NotificationProvider provider,
    NotificationModel notif,
  ) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || notif.refId == null) return;
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 72,
    );
    if (file == null) return;
    final encoded = base64Encode(await file.readAsBytes());
    await ClubPaymentService().uploadReceipt(
      requestId: notif.refId!,
      user: user,
      receiptBase64: encoded,
    );
    await provider.markRead(notif.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt uploaded.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _opensEvent(String type) =>
      type == 'event' || type == 'event_invite' || type == 'event_registration';

  bool _opensPost(String type) => type == 'post';

  bool _opensDirectMessage(String type) => type == 'direct_message';

  bool _opensClub(String type) => type == 'club';

  Future<void> _openEvent(
    BuildContext context,
    NotificationProvider provider,
    NotificationModel notif,
  ) async {
    if (notif.refId == null) return;
    final userId = context.read<AuthProvider>().currentUser?.id;
    final event = await EventService().getEventById(
      notif.refId!,
      userId: userId,
    );
    await provider.markRead(notif.id);
    if (!context.mounted) return;
    if (event == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event not found.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(event: event),
      ),
    );
  }

  Future<void> _openPost(
    BuildContext context,
    NotificationProvider provider,
    NotificationModel notif,
  ) async {
    if (notif.refId == null) return;
    final post = await DatabaseService().getPostById(notif.refId!);
    await provider.markRead(notif.id);
    if (!context.mounted) return;
    if (post == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post not found.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(post: post),
      ),
    );
  }

  Future<void> _openDirectMessage(
    BuildContext context,
    NotificationProvider provider,
    NotificationModel notif,
  ) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || notif.refId == null) return;
    await provider.markRead(notif.id);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DirectChatScreen(
          chatId: notif.refId!,
          title: notif.title.replaceFirst('Message from ', ''),
          user: user,
        ),
      ),
    );
  }

  Future<void> _openClub(
    BuildContext context,
    NotificationProvider provider,
    NotificationModel notif,
  ) async {
    final clubId = notif.refId?.isNotEmpty == true ? notif.refId! : notif.clubId;
    final club = context.read<ClubProvider>().getById(clubId);
    await provider.markRead(notif.id);
    if (!context.mounted || club == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClubDetailScreen(club: club)),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  List<NotificationModel> _today(List<NotificationModel> items) =>
      items.where((n) => DateTime.now().difference(n.time).inDays == 0).toList();

  List<NotificationModel> _yesterday(List<NotificationModel> items) =>
      items.where((n) => DateTime.now().difference(n.time).inDays == 1).toList();

  List<NotificationModel> _older(List<NotificationModel> items) =>
      items.where((n) => DateTime.now().difference(n.time).inDays > 1).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;
    final unread = provider.unreadCount;

    final today = _today(notifications);
    final yesterday = _yesterday(notifications);
    final older = _older(notifications);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications'),
            if (unread > 0)
              Text(
                '$unread unread',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: cs.primary),
              ),
          ],
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => provider.markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 60,
                      color: cs.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  Text('No notifications yet',
                      style: TextStyle(
                          fontSize: 16,
                          color: cs.onSurface.withValues(alpha: 0.4))),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (today.isNotEmpty) ...[
                  const _SectionHeader(label: 'Today'),
                  ...today.map((n) => _NotifTile(
                        notif: n,
                        icon: _iconFor(n.type),
                        timeLabel: _timeAgo(n.time),
                        onTap: _opensEvent(n.type)
                            ? () => _openEvent(context, provider, n)
                            : _opensPost(n.type)
                                ? () => _openPost(context, provider, n)
                                : _opensDirectMessage(n.type)
                                    ? () => _openDirectMessage(
                                          context,
                                          provider,
                                          n,
                                        )
                                    : _opensClub(n.type)
                                        ? () => _openClub(context, provider, n)
                            : () => provider.markRead(n.id),
                        onJoinRoom: n.type == 'room_invite'
                            ? () => _joinRoom(context, provider, n)
                            : null,
                        onUploadReceipt: n.type == 'club_payment_request' &&
                                !n.isRead
                            ? () => _uploadPaymentReceipt(context, provider, n)
                            : null,
                      )),
                ],
                if (yesterday.isNotEmpty) ...[
                  const _SectionHeader(label: 'Yesterday'),
                  ...yesterday.map((n) => _NotifTile(
                        notif: n,
                        icon: _iconFor(n.type),
                        timeLabel: _timeAgo(n.time),
                        onTap: _opensEvent(n.type)
                            ? () => _openEvent(context, provider, n)
                            : _opensPost(n.type)
                                ? () => _openPost(context, provider, n)
                                : _opensDirectMessage(n.type)
                                    ? () => _openDirectMessage(
                                          context,
                                          provider,
                                          n,
                                        )
                                    : _opensClub(n.type)
                                        ? () => _openClub(context, provider, n)
                            : () => provider.markRead(n.id),
                        onJoinRoom: n.type == 'room_invite'
                            ? () => _joinRoom(context, provider, n)
                            : null,
                        onUploadReceipt: n.type == 'club_payment_request' &&
                                !n.isRead
                            ? () => _uploadPaymentReceipt(context, provider, n)
                            : null,
                      )),
                ],
                if (older.isNotEmpty) ...[
                  const _SectionHeader(label: 'Earlier'),
                  ...older.map((n) => _NotifTile(
                        notif: n,
                        icon: _iconFor(n.type),
                        timeLabel: _timeAgo(n.time),
                        onTap: _opensEvent(n.type)
                            ? () => _openEvent(context, provider, n)
                            : _opensPost(n.type)
                                ? () => _openPost(context, provider, n)
                                : _opensDirectMessage(n.type)
                                    ? () => _openDirectMessage(
                                          context,
                                          provider,
                                          n,
                                        )
                                    : _opensClub(n.type)
                                        ? () => _openClub(context, provider, n)
                            : () => provider.markRead(n.id),
                        onJoinRoom: n.type == 'room_invite'
                            ? () => _joinRoom(context, provider, n)
                            : null,
                        onUploadReceipt: n.type == 'club_payment_request' &&
                                !n.isRead
                            ? () => _uploadPaymentReceipt(context, provider, n)
                            : null,
                      )),
                ],
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final IconData icon;
  final String timeLabel;
  final VoidCallback onTap;
  final VoidCallback? onJoinRoom;
  final VoidCallback? onUploadReceipt;

  const _NotifTile({
    required this.notif,
    required this.icon,
    required this.timeLabel,
    required this.onTap,
    this.onJoinRoom,
    this.onUploadReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = Color(int.parse(notif.color, radix: 16));

    return Container(
      color: notif.isRead ? null : cs.primary.withValues(alpha: 0.04),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          notif.title,
          style: TextStyle(
              fontSize: 14,
              fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              notif.body,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              timeLabel,
              style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        trailing: onJoinRoom != null || onUploadReceipt != null
            ? FilledButton.tonal(
                onPressed: onJoinRoom ?? onUploadReceipt,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(onJoinRoom != null ? 'Join' : 'Upload'),
              )
            : !notif.isRead
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
      ),
    );
  }
}
