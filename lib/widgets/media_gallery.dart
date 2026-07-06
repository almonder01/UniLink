import 'package:flutter/material.dart';

import 'base64_image.dart';

class MediaGallery extends StatelessWidget {
  final List<String> images;

  const MediaGallery({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (images.isEmpty) {
      return Container(
        height: 96,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            Icons.photo_library_outlined,
            color: cs.onSurface.withValues(alpha: 0.35),
          ),
        ),
      );
    }

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => TappableBase64Image(
            data: images[i],
            width: 104,
            height: 104,
            borderRadius: BorderRadius.circular(12),
          ),
      ),
    );
  }
}
