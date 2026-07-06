part of '../event_dashboard_tab.dart';

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'pending' => ('Pending', const Color(0xFFF59E0B)),
      'approved' => ('Approved', const Color(0xFF22C55E)),
      'rejected' => ('Rejected', const Color(0xFFEF4444)),
      'cancelled' => ('Cancelled', const Color(0xFF64748B)),
      _ => ('Updated', Theme.of(context).colorScheme.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
