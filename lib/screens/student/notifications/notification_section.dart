part of '../notifications_screen.dart';

class _NotificationSection extends StatelessWidget {
  final String label;
  final List<NotificationModel> items;
  final IconData Function(String type) iconFor;
  final String Function(DateTime time) timeAgo;
  final VoidCallback Function(NotificationModel notification) onTapFor;
  final VoidCallback? Function(NotificationModel notification) onJoinRoomFor;
  final VoidCallback? Function(NotificationModel notification) onUploadReceiptFor;

  const _NotificationSection({
    required this.label,
    required this.items,
    required this.iconFor,
    required this.timeAgo,
    required this.onTapFor,
    required this.onJoinRoomFor,
    required this.onUploadReceiptFor,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NotificationSectionHeader(label: label),
        for (final notification in items)
          _NotifTile(
            notif: notification,
            icon: iconFor(notification.type),
            timeLabel: timeAgo(notification.time),
            onTap: onTapFor(notification),
            onJoinRoom: onJoinRoomFor(notification),
            onUploadReceipt: onUploadReceiptFor(notification),
          ),
      ],
    );
  }
}
