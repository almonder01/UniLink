import 'package:flutter/material.dart';

import 'direct_video_preview.dart';
import 'youtube_video_preview.dart';

class VideoMediaPreview extends StatelessWidget {
  final String url;
  final String title;
  final String? type;
  final bool compact;

  const VideoMediaPreview({
    super.key,
    required this.url,
    required this.title,
    this.type,
    this.compact = false,
  });

  bool get _isYoutube => type == 'youtube' || youtubeVideoIdFromUrl(url) != null;

  @override
  Widget build(BuildContext context) {
    if (_isYoutube) {
      return YouTubeVideoPreview(
        url: url,
        title: title,
        compact: compact,
      );
    }

    return DirectVideoPreview(
      url: url,
      title: title,
      compact: compact,
    );
  }
}
