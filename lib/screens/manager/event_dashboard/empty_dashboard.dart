part of '../event_dashboard_tab.dart';

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: 54,
            color: cs.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Text(
            'Create an event to start seeing analytics.',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}
