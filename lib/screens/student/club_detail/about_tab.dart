part of '../club_detail_screen.dart';

class _AboutTab extends StatelessWidget {
  final ClubModel club;
  final Color clubColor;

  const _AboutTab({
    required this.club,
    required this.clubColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (club.managerName != null) ...[
          Row(
            children: [
              Icon(
                Icons.manage_accounts_rounded,
                size: 16,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                'Managed by ${club.managerName}',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
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
        if ((club.backgroundVideoUrl ?? '').trim().isNotEmpty ||
            (club.backgroundMusicUrl ?? '').trim().isNotEmpty ||
            (club.featureTitle ?? '').trim().isNotEmpty ||
            (club.featureDescription ?? '').trim().isNotEmpty ||
            (club.featureCodeSnippet ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(
            'Club Experience',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if ((club.backgroundVideoUrl ?? '').trim().isNotEmpty) ...[
            VideoMediaPreview(
              url: club.backgroundVideoUrl!.trim(),
              type: club.backgroundVideoType,
              title: '${club.name} background video',
            ),
            const SizedBox(height: 12),
          ],
          if ((club.backgroundMusicUrl ?? '').trim().isNotEmpty &&
              club.backgroundMusicType == 'youtube') ...[
            YouTubeVideoPreview(
              url: club.backgroundMusicUrl!.trim(),
              title: '${club.name} background music',
              subtitle: 'Club music',
              compact: true,
            ),
            const SizedBox(height: 12),
          ],
          if ((club.featureTitle ?? '').trim().isNotEmpty ||
              (club.featureDescription ?? '').trim().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: clubColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: clubColor.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((club.featureTitle ?? '').trim().isNotEmpty)
                    Text(
                      club.featureTitle!.trim(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  if ((club.featureDescription ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      club.featureDescription!.trim(),
                      style: TextStyle(
                        height: 1.55,
                        color: cs.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if ((club.featureCodeSnippet ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.inverseSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                club.featureCodeSnippet!.trim(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.45,
                  color: cs.onSurface.withValues(alpha: 0.82),
                ),
              ),
            ),
          ],
        ],
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
