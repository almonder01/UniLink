part of '../club_detail_screen.dart';

class _AboutTab extends StatelessWidget {
  final ClubModel club;
  final Color clubColor;
  const _AboutTab({required this.club, required this.clubColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
          if (club.managerName != null) ...[
            Row(
              children: [
                Icon(Icons.manage_accounts_rounded,
                    size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Text(
                  'Managed by ${club.managerName}',
                  style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: clubColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              club.category,
              style: TextStyle(
                  fontSize: 12, color: clubColor, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'About',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            club.description,
            style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: cs.onSurface.withValues(alpha: 0.75)),
          ),
          if (club.galleryBase64List.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              'Photos',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            MediaGallery(images: club.galleryBase64List),
          ],
        ],
    );
  }
}
