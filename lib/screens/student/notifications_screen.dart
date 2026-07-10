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
import '../../services/club_detail_edit_request_service.dart';
import '../../services/club_room_service.dart';
import '../../services/database_service.dart';
import '../../services/event_service.dart';
import '../../widgets/confirm_action_dialog.dart';
import 'event_detail_screen.dart';
import 'club_detail_screen.dart';
import 'post_detail_screen.dart';

part 'notifications/empty_notifications.dart';
part 'notifications/notification_section.dart';
part 'notifications/notification_tile.dart';

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
      case 'club_detail_edit_request':
        return Icons.edit_note_rounded;
      case 'club_detail_edit_permission':
        return Icons.lock_open_rounded;
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

  bool _opensClub(String type) =>
      type == 'club' || type == 'club_detail_edit_permission';

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

  VoidCallback _tapFor(
    BuildContext context,
    NotificationProvider provider,
    NotificationModel notification,
  ) {
    if (_opensEvent(notification.type)) {
      return () => _openEvent(context, provider, notification);
    }
    if (_opensPost(notification.type)) {
      return () => _openPost(context, provider, notification);
    }
    if (_opensDirectMessage(notification.type)) {
      return () => _openDirectMessage(context, provider, notification);
    }
    if (_opensClub(notification.type)) {
      return () => _openClub(context, provider, notification);
    }
    return () => provider.markRead(notification.id);
  }

  Future<void> _grantClubDetailEditAccess(
    BuildContext context,
    NotificationProvider provider,
    NotificationModel notif,
  ) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || user.role != 'admin' || notif.refId == null) return;

    final request =
        await ClubDetailEditRequestService().requestById(notif.refId!);
    final fields = request?.fields ?? ClubDetailEditField.details;
    final fieldSummary = ClubDetailEditField.describe(fields);
    if (!context.mounted) return;

    final confirmed = await showConfirmActionDialog(
      context,
      title: 'Grant edit access?',
      message: 'Allow this club manager to edit the $fieldSummary '
          'for ${ClubDetailEditRequestService.defaultGrantMinutes} minutes?',
      confirmLabel: 'Grant',
      icon: Icons.lock_open_rounded,
    );
    if (!confirmed) return;

    try {
      final expiresAt = await ClubDetailEditRequestService().grantEditAccess(
        requestId: notif.refId!,
        adminId: user.id,
      );
      await provider.markMatchingActionsCompleted(
        type: notif.type,
        refId: notif.refId!,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Temporary edit access granted until '
            '${TimeOfDay.fromDateTime(expiresAt).format(context)}.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not grant access: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  VoidCallback? _joinRoomFor(
    BuildContext context,
    NotificationProvider provider,
    NotificationModel notification,
  ) {
    if (notification.type != 'room_invite') return null;
    return () => _joinRoom(context, provider, notification);
  }

  VoidCallback? _uploadReceiptFor(
    BuildContext context,
    NotificationProvider provider,
    NotificationModel notification,
  ) {
    if (notification.type != 'club_payment_request' || notification.isRead) {
      return null;
    }
    return () => _uploadPaymentReceipt(context, provider, notification);
  }

  VoidCallback? _grantClubDetailEditAccessFor(
    BuildContext context,
    NotificationProvider provider,
    NotificationModel notification,
  ) {
    final user = context.read<AuthProvider>().currentUser;
    if (notification.type != 'club_detail_edit_request' ||
        notification.actionCompleted ||
        user?.role != 'admin') {
      return null;
    }
    return () => _grantClubDetailEditAccess(context, provider, notification);
  }

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
          ? const _EmptyNotifications()
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NotificationSection(
                  label: 'Today',
                  items: today,
                  iconFor: _iconFor,
                  timeAgo: _timeAgo,
                  onTapFor: (n) => _tapFor(context, provider, n),
                  onJoinRoomFor: (n) => _joinRoomFor(context, provider, n),
                  onUploadReceiptFor: (n) =>
                      _uploadReceiptFor(context, provider, n),
                  onGrantEditAccessFor: (n) =>
                      _grantClubDetailEditAccessFor(context, provider, n),
                ),
                _NotificationSection(
                  label: 'Yesterday',
                  items: yesterday,
                  iconFor: _iconFor,
                  timeAgo: _timeAgo,
                  onTapFor: (n) => _tapFor(context, provider, n),
                  onJoinRoomFor: (n) => _joinRoomFor(context, provider, n),
                  onUploadReceiptFor: (n) =>
                      _uploadReceiptFor(context, provider, n),
                  onGrantEditAccessFor: (n) =>
                      _grantClubDetailEditAccessFor(context, provider, n),
                ),
                _NotificationSection(
                  label: 'Earlier',
                  items: older,
                  iconFor: _iconFor,
                  timeAgo: _timeAgo,
                  onTapFor: (n) => _tapFor(context, provider, n),
                  onJoinRoomFor: (n) => _joinRoomFor(context, provider, n),
                  onUploadReceiptFor: (n) =>
                      _uploadReceiptFor(context, provider, n),
                  onGrantEditAccessFor: (n) =>
                      _grantClubDetailEditAccessFor(context, provider, n),
                ),
              ],
            ),
    );
  }
}
