part of '../event_card.dart';

class _FullChip extends StatelessWidget {
  const _FullChip();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = tokens.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: tokens.radiusSmBorder,
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block_rounded, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            'Full',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
