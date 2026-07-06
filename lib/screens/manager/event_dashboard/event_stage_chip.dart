part of '../event_dashboard_tab.dart';

class _EventStageChip extends StatelessWidget {
  final EventModel event;

  const _EventStageChip({required this.event});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final estimatedEnd = event.eventDate.add(const Duration(hours: 3));
    final (label, icon, color) = event.eventDate.isAfter(now)
        ? ('Planning', Icons.schedule_rounded, const Color(0xFF6366F1))
        : estimatedEnd.isAfter(now)
            ? ('Ongoing', Icons.play_circle_rounded, const Color(0xFF22C55E))
            : ('Ended', Icons.flag_rounded, const Color(0xFF64748B));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
