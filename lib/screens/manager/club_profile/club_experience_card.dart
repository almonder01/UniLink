part of '../club_profile_tab.dart';

class _ClubExperienceCard extends StatelessWidget {
  final TextEditingController backgroundVideoCtrl;
  final String backgroundVideoType;
  final ValueChanged<String> onBackgroundVideoTypeChanged;
  final bool backgroundVideoAutoOpen;
  final ValueChanged<bool> onBackgroundVideoAutoOpenChanged;
  final String? pendingBackgroundVideoName;
  final VoidCallback onUploadBackgroundVideo;
  final List<MediaAsset> videoAssets;
  final ValueChanged<MediaAsset> onVideoAssetSelected;
  final TextEditingController musicCtrl;
  final String musicType;
  final ValueChanged<String> onMusicTypeChanged;
  final bool musicAutoPlay;
  final ValueChanged<bool> onMusicAutoPlayChanged;
  final String? pendingMusicName;
  final VoidCallback onUploadMusic;
  final List<MediaAsset> audioAssets;
  final ValueChanged<MediaAsset> onAudioAssetSelected;
  final TextEditingController featureTitleCtrl;
  final TextEditingController featureDescCtrl;
  final TextEditingController featureCodeCtrl;

  const _ClubExperienceCard({
    required this.backgroundVideoCtrl,
    required this.backgroundVideoType,
    required this.onBackgroundVideoTypeChanged,
    required this.backgroundVideoAutoOpen,
    required this.onBackgroundVideoAutoOpenChanged,
    required this.pendingBackgroundVideoName,
    required this.onUploadBackgroundVideo,
    required this.videoAssets,
    required this.onVideoAssetSelected,
    required this.musicCtrl,
    required this.musicType,
    required this.onMusicTypeChanged,
    required this.musicAutoPlay,
    required this.onMusicAutoPlayChanged,
    required this.pendingMusicName,
    required this.onUploadMusic,
    required this.audioAssets,
    required this.onAudioAssetSelected,
    required this.featureTitleCtrl,
    required this.featureDescCtrl,
    required this.featureCodeCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MediaAttachmentFields(
              title: 'Club Experience',
              subtitle: 'Choose what visitors can see on the club page.',
              youtubeVideoController: backgroundVideoCtrl,
              directVideoController: backgroundVideoCtrl,
              videoType: backgroundVideoType,
              onVideoTypeChanged: onBackgroundVideoTypeChanged,
              onPickVideo: onUploadBackgroundVideo,
              pendingVideoName: pendingBackgroundVideoName,
              videoAssets: videoAssets,
              selectedVideoUrl: backgroundVideoCtrl.text.trim(),
              onVideoAssetSelected: onVideoAssetSelected,
              audioController: musicCtrl,
              audioType: musicType,
              onAudioTypeChanged: onMusicTypeChanged,
              onPickAudio: onUploadMusic,
              pendingAudioName: pendingMusicName,
              videoPreviewTitle: 'Club background preview',
              audioPreviewTitle: 'Club music preview',
              showAudio: false,
              wrapInCard: false,
              compactPreviews: true,
              videoOptions: [
                MediaAutoOptionSwitch(
                  value: backgroundVideoAutoOpen,
                  onChanged: onBackgroundVideoAutoOpenChanged,
                  title: 'Auto-open video',
                  subtitle: 'Only if the student allows club videos',
                  icon: Icons.ondemand_video_rounded,
                ),
              ],
            ),
            _ExperienceExpansion(
              icon: Icons.music_note_rounded,
              title: 'Background music',
              children: [
                MediaAttachmentFields(
                  youtubeVideoController: backgroundVideoCtrl,
                  directVideoController: backgroundVideoCtrl,
                  videoType: backgroundVideoType,
                  onVideoTypeChanged: onBackgroundVideoTypeChanged,
                  onPickVideo: onUploadBackgroundVideo,
                  pendingVideoName: pendingBackgroundVideoName,
                  audioController: musicCtrl,
                  audioType: musicType,
                  onAudioTypeChanged: onMusicTypeChanged,
                  onPickAudio: onUploadMusic,
                  pendingAudioName: pendingMusicName,
                  audioAssets: audioAssets,
                  selectedAudioUrl: musicCtrl.text.trim(),
                  onAudioAssetSelected: onAudioAssetSelected,
                  videoPreviewTitle: 'Club background preview',
                  audioPreviewTitle: 'Club music preview',
                  showVideo: false,
                  wrapInCard: false,
                  compactPreviews: true,
                  audioOptions: [
                    MediaAutoOptionSwitch(
                      value: musicAutoPlay,
                      onChanged: onMusicAutoPlayChanged,
                      title: 'Auto-play music',
                      subtitle: 'Only if the student allows club music',
                      icon: Icons.music_note_rounded,
                    ),
                  ],
                ),
              ],
            ),
            _ExperienceExpansion(
              icon: Icons.auto_awesome_rounded,
              title: 'Feature area',
              children: [
                TextFormField(
                  controller: featureTitleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Feature title',
                    hintText: 'Example: Build. Learn. Innovate.',
                    prefixIcon: Icon(Icons.auto_awesome_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: featureDescCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Feature description',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 34),
                      child: Icon(Icons.short_text_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: featureCodeCtrl,
                  minLines: 3,
                  maxLines: 6,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    labelText: 'Visual code snippet (optional)',
                    hintText: 'print("Welcome to Tech Club");',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 58),
                      child: Icon(Icons.code_rounded),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExperienceExpansion extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _ExperienceExpansion({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        leading: Icon(icon, color: cs.primary),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        children: children,
      ),
    );
  }
}
