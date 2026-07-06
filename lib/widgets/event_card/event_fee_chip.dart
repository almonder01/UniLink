part of '../event_card.dart';

class _EventFeeChip extends StatelessWidget {
  final String label;

  const _EventFeeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.payments_rounded,
              size: 12, color: Color(0xFF14B8A6)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF14B8A6),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
