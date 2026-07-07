part of '../settings_screen.dart';

class _FeedPriorityCard extends StatelessWidget {
  final ThemeProvider themeProvider;

  const _FeedPriorityCard({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _PrioritySelector(
              title: 'Post priority',
              value: themeProvider.postFeedPriority,
              onChanged: themeProvider.setPostFeedPriority,
            ),
            const SizedBox(height: 16),
            _PrioritySelector(
              title: 'Event priority',
              value: themeProvider.eventFeedPriority,
              onChanged: themeProvider.setEventFeedPriority,
            ),
          ],
        ),
      ),
    );
  }
}
