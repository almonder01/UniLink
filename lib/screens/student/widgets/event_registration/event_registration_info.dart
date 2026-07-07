part of '../event_registration_dialog.dart';

class _EventRegistrationInfo extends StatelessWidget {
  final EventModel event;

  const _EventRegistrationInfo({required this.event});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.calendar_today_rounded,
          label: DateFormat('EEE, MMM d, y').format(event.eventDate),
        ),
        const SizedBox(height: 6),
        _InfoRow(
          icon: Icons.schedule_rounded,
          label: DateFormat('h:mm a').format(event.eventDate),
        ),
        const SizedBox(height: 6),
        _InfoRow(
          icon: Icons.location_on_rounded,
          label: event.location,
        ),
        if (event.hasCapacityLimit) ...[
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.groups_rounded,
            label: '${event.registeredCount}/${event.maxParticipants} registered',
          ),
        ],
      ],
    );
  }
}
