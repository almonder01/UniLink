part of '../home_screen.dart';

class _LoadMoreEventCard extends StatelessWidget {
  final double width;
  final bool isLoading;
  final VoidCallback onTap;

  const _LoadMoreEventCard({
    required this.width,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: cs.primary,
                    ),
                  )
                else
                  Icon(Icons.expand_more_rounded, color: cs.primary, size: 30),
                const SizedBox(height: 8),
                Text(
                  isLoading ? 'Loading...' : 'Load more events',
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
