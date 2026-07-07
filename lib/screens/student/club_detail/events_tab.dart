part of '../club_detail_screen.dart';

class _EventsTab extends StatelessWidget {
  final List<EventModel> events;
  final ValueChanged<EventModel> onRegister;
  final ValueChanged<EventModel> onShare;
  const _EventsTab({
    required this.events,
    required this.onRegister,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _EmptyTabState(
          icon: Icons.event_outlined, message: 'No events yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (_, i) => EventCard(
        event: events[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EventDetailScreen(event: events[i])),
        ),
        onRegister: () => onRegister(events[i]),
        onShare: () => onShare(events[i]),
      ),
    );
  }
}
