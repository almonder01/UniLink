part of '../profile_screen.dart';

class _ProfileClubList extends StatelessWidget {
  final String title;
  final List<ClubModel> clubs;
  final IconData emptyIcon;
  final String emptyText;

  const _ProfileClubList({
    required this.title,
    required this.clubs,
    required this.emptyIcon,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SectionLabel(title),
            const SizedBox(width: 8),
            if (clubs.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${clubs.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: clubs.isEmpty
              ? Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        emptyIcon,
                        size: 22,
                        color: cs.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        emptyText,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < clubs.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 56),
                      FollowedClubTile(
                        club: clubs[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClubDetailScreen(club: clubs[i]),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
