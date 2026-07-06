part of '../event_dashboard_tab.dart';

class _EventAnalyticsCard extends StatelessWidget {
  final EventModel event;
  final int registrations;
  final int attendance;
  final VoidCallback onTap;

  const _EventAnalyticsCard({
    required this.event,
    required this.registrations,
    required this.attendance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rate = registrations == 0 ? 0.0 : attendance / registrations;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_rounded,
                      color: Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormat('MMM d, y - h:mm a')
                              .format(event.eventDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 10),
              _EventStageChip(event: event),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: rate.clamp(0, 1),
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _MetricChip(
                    icon: Icons.how_to_reg_rounded,
                    label: '$registrations registered',
                  ),
                  const SizedBox(width: 8),
                  _MetricChip(
                    icon: Icons.fact_check_rounded,
                    label: '$attendance attended',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
