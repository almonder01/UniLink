part of '../club_profile_tab.dart';

class _ClubGalleryCard extends StatelessWidget {
  final List<Uint8List> images;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveAt;

  const _ClubGalleryCard({
    required this.images,
    required this.onAdd,
    required this.onRemoveAt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AdditionalPhotosGrid(
          images: images,
          onAdd: onAdd,
          onRemoveAt: onRemoveAt,
        ),
      ),
    );
  }
}
