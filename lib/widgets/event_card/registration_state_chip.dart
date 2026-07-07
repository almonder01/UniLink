part of '../event_card.dart';

class _RegistrationStateChip extends StatelessWidget {
  final String? status;

  const _RegistrationStateChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    final color =
        isPending ? const Color(0xFFF59E0B) : const Color(0xFF22C55E);
    final label = isPending ? 'Pending approval' : 'Registered';
    final icon =
        isPending ? Icons.hourglass_top_rounded : Icons.check_circle_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
