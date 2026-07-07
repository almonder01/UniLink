part of '../home_screen.dart';

class _EmptyFeed extends StatelessWidget {
  final bool isSearching;

  const _EmptyFeed({this.isSearching = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(
            isSearching ? Icons.search_off_rounded : Icons.dynamic_feed_rounded,
            size: 64,
            color: cs.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No matches' : 'Your feed is empty',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try searching by title, club, location,\nor description'
                : 'Follow some clubs to see their\nposts and events here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
