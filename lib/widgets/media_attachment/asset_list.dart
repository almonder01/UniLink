part of '../media_attachment_fields.dart';

class _MediaAssetList extends StatelessWidget {
  final String title;
  final List<MediaAsset> assets;
  final String? selectedUrl;
  final ValueChanged<MediaAsset>? onSelected;

  const _MediaAssetList({
    required this.title,
    required this.assets,
    required this.selectedUrl,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: assets.length <= 3,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          title: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            '${assets.length} saved',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.56),
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            for (final asset in assets)
              _MediaAssetTile(
                asset: asset,
                selected: selectedUrl == asset.url,
                onTap: onSelected == null ? null : () => onSelected!(asset),
              ),
          ],
        ),
      ),
    );
  }
}

class _MediaAssetTile extends StatelessWidget {
  final MediaAsset asset;
  final bool selected;
  final VoidCallback? onTap;

  const _MediaAssetTile({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = asset.isAudio
        ? Icons.music_note_rounded
        : asset.isYouTube
            ? Icons.smart_display_rounded
            : Icons.movie_creation_rounded;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? cs.primaryContainer.withValues(alpha: 0.72)
            : cs.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: cs.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        asset.sourceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.56),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Selected',
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.north_west_rounded,
                    size: 17,
                    color: cs.onSurface.withValues(alpha: 0.38),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
