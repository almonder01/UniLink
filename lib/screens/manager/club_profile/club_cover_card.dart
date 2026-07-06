part of '../club_profile_tab.dart';

class _ClubCoverCard extends StatelessWidget {
  final Color logoColor;
  final Uint8List? clubImage;
  final VoidCallback onPickClubImage;
  final VoidCallback onRemoveClubImage;

  const _ClubCoverCard({
    required this.logoColor,
    required this.clubImage,
    required this.onPickClubImage,
    required this.onRemoveClubImage,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Club Cover',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Tap the cover to preview it.',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (clubImage != null)
                  TextButton.icon(
                    onPressed: () => showBase64ImagePreview(
                      context,
                      data: base64Encode(clubImage!),
                    ),
                    icon: const Icon(Icons.open_in_full_rounded),
                    label: const Text('Preview'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: clubImage == null
                  ? onPickClubImage
                  : () => showBase64ImagePreview(
                        context,
                        data: base64Encode(clubImage!),
                      ),
              child: AspectRatio(
                aspectRatio: 16 / 7,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        logoColor,
                        Color.lerp(logoColor, Colors.black, 0.35)!,
                      ],
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (clubImage != null)
                        Image.memory(clubImage!, fit: BoxFit.cover)
                      else
                        Icon(
                          Icons.groups_rounded,
                          size: 84,
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: GestureDetector(
                          onTap: onPickClubImage,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.photo_camera_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Change photo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (clubImage != null)
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: IconButton.filledTonal(
                            onPressed: onRemoveClubImage,
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
