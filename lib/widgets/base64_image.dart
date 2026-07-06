import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class Base64Image extends StatelessWidget {
  final String data;
  final BoxFit fit;
  final double? width;
  final double? height;

  const Base64Image({
    super.key,
    required this.data,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    try {
      bytes = base64Decode(data);
    } catch (_) {
      bytes = null;
    }

    if (bytes == null) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      );
    }

    return Image.memory(
      bytes,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
    );
  }
}

Future<void> showBase64ImagePreview(
  BuildContext context, {
  required String data,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.82),
    builder: (_) => Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Base64Image(
                      data: data,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton.filled(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class TappableBase64Image extends StatelessWidget {
  final String data;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const TappableBase64Image({
    super.key,
    required this.data,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final image = Base64Image(
      data: data,
      fit: fit,
      width: width,
      height: height,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showBase64ImagePreview(context, data: data),
        borderRadius: borderRadius,
        child: borderRadius == null
            ? image
            : ClipRRect(borderRadius: borderRadius!, child: image),
      ),
    );
  }
}
