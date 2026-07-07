part of '../home_screen.dart';

class _HomeEventsSection extends StatelessWidget {
  final List<EventModel> events;
  final bool hasMore;
  final double cardWidth;
  final double carouselHeight;
  final VoidCallback onLoadMore;
  final ValueChanged<EventModel> onOpenEvent;
  final ValueChanged<EventModel> onRegister;
  final ValueChanged<EventModel> onShare;
  final ValueChanged<String> onClubTap;

  const _HomeEventsSection({
    required this.events,
    required this.hasMore,
    required this.cardWidth,
    required this.carouselHeight,
    required this.onLoadMore,
    required this.onOpenEvent,
    required this.onRegister,
    required this.onShare,
    required this.onClubTap,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Upcoming Events',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: carouselHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: events.length + (hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == events.length) {
                return _LoadMoreEventCard(
                  width: cardWidth,
                  onTap: onLoadMore,
                );
              }
              final event = events[index];
              return SizedBox(
                width: cardWidth,
                child: EventCard(
                  event: event,
                  onTap: () => onOpenEvent(event),
                  onRegister: () => onRegister(event),
                  onShare: () => onShare(event),
                  onClubTap: () => onClubTap(event.clubId),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
