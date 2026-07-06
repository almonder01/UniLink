part of '../event_dashboard_tab.dart';

class _EventStageFilter extends StatelessWidget {
  final String selectedStage;
  final ValueChanged<String> onChanged;

  const _EventStageFilter({
    required this.selectedStage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const filters = [
      MapEntry('all', 'All'),
      MapEntry('planned', 'Planning'),
      MapEntry('ongoing', 'Ongoing'),
      MapEntry('ended', 'Ended'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EVENT STATUS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: cs.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in filters)
              FilterChip(
                label: Text(filter.value),
                selected: selectedStage == filter.key,
                onSelected: (_) => onChanged(filter.key),
                selectedColor: cs.primary.withValues(alpha: 0.15),
                checkmarkColor: cs.primary,
              ),
          ],
        ),
      ],
    );
  }
}
