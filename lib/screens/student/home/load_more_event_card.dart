part of '../home_screen.dart';

class _LoadMoreEventCard extends StatelessWidget {
  final double width;
  final VoidCallback onTap;

  const _LoadMoreEventCard({required this.width, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.expand_more_rounded, color: cs.primary, size: 30),
                const SizedBox(height: 8),
                Text(
                  'Load more events',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
