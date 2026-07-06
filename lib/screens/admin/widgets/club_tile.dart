import 'package:flutter/material.dart';
import '../../../widgets/identity_avatar.dart';

class ClubTile extends StatelessWidget {
  final Map<String, dynamic> club;
  final VoidCallback onAssign;
  final VoidCallback onUnassign;
  final VoidCallback onDelete;

  const ClubTile({
    super.key,
    required this.club,
    required this.onAssign,
    required this.onUnassign,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colorHex = (club['logo_color'] as String?) ?? 'FF6366F1';
    final logoColor = Color(int.parse(
      'FF$colorHex'.length > 8 ? colorHex : 'FF$colorHex',
      radix: 16,
    ));
    final name = club['name'] as String? ?? '?';
    final managerName = club['manager_name'] as String?;
    final hasManager = managerName != null && managerName.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClubAvatar(
                  color: logoColor,
                  logoBase64: club['logo_image_base64'] as String?,
                  showBackground:
                      club['show_logo_background'] as bool? ?? true,
                  size: 44,
                  borderRadius: 12,
                ),
                const SizedBox(width: 12),
                // Name + manager
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.manage_accounts_rounded,
                            size: 12,
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              hasManager ? managerName : 'No manager assigned',
                              style: TextStyle(
                                fontSize: 12,
                                color: hasManager
                                    ? cs.onSurface.withValues(alpha: 0.6)
                                    : Colors.orange,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Category chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: logoColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    (club['category'] as String?) ?? 'General',
                    style: TextStyle(
                      fontSize: 10,
                      color: logoColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete club',
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onAssign,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_rounded, size: 14),
                        SizedBox(width: 5),
                        Text('Assign Manager'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: hasManager ? onUnassign : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                      foregroundColor: Colors.red,
                      side: BorderSide(
                        color: hasManager
                            ? Colors.red.withValues(alpha: 0.5)
                            : Colors.grey.withValues(alpha: 0.3),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_remove_rounded, size: 14),
                        SizedBox(width: 5),
                        Text('Unassign'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
