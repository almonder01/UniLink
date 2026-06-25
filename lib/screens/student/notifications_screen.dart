import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(String type) {
    switch (type) {
      case 'event':
        return Icons.event_rounded;
      case 'club':
        return Icons.groups_rounded;
      default:
        return Icons.chat_bubble_rounded;
    }
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
                        onTap: () => provider.markRead(n.id),
                      )),
                ],
                if (yesterday.isNotEmpty) ...[
                  const _SectionHeader(label: 'Yesterday'),
                  ...yesterday.map((n) => _NotifTile(
                        notif: n,
                        icon: _iconFor(n.type),
                        timeLabel: _timeAgo(n.time),
                        onTap: () => provider.markRead(n.id),
                      )),
                ],
                if (older.isNotEmpty) ...[
                  const _SectionHeader(label: 'Earlier'),
                  ...older.map((n) => _NotifTile(
                        notif: n,
                        icon: _iconFor(n.type),
                        timeLabel: _timeAgo(n.time),
                        onTap: () => provider.markRead(n.id),
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

  const _NotifTile({
    required this.notif,
    required this.icon,
    required this.timeLabel,
    required this.onTap,
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
        trailing: !notif.isRead
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
