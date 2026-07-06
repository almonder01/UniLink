part of '../event_card.dart';

class _EventCapacityChip extends StatelessWidget {
  final int registered;
  final int max;
  final bool isFull;

  const _EventCapacityChip({
    required this.registered,
    required this.max,
    required this.isFull,
  });

  @override
  Widget build(BuildContext context) {
    final color = isFull ? const Color(0xFFEF4444) : const Color(0xFF6366F1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.groups_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$registered/$max',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
