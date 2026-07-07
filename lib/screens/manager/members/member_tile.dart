part of '../members_tab.dart';

class _MemberTile extends StatelessWidget {
  final Map<String, dynamic> member;
  final Color avatarColor;
  final bool isManager;
  final bool canMessage;
  final VoidCallback onMessage;
  final VoidCallback onRemove;

  const _MemberTile({
    required this.member,
    required this.avatarColor,
    required this.isManager,
    required this.canMessage,
    required this.onMessage,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: UserAvatar(
        photoBase64: member['photoBase64'] as String?,
        gender: member['gender'] as String?,
        radius: 20,
        backgroundColor: avatarColor,
      ),
      title: Text(
        member['name'] as String,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(member['email'] as String),
      trailing: isManager
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'You',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canMessage)
                  IconButton(
                    tooltip: 'Message',
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 20,
                    ),
                    onPressed: onMessage,
                  ),
                IconButton(
                  tooltip: 'Remove member',
                  icon: const Icon(
                    Icons.person_remove_outlined,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: onRemove,
                ),
              ],
            ),
    );
  }
}
