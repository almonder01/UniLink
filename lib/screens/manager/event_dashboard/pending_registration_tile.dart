part of '../event_dashboard_tab.dart';

class _PendingRegistrationTile extends StatelessWidget {
  final EventRegistration registration;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingRegistrationTile({
    required this.registration,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.pending_actions_rounded,
                  color: Color(0xFFF59E0B), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    registration.userName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    registration.userEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Approve',
              onPressed: onApprove,
              icon: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF22C55E)),
            ),
            IconButton(
              tooltip: 'Reject',
              onPressed: onReject,
              icon:
                  const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444)),
            ),
          ],
        ),
      ),
    );
  }
}
