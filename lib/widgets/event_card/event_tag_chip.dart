part of '../event_card.dart';

class _EventTagChip extends StatelessWidget {
  const _EventTagChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_rounded, size: 12, color: Color(0xFFF97316)),
          SizedBox(width: 4),
          Text(
            'Event',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFFF97316),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
