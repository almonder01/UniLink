part of '../event_dashboard_tab.dart';

class _ParticipantSummaryCard extends StatelessWidget {
  final int approvedCount;
  final int pendingCount;
  final VoidCallback? onApprovePending;

  const _ParticipantSummaryCard({
    required this.approvedCount,
    required this.pendingCount,
    required this.onApprovePending,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniCountChip(
                    icon: Icons.fact_check_rounded,
                    label: '$approvedCount approved',
                    color: const Color(0xFF22C55E),
                  ),
                  _MiniCountChip(
                    icon: Icons.pending_actions_rounded,
                    label: '$pendingCount pending',
                    color: const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onApprovePending,
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Approve all'),
              style: FilledButton.styleFrom(
                foregroundColor: cs.primary,
                textStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
