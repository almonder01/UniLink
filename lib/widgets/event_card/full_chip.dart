part of '../event_card.dart';

class _FullChip extends StatelessWidget {
  const _FullChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.35),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block_rounded, size: 13, color: Color(0xFFEF4444)),
          SizedBox(width: 4),
          Text(
            'Full',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
