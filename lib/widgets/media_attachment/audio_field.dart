part of '../media_attachment_fields.dart';

class _AudioField extends StatelessWidget {
  final TextEditingController controller;
  final String audioType;
  final String? pendingName;
  final VoidCallback onPick;
  final String previewTitle;
  final bool compactPreview;

  const _AudioField({
    required this.controller,
    required this.audioType,
    required this.pendingName,
    required this.onPick,
    required this.previewTitle,
    required this.compactPreview,
  });

  @override
  Widget build(BuildContext context) {
    final url = controller.text.trim();
    final isYoutube = audioType == 'youtube';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: isYoutube ? 'YouTube music link' : 'MP3/audio link',
            hintText:
                isYoutube ? 'https://youtu.be/...' : 'Upload below or paste URL',
            prefixIcon: const Icon(Icons.music_note_rounded),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty || pendingName != null) return null;
            if (isYoutube && youtubeVideoIdFromUrl(text) == null) {
              return 'Enter a valid YouTube link';
            }
            if (!isYoutube && !_isHttpUrl(text)) {
              return 'Enter a valid audio link';
            }
            return null;
          },
        ),
        if (isYoutube && url.isNotEmpty && youtubeVideoIdFromUrl(url) != null) ...[
          const SizedBox(height: 12),
          YouTubeVideoPreview(
            url: url,
            title: previewTitle,
            subtitle: 'Music preview',
            compact: compactPreview,
          ),
        ],
        if (!isYoutube) ...[
          const SizedBox(height: 8),
          _PickFileButton(
            icon: Icons.audio_file_rounded,
            label: 'Choose audio file',
            pendingName: pendingName,
            onPressed: onPick,
          ),
        ],
      ],
    );
  }
}
