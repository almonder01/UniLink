import 'package:flutter/material.dart';

import '../models/media_asset.dart';
import 'media_attachment_fields.dart';
import 'media_auto_option_switch.dart';

class PublishMediaAttachmentFields extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController youtubeVideoController;
  final TextEditingController directVideoController;
  final String videoType;
  final ValueChanged<String> onVideoTypeChanged;
  final VoidCallback onPickVideo;
  final String? pendingVideoName;
  final List<MediaAsset> videoAssets;
  final String? selectedVideoUrl;
  final ValueChanged<MediaAsset> onVideoAssetSelected;
  final bool videoAutoOpen;
  final ValueChanged<bool> onVideoAutoOpenChanged;
  final TextEditingController audioController;
  final String audioType;
  final ValueChanged<String> onAudioTypeChanged;
  final VoidCallback onPickAudio;
  final String? pendingAudioName;
  final List<MediaAsset> audioAssets;
  final String? selectedAudioUrl;
  final ValueChanged<MediaAsset> onAudioAssetSelected;
  final bool audioAutoPlay;
  final ValueChanged<bool> onAudioAutoPlayChanged;
  final String videoPreviewTitle;
  final String audioPreviewTitle;

  const PublishMediaAttachmentFields({
    super.key,
    required this.title,
    required this.subtitle,
    required this.youtubeVideoController,
    required this.directVideoController,
    required this.videoType,
    required this.onVideoTypeChanged,
    required this.onPickVideo,
    this.pendingVideoName,
    required this.videoAssets,
    this.selectedVideoUrl,
    required this.onVideoAssetSelected,
    required this.videoAutoOpen,
    required this.onVideoAutoOpenChanged,
    required this.audioController,
    required this.audioType,
    required this.onAudioTypeChanged,
    required this.onPickAudio,
    this.pendingAudioName,
    required this.audioAssets,
    this.selectedAudioUrl,
    required this.onAudioAssetSelected,
    required this.audioAutoPlay,
    required this.onAudioAutoPlayChanged,
    required this.videoPreviewTitle,
    required this.audioPreviewTitle,
  });

  @override
  Widget build(BuildContext context) {
    return MediaAttachmentFields(
      title: title,
      subtitle: subtitle,
      youtubeVideoController: youtubeVideoController,
      directVideoController: directVideoController,
      videoType: videoType,
      onVideoTypeChanged: onVideoTypeChanged,
      onPickVideo: onPickVideo,
      pendingVideoName: pendingVideoName,
      videoAssets: videoAssets,
      selectedVideoUrl: selectedVideoUrl,
      onVideoAssetSelected: onVideoAssetSelected,
      videoOptions: [
        MediaAutoOptionSwitch(
          value: videoAutoOpen,
          onChanged: onVideoAutoOpenChanged,
          title: 'Auto-open video',
          subtitle: 'Only if the student allows post/event videos',
          icon: Icons.ondemand_video_rounded,
        ),
      ],
      audioController: audioController,
      audioType: audioType,
      onAudioTypeChanged: onAudioTypeChanged,
      onPickAudio: onPickAudio,
      pendingAudioName: pendingAudioName,
      audioAssets: audioAssets,
      selectedAudioUrl: selectedAudioUrl,
      onAudioAssetSelected: onAudioAssetSelected,
      videoPreviewTitle: videoPreviewTitle,
      audioPreviewTitle: audioPreviewTitle,
      audioOptions: [
        MediaAutoOptionSwitch(
          value: audioAutoPlay,
          onChanged: onAudioAutoPlayChanged,
          title: 'Auto-play music',
          subtitle: 'Only if the student allows post/event music',
          icon: Icons.music_note_rounded,
        ),
      ],
    );
  }
}
