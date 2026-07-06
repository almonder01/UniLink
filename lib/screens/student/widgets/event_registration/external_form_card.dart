part of '../event_registration_dialog.dart';

class _ExternalFormCard extends StatelessWidget {
  final String link;
  final VoidCallback onCopy;

  const _ExternalFormCard({
    required this.link,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'External form',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            link,
            style: TextStyle(
              fontSize: 12,
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy link'),
          ),
        ],
      ),
    );
  }
}
