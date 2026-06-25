import 'dart:typed_data';
import 'package:flutter/material.dart';

class AdditionalPhotosGrid extends StatelessWidget {
  final List<Uint8List> images;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveAt;

  const AdditionalPhotosGrid({
    super.key,
    required this.images,
    required this.onAdd,
    required this.onRemoveAt,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Additional Photos',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.6))),
            const SizedBox(width: 8),
            Text('${images.length}/5',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...images.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(entry.value,
                            width: 90, height: 90, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemoveAt(entry.key),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (images.length < 5)
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: cs.onSurface.withValues(alpha: 0.15),
                          width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded,
                            color: cs.onSurface.withValues(alpha: 0.4),
                            size: 28),
                        const SizedBox(height: 4),
                        Text('Add',
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.4))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
