import 'package:flutter/material.dart';

import '../models/media_asset.dart';
import 'video_media_preview.dart';
import 'youtube_video_preview.dart';

part 'media_attachment/asset_list.dart';
part 'media_attachment/audio_field.dart';
part 'media_attachment/direct_video_field.dart';
part 'media_attachment/pick_file_button.dart';
part 'media_attachment/section_header.dart';
part 'media_attachment/source_selector.dart';
part 'media_attachment/url_utils.dart';
part 'media_attachment/youtube_video_field.dart';

class MediaAttachmentFields extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final TextEditingController youtubeVideoController;
  final TextEditingController directVideoController;
  final String videoType;
  final ValueChanged<String> onVideoTypeChanged;
  final VoidCallback onPickVideo;
  final String? pendingVideoName;
  final TextEditingController audioController;
  final String audioType;
  final ValueChanged<String> onAudioTypeChanged;
  final VoidCallback onPickAudio;
  final String? pendingAudioName;
  final String videoPreviewTitle;
  final String audioPreviewTitle;
  final List<Widget> videoOptions;
  final List<Widget> audioOptions;
  final bool wrapInCard;
  final bool compactPreviews;
  final bool showVideo;
  final bool showAudio;
  final List<MediaAsset> videoAssets;
  final List<MediaAsset> audioAssets;
  final String? selectedVideoUrl;
  final String? selectedAudioUrl;
  final ValueChanged<MediaAsset>? onVideoAssetSelected;
  final ValueChanged<MediaAsset>? onAudioAssetSelected;

  const MediaAttachmentFields({
    super.key,
    this.title,
    this.subtitle,
    required this.youtubeVideoController,
    required this.directVideoController,
    required this.videoType,
    required this.onVideoTypeChanged,
    required this.onPickVideo,
    this.pendingVideoName,
    required this.audioController,
    required this.audioType,
    required this.onAudioTypeChanged,
    required this.onPickAudio,
    this.pendingAudioName,
    required this.videoPreviewTitle,
    required this.audioPreviewTitle,
    this.videoOptions = const [],
    this.audioOptions = const [],
    this.wrapInCard = true,
    this.compactPreviews = false,
    this.showVideo = true,
    this.showAudio = true,
    this.videoAssets = const [],
    this.audioAssets = const [],
    this.selectedVideoUrl,
    this.selectedAudioUrl,
    this.onVideoAssetSelected,
    this.onAudioAssetSelected,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null || subtitle != null) ...[
          _SectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 14),
        ],
        if (showVideo) ..._buildVideoSection(),
        if (showVideo && showAudio) const SizedBox(height: 18),
        if (showAudio) ..._buildAudioSection(),
      ],
    );

    if (!wrapInCard) return content;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }

  List<Widget> _buildVideoSection() => [
        _MediaSourceSelector(
          title: 'Video',
          icon: Icons.ondemand_video_rounded,
          value: videoType,
          segments: const [
            ButtonSegment(
              value: 'youtube',
              icon: Icon(Icons.smart_display_rounded),
              label: Text('YouTube'),
            ),
            ButtonSegment(
              value: 'video',
              icon: Icon(Icons.upload_file_rounded),
              label: Text('Upload'),
            ),
          ],
          onChanged: onVideoTypeChanged,
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: videoType == 'youtube'
              ? _YouTubeVideoField(
                  key: const ValueKey('youtube-video-field'),
                  controller: youtubeVideoController,
                  previewTitle: videoPreviewTitle,
                  compactPreview: compactPreviews,
                )
              : _DirectVideoField(
                  key: const ValueKey('direct-video-field'),
                  controller: directVideoController,
                  pendingName: pendingVideoName,
                  onPick: onPickVideo,
                  previewTitle: videoPreviewTitle,
                  compactPreview: compactPreviews,
                ),
        ),
        if (videoAssets.isNotEmpty) ...[
          const SizedBox(height: 12),
          _MediaAssetList(
            title: 'Saved videos',
            assets: videoAssets,
            selectedUrl: selectedVideoUrl,
            onSelected: onVideoAssetSelected,
          ),
        ],
        ...videoOptions,
      ];

  List<Widget> _buildAudioSection() => [
        _MediaSourceSelector(
          title: 'Music',
          icon: Icons.music_note_rounded,
          value: audioType,
          segments: const [
            ButtonSegment(
              value: 'youtube',
              icon: Icon(Icons.smart_display_rounded),
              label: Text('YouTube'),
            ),
            ButtonSegment(
              value: 'audio',
              icon: Icon(Icons.audio_file_rounded),
              label: Text('MP3'),
            ),
          ],
          onChanged: onAudioTypeChanged,
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _AudioField(
            key: ValueKey('audio-$audioType'),
            controller: audioController,
            audioType: audioType,
            pendingName: pendingAudioName,
            onPick: onPickAudio,
            previewTitle: audioPreviewTitle,
            compactPreview: compactPreviews,
          ),
        ),
        if (audioAssets.isNotEmpty) ...[
          const SizedBox(height: 12),
          _MediaAssetList(
            title: 'Saved music',
            assets: audioAssets,
            selectedUrl: selectedAudioUrl,
            onSelected: onAudioAssetSelected,
          ),
        ],
        ...audioOptions,
      ];
}
