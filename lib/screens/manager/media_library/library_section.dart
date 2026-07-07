part of '../media_library_screen.dart';

class _LibrarySection extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<MediaAsset> assets;
  final ValueChanged<MediaAsset> onRename;

  const _LibrarySection({
    required this.title,
    required this.emptyText,
    required this.assets,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (assets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  emptyText,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              for (final asset in assets)
                _ManageAssetTile(asset: asset, onRename: () => onRename(asset)),
          ],
        ),
      ),
    );
  }
}

class _ManageAssetTile extends StatelessWidget {
  final MediaAsset asset;
  final VoidCallback onRename;

  const _ManageAssetTile({
    required this.asset,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = asset.isAudio
        ? Icons.music_note_rounded
        : asset.isYouTube
            ? Icons.smart_display_rounded
            : Icons.movie_creation_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(
          asset.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${asset.sourceLabel} - ${asset.url}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          tooltip: 'Rename',
          onPressed: onRename,
          icon: const Icon(Icons.edit_outlined),
        ),
      ),
    );
  }
}
