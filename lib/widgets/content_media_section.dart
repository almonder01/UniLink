import 'package:flutter/material.dart';

import 'club_audio_player.dart';
import 'video_media_preview.dart';
import 'youtube_video_preview.dart';

class ContentMediaSection extends StatelessWidget {
  final String title;
  final String? youtubeVideoUrl;
  final String? directVideoUrl;
  final String videoType;
  final String? audioUrl;
  final String audioType;
  final String audioSubtitle;
  final bool autoPlayAudio;
  final TextStyle? headingStyle;
  final double topSpacing;
  final double betweenSpacing;
  final double bottomSpacing;

  const ContentMediaSection({
    super.key,
    required this.title,
    this.youtubeVideoUrl,
    this.directVideoUrl,
    this.videoType = 'video',
    this.audioUrl,
    this.audioType = 'audio',
    this.audioSubtitle = 'Content music',
    required this.autoPlayAudio,
    this.headingStyle,
    this.topSpacing = 0,
    this.betweenSpacing = 20,
    this.bottomSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    final youtubeUrl = youtubeVideoUrl?.trim() ?? '';
    final directUrl = directVideoUrl?.trim() ?? '';
    final musicUrl = audioUrl?.trim() ?? '';
    final hasVideo = youtubeUrl.isNotEmpty || directUrl.isNotEmpty;
    final hasAudio = musicUrl.isNotEmpty;
    final blocks = <Widget>[];

    void addBlock(Widget block) {
      if (blocks.isEmpty) {
        if (topSpacing > 0) blocks.add(SizedBox(height: topSpacing));
      } else {
        blocks.add(SizedBox(height: betweenSpacing));
      }
      blocks.add(block);
    }

    if (hasVideo) {
      addBlock(
        _MediaBlock(
          label: 'Video',
          headingStyle: headingStyle,
          children: [
            if (youtubeUrl.isNotEmpty) ...[
              VideoMediaPreview(
                url: youtubeUrl,
                type: 'youtube',
                title: title,
              ),
              if (directUrl.isNotEmpty) const SizedBox(height: 12),
            ],
            if (directUrl.isNotEmpty)
              VideoMediaPreview(
                url: directUrl,
                type: videoType,
                title: title,
              ),
          ],
        ),
      );
    }

    if (hasAudio) {
      addBlock(
        _MediaBlock(
          label: 'Music',
          headingStyle: headingStyle,
          children: [
            if (audioType == 'youtube')
              YouTubeVideoPreview(
                url: musicUrl,
                title: '$title music',
                subtitle: audioSubtitle,
                compact: true,
              )
            else
              ClubAudioPlayer(
                url: musicUrl,
                title: '$title music',
                subtitle: audioSubtitle,
                autoPlay: autoPlayAudio,
              ),
          ],
        ),
      );
    }

    if (blocks.isNotEmpty && bottomSpacing > 0) {
      blocks.add(SizedBox(height: bottomSpacing));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }
}

class _MediaBlock extends StatelessWidget {
  final String label;
  final TextStyle? headingStyle;
  final List<Widget> children;

  const _MediaBlock({
    required this.label,
    required this.headingStyle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: headingStyle ??
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}
