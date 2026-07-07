import 'package:flutter/material.dart';

import 'direct_video_preview.dart';
import 'youtube_video_preview.dart';

class ContentAutoMediaLauncher extends StatefulWidget {
  final String title;
  final String? youtubeVideoUrl;
  final String? directVideoUrl;
  final bool autoOpenVideo;
  final String? audioUrl;
  final String audioType;
  final bool autoPlayAudio;
  final Widget child;

  const ContentAutoMediaLauncher({
    super.key,
    required this.title,
    this.youtubeVideoUrl,
    this.directVideoUrl,
    required this.autoOpenVideo,
    this.audioUrl,
    required this.audioType,
    required this.autoPlayAudio,
    required this.child,
  });

  @override
  State<ContentAutoMediaLauncher> createState() =>
      _ContentAutoMediaLauncherState();
}

class _ContentAutoMediaLauncherState extends State<ContentAutoMediaLauncher> {
  bool _openedAutoVideoPreview = false;
  bool _openedAutoAudioPreview = false;

  String _contentKey(ContentAutoMediaLauncher widget) {
    return [
      widget.title,
      widget.youtubeVideoUrl?.trim() ?? '',
      widget.directVideoUrl?.trim() ?? '',
      widget.audioUrl?.trim() ?? '',
      widget.audioType,
    ].join('|');
  }

  @override
  void didUpdateWidget(covariant ContentAutoMediaLauncher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_contentKey(widget) == _contentKey(oldWidget)) return;
    _openedAutoVideoPreview = false;
    _openedAutoAudioPreview = false;
  }

  void _scheduleAutoPreviews() {
    final youtubeVideoUrl = widget.youtubeVideoUrl?.trim() ?? '';
    final directVideoUrl = widget.directVideoUrl?.trim() ?? '';
    final videoUrl =
        youtubeVideoUrl.isNotEmpty ? youtubeVideoUrl : directVideoUrl;
    final shouldAutoOpenVideo = widget.autoOpenVideo &&
        videoUrl.isNotEmpty &&
        !_openedAutoVideoPreview;

    if (shouldAutoOpenVideo) {
      _openedAutoVideoPreview = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (youtubeVideoUrl.isNotEmpty ||
            youtubeVideoIdFromUrl(videoUrl) != null) {
          showYouTubePreviewDialog(
            context,
            url: videoUrl,
            title: widget.title,
          );
        } else {
          showDirectVideoDialog(
            context,
            url: videoUrl,
            title: widget.title,
          );
        }
      });
    }

    final audioUrl = widget.audioUrl?.trim() ?? '';
    if (widget.autoPlayAudio &&
        !_openedAutoAudioPreview &&
        !shouldAutoOpenVideo &&
        widget.audioType == 'youtube' &&
        audioUrl.isNotEmpty) {
      _openedAutoAudioPreview = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showYouTubePreviewDialog(
          context,
          url: audioUrl,
          title: '${widget.title} music',
          autoPlay: true,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _scheduleAutoPreviews();
    return widget.child;
  }
}
