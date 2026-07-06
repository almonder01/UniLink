part of '../notifications_screen.dart';

class _NotificationSectionHeader extends StatelessWidget {
  final String label;
  const _NotificationSectionHeader({required this.label});

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
            fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              notif.body,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              timeLabel,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
              ),
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
