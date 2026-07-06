part of '../event_dashboard_tab.dart';

class _StatsGrid extends StatelessWidget {
  final EventAnalytics analytics;

  const _StatsGrid({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = constraints.maxWidth < 340 ? 1 : 2;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final cards = [
          _StatCard(
            icon: Icons.event_available_rounded,
            label: 'Events',
            value: '${analytics.totalEvents}',
            color: const Color(0xFFF97316),
          ),
          _StatCard(
            icon: Icons.how_to_reg_rounded,
            label: 'Registrations',
            value: '${analytics.totalRegistrations}',
            color: const Color(0xFF14B8A6),
          ),
          _StatCard(
            icon: Icons.fact_check_rounded,
            label: 'Attendance',
            value: '${analytics.totalAttendance}',
            color: const Color(0xFF22C55E),
          ),
          _StatCard(
            icon: Icons.insights_rounded,
            label: 'Attendance Rate',
            value: '${(analytics.attendanceRate * 100).round()}%',
            color: const Color(0xFF6366F1),
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((card) => SizedBox(width: cardWidth, child: card))
              .toList(),
        );
      },
    );
  }
}
