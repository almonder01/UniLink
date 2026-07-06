part of '../event_dashboard_tab.dart';

class _EventFilter extends StatelessWidget {
  final List<EventModel> events;
  final String selectedEventId;
  final ValueChanged<String?> onChanged;

  const _EventFilter({
    required this.events,
    required this.selectedEventId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filters = [
      const MapEntry('all', 'All events'),
      ...events.map((event) => MapEntry(event.id, event.title)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DASHBOARD FILTER',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: cs.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final filter = filters[index];
              final selected = selectedEventId == filter.key;
              return FilterChip(
                label: Text(
                  filter.value,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: selected,
                onSelected: (_) => onChanged(filter.key),
                selectedColor: cs.primary.withValues(alpha: 0.15),
                checkmarkColor: cs.primary,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.65),
                ),
                side: BorderSide(
                  color: selected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
