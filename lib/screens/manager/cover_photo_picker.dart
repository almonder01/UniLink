import 'dart:typed_data';
import 'package:flutter/material.dart';

class CoverPhotoPicker extends StatelessWidget {
  final Uint8List? coverImage;
  final Color previewColor;
  final VoidCallback onTap;

  const CoverPhotoPicker({
    super.key,
    required this.coverImage,
    required this.previewColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: previewColor.withValues(alpha: 0.3), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: coverImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(coverImage!, fit: BoxFit.cover),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded,
                              size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Change',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      previewColor,
                      Color.lerp(previewColor, Colors.orange.shade900, 0.4)!
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded,
                        size: 44, color: Colors.white.withValues(alpha: 0.85)),
                    const SizedBox(height: 8),
                    Text('Tap to add cover photo',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('Optional',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12)),
                  ],
                ),
              ),
      ),
    );
  }
}
