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
  final bool collapsibleSections;
  final bool videoInitiallyExpanded;
  final bool audioInitiallyExpanded;
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
    this.collapsibleSections = true,
    this.videoInitiallyExpanded = true,
    this.audioInitiallyExpanded = false,
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

  List<Widget> _buildVideoSection() {
    final content = _buildVideoContent();
    if (!collapsibleSections) return content;

    return [
      _MediaAttachmentExpansion(
        icon: Icons.ondemand_video_rounded,
        title: 'Video',
        subtitle: videoType == 'youtube'
            ? 'YouTube link, saved video, or upload'
            : 'Uploaded file, direct link, or saved video',
        initiallyExpanded: videoInitiallyExpanded,
        children: content,
      ),
    ];
  }

  List<Widget> _buildVideoContent() => [
        _MediaSourceSelector(
          title: collapsibleSections ? 'Source' : 'Video',
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
        if (videoType == 'youtube')
          _YouTubeVideoField(
            controller: youtubeVideoController,
            previewTitle: videoPreviewTitle,
            compactPreview: compactPreviews,
          )
        else
          _DirectVideoField(
            controller: directVideoController,
            pendingName: pendingVideoName,
            onPick: onPickVideo,
            previewTitle: videoPreviewTitle,
            compactPreview: compactPreviews,
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

  List<Widget> _buildAudioSection() {
    final content = _buildAudioContent();
    if (!collapsibleSections) return content;

    return [
      _MediaAttachmentExpansion(
        icon: Icons.music_note_rounded,
        title: 'Music',
        subtitle: audioType == 'youtube'
            ? 'YouTube audio, saved music, or MP3'
            : 'MP3 file, audio link, or saved music',
        initiallyExpanded: audioInitiallyExpanded,
        children: content,
      ),
    ];
  }

  List<Widget> _buildAudioContent() => [
        _MediaSourceSelector(
          title: collapsibleSections ? 'Source' : 'Music',
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
        _AudioField(
          controller: audioController,
          audioType: audioType,
          pendingName: pendingAudioName,
          onPick: onPickAudio,
          previewTitle: audioPreviewTitle,
          compactPreview: compactPreviews,
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

class _MediaAttachmentExpansion extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool initiallyExpanded;
  final List<Widget> children;

  const _MediaAttachmentExpansion({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.initiallyExpanded,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          maintainState: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Icon(icon, color: cs.primary),
          title: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          children: children,
        ),
      ),
    );
  }
}
